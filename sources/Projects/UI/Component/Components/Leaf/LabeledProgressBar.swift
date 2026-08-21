import DesignSystem
import SwiftUI

// MARK: - LabeledProgressBar

public struct LabeledProgressBar: View {

    // MARK: Lifecycle

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(
            label: String,
            progress: Double,
            valueText: String,
        ) {
            self.label = label
            self.progress = progress
            self.valueText = valueText
        }

        public let label: String
        public let progress: Double
        public let valueText: String
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.compactSpacing.cgFloatValue) {
            HStack {
                StyledText.caption1(viewModel.label, color: .grey400)
                Spacer(minLength: 0)
                StyledText.caption1(viewModel.valueText, color: .grey400)
            }

            ContinuousProgressBar(viewModel: .init(progress: viewModel.progress))
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private let viewModel: ViewModel

}

#Preview("Labeled Progress Bar") {
    LabeledProgressBar(
        viewModel: .init(label: "학습 진행률", progress: 0.6, valueText: "6 / 10")
    )
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
