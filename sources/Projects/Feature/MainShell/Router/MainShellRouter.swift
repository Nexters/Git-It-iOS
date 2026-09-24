import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - MainShellRouter

@ViewAction(for: MainShellRouterFeature.self)
public struct MainShellRouter: View {

    // MARK: Lifecycle

    public init(store: StoreOf<MainShellRouterFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<MainShellRouterFeature>

    public var body: some View {
        TabShell(selected: selectedTab) { tab in
            switch tab {
            case .home:
                HomeScreen(store: store.scope(
                    state: \.home,
                    action: \.home,
                ))

            case .projects:
                if store.access == .member {
                    ProjectListScreen(store: store.scope(
                        state: \.projectList,
                        action: \.projectList,
                    ))
                } else {
                    ScreenContainer { EmptyView() }
                }

            case .saved:
                if store.access == .member {
                    SavedScreen(store: store.scope(
                        state: \.saved,
                        action: \.saved,
                    ))
                } else {
                    ScreenContainer { EmptyView() }
                }

            case .settings:
                if store.access == .member {
                    SettingsRouter(store: store.scope(
                        state: \.settings,
                        action: \.settings,
                    ))
                } else {
                    ScreenContainer { EmptyView() }
                }
            }
        }
        .overlay {
            if store.singleQuestionEntry?.isPreparing == true {
                entryOverlay
            }
        }
        .alert(
            LocalizedText.MainShell.singleQuestionFailureTitle,
            isPresented: entryFailureBinding,
        ) {
            Button(
                LocalizedText.MainShell.singleQuestionFailureConfirmButtonTitle,
                role: .cancel,
            ) {
                send(.singleQuestionFailureDismissed)
            }
        } message: {
            Text(LocalizedText.MainShell.singleQuestionFailureMessage)
        }
        .overlay { singleQuestionOverlay }
        .alert(
            LocalizedText.MainShell.signInRequiredTitle,
            isPresented: signInRequiredAlertBinding,
        ) {
            Button(LocalizedText.MainShell.signInRequiredSignInButtonTitle) {
                send(.signInRequiredAlertSignInTapped)
            }
            Button(
                LocalizedText.MainShell.signInRequiredCloseButtonTitle,
                role: .cancel,
            ) {
                send(.signInRequiredAlertDismissed)
            }
        } message: {
            Text(LocalizedText.MainShell.signInRequiredMessage)
        }
    }

    // MARK: Private

    private var selectedTab: Binding<MainShellTab> {
        Binding(
            get: { store.selectedTab },
            set: { send(.tabSelected($0)) },
        )
    }

    private var signInRequiredAlertBinding: Binding<Bool> {
        Binding(
            get: { store.isSignInRequiredAlertPresented },
            set: { isPresented in
                guard !isPresented else { return }
                send(.signInRequiredAlertDismissed)
            },
        )
    }

    private var entryFailureBinding: Binding<Bool> {
        Binding(
            get: { store.singleQuestionEntry?.preparationError != nil },
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
        .accessibilityLabel(LocalizedText.MainShell.singleQuestionLoadingAccessibilityLabel)
    }

    private var singleQuestionStore: StoreOf<QuestionSolvingFeature>? {
        store.scope(
            state: \.singleQuestion,
            action: \.singleQuestion.presented,
        )
    }

    private var singleQuestionOverlay: some View {
        PushedScreenOverlay {
            if let singleQuestionStore {
                QuestionSolvingScreen(store: singleQuestionStore)
            }
        }
        .presented(store.singleQuestion != nil)
    }

}
