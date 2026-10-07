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
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: LayoutToken.gutter) {
                    ScreenHeaderTitle(title: Constant.title)
                        .frame(height: Constant.headerControlRowHeight)
                    Spacer()

                    IconGlassButton.neutral(
                        icon: Constant.settingsControl.icon,
                        label: Constant.settingsControl.label,
                        size: .medium,
                        action: { send(.settingsTapped) },
                    )
                }
                .padding(.vertical, Constant.headerBottomPadding)
                .designSystemScreenMargin()
            }
        } content: {
            content
        }
        .task { await send(.task).finish() }
    }

    // MARK: Private

    private var display: ProfileDisplay {
        ProfileDisplay(store.profileLoad)
    }

    @ViewBuilder
    private var content: some View {
        let current = display
        if current.isFailed {
            Self.LoadFailureView(onRetry: { send(.retryTapped) })
                .designSystemScreenMargin()
                .padding(.top, Constant.failureTopPadding)
        } else if current.isLoading {
            ProgressView()
                .tint(Color(designSystem: .grey300))
                .frame(maxWidth: .infinity)
                .padding(.top, Constant.loadingTopPadding)
        } else {
            Self.ProfileHeaderView(display: current)
                .padding(Constant.profileCardPadding)
            StyledText.caption2(Constant.statisticsSectionTitle, color: .grey400)
                .frame(maxWidth: .infinity, alignment: .leading)
                .designSystemScreenMargin()
                .padding(.top, Constant.sectionTitleTopPadding)
                .padding(.bottom, Constant.sectionTitleBottomPadding)

            VStack(spacing: Constant.cardSpacing) {
                Self.StatisticsCardView(display: current)
                Self.WeeklyChartView(display: current)
            }
            .designSystemScreenMargin()
            .padding(.bottom, Constant.contentBottomPadding)
        }
    }

}

// MARK: ProfileScreen.Constant

extension ProfileScreen {
    fileprivate enum Constant {
        static let title = "마이"
        static let statisticsSectionTitle = "학습 현황"
        static let settingsControl = ScreenControlBar.Control(icon: .setting, label: "설정")
        static let profileCardPadding: CGFloat = 20
        static let sectionTitleTopPadding: CGFloat = 20
        static let sectionTitleBottomPadding: CGFloat = 10
        static let cardSpacing: CGFloat = 16
        static let contentBottomPadding: CGFloat = 32
        static let loadingTopPadding: CGFloat = 120
        static let failureTopPadding: CGFloat = 20
        static let headerControlRowHeight: CGFloat = 40
        static let headerBottomPadding: CGFloat = 10
    }
}
