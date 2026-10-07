import ComposableArchitecture
import SwiftUI
import UIComponent

// MARK: - ProfileScreen

/// "마이" 탭의 프로필 화면(Figma `1539:19209`).
@ViewAction(for: ProfileFeature.self)
public struct ProfileScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<ProfileFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<ProfileFeature>

    public var body: some View {
        OverlayContainer(content: {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(
                    title: Constant.title,
                    style: .inlineTitle,
                    leading: nil,
                    trailing: Constant.settingsControl,
                    onTrailingTap: { send(.settingsTapped) },
                )
                .designSystemScreenMargin()

                content
            }
        })
        .scrollIndicators(.hidden)
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
        static let settingsControl = ScreenHeader.Control(symbol: "gearshape", label: "설정")
        static let profileCardPadding: CGFloat = 20
        static let sectionTitleTopPadding: CGFloat = 20
        static let sectionTitleBottomPadding: CGFloat = 10
        static let cardSpacing: CGFloat = 16
        static let contentBottomPadding: CGFloat = 32
        static let loadingTopPadding: CGFloat = 120
        static let failureTopPadding: CGFloat = 20
    }
}
