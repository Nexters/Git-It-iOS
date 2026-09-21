import DesignSystem
import SwiftUI

// MARK: - LabeledProgressBar

public struct LabeledProgressBar: View {

    // MARK: Lifecycle

    public init(displayModel: DisplayModel) {
        self.displayModel = displayModel
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: Constant.labelSpacing) {
            HStack {
                StyledText(text: displayModel.label)
                    .textStyle(.caption1)
                    .foregroundColorToken(.grey400)
                Spacer(minLength: 0)
                StyledText(text: displayModel.valueText)
                    .textStyle(.caption1)
                    .foregroundColorToken(foregroundColor)
            }

            ContinuousProgressBar(progress: displayModel.progress)
                .size(.detail)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private enum Constant {
        static let labelSpacing: CGFloat = 10
    }

    private let displayModel: DisplayModel
    private var foregroundColor = ColorToken.grey400

}

// MARK: LabeledProgressBar.DisplayModel

extension LabeledProgressBar {
    public struct DisplayModel: Sendable, Equatable {
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
}

// MARK: ForegroundColorConfigurable

extension LabeledProgressBar: ForegroundColorConfigurable {
    public func foregroundColorToken(_ color: ColorToken) -> Self {
        var copy = self
        copy.foregroundColor = color
        return copy
    }
}

#Preview("Labeled Progress Bar") {
    LabeledProgressBar(displayModel: .init(label: "학습 진행률", progress: 0.6, valueText: "6 / 10"))
        .frame(width: 320)
        .designSystemScreenMargin()
        .padding(.vertical, LayoutToken.margin)
        .designSystemBackground(.grey700)
}
