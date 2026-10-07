import ComposableArchitecture
import DomainIdentifier
import DomainProject
import DomainUserInfo

@Reducer
public struct HomeFeature: Sendable {

    // MARK: Lifecycle

    public init(
        projects: @escaping @Sendable () async -> AsyncStream<ProjectList>,
        refreshProjects: @escaping @Sendable () async throws -> Void,
        profile: @escaping @Sendable () async throws -> UserProfile,
    ) {
        self.projects = projects
        self.refreshProjects = refreshProjects
        self.profile = profile
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
            case loaded(UserProfile)
            case failed(UserInfoError)
        }

        public enum ProjectLoad: Equatable, Sendable {
            case idle
            case loading
            case loaded(ProjectList)
            case failed(ProjectError)

            var isLoaded: Bool {
                if case .loaded = self {
                    return true
                }
                return false
            }
        }

        public var profileLoad = ProfileLoad.idle
        public var projectLoad = ProjectLoad.idle
        public var profileRequestID = 0
        public var projectRequestID = 0

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
            case projectCardTapped(projectID: ProjectID)
            case learningTapped(projectID: ProjectID)
        }

        @CasePathable
        public enum Input: Equatable, Sendable {
            case learningProjectsReloadRequested
            case generationProgressChanged(isInProgress: Bool)
        }

        @CasePathable
        public enum Effect: Equatable, Sendable {
            case profileLoadFinished(requestID: Int, result: Result<UserProfile, UserInfoError>)
            case projectsReceived(ProjectList)
            case refreshFinished(requestID: Int, error: ProjectError?)
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case projectRegistrationRequested
            case projectDetailRequested(projectID: ProjectID)
            case learningRequested(projectID: ProjectID, nextSetID: QuizSetID)
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
                effects.append(observeProjects())
                effects.append(startRefresh(state: &state))
                return .merge(effects)

            case .input(.learningProjectsReloadRequested):
                return startRefresh(state: &state)

            case .view(.profileRetryTapped):
                guard case .failed = state.profileLoad else { return .none }
                return startProfileLoad(state: &state)

            case .view(.projectRetryTapped):
                guard case .failed = state.projectLoad else { return .none }
                return startRefresh(state: &state)

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
                    case .loaded(let list) = state.projectLoad,
                    let summary = list.summaries.first(where: { $0.id == projectID }),
                    let next = summary.next,
                    next.quizID != nil
                else { return .none }
                return .send(
                    .delegate(.learningRequested(projectID: projectID, nextSetID: next.setID))
                )

            case .effect(.profileLoadFinished(let requestID, let result)):
                guard requestID == state.profileRequestID else { return .none }
                switch result {
                case .success(let profile): state.profileLoad = .loaded(profile)
                case .failure(let error): state.profileLoad = .failed(error)
                }
                return .none

            case .effect(.projectsReceived(let list)):
                guard list.isLoaded else { return .none }
                state.projectLoad = .loaded(list)
                return .none

            case .effect(.refreshFinished(let requestID, let error)):
                guard requestID == state.projectRequestID else { return .none }
                guard let error, !state.projectLoad.isLoaded else { return .none }
                state.projectLoad = .failed(error)
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID {
        case profile
        case projects
        case refresh
    }

    private let projects: @Sendable () async -> AsyncStream<ProjectList>
    private let refreshProjects: @Sendable () async throws -> Void
    private let profile: @Sendable () async throws -> UserProfile

    private func startProfileLoad(state: inout State) -> ComposableArchitecture.Effect<Action> {
        state.profileRequestID += 1
        state.profileLoad = .loading
        let requestID = state.profileRequestID
        let profile = profile

        return .run { send in
            do {
                await send(.effect(.profileLoadFinished(requestID: requestID, result: .success(try await profile()))))
            } catch let error as UserInfoError {
                await send(.effect(.profileLoadFinished(requestID: requestID, result: .failure(error))))
            } catch {
                await send(.effect(.profileLoadFinished(requestID: requestID, result: .failure(.temporarilyUnavailable))))
            }
        }
        .cancellable(id: CancelID.profile, cancelInFlight: true)
    }

    private func observeProjects() -> ComposableArchitecture.Effect<Action> {
        let projects = projects
        return .run { send in
            for await list in await projects() {
                await send(.effect(.projectsReceived(list)))
            }
        }
        .cancellable(id: CancelID.projects, cancelInFlight: true)
    }

    private func startRefresh(state: inout State) -> ComposableArchitecture.Effect<Action> {
        state.projectRequestID += 1
        if !state.projectLoad.isLoaded {
            state.projectLoad = .loading
        }
        let requestID = state.projectRequestID
        let refreshProjects = refreshProjects

        return .run { send in
            do {
                try await refreshProjects()
                await send(.effect(.refreshFinished(requestID: requestID, error: nil)))
            } catch {
                let mapped = error as? ProjectError ?? .unexpected
                await send(.effect(.refreshFinished(requestID: requestID, error: mapped)))
            }
        }
        .cancellable(id: CancelID.refresh, cancelInFlight: true)
    }

}
