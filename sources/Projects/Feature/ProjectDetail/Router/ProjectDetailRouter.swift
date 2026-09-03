import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

public struct ProjectDetailRouter: View {

    // MARK: Lifecycle

    public init(store: StoreOf<ProjectDetailRouterFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<ProjectDetailRouterFeature>

    public var body: some View {
        ScreenContainer { _ in
            content
                .overlay {
                    if store.singleQuestionEntry.isPreparing {
                        entryOverlay
                    }
                }
                .alert("문제를 불러오지 못했어요", isPresented: entryFailureBinding) {
                    Button("확인", role: .cancel) {
                        store.send(.singleQuestionEntry(.input(.failureDismissed)))
                    }
                } message: {
                    Text("잠시 후 다시 시도해 주세요.")
                }
        }
    }

    // MARK: Private

    private var entryFailureBinding: Binding<Bool> {
        Binding(
            get: { store.singleQuestionEntry.preparationError != nil },
            set: { isPresented in
                guard !isPresented else { return }
                store.send(.singleQuestionEntry(.input(.failureDismissed)))
            },
        )
    }

    private var entryOverlay: some View {
        ZStack {
            Color(designSystem: ColorToken.black)
                .designSystemOpacity(.scrim)
                .ignoresSafeArea()

            ProgressView()
                .tint(Color(designSystem: .blue100))
        }
        .accessibilityLabel("문제를 불러오는 중")
    }

    @ViewBuilder
    private var content: some View {
        switch store.activeScreen {
        case .projectDetail:
            ProjectDetailScreen(
                store: store.scope(state: \.projectDetail, action: \.projectDetail)
            )

        case .savedQuestions:
            SavedScreen(
                store: store.scope(state: \.savedQuestions, action: \.savedQuestions)
            )

        case .singleQuestion:
            if let singleQuestionStore = store.scope(state: \.singleQuestion, action: \.singleQuestion) {
                QuestionSolvingScreen(store: singleQuestionStore)
            }
        }
    }

}
