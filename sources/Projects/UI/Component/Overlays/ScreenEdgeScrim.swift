import DesignSystem
import SwiftUI

public struct ScreenEdgeScrim: View {

    // MARK: Public

    public var body: some View {
        LinearGradient(designSystem: gradientToken)
            .frame(height: height)
            .allowsHitTesting(Constant.allowsHitTesting)
            .accessibilityHidden(true)
    }

    public static func top(height: CGFloat) -> Self {
        Self(gradientToken: .topEdgeScrim, height: height)
    }

    public static func bottom(height: CGFloat) -> Self {
        Self(gradientToken: .bottomEdgeScrim, height: height)
    }

    // MARK: Internal

    static var allowsHitTesting: Bool {
        Constant.allowsHitTesting
    }

    // MARK: Private

    private enum Constant {
        static let allowsHitTesting = false
    }

    private let gradientToken: GradientToken
    private let height: CGFloat

}

#Preview("Screen Edge Scrim") {
    VStack(spacing: LayoutToken.margin.cgFloatValue) {
        ScreenEdgeScrim.top(height: 70)

        ScreenEdgeScrim.bottom(height: 92)
    }
    .frame(width: 360)
    .designSystemBackground(.grey700)
}
