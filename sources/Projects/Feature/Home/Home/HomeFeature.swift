import ComposableArchitecture
import DomainLearningProject
import DomainMember

@Reducer
public struct HomeFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchLearningProjects: any FetchLearningProjectsUseCase,
        fetchMemberProfile: any FetchMemberProfileUseCase,
        observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase,
    ) {
        self.fetchLearningProjects = fetchLearningProjects
        self.fetchMemberProfile = fetchMemberProfile
        self.observeGenerationOutcomes = observeGenerationOutcomes
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public enum ProfileLoad: Equatable, Sendable {
            case idle
            case loading
            case loaded(MemberProfile)
            case failed(MemberError)
        }

        public enum ProjectLoad: Equatable, Sendable {
            case idle
            case loading
            case loaded(LearningProjectPage)
            case failed(LearningProjectError)

            var isLoaded: Bool {
                if case .loaded = self {
                    return true
                }
                return false
            }
        }

        public enum GenerationOutcomeObservation: Equatable, Sendable {
            case idle
            case observing
        }

        public var profileLoad = ProfileLoad.idle
        public var projectLoad = ProjectLoad.idle
        public var profileRequestID = 0
        public var projectRequestID = 0
        public var generationOutcomeObservation = GenerationOutcomeObservation.idle

        public var isProjectRefreshPending = false

        public var appliedOutcomeProjectIDs = Set<String>()

        public var isGenerationInProgress = false

    }

    public enum Action: ViewAction, Equatable, Sendable {
        case view(View)
        case input(Input)
        case effect(Effect)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Equatable, Sendable {
            case task
            case profileRetryTapped
            case projectRetryTapped
            case projectRegistrationTapped
            case showAllProjectsTapped
            case projectCardTapped(projectID: String)
            case learningTapped(projectID: String)
        }

        @CasePathable
        public enum Input: Equatable, Sendable {
            case learningProjectsReloadRequested
            case generationProgressChanged(isInProgress: Bool)
        }

        @CasePathable
        public enum Effect: Equatable, Sendable {
            case profileLoadFinished(requestID: Int, result: Result<MemberProfile, MemberError>)
            case projectsLoadFinished(requestID: Int, result: Result<LearningProjectPage, LearningProjectError>)
            case generationOutcomeReceived(GenerationOutcome)
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case projectRegistrationRequested
            case projectDetailRequested(projectID: String)
            case learningRequested(projectID: String, nextSetID: String)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task):
                var effects = [ComposableArchitecture.Effect<Action>]()
                if state.profileLoad == .idle {
                    effects.append(startProfileLoad(state: &state))
                }
                if state.projectLoad == .idle {
                    effects.append(startProjectLoad(state: &state))
                }
                if state.generationOutcomeObservation == .idle {
                    state.generationOutcomeObservation = .observing
                    effects.append(startGenerationOutcomeObservation())
                }
                return .merge(effects)

            case .input(.learningProjectsReloadRequested):
                guard state.projectLoad != .loading else {
                    state.isProjectRefreshPending = true
                    return .none
                }
                return startProjectLoad(state: &state)

            case .view(.profileRetryTapped):
                guard case .failed = state.profileLoad else { return .none }
                return startProfileLoad(state: &state)

            case .view(.projectRetryTapped):
                guard case .failed = state.projectLoad else { return .none }
                return startProjectLoad(state: &state)

            case .input(.generationProgressChanged(let isInProgress)):
                state.isGenerationInProgress = isInProgress
                return .none

            case .view(.projectRegistrationTapped):
                guard !state.isGenerationInProgress else { return .none }
                return .send(.delegate(.projectRegistrationRequested))

            case .view(.showAllProjectsTapped):
                return .none

            case .view(.projectCardTapped(let projectID)):
                return .send(.delegate(.projectDetailRequested(projectID: projectID)))

            case .view(.learningTapped(let projectID)):
                guard
                    case .loaded(let page) = state.projectLoad,
                    let project = page.items.first(where: { $0.projectID == projectID }),
                    let nextSetID = project.nextSetID,
                    project.nextQuestionID != nil
                else { return .none }
                return .send(
                    .delegate(.learningRequested(projectID: projectID, nextSetID: nextSetID))
                )

            case .effect(.profileLoadFinished(let requestID, let result)):
                guard requestID == state.profileRequestID else { return .none }
                switch result {
                case .success(let profile): state.profileLoad = .loaded(profile)
                case .failure(let error): state.profileLoad = .failed(error)
                }
                return .none

            case .effect(.projectsLoadFinished(let requestID, let result)):
                guard requestID == state.projectRequestID else { return .none }
                switch result {
                case .success(let page):
                    state.projectLoad = .loaded(page)

                case .failure(let error):
                    if !state.projectLoad.isLoaded {
                        state.projectLoad = .failed(error)
                    }
                }

                guard state.isProjectRefreshPending else { return .none }
                state.isProjectRefreshPending = false
                return startProjectLoad(state: &state)

            case .effect(.generationOutcomeReceived(let outcome)):
                guard state.appliedOutcomeProjectIDs.insert(outcome.projectID).inserted else { return .none }
                guard state.projectLoad != .loading else {
                    state.isProjectRefreshPending = true
                    return .none
                }
                return startProjectLoad(state: &state)

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID {
        case profile
        case projects
    }

    private let fetchLearningProjects: any FetchLearningProjectsUseCase
    private let fetchMemberProfile: any FetchMemberProfileUseCase
    private let observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase

    private func startProfileLoad(state: inout State) -> ComposableArchitecture.Effect<Action> {
        state.profileRequestID += 1
        state.profileLoad = .loading
        let requestID = state.profileRequestID
        let fetchMemberProfile = fetchMemberProfile

        return .run { send in
            do {
                await send(.effect(.profileLoadFinished(requestID: requestID, result: .success(try await fetchMemberProfile()))))
            } catch let error as MemberError {
                await send(.effect(.profileLoadFinished(requestID: requestID, result: .failure(error))))
            } catch {
                await send(.effect(.profileLoadFinished(requestID: requestID, result: .failure(.temporarilyUnavailable))))
            }
        }
        .cancellable(id: CancelID.profile, cancelInFlight: true)
    }

    private func startProjectLoad(state: inout State) -> ComposableArchitecture.Effect<Action> {
        state.projectRequestID += 1
        if !state.projectLoad.isLoaded {
            state.projectLoad = .loading
        }
        let requestID = state.projectRequestID
        let fetchLearningProjects = fetchLearningProjects

        return .run { send in
            do {
                await send(.effect(.projectsLoadFinished(
                    requestID: requestID,
                    result: .success(try await fetchLearningProjects()),
                )))
            } catch let error as LearningProjectError {
                await send(.effect(.projectsLoadFinished(requestID: requestID, result: .failure(error))))
            } catch {
                await send(.effect(.projectsLoadFinished(requestID: requestID, result: .failure(.unexpected))))
            }
        }
        .cancellable(id: CancelID.projects, cancelInFlight: true)
    }

    private func startGenerationOutcomeObservation() -> ComposableArchitecture.Effect<Action> {
        let observeGenerationOutcomes = observeGenerationOutcomes
        return .run { send in
            for await outcome in await observeGenerationOutcomes() {
                await send(.effect(.generationOutcomeReceived(outcome)))
            }
        }
    }

}
