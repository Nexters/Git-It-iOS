import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

public struct QuizRouter: View {

    // MARK: Lifecycle

    public init(store: StoreOf<QuizRouterFeature>) {
        self.store = store
    }

    // MARK: Public

    public var body: some View {
        FlowNavigationStack(path: pushedScreens) {
            LearningSetIntroScreen(
                store: store.scope(state: \.learningSetIntro, action: \.learningSetIntro)
            )
        } destination: { screen in
            pushedScreen(screen)
        }
    }

    // MARK: Private

    @Bindable private var store: StoreOf<QuizRouterFeature>

    private var pushedScreens: [QuizRouterFeature.ActiveScreen] {
        switch store.activeScreen {
        case .learningSetIntro:
            []

        case .questionSolving:
            [.questionSolving]

        case .learningCompletion:
            [.questionSolving, .learningCompletion]
        }
    }

    @ViewBuilder
    private func pushedScreen(_ screen: QuizRouterFeature.ActiveScreen) -> some View {
        switch screen {
        case .learningSetIntro:
            EmptyView()

        case .questionSolving:
            if let questionSolvingStore = store.scope(state: \.questionSolving, action: \.questionSolving) {
                QuestionSolvingScreen(store: questionSolvingStore)
            }

        case .learningCompletion:
            LearningCompletionScreen(
                store: store.scope(state: \.learningCompletion, action: \.learningCompletion)
            )
        }
    }

}
