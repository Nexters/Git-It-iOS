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
        TabShell(
            selected: selectedTab,
            isEnabled: isTabEnabled,
        ) { tab in
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
                    Self.SignInPromptView(onSignIn: { send(.signInTapped) })
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
        .overlay { guestLegalAgreementOverlay }
        .overlay { guestLegalDocumentOverlay }
        .alert(
            LocalizedText.MainShell.signInFailureTitle,
            isPresented: signInFailureBinding,
        ) {
            Button(
                LocalizedText.MainShell.signInFailureConfirmButtonTitle,
                role: .cancel,
            ) {
                send(.signInFailureDismissed)
            }
        } message: {
            Text(LocalizedText.MainShell.signInFailureMessage)
        }
    }

    // MARK: Private

    private var isTabEnabled: (MainShellTab) -> Bool {
        let access = store.access
        return { access == .member || ($0 != .projects && $0 != .saved) }
    }

    private var selectedTab: Binding<MainShellTab> {
        Binding(
            get: { store.selectedTab },
            set: { send(.tabSelected($0)) },
        )
    }

    private var signInFailureBinding: Binding<Bool> {
        Binding(
            get: { store.signIn.isFailed },
            set: { isPresented in
                guard !isPresented else { return }
                send(.signInFailureDismissed)
            },
        )
    }

    private var guestLegalAgreementOverlay: some View {
        ModalOverlay(
            isPresented: Binding(
                get: { store.signIn.isLegalAgreementPresented },
                set: { isPresented in
                    if !isPresented {
                        send(.legalAgreementDismissed)
                    }
                },
            )
        ) {
            LegalAgreementScreen(
                store: store.scope(
                    state: \.signIn.legalAgreement,
                    action: \.signIn.legalAgreement,
                )
            )
        }
    }

    private var guestLegalDocumentOverlay: some View {
        ModalOverlay(
            isPresented: Binding(
                get: { store.signIn.legalAgreement.presentedDocument != nil },
                set: { isPresented in
                    if !isPresented {
                        send(.legalDocumentSheetDismissed)
                    }
                },
            )
        ) {
            if let document = store.signIn.legalAgreement.presentedDocument {
                WebSheet(
                    displayModel: .init(
                        title: document.displayName,
                        url: document.approvedURL,
                    ),
                    onDismiss: { send(.legalDocumentSheetDismissed) },
                )
            }
        }
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
