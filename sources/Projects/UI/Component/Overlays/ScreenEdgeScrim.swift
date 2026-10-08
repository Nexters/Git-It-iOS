import DesignSystem
import SwiftUI

public struct ScreenEdgeScrim: View {

    // MARK: Lifecycle

    public init(
        edge: Edge,
        height: CGFloat,
    ) {
        self.edge = edge
        self.height = height
    }

    // MARK: Public

    public enum Edge: Sendable, Equatable {
        case top
        case bottom

        // MARK: Internal

        var gradientToken: GradientToken {
            switch self {
            case .top: .topEdgeScrim
            case .bottom: .bottomEdgeScrim
            }
        }
    }

    public var body: some View {
        LinearGradient(designSystem: edge.gradientToken)
            .frame(height: height)
            .allowsHitTesting(Constant.allowsHitTesting)
            .accessibilityHidden(true)
    }

    // MARK: Internal

    static var allowsHitTesting: Bool {
        Constant.allowsHitTesting
    }

    // MARK: Private

    private enum Constant {
        static let allowsHitTesting = false
    }

    private let edge: Edge
    private let height: CGFloat

}

#Preview("Screen Edge Scrim") {
    VStack(spacing: LayoutToken.margin) {
        ScreenEdgeScrim(
            edge: .top,
            height: 70,
        )

        ScreenEdgeScrim(
            edge: .bottom,
            height: 92,
        )
    }
    .frame(width: 360)
    .designSystemBackground(.grey700)
}
