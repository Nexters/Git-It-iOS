import DesignSystem
import SwiftUI

public struct ScreenEdgeScrim: View {

    // MARK: Lifecycle

    private init(_ style: Style) {
        self.style = style
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

        /// 정본 고정값 대신 화면 크기에서 유도한 높이를 쓴다.
        func height(layoutMetrics: LayoutMetrics) -> CGFloat {
            switch self {
            case let .top(headerStyle):
                CGFloat(layoutMetrics.topScrimHeight(headerStyle: headerStyle))
            case let .bottom(hasTabBar):
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

    public static func top(headerStyle: LayoutMetrics.HeaderStyle = .plain) -> Self {
        Self(.top(headerStyle: headerStyle))
    }

    public static func bottom(hasTabBar: Bool = false) -> Self {
        Self(.bottom(hasTabBar: hasTabBar))
    }

    // MARK: Internal

    static var allowsHitTesting: Bool {
        Constant.allowsHitTesting
    }

    // MARK: Private

    private enum Constant {
        static let allowsHitTesting = false
    }

    @Environment(\.layoutMetrics) private var layoutMetrics

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
