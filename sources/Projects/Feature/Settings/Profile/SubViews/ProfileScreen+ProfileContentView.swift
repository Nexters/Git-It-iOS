import DesignSystem
import SwiftUI
import UIComponent

extension ProfileScreen {
    struct ProfileContentView: View {

        // MARK: Internal

        let display: ProfileDisplay
        let statisticsSectionTitle: String
        let onRetry: () -> Void

        var body: some View {
            if display.isFailed {
                ProfileScreen.LoadFailureView(onRetry: onRetry)
                    .designSystemScreenMargin()
                    .padding(.top, Constant.failureTopPadding)
            } else if display.isLoading {
                ProgressView()
                    .tint(Color(designSystem: .grey300))
                    .frame(maxWidth: .infinity)
                    .padding(.top, Constant.loadingTopPadding)
            } else {
                loaded
            }
        }

        // MARK: Private

        private enum Constant {
            static let profileCardPadding: CGFloat = 20
            static let sectionTitleTopPadding: CGFloat = 20
            static let sectionTitleBottomPadding: CGFloat = 10
            static let cardSpacing: CGFloat = 16
            static let contentBottomPadding: CGFloat = 32
            static let loadingTopPadding: CGFloat = 120
            static let failureTopPadding: CGFloat = 20
        }

        private var loaded: some View {
            VStack(
                alignment: .leading,
                spacing: 0,
            ) {
                ProfileScreen.ProfileHeaderView(display: display)
                    .padding(Constant.profileCardPadding)

                StyledText(text: statisticsSectionTitle)
                    .textStyle(.caption2)
                    .foregroundColorToken(.grey400)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading,
                    )
                    .designSystemScreenMargin()
                    .padding(.top, Constant.sectionTitleTopPadding)
                    .padding(.bottom, Constant.sectionTitleBottomPadding)

                VStack(spacing: Constant.cardSpacing) {
                    ProfileScreen.StatisticsCardView(display: display)
                    ProfileScreen.WeeklyChartView(display: display)
                }
                .designSystemScreenMargin()
                .padding(.bottom, Constant.contentBottomPadding)
            }
        }

    }
}
