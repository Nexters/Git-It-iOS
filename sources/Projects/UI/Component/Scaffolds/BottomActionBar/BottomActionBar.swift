import DesignSystem
import SwiftUI

// MARK: - BottomActionBar

/// 크기 결정 방식은 `SizingMode.fill`.
public struct BottomActionBar<Content: View>: View {

    // MARK: Lifecycle

    public init(
        layoutMetrics: LayoutMetrics = .default,
        @ViewBuilder content: () -> Content,
    ) {
        self.layoutMetrics = layoutMetrics
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.top, Constant.topPadding)
            .padding(.bottom, CGFloat(layoutMetrics.tabBarBottomInset))
    }

    // MARK: Private

    private let layoutMetrics: LayoutMetrics
    private let content: Content

}

#Preview("Bottom Action Bar") {
    VStack(spacing: 0) {
        Spacer()

        BottomActionBar {
            ActionButton.primary("계속하기")
        }
        .designSystemBackground(.cardBackground)
    }
    .frame(width: 390, height: 240)
    .designSystemBackground(.grey700)
}
