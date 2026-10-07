import DesignSystem
import SwiftUI

// MARK: - LabeledProgressBar

public struct LabeledProgressBar: View {

    // MARK: Lifecycle

    public init(
        label: String,
        progress: Double,
        valueText: String,
        valueColor: ColorToken = .grey400,
    ) {
        self.label = label
        self.progress = progress
        self.valueText = valueText
        self.valueColor = valueColor
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: Constant.labelSpacing) {
            HStack {
                StyledText.caption1(label, color: .grey400)
                Spacer(minLength: 0)
                StyledText.caption1(valueText, color: valueColor)
            }

            ContinuousProgressBar(progress: progress, height: .detail)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private enum Constant {
        static let labelSpacing: CGFloat = 10
    }

    private let label: String
    private let progress: Double
    private let valueText: String
    private let valueColor: ColorToken

}

#Preview("Labeled Progress Bar") {
    LabeledProgressBar(label: "학습 진행률", progress: 0.6, valueText: "6 / 10")
        .frame(width: 320)
        .designSystemScreenMargin()
        .padding(.vertical, LayoutToken.margin)
        .designSystemBackground(.grey700)
}
