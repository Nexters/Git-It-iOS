import DesignSystem
import SwiftUI

// MARK: - ScreenOverlayFooter

public struct ScreenOverlayFooter<Content: View>: View {

    // MARK: Lifecycle

    public init(
        background: SemanticColorToken = .screenBackground,
        @ViewBuilder content: () -> Content,
    ) {
        self.background = background
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        BottomActionBar {
            content
                .designSystemScreenMargin()
        }
        .background {
            ZStack(alignment: .top) {
                Color(designSystem: background)

                scrim
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: Private

    private let background: SemanticColorToken
    private let content: Content

    private var scrim: some View {
        GeometryReader { proxy in
            ScreenEdgeScrim.bottom(height: proxy.size.height)
        }
    }

}

#Preview("Screen Overlay Footer") {
    OverlayContainer {
        ScreenOverlayHeader(title: "문제 풀이")
    } content: {
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            ForEach(0..<12, id: \.self) { index in
                LabeledCard.neutral(label: "항목 \(index)", text: "푸터 뒤로 지나가지 않습니다.")
            }
        }
        .designSystemScreenMargin()
    } footer: {
        ScreenOverlayFooter {
            ActionButton.primary("계속하기")
        }
    }
}
