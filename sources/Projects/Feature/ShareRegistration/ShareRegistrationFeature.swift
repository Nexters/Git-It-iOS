import ComposableArchitecture
import DomainAccount
import DomainExternalRepository
import DomainIdentifier
import DomainProjectGeneration
import Foundation

// MARK: - ShareRegistrationFeature

@Reducer
public struct ShareRegistrationFeature: Sendable {

    // MARK: Lifecycle

    public init(
        parseRepositoryLink: any ExternalRepositoryLocator,
        externalRepository: any ExternalRepositoryUseCase,
        projectGeneration: any ProjectGenerationUseCase,
        signInAvailability: @escaping @Sendable () async -> SignInAvailability,
        recordDiagnostic: @escaping @Sendable (ShareRegistrationDiagnosticEvent) -> Void = { _ in },
        dismiss: @escaping @MainActor @Sendable () -> Void = { },
    ) {
        self.parseRepositoryLink = parseRepositoryLink
        self.externalRepository = externalRepository
        self.projectGeneration = projectGeneration
        self.signInAvailability = signInAvailability
        self.recordDiagnostic = recordDiagnostic
        self.dismiss = dismiss
    }

    // MARK: Public

    public enum Step: Equatable, Sendable {
        case repositoryConfirmation
        case quizLevelSelection
        case quizGenerationConfirmation
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(sharedURL: String? = nil) {
            registration = SharedRepositoryRegistrationFeature.State(sharedURL: sharedURL)
        }

        // MARK: Public

        public var step = Step.repositoryConfirmation
        public var registration: SharedRepositoryRegistrationFeature.State

        public var repositoryConfirmation = RepositoryConfirmationFeature.State()
        public var quizLevelSelection = QuizLevelSelectionFeature.State()
        public var quizGenerationConfirmation = QuizGenerationConfirmationFeature.State()

        public var repository: ExternalRepository? {
            repositoryConfirmation.repository
        }

        public var quizLevel: QuizLevel {
            quizLevelSelection.quizLevel
        }

        public var isBusy: Bool {
            registration.isSubmitting
        }

        public var canDismiss: Bool {
            !isBusy
        }

        public var canRetry: Bool {
            if case .failed = registration.phase {
                return true
            }
            return false
        }

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case registration(SharedRepositoryRegistrationFeature.Action)
        case repositoryConfirmation(RepositoryConfirmationFeature.Action)
        case quizLevelSelection(QuizLevelSelectionFeature.Action)
        case quizGenerationConfirmation(QuizGenerationConfirmationFeature.Action)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case sharedURLResolved(String?)
            case retryTapped
            case dismissTapped
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case dismissRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.registration, action: \.registration) {
            SharedRepositoryRegistrationFeature(
                parseRepositoryLink: parseRepositoryLink,
                externalRepository: externalRepository,
                projectGeneration: projectGeneration,
                signInAvailability: signInAvailability,
                recordDiagnostic: recordDiagnostic,
            )
        }
        Scope(state: \.repositoryConfirmation, action: \.repositoryConfirmation) {
            RepositoryConfirmationFeature()
        }
        Scope(state: \.quizLevelSelection, action: \.quizLevelSelection) {
            QuizLevelSelectionFeature()
        }
        Scope(state: \.quizGenerationConfirmation, action: \.quizGenerationConfirmation) {
            QuizGenerationConfirmationFeature()
        }
        Reduce { state, action in
            switch action {
            case .view(.task):
                guard let sharedURL = state.registration.sharedURL else { return .none }
                return .send(.registration(.input(.validate(sharedURL: sharedURL))))

            case .view(.sharedURLResolved(let sharedURL)):
                return .send(.registration(.input(.validate(sharedURL: sharedURL))))

            case .view(.retryTapped):
                return .send(.registration(.input(.retry)))

            case .view(.dismissTapped):
                return dismissIfIdle(state)

            case .registration(.delegate(.repositoryResolved(let repository))):
                state.step = .repositoryConfirmation
                return .send(.repositoryConfirmation(.input(.repositoryProvided(repository))))

            case .repositoryConfirmation(.delegate(.confirmed)):
                state.step = .quizLevelSelection
                return .none

            case .repositoryConfirmation(.delegate(.rejected)):
                return dismissIfIdle(state)

            case .quizLevelSelection(.delegate(.confirmed)):
                state.step = .quizGenerationConfirmation
                return .none

            case .quizLevelSelection(.delegate(.backRequested)):
                state.step = .repositoryConfirmation
                return .none

            case .quizGenerationConfirmation(.delegate(.submitRequested)):
                guard let repository = state.repository else { return .none }
                return .send(.registration(.input(.submit(repository: repository, quizLevel: state.quizLevel))))

            case .quizGenerationConfirmation(.delegate(.backRequested)):
                state.step = .quizLevelSelection
                return .none

            case .registration,
                 .repositoryConfirmation,
                 .quizGenerationConfirmation,
                 .quizLevelSelection:
                return .none

            case .delegate(.dismissRequested):
                return .run { _ in await dismiss() }
            }
        }
    }

    // MARK: Private

    private let parseRepositoryLink: any ExternalRepositoryLocator
    private let externalRepository: any ExternalRepositoryUseCase
    private let projectGeneration: any ProjectGenerationUseCase
    private let signInAvailability: @Sendable () async -> SignInAvailability
    private let recordDiagnostic: @Sendable (ShareRegistrationDiagnosticEvent) -> Void
    private let dismiss: @MainActor @Sendable () -> Void

    private func dismissIfIdle(_ state: State) -> Effect<Action> {
        guard state.canDismiss else { return .none }
        return .merge(
            .send(.registration(.input(.cancel))),
            .send(.delegate(.dismissRequested)),
        )
    }

}
