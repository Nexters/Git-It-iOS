import DesignSystem
import SwiftUI

// MARK: - ContinuousProgressBar

public struct ContinuousProgressBar: View {

    // MARK: Lifecycle

    public init(progress: Double) {
        self.progress = Self.clampedProgress(progress)
    }

    // MARK: Public

    public enum Height: Sendable, Equatable {
        case row
        case detail

        // MARK: Internal

        var value: CGFloat {
            switch self {
            case .row:
                Constant.rowHeight
            case .detail:
                Constant.detailHeight
            }
        }
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(designSystem: Constant.trackColorToken))

                Capsule()
                    .fill(Color(designSystem: Constant.fillColorToken))
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: size.value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LocalizedText.ContinuousProgressBar.accessibilityLabel)
        .accessibilityValue(LocalizedText.ContinuousProgressBar.accessibilityValue(percent: Int((progress * 100).rounded())))
    }

    // MARK: Internal

    static var surfaceHeight: CGFloat {
        Constant.rowHeight
    }

    static var trackColorToken: ColorToken {
        Constant.trackColorToken
    }

    static var fillColorToken: ColorToken {
        Constant.fillColorToken
    }

    static func clampedProgress(_ progress: Double) -> Double {
        progress.isNaN
            ? 0
            : min(max(progress, 0), 1)
    }

    // MARK: Private

    private enum Constant {
        static let rowHeight: CGFloat = 6
        static let detailHeight: CGFloat = 10
        static let trackColorToken = ColorToken.grey500
        static let fillColorToken = ColorToken.blue200
    }

    private let progress: Double
    private var size = Height.row

}

// MARK: SizeConfigurable

extension ContinuousProgressBar: SizeConfigurable {
    public func size(_ size: Height) -> Self {
        var copy = self
        copy.size = size
        return copy
    }
}

#Preview("Continuous Progress Bar") {
    VStack(spacing: LayoutToken.margin) {
        ContinuousProgressBar(progress: 0)
        ContinuousProgressBar(progress: 0.45)
        ContinuousProgressBar(progress: 1)
    }
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
