import DesignSystem
import SwiftUI

public struct ScreenEdgeScrim: View {

    // MARK: Lifecycle

    private init(
        _ style: Style,
        layoutMetrics: LayoutMetrics,
    ) {
        self.style = style
        self.layoutMetrics = layoutMetrics
    }

    // MARK: Public

    public enum Style: Sendable, Equatable {
        case top(headerStyle: LayoutMetrics.HeaderStyle)
        case bottom(hasTabBar: Bool)

        // MARK: Internal

        var gradientToken: GradientToken {
            switch self {
            case .top:
                .topEdgeScrim
            case .bottom:
                .bottomEdgeScrim
            }
        }

        func height(layoutMetrics: LayoutMetrics) -> CGFloat {
            switch self {
            case .top(let headerStyle):
                CGFloat(layoutMetrics.topScrimHeight(headerStyle: headerStyle))
            case .bottom(let hasTabBar):
                CGFloat(layoutMetrics.bottomScrimHeight(hasTabBar: hasTabBar))
            }
        }
    }

    public var body: some View {
        LinearGradient(designSystem: style.gradientToken)
            .frame(height: style.height(layoutMetrics: layoutMetrics))
            .allowsHitTesting(Constant.allowsHitTesting)
            .accessibilityHidden(true)
    }

    public static func top(
        headerStyle: LayoutMetrics.HeaderStyle = .plain,
        layoutMetrics: LayoutMetrics = .default,
    ) -> Self {
        Self(.top(headerStyle: headerStyle), layoutMetrics: layoutMetrics)
    }

    public static func bottom(
        hasTabBar: Bool = false,
        layoutMetrics: LayoutMetrics = .default,
    ) -> Self {
        Self(.bottom(hasTabBar: hasTabBar), layoutMetrics: layoutMetrics)
    }

    // MARK: Internal

    static var allowsHitTesting: Bool {
        Constant.allowsHitTesting
    }

    // MARK: Private

    private enum Constant {
        static let allowsHitTesting = false
    }

    private let layoutMetrics: LayoutMetrics
    private let style: Style

}

#Preview("Screen Edge Scrim") {
    VStack(spacing: LayoutToken.margin.cgFloatValue) {
        ScreenEdgeScrim.top(headerStyle: .plain)

        ScreenEdgeScrim.bottom(hasTabBar: true)
    }
    .frame(width: 360)
    .designSystemBackground(.grey700)
}
