import ComposableArchitecture
import SwiftUI

public struct SettingsRouter: View {

    // MARK: Lifecycle

    public init(store: StoreOf<SettingsRouterFeature>) {
        self.store = store
    }

    // MARK: Public

    public var body: some View {
        switch store.activeScreen {
        case .profile:
            ProfileScreen(store: store.scope(state: \.profile, action: \.profile))

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

    // MARK: Private

    @Bindable private var store: StoreOf<SettingsRouterFeature>

    private var settingsStore: StoreOf<SettingsFeature> {
        store.scope(state: \.settings, action: \.settings)
    }

}
