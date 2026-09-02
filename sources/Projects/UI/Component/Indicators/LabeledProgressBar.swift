import DesignSystem
import SwiftUI

// MARK: - LabeledProgressBar

/// 크기 결정 방식은 `SizingMode.fill`.
public struct LabeledProgressBar: View {

    // MARK: Lifecycle

    public init(
        label: String,
        progress: Double,
        valueText: String,
    ) {
        self.label = label
        self.progress = progress
        self.valueText = valueText
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.compactSpacing.cgFloatValue) {
            HStack {
                StyledText.caption1(label, color: .grey400)
                Spacer(minLength: 0)
                StyledText.caption1(valueText, color: .grey400)
            }

            ContinuousProgressBar(progress: progress)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private let label: String
    private let progress: Double
    private let valueText: String

}

#Preview("Labeled Progress Bar") {
    LabeledProgressBar(label: "학습 진행률", progress: 0.6, valueText: "6 / 10")
        .frame(width: 320)
        .designSystemScreenMargin()
        .padding(.vertical, LayoutToken.margin.cgFloatValue)
        .designSystemBackground(.grey700)
}
