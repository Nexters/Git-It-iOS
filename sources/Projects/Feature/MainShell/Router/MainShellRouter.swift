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
        TabShell(selected: selectedTab, isEnabled: isTabEnabled) { tab in
            switch tab {
            case .home:
                HomeScreen(store: store.scope(state: \.home, action: \.home))

            case .projects:
                if store.access == .member {
                    ProjectListScreen(store: store.scope(state: \.projectList, action: \.projectList))
                } else {
                    ScreenContainer { EmptyView() }
                }

            case .saved:
                if store.access == .member {
                    SavedScreen(store: store.scope(state: \.saved, action: \.saved))
                } else {
                    ScreenContainer { EmptyView() }
                }

            case .settings:
                if store.access == .member {
                    SettingsRouter(store: store.scope(state: \.settings, action: \.settings))
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
        .alert("문제를 불러오지 못했어요", isPresented: entryFailureBinding) {
            Button("확인", role: .cancel) {
                store.send(.singleQuestionEntry(.input(.failureDismissed)))
            }
        } message: {
            Text("잠시 후 다시 시도해 주세요.")
        }
        .overlay { singleQuestionOverlay }
        .overlay { guestLegalAgreementOverlay }
        .overlay { guestLegalDocumentOverlay }
        .alert("로그인하지 못했어요", isPresented: signInFailureBinding) {
            Button("확인", role: .cancel) {
                store.send(.signIn(.view(.failureDismissed)))
            }
        } message: {
            Text("잠시 후 다시 시도해 주세요.")
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
                store.send(.signIn(.view(.failureDismissed)))
            },
        )
    }

    private var guestLegalAgreementOverlay: some View {
        ModalOverlay(
            isPresented: store.signIn.isLegalAgreementPresented,
            onDismiss: { store.send(.signIn(.view(.legalAgreementDismissed))) },
        ) {
            LegalAgreementScreen(
                store: store.scope(state: \.signIn.legalAgreement, action: \.signIn.legalAgreement)
            )
        }
    }

    private var guestLegalDocumentOverlay: some View {
        ModalOverlay(
            isPresented: store.signIn.legalAgreement.presentedDocument != nil,
            onDismiss: { store.send(.signIn(.view(.legalDocumentSheetDismissed))) },
        ) {
            if let document = store.signIn.legalAgreement.presentedDocument {
                WebSheet(
                    displayModel: .init(title: document.displayName, url: document.approvedURL),
                    onDismiss: { store.send(.signIn(.view(.legalDocumentSheetDismissed))) },
                )
            }
        }
    }

    private var entryFailureBinding: Binding<Bool> {
        Binding(
            get: { store.singleQuestionEntry?.preparationError != nil },
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

    private var singleQuestionStore: StoreOf<QuestionSolvingFeature>? {
        store.scope(state: \.singleQuestion, action: \.singleQuestion.presented)
    }

    private var singleQuestionOverlay: some View {
        PushedScreenOverlay(isPresented: store.singleQuestion != nil) {
            if let singleQuestionStore {
                QuestionSolvingScreen(store: singleQuestionStore)
            }
        }
    }

}
