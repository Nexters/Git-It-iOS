import DesignSystem
import SwiftUI

public struct ScreenContainer<Content: View>: View {

    // MARK: Lifecycle

    public init(
        background: SemanticColorToken = .screenBackground,
        @ViewBuilder content: @escaping (LayoutMetrics) -> Content,
    ) {
        self.background = background
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        LayoutMetricsReader { layoutMetrics in
            content(layoutMetrics)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(designSystem: background).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: Private

    private let background: SemanticColorToken
    private let content: (LayoutMetrics) -> Content

}

#Preview("Screen Container") {
    ScreenContainer { _ in
        StyledText.subtitle1("화면 콘텐츠", alignment: .center)
    }
    .frame(width: 320, height: 240)
}
