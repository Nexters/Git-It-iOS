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
                HomeScreen(store: store.scope(state: \.home, action: \.home))

            case .projects:
                ProjectListScreen(store: store.scope(state: \.projectList, action: \.projectList))

            case .saved:
                SavedScreen(store: store.scope(state: \.saved, action: \.saved))

            case .settings:
                SettingsRouter(store: store.scope(state: \.settings, action: \.settings))
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
    }

    // MARK: Private

    private var selectedTab: Binding<MainShellTab> {
        Binding(
            get: { store.selectedTab },
            set: { send(.tabSelected($0)) },
        )
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
