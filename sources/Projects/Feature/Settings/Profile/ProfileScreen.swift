import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - ProfileScreen

@ViewAction(for: ProfileFeature.self)
public struct ProfileScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<ProfileFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<ProfileFeature>

    public var body: some View {
        OverlayContainer {
            header
        } content: {
            content
        }
        .task { await send(.task).finish() }
    }

    // MARK: Private

    private var display: ProfileDisplay {
        ProfileDisplay(store.profile.load)
    }

    private var header: some View {
        HStack(
            alignment: .top,
            spacing: LayoutToken.gutter,
        ) {
            ScreenHeaderTitle(displayModel: .init(title: LocalizedText.Settings.profileTitle))
                .frame(height: Constant.headerControlRowHeight)

            Spacer()

            IconGlassButton(
                icon: .setting,
                label: LocalizedText.Settings.profileSettingsAccessibilityLabel,
                action: { send(.settingsTapped) },
            )
            .size(.medium)
        }
        .padding(.vertical, Constant.headerBottomPadding)
        .designSystemScreenMargin()
    }

    private var content: some View {
        Self.ProfileContentView(
            display: display,
            statisticsSectionTitle: LocalizedText.Settings.profileStatisticsSectionTitle,
            onRetry: { send(.retryTapped) },
        )
    }

}

// MARK: ProfileScreen.Constant

extension ProfileScreen {
    fileprivate enum Constant {
        static let headerControlRowHeight: CGFloat = 40
        static let headerBottomPadding: CGFloat = 10
    }
}
