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
    ) {
        self.fetchExternalRepository = fetchExternalRepository
        self.createLearningProject = createLearningProject
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
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case validationFinished(requestID: Int, result: Result<ExternalRepository, ExternalRepositoryError>)
            case submissionFinished(Result<ProjectRegistrationReceipt, LearningProjectError>)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectRegistered(ProjectRegistrationReceipt)
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
                state.submission = .committing
                let quizLevel = state.quizLevel
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
                state.submission = .idle
                return .send(.delegate(.projectRegistered(receipt)))

            case .effect(.submissionFinished(.failure(let error))):
                state.submission = .failed(error)
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case validation
        case submission
    }

    private let fetchExternalRepository: any FetchExternalRepositoryUseCase
    private let createLearningProject: any CreateLearningProjectUseCase

}
