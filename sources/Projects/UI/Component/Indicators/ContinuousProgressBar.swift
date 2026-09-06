import DesignSystem
import SwiftUI

public struct ContinuousProgressBar: View {

    // MARK: Lifecycle

    public init(
        progress: Double,
        height: Height = .row,
    ) {
        self.progress = Self.clampedProgress(progress)
        self.height = height
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
        .frame(height: height.value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("학습 진행률")
        .accessibilityValue("\(Int((progress * 100).rounded()))퍼센트")
    }

    // MARK: Internal

    static var surfaceHeight: CGFloat {
        Constant.rowHeight
    }

    static var trackColorToken: SemanticColorToken {
        Constant.trackColorToken
    }

    static var fillColorToken: SemanticColorToken {
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
        static let trackColorToken = SemanticColorToken.progressTrack
        static let fillColorToken = SemanticColorToken.progressFill
    }

    private let progress: Double
    private let height: Height

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
