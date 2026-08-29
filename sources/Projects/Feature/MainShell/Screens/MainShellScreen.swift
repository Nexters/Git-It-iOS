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

    public var body: some View {
        TabShell(selected: selectedTab) { tab in
            ScreenContainer {
                StyledText.subtitle1(tab.tabTitle, alignment: .center)
            }
        }
    }

    // MARK: Private

    @Bindable public var store: StoreOf<MainShellFeature>

    private var selectedTab: Binding<MainShellTab> {
        Binding(
            get: { store.selectedTab },
            set: { send(.tabSelected($0)) },
        )
    }

}
