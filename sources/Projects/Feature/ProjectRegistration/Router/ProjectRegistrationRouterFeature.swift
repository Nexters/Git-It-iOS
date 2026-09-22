import ComposableArchitecture
import DomainAppSetting
import DomainExternalRepository
import DomainProjectGeneration

@Reducer
public struct ProjectRegistrationRouterFeature: Sendable {

    // MARK: Lifecycle

    public init(
        externalRepository: any ExternalRepositoryUseCase,
        projectGeneration: any ProjectGenerationUseCase,
        appSetting: any AppSettingUseCase,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
    ) {
        self.externalRepository = externalRepository
        self.projectGeneration = projectGeneration
        self.appSetting = appSetting
        self.openNotificationSettings = openNotificationSettings
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
            case projectRegistered(ProjectGenerationReceipt)
            case generationReminderPreferenceSelected(isEnabled: Bool)
            case dismissRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(
            state: \.repositoryLinkInput,
            action: \.repositoryLinkInput,
        ) {
            RepositoryLinkInputFeature(
                repository: { [externalRepository] in try await externalRepository.repository(at: $0) }
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
        Scope(
            state: \.quizGenerationProgress,
            action: \.quizGenerationProgress,
        ) {
            QuizGenerationProgressFeature(
                requestGeneration: { [projectGeneration] in try await projectGeneration.request($0) },
                generationStates: { [projectGeneration] in await projectGeneration.states() },
                notificationAuthorization: { [appSetting] in await appSetting.notificationAuthorization() },
                requestNotificationAuthorization: { [appSetting] in
                    await appSetting.requestNotificationAuthorization()
                },
                openNotificationSettings: openNotificationSettings,
            )
        }
        Reduce { state, action in
            switch action {
            case .repositoryLinkInput(.delegate(.repositoryValidated(let repository))):
                return .merge(
                    .send(.repositoryConfirmation(.input(.repositoryProvided(repository)))),
                    activate(
                        .repositoryConfirmation,
                        state: &state,
                    ),
                )

            case .repositoryLinkInput(.delegate(.dismissRequested)):
                return .send(.delegate(.dismissRequested))

            case .repositoryConfirmation(.delegate(.confirmed)):
                return activate(
                    .quizLevelSelection,
                    state: &state,
                )

            case .repositoryConfirmation(.delegate(.rejected)):
                return .merge(
                    .send(.repositoryLinkInput(.input(.validationReset))),
                    .send(.repositoryConfirmation(.input(.cleared))),
                    activate(
                        .repositoryLinkInput,
                        state: &state,
                    ),
                )

            case .quizLevelSelection(.delegate(.confirmed)):
                return activate(
                    .quizGenerationConfirmation,
                    state: &state,
                )

            case .quizLevelSelection(.delegate(.backRequested)):
                return activate(
                    .repositoryConfirmation,
                    state: &state,
                )

            case .quizGenerationConfirmation(.delegate(.submitRequested)):
                guard let repository = state.repositoryConfirmation.repository else { return .none }
                let quizLevel = state.quizLevelSelection.quizLevel
                return .merge(
                    activate(
                        .quizGenerationProgress,
                        state: &state,
                    ),
                    .send(.quizGenerationProgress(.submit(
                        repository: repository,
                        quizLevel: quizLevel,
                    ))),
                )

            case .quizGenerationConfirmation(.delegate(.backRequested)):
                return activate(
                    .quizLevelSelection,
                    state: &state,
                )

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

    private let externalRepository: any ExternalRepositoryUseCase
    private let projectGeneration: any ProjectGenerationUseCase
    private let appSetting: any AppSettingUseCase
    private let openNotificationSettings: @MainActor @Sendable () async -> Void

    private func activate(
        _ screen: ActiveScreen,
        state: inout State,
    ) -> Effect<Action> {
        guard state.activeScreen != screen else { return .none }
        state.screenTransitions.append(ScreenTransition(
            from: state.activeScreen,
            to: screen,
        ))
        state.activeScreen = screen
        return .none
    }

}
