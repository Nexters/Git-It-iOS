import DesignSystem
import SwiftUI

/// 크기 결정 방식은 `SizingMode.fill` — 화면 전체를 채우고 레이아웃 변수를 주입한다.
public struct ScreenContainer<Content: View>: View {

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
        GeometryReader { proxy in
            content
                .designSystemScreenMargin()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, proxy.safeAreaInsets.top)
                .padding(.bottom, proxy.safeAreaInsets.bottom)
                .environment(\.layoutMetrics, Self.layoutMetrics(proxy: proxy))
        }
        .ignoresSafeArea()
        .background(Color(designSystem: background))
        .preferredColorScheme(.dark)
    }

    // MARK: Internal

    /// 화면 크기와 safe area만 읽어 레이아웃 변수를 만든다. 다른 기기 값을 직접 읽지 않는다.
    static func layoutMetrics(proxy: GeometryProxy) -> LayoutMetrics {
        LayoutMetrics(
            screenWidth: proxy.size.width,
            screenHeight: proxy.size.height,
            safeAreaTop: proxy.safeAreaInsets.top,
            safeAreaBottom: proxy.safeAreaInsets.bottom,
        )
    }

    // MARK: Private

    private let background: SemanticColorToken
    private let content: Content

}

#Preview("Screen Container") {
    ScreenContainer {
        StyledText.subtitle1("화면 콘텐츠", alignment: .center)
    }
    .frame(width: 320, height: 240)
}
