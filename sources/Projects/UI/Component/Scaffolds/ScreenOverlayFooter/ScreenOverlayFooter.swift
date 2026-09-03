import DesignSystem
import SwiftUI

// MARK: - ScreenOverlayFooter

public struct ScreenOverlayFooter<Content: View>: View {

    // MARK: Lifecycle

    public init(
        background: SemanticColorToken = .screenBackground,
        layoutMetrics: LayoutMetrics = .default,
        @ViewBuilder content: () -> Content,
    ) {
        self.background = background
        self.layoutMetrics = layoutMetrics
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        BottomActionBar(layoutMetrics: layoutMetrics) {
            content
                .designSystemScreenMargin()
        }
        .designSystemBackground(background)
    }

    // MARK: Private

    private let background: SemanticColorToken
    private let layoutMetrics: LayoutMetrics
    private let content: Content

}

#Preview("Screen Overlay Footer") {
    OverlayContainer { layoutMetrics in
        ScreenOverlayHeader(title: "문제 풀이", layoutMetrics: layoutMetrics)
    } content: { _ in
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            ForEach(0..<12, id: \.self) { index in
                LabeledCard.neutral(label: "항목 \(index)", text: "푸터 뒤로 지나가지 않습니다.")
            }
        }
        .designSystemScreenMargin()
    } footer: { layoutMetrics in
        ScreenOverlayFooter(layoutMetrics: layoutMetrics) {
            ActionButton.primary("계속하기")
        }
    }
}
