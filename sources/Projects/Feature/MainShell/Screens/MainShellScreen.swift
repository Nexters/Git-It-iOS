import ComposableArchitecture
import SwiftUI
import UIComponent

// MARK: - MainShellScreen

@ViewAction(for: MainShellFeature.self)
public struct MainShellScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<MainShellFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<MainShellFeature>

    public var body: some View {
        TabShell(selected: selectedTab) { tab in
            switch tab {
            case .home:
                HomeScreen(store: store.scope(state: \.home, action: \.home))

            case .projects,
                 .saved,
                 .settings:
                ScreenContainer {
                    StyledText.subtitle1(tab.tabTitle, alignment: .center)
                }
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
