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
            ScreenHeaderTitle(displayModel: .init(title: Constant.title))
                .frame(height: Constant.headerControlRowHeight)

            Spacer()

            IconGlassButton(
                icon: Constant.settingsControl.icon,
                label: Constant.settingsControl.label,
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
            statisticsSectionTitle: Constant.statisticsSectionTitle,
            onRetry: { send(.retryTapped) },
        )
    }

}

// MARK: ProfileScreen.Constant

extension ProfileScreen {
    fileprivate enum Constant {
        static let title = "마이"
        static let statisticsSectionTitle = "학습 현황"
        static let settingsControl = ScreenControlBar.Control(
            icon: .setting,
            label: "설정",
        )
        static let headerControlRowHeight: CGFloat = 40
        static let headerBottomPadding: CGFloat = 10
    }
}
