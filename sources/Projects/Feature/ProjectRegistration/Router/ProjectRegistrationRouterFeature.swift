import ComposableArchitecture
import DomainLearningProject
import Foundation

@Reducer
public struct ProjectRegistrationRouterFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchExternalRepository: any FetchExternalRepositoryUseCase,
        createLearningProject: any CreateLearningProjectUseCase,
        observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase,
        requestGenerationReminder: any RequestGenerationReminderUseCase,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
        waitPolicy: GenerationWaitPolicy = .standard,
        now: @escaping @Sendable () -> Date = { Date() },
    ) {
        self.fetchExternalRepository = fetchExternalRepository
        self.createLearningProject = createLearningProject
        self.observeGenerationOutcomes = observeGenerationOutcomes
        self.requestGenerationReminder = requestGenerationReminder
        self.openNotificationSettings = openNotificationSettings
        self.waitPolicy = waitPolicy
        self.now = now
    }

    // MARK: Public

    public enum ActiveScreen: Hashable, Sendable {
        case repositoryLinkInput
        case repositoryConfirmation
        case quizLevelSelection
        case quizGenerationConfirmation
        case quizGenerationProgress
    }

    public struct ScreenTransition: Equatable, Sendable {
        public let from: ActiveScreen
        public let to: ActiveScreen
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        public init() { }

        public var activeScreen = ActiveScreen.repositoryLinkInput
        public var screenTransitions = [ScreenTransition]()

        public var repositoryLinkInput = RepositoryLinkInputFeature.State()
        public var repositoryConfirmation = RepositoryConfirmationFeature.State()
        public var quizLevelSelection = QuizLevelSelectionFeature.State()
        public var quizGenerationConfirmation = QuizGenerationConfirmationFeature.State()
        public var quizGenerationProgress = QuizGenerationProgressFeature.State()

    }

    public enum Action: Sendable, Equatable {
        case repositoryLinkInput(RepositoryLinkInputFeature.Action)
        case repositoryConfirmation(RepositoryConfirmationFeature.Action)
        case quizLevelSelection(QuizLevelSelectionFeature.Action)
        case quizGenerationConfirmation(QuizGenerationConfirmationFeature.Action)
        case quizGenerationProgress(QuizGenerationProgressFeature.Action)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectRegistered(ProjectRegistrationReceipt)
            case generationReminderPreferenceSelected(isEnabled: Bool)
            case dismissRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.repositoryLinkInput, action: \.repositoryLinkInput) {
            RepositoryLinkInputFeature(fetchExternalRepository: fetchExternalRepository)
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
        Scope(state: \.quizGenerationProgress, action: \.quizGenerationProgress) {
            QuizGenerationProgressFeature(
                createLearningProject: createLearningProject,
                observeGenerationOutcomes: observeGenerationOutcomes,
                requestGenerationReminder: requestGenerationReminder,
                openNotificationSettings: openNotificationSettings,
                waitPolicy: waitPolicy,
                now: now,
            )
        }
        Reduce { state, action in
            switch action {
            case .repositoryLinkInput(.delegate(.repositoryValidated(let repository))):
                state.repositoryConfirmation.repository = repository
                return activate(.repositoryConfirmation, state: &state)

            case .repositoryLinkInput(.delegate(.dismissRequested)):
                return .send(.delegate(.dismissRequested))

            case .repositoryConfirmation(.delegate(.confirmed)):
                return activate(.quizLevelSelection, state: &state)

            case .repositoryConfirmation(.delegate(.rejected)):
                state.repositoryLinkInput.validation = .idle
                state.repositoryConfirmation.repository = nil
                return activate(.repositoryLinkInput, state: &state)

            case .quizLevelSelection(.delegate(.confirmed)):
                return activate(.quizGenerationConfirmation, state: &state)

            case .quizLevelSelection(.delegate(.backRequested)):
                return activate(.repositoryConfirmation, state: &state)

            case .quizGenerationConfirmation(.delegate(.submitRequested)):
                guard let repository = state.repositoryConfirmation.repository else { return .none }
                let quizLevel = state.quizLevelSelection.quizLevel
                return .merge(
                    activate(.quizGenerationProgress, state: &state),
                    .send(.quizGenerationProgress(.submit(repository: repository, quizLevel: quizLevel))),
                )

            case .quizGenerationConfirmation(.delegate(.backRequested)):
                return activate(.quizLevelSelection, state: &state)

            case .quizGenerationProgress(.delegate(.projectRegistered(let receipt))):
                return .send(.delegate(.projectRegistered(receipt)))

            case .quizGenerationProgress(.delegate(.generationReminderPreferenceSelected(let isEnabled))):
                return .send(.delegate(.generationReminderPreferenceSelected(isEnabled: isEnabled)))

            case .quizGenerationProgress(.delegate(.dismissRequested)):
                return .send(.delegate(.dismissRequested))

            case .repositoryLinkInput,
                 .repositoryConfirmation,
                 .quizLevelSelection,
                 .quizGenerationConfirmation,
                 .quizGenerationProgress,
                 .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private let fetchExternalRepository: any FetchExternalRepositoryUseCase
    private let createLearningProject: any CreateLearningProjectUseCase
    private let observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase
    private let requestGenerationReminder: any RequestGenerationReminderUseCase
    private let openNotificationSettings: @MainActor @Sendable () async -> Void
    private let waitPolicy: GenerationWaitPolicy
    private let now: @Sendable () -> Date

    private func activate(
        _ screen: ActiveScreen,
        state: inout State,
    ) -> Effect<Action> {
        guard state.activeScreen != screen else { return .none }
        state.screenTransitions.append(ScreenTransition(from: state.activeScreen, to: screen))
        state.activeScreen = screen
        return .none
    }

}
