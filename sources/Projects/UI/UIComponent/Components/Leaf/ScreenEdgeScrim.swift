import DesignSystem
import SwiftUI

public struct ScreenEdgeScrim: View {

    // MARK: Lifecycle

    private init(_ style: Style) {
        self.style = style
    }

    // MARK: Public

    public enum Style: Sendable, Equatable {
        case top
        case bottom

        var gradientToken: GradientToken {
            switch self {
            case .top:
                .topEdgeScrim
            case .bottom:
                .bottomEdgeScrim
            }
        }
    }

    public var body: some View {
        LinearGradient(designSystem: style.gradientToken)
            .allowsHitTesting(Constant.allowsHitTesting)
            .accessibilityHidden(true)
    }

    public static func top() -> Self {
        Self(.top)
    }

    public static func bottom() -> Self {
        Self(.bottom)
    }

    // MARK: Internal

    static var allowsHitTesting: Bool {
        Constant.allowsHitTesting
    }

    // MARK: Private

    private enum Constant {
        static let allowsHitTesting = false
    }

    private let style: Style

}

#Preview("Screen Edge Scrim") {
    VStack(spacing: LayoutToken.margin.cgFloatValue) {
        ScreenEdgeScrim.top()
            .frame(height: 103)

        ScreenEdgeScrim.bottom()
            .frame(height: 127)
    }
    .frame(width: 360)
    .designSystemBackground(.grey700)
}
