import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

@ViewAction(for: ProjectDetailRouterFeature.self)
public struct ProjectDetailRouter: View {

    // MARK: Lifecycle

    public init(store: StoreOf<ProjectDetailRouterFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<ProjectDetailRouterFeature>

    public var body: some View {
        content
            .overlay {
                if store.singleQuestionEntry.isPreparing {
                    entryOverlay
                }
            }
            .alert(
                LocalizedText.ProjectDetail.SingleQuestion.Failure.title,
                isPresented: entryFailureBinding,
            ) {
                Button(
                    LocalizedText.ProjectDetail.SingleQuestion.FailureConfirm.buttonTitle,
                    role: .cancel,
                ) {
                    send(.singleQuestionFailureDismissed)
                }
            } message: {
                Text(LocalizedText.ProjectDetail.SingleQuestion.Failure.message)
            }
    }

    // MARK: Private

    private var entryFailureBinding: Binding<Bool> {
        Binding(
            get: { store.singleQuestionEntry.preparationError != nil },
            set: { isPresented in
                guard !isPresented else { return }
                send(.singleQuestionFailureDismissed)
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
                store: store.scope(
                    state: \.projectDetail,
                    action: \.projectDetail,
                )
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
                store: store.scope(
                    state: \.savedQuestions,
                    action: \.savedQuestions,
                )
            )

        case .singleQuestion:
            if
                let singleQuestionStore = store.scope(
                    state: \.singleQuestion,
                    action: \.singleQuestion,
                )
            {
                QuestionSolvingScreen(store: singleQuestionStore)
            }
        }
    }

}
