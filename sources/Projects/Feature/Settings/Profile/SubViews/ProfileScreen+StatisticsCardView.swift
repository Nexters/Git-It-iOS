import SwiftUI
import UIComponent

extension ProfileScreen {
    struct StatisticsCardView: View {

        // MARK: Internal

        let display: ProfileDisplay

        var body: some View {
            HStack(spacing: 0) {
                column(
                    label: LocalizedText.Settings.StatisticsCard.ThisWeek.label,
                    value: LocalizedText.Settings.StatisticsCard.SolvedCount.value(count: display.thisWeekSolvedCount),
                )
                column(
                    label: LocalizedText.Settings.StatisticsCard.ThisMonth.label,
                    value: LocalizedText.Settings.StatisticsCard.SolvedCount.value(count: display.thisMonthSolvedCount),
                )
                column(
                    label: LocalizedText.Settings.StatisticsCard.Streak.label,
                    value: LocalizedText.Settings.StatisticsCard.Streak.Days.value(days: display.streakDays),
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: Constant.height)
            .background(
                cardGradient,
                in: RoundedRectangle(designSystem: .large),
            )
        }

        // MARK: Private

        private enum Constant {
            static let height: CGFloat = 88
            static let columnSpacing: CGFloat = 4
            static let gradientEndOpacity = 0.5
        }

        private var cardGradient: LinearGradient {
            LinearGradient(
                colors: [
                    Color(designSystem: .blue500),
                    Color(designSystem: .blue500).opacity(Constant.gradientEndOpacity),
                ],
                startPoint: .leading,
                endPoint: .trailing,
            )
        }

        private func column(
            label: String,
            value: String,
        ) -> some View {
            VStack(spacing: Constant.columnSpacing) {
                StyledText(text: label)
                    .textStyle(.caption2)
                    .foregroundColorToken(.grey300)
                    .multilineTextAlignment(.center)
                StyledText(text: value)
                    .textStyle(.subtitle2)
                    .foregroundColorToken(.blue100)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }

    }
}
