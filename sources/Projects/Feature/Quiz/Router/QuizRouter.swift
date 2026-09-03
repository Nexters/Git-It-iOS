import ComposableArchitecture
import SwiftUI
import UIComponent

public struct QuizRouter: View {

    // MARK: Lifecycle

    public init(store: StoreOf<QuizRouterFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable private var store: StoreOf<QuizRouterFeature>

    public var body: some View {
        ScreenContainer { _ in
            content
        }
    }

    // MARK: Private

    @ViewBuilder
    private var content: some View {
        switch store.activeScreen {
        case .learningSetIntro:
            LearningSetIntroScreen(
                store: store.scope(state: \.learningSetIntro, action: \.learningSetIntro)
            )

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
