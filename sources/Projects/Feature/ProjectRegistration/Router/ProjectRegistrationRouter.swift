import ComposableArchitecture
import SwiftUI
import UIComponent

public struct ProjectRegistrationRouter: View {

    // MARK: Lifecycle

    public init(store: StoreOf<ProjectRegistrationRouterFeature>) {
        self.store = store
    }

    // MARK: Public

    public var body: some View {
        ScreenContainer {
            FlowNavigationStack(path: pushedScreens) {
                RepositoryLinkInputScreen(
                    store: store.scope(state: \.repositoryLinkInput, action: \.repositoryLinkInput)
                )
            } destination: { screen in
                pushedScreen(screen)
            }
        }
    }

    // MARK: Private

    @Bindable private var store: StoreOf<ProjectRegistrationRouterFeature>

    private var pushedScreens: [ProjectRegistrationRouterFeature.ActiveScreen] {
        switch store.activeScreen {
        case .repositoryLinkInput:
            []

        case .repositoryConfirmation:
            [.repositoryConfirmation]

        case .quizLevelSelection:
            [.repositoryConfirmation, .quizLevelSelection]

        case .quizGenerationConfirmation:
            [.repositoryConfirmation, .quizLevelSelection, .quizGenerationConfirmation]

        case .quizGenerationProgress:
            [
                .repositoryConfirmation,
                .quizLevelSelection,
                .quizGenerationConfirmation,
                .quizGenerationProgress,
            ]
        }
    }

    @ViewBuilder
    private func pushedScreen(_ screen: ProjectRegistrationRouterFeature.ActiveScreen) -> some View {
        switch screen {
        case .repositoryLinkInput:
            EmptyView()

        case .repositoryConfirmation:
            RepositoryConfirmationScreen(
                store: store.scope(state: \.repositoryConfirmation, action: \.repositoryConfirmation)
            )

        case .quizLevelSelection:
            QuizLevelSelectionScreen(
                store: store.scope(state: \.quizLevelSelection, action: \.quizLevelSelection)
            )

        case .quizGenerationConfirmation:
            QuizGenerationConfirmationScreen(
                store: store.scope(state: \.quizGenerationConfirmation, action: \.quizGenerationConfirmation)
            )

        case .quizGenerationProgress:
            QuizGenerationProgressScreen(
                store: store.scope(state: \.quizGenerationProgress, action: \.quizGenerationProgress)
            )
        }
    }

}
