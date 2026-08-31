import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - ProjectRegistrationFeature

@Reducer
public struct ProjectRegistrationFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchExternalRepository: any FetchExternalRepositoryUseCase,
        createLearningProject: any CreateLearningProjectUseCase,
        learningProjectOutcomes: any LearningProjectOutcomesUseCase,
        openNotificationSettings: @escaping @Sendable () async -> Void = { },
    ) {
        self.fetchExternalRepository = fetchExternalRepository
        self.createLearningProject = createLearningProject
        self.learningProjectOutcomes = learningProjectOutcomes
        self.openNotificationSettings = openNotificationSettings
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var repositoryURLInput = ""
        public var quizLevel = QuizLevel.l1
        public var validation = ValidationStatus.idle
        public var submission = SubmissionStatus.idle
        public var validationRequestID = 0
        public var isNotificationOptionSheetPresented = false
    }

    public enum ValidationStatus: Equatable, Sendable {
        case idle
        case validating
        case validated(ExternalRepository)
        case failed
    }

    public enum SubmissionStatus: Equatable, Sendable {
        case idle
        case committing
        case awaitingGeneration(ProjectRegistrationReceipt)
        case failed(LearningProjectError)
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case repositoryURLChanged(String)
            case quizLevelSelected(QuizLevel)
            case validateTapped
            case submitTapped
            case waitAtHomeTapped
            case notificationOptionAccepted
            case notificationOptionDeclined
            case retryTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case validationFinished(requestID: Int, result: Result<ExternalRepository, ExternalRepositoryError>)
            case submissionFinished(Result<ProjectRegistrationReceipt, LearningProjectError>)
            case generationOutcomeReceived(LearningProjectGenerationOutcome)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectRegistered(ProjectRegistrationReceipt)
            case notificationOptionSelected(accepted: Bool)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.repositoryURLChanged(let text)):
                state.repositoryURLInput = text
                state.validation = .idle
                return .none

            case .view(.quizLevelSelected(let level)):
                state.quizLevel = level
                return .none

            case .view(.validateTapped):
                guard !state.repositoryURLInput.isEmpty else { return .none }
                state.validationRequestID += 1
                let currentRequestID = state.validationRequestID
                state.validation = .validating
                let url = state.repositoryURLInput
                return .run { send in
                    do {
                        let repository = try await fetchExternalRepository(url: url)
                        await send(.effect(.validationFinished(requestID: currentRequestID, result: .success(repository))))
                    } catch {
                        let mapped = error as? ExternalRepositoryError ?? .other
                        await send(.effect(.validationFinished(requestID: currentRequestID, result: .failure(mapped))))
                    }
                }
                .cancellable(id: CancelID.validation, cancelInFlight: true)

            case .view(.submitTapped):
                guard
                    case .validated(let repository) = state.validation,
                    state.submission != .committing
                else { return .none }
                return submit(repository: repository, quizLevel: state.quizLevel, state: &state)

            case .view(.retryTapped):
                guard
                    case .failed = state.submission,
                    case .validated(let repository) = state.validation
                else { return .none }
                return submit(repository: repository, quizLevel: state.quizLevel, state: &state)

            case .view(.waitAtHomeTapped):
                guard case .awaitingGeneration = state.submission else { return .none }
                state.isNotificationOptionSheetPresented = true
                return .none

            case .view(.notificationOptionAccepted):
                guard case .awaitingGeneration(let receipt) = state.submission else { return .none }
                state.isNotificationOptionSheetPresented = false
                return .merge(
                    .run { [openNotificationSettings] _ in await openNotificationSettings() },
                    finishWaiting(receipt: receipt, notifyAccepted: true),
                )

            case .view(.notificationOptionDeclined):
                guard case .awaitingGeneration(let receipt) = state.submission else { return .none }
                state.isNotificationOptionSheetPresented = false
                return finishWaiting(receipt: receipt, notifyAccepted: false)

            case .effect(.validationFinished(let requestID, let result)):
                guard requestID == state.validationRequestID else { return .none }
                switch result {
                case .success(let repository):
                    state.validation = .validated(repository)

                case .failure:
                    state.validation = .failed
                }
                return .none

            case .effect(.submissionFinished(.success(let receipt))):
                state.submission = .awaitingGeneration(receipt)
                return observeGenerationOutcomes(projectID: receipt.projectID)

            case .effect(.submissionFinished(.failure(let error))):
                state.submission = .failed(error)
                return .cancel(id: CancelID.generationOutcomeObservation)

            case .effect(.generationOutcomeReceived(let outcome)):
                guard
                    case .awaitingGeneration(let receipt) = state.submission,
                    outcome.projectID == receipt.projectID
                else { return .none }
                switch outcome.status {
                case .completed:
                    return finishWaiting(receipt: receipt, notifyAccepted: nil)

                case .failed:
                    state.submission = .failed(.unexpected)
                    return .cancel(id: CancelID.generationOutcomeObservation)

                @unknown default:
                    return .none
                }

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case validation
        case submission
        case generationOutcomeObservation
    }

    private let fetchExternalRepository: any FetchExternalRepositoryUseCase
    private let createLearningProject: any CreateLearningProjectUseCase
    private let learningProjectOutcomes: any LearningProjectOutcomesUseCase
    private let openNotificationSettings: @Sendable () async -> Void

    private func submit(
        repository: ExternalRepository,
        quizLevel: QuizLevel,
        state: inout State,
    ) -> Effect<Action> {
        state.submission = .committing
        return .run { send in
            do {
                let receipt = try await createLearningProject(
                    githubRepoURL: repository.canonicalURL,
                    quizLevel: quizLevel,
                )
                await send(.effect(.submissionFinished(.success(receipt))))
            } catch {
                let mapped = error as? LearningProjectError ?? .unexpected
                await send(.effect(.submissionFinished(.failure(mapped))))
            }
        }
        .cancellable(id: CancelID.submission)
    }

    private func observeGenerationOutcomes(projectID: String) -> Effect<Action> {
        .run { send in
            for await outcome in await learningProjectOutcomes() where outcome.projectID == projectID {
                await send(.effect(.generationOutcomeReceived(outcome)))
            }
        }
        .cancellable(id: CancelID.generationOutcomeObservation)
    }

    private func finishWaiting(
        receipt: ProjectRegistrationReceipt,
        notifyAccepted: Bool?,
    ) -> Effect<Action> {
        .merge(
            .cancel(id: CancelID.generationOutcomeObservation),
            .run { send in
                if let notifyAccepted {
                    await send(.delegate(.notificationOptionSelected(accepted: notifyAccepted)))
                }
                await send(.delegate(.projectRegistered(receipt)))
            },
        )
    }

}
