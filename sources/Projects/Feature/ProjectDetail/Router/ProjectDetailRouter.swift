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

    public var body: some View {
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

    // MARK: Private

    @Bindable private var store: StoreOf<ProjectDetailRouterFeature>

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

    private var pushedScreens: [ProjectDetailRouterFeature.ActiveScreen] {
        switch store.activeScreen {
        case .projectDetail:
            []

        case .savedQuestions:
            [.savedQuestions]

        case .singleQuestion:
            [.savedQuestions, .singleQuestion]
        }
    }

    private var content: some View {
        FlowNavigationStack(path: pushedScreens) {
            ProjectDetailScreen(
                store: store.scope(state: \.projectDetail, action: \.projectDetail)
            )
        } destination: { screen in
            pushedScreen(screen)
        }
    }

    @ViewBuilder
    private func pushedScreen(_ screen: ProjectDetailRouterFeature.ActiveScreen) -> some View {
        switch screen {
        case .projectDetail:
            EmptyView()

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
