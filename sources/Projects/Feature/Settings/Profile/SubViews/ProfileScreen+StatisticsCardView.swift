import SwiftUI
import UIComponent

extension ProfileScreen {
    struct StatisticsCardView: View {

        // MARK: Internal

        let display: ProfileDisplay

        var body: some View {
            HStack(spacing: 0) {
                column(label: Constant.thisWeekLabel, value: "\(display.thisWeekSolvedCount)\(Constant.countUnit)")
                column(label: Constant.thisMonthLabel, value: "\(display.thisMonthSolvedCount)\(Constant.countUnit)")
                column(label: Constant.streakLabel, value: "\(display.streakDays)\(Constant.dayUnit)")
            }
            .frame(maxWidth: .infinity)
            .frame(height: Constant.height)
            .background(cardGradient, in: RoundedRectangle(designSystem: .large))
        }

        // MARK: Private

        private enum Constant {
            static let thisWeekLabel = "이번 주"
            static let thisMonthLabel = "이번 달"
            static let streakLabel = "연속 학습"
            static let countUnit = "문제"
            static let dayUnit = "일"
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
                StyledText.caption2(label, color: .grey300, alignment: .center)
                StyledText.subtitle2(value, color: .blue100, alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }

    }
}
