import SwiftUI
import UIComponent

extension ProfileScreen {
    struct WeeklyChartView: View {

        // MARK: Internal

        let display: ProfileDisplay

        var body: some View {
            VStack(
                alignment: .leading,
                spacing: Constant.headerToChartSpacing,
            ) {
                VStack(
                    alignment: .leading,
                    spacing: Constant.headerSpacing,
                ) {
                    StyledText(text: LocalizedText.Settings.WeeklyChart.Section.label)
                        .textStyle(.body3)
                        .foregroundColorToken(.grey400)
                    StyledText(text: display.weeklyTitle)
                        .textStyle(.subtitle3)
                }

                VStack(spacing: Constant.barsToLabelsSpacing) {
                    HStack(
                        alignment: .bottom,
                        spacing: Constant.barSpacing,
                    ) {
                        ForEach(display.weeklyBars) { bar in
                            barColumn(bar)
                        }
                    }
                    .frame(
                        height: Constant.barsHeight,
                        alignment: .bottom,
                    )

                    HStack(spacing: Constant.barSpacing) {
                        ForEach(display.weeklyBars) { bar in
                            StyledText(text: bar.dayLabel)
                                .textStyle(.caption2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: Constant.labelRowHeight)
                }
                .frame(maxWidth: .infinity)
                .frame(
                    height: Constant.chartHeight,
                    alignment: .bottom,
                )
            }
            .padding(.horizontal, Constant.horizontalPadding)
            .padding(.vertical, Constant.verticalPadding)
            .frame(maxWidth: .infinity)
            .frame(
                height: Constant.cardHeight,
                alignment: .top,
            )
            .background(
                Color(designSystem: .grey600),
                in: RoundedRectangle(designSystem: .large),
            )
        }

        // MARK: Private

        private enum Constant {
            static let cardHeight: CGFloat = 223
            static let horizontalPadding: CGFloat = 16
            static let verticalPadding: CGFloat = 14
            static let headerSpacing: CGFloat = 1
            static let headerToChartSpacing: CGFloat = 26
            static let chartHeight: CGFloat = 126
            static let barsHeight: CGFloat = 101
            static let barsToLabelsSpacing: CGFloat = 7
            static let labelRowHeight: CGFloat = 18
            static let barSpacing: CGFloat = 12
            static let countToBarSpacing: CGFloat = 2
            static let emptyBarHeight: CGFloat = 1
            static let barCornerRadius: CGFloat = 4
        }

        private var maxBarHeight: CGFloat {
            Constant.barsHeight - Constant.labelRowHeight - Constant.countToBarSpacing
        }

        private func barColumn(_ bar: ProfileDisplay.WeeklyBar) -> some View {
            VStack(spacing: Constant.countToBarSpacing) {
                StyledText(text: "\(bar.count)")
                    .textStyle(.caption2)
                    .foregroundColorToken(bar.isHighlighted ? .grey200 : .grey300)
                    .multilineTextAlignment(.center)
                    .frame(height: Constant.labelRowHeight)

                LinearGradient(designSystem: bar.isHighlighted ? .gradient3 : .gradient1)
                    .frame(height: barHeight(for: bar.count))
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: Constant.barCornerRadius,
                        topTrailingRadius: Constant.barCornerRadius,
                    ))
            }
            .frame(maxWidth: .infinity)
        }

        private func barHeight(for count: Int) -> CGFloat {
            guard count > 0, display.maxWeeklyCount > 0 else { return Constant.emptyBarHeight }
            let ratio = CGFloat(count) / CGFloat(display.maxWeeklyCount)
            return max(Constant.emptyBarHeight, maxBarHeight * ratio)
        }

    }
}
