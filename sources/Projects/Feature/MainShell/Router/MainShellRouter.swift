import ComposableArchitecture
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

            case .projects,
                 .saved,
                 .settings:
                Self.PlaceholderView(title: tab.tabTitle)
            }
        }
    }

    // MARK: Private

    private var selectedTab: Binding<MainShellTab> {
        Binding(
            get: { store.selectedTab },
            set: { send(.tabSelected($0)) },
        )
    }

}
