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
        Scope(
            state: \.registration,
            action: \.registration,
        ) {
            SharedRepositoryRegistrationFeature(
                parseRepositoryLink: parseRepositoryLink,
                externalRepository: externalRepository,
                projectGeneration: projectGeneration,
                signInAvailability: signInAvailability,
                recordDiagnostic: recordDiagnostic,
            )
        }
        Scope(
            state: \.repositoryConfirmation,
            action: \.repositoryConfirmation,
        ) {
            RepositoryConfirmationFeature()
        }
        Scope(
            state: \.quizLevelSelection,
            action: \.quizLevelSelection,
        ) {
            QuizLevelSelectionFeature()
        }
        Scope(
            state: \.quizGenerationConfirmation,
            action: \.quizGenerationConfirmation,
        ) {
            QuizGenerationConfirmationFeature()
        }
        Reduce { state, action in
            switch action {
            case .view(let action):
                reduce(
                    into: &state,
                    view: action,
                )

            case .registration(let action):
                reduce(
                    into: &state,
                    registration: action,
                )

            case .repositoryConfirmation(let action):
                reduce(
                    into: &state,
                    repositoryConfirmation: action,
                )

            case .quizLevelSelection(let action):
                reduce(
                    into: &state,
                    quizLevelSelection: action,
                )

            case .quizGenerationConfirmation(let action):
                reduce(
                    into: &state,
                    quizGenerationConfirmation: action,
                )

            case .delegate(let action):
                reduce(
                    into: &state,
                    delegate: action,
                )
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

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .task:
            guard let sharedURL = state.registration.sharedURL else { return .none }
            return .send(.registration(.input(.validate(sharedURL: sharedURL))))

        case .sharedURLResolved(let sharedURL):
            return .send(.registration(.input(.validate(sharedURL: sharedURL))))

        case .retryTapped:
            return .send(.registration(.input(.retry)))

        case .dismissTapped:
            return dismissIfIdle(state)
        }
    }

    private func reduce(
        into state: inout State,
        registration action: SharedRepositoryRegistrationFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .repositoryResolved(let repository):
            state.step = .repositoryConfirmation
            return .send(.repositoryConfirmation(.input(.repositoryProvided(repository))))
        }
    }

    private func reduce(
        into state: inout State,
        repositoryConfirmation action: RepositoryConfirmationFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .confirmed:
            state.step = .quizLevelSelection
            return .none

        case .rejected:
            return dismissIfIdle(state)
        }
    }

    private func reduce(
        into state: inout State,
        quizLevelSelection action: QuizLevelSelectionFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .confirmed:
            state.step = .quizGenerationConfirmation
            return .none

        case .backRequested:
            state.step = .repositoryConfirmation
            return .none
        }
    }

    private func reduce(
        into state: inout State,
        quizGenerationConfirmation action: QuizGenerationConfirmationFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .submitRequested:
            guard let repository = state.repository else { return .none }
            return .send(.registration(.input(.submit(
                repository: repository,
                quizLevel: state.quizLevel,
            ))))

        case .backRequested:
            state.step = .quizLevelSelection
            return .none
        }
    }

    private func reduce(
        into _: inout State,
        delegate action: Action.Delegate,
    ) -> Effect<Action> {
        switch action {
        case .dismissRequested:
            .run { _ in await dismiss() }
        }
    }

    private func dismissIfIdle(_ state: State) -> Effect<Action> {
        guard state.canDismiss else { return .none }
        return .merge(
            .send(.registration(.input(.cancel))),
            .send(.delegate(.dismissRequested)),
        )
    }

}
