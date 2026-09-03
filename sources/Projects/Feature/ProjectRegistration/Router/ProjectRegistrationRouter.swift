import ComposableArchitecture
import SwiftUI
import UIComponent

public struct ProjectRegistrationRouter: View {

    public init(store: StoreOf<ProjectRegistrationRouterFeature>) {
        self.store = store
    }

    @Bindable private var store: StoreOf<ProjectRegistrationRouterFeature>

    public var body: some View {
        ScreenContainer { _ in
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.activeScreen {
        case .repositoryLinkInput:
            RepositoryLinkInputScreen(
                store: store.scope(state: \.repositoryLinkInput, action: \.repositoryLinkInput)
            )

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
