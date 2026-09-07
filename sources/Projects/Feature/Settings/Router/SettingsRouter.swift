import ComposableArchitecture
import SwiftUI
import UIComponent

public struct SettingsRouter: View {

    // MARK: Lifecycle

    public init(store: StoreOf<SettingsRouterFeature>) {
        self.store = store
    }

    // MARK: Public

    public var body: some View {
        FlowNavigationStack(path: pushedScreens) {
            ProfileScreen(store: store.scope(state: \.profile, action: \.profile))
        } destination: { screen in
            pushedScreen(screen)
        }
    }

    // MARK: Private

    @Bindable private var store: StoreOf<SettingsRouterFeature>

    private var settingsStore: StoreOf<SettingsFeature> {
        store.scope(state: \.settings, action: \.settings)
    }

    private var pushedScreens: [SettingsRouterFeature.State.ActiveScreen] {
        switch store.activeScreen {
        case .profile:
            []

        case .settings(.list):
            [.settings(.list)]

        case .settings(let step):
            [.settings(.list), .settings(step)]
        }
    }

    @ViewBuilder
    private func pushedScreen(_ screen: SettingsRouterFeature.State.ActiveScreen) -> some View {
        switch screen {
        case .profile:
            EmptyView()

        case .settings(.list):
            SettingsScreen(store: settingsStore)

        case .settings(.positionSelection):
            SettingsScreen.PositionSelectionView(store: settingsStore)

        case .settings(.careerLevelSelection):
            SettingsScreen.CareerLevelSelectionView(store: settingsStore)

        case .settings(.accountDeletion):
            SettingsScreen.AccountDeletionView(store: settingsStore)
        }
    }

}
