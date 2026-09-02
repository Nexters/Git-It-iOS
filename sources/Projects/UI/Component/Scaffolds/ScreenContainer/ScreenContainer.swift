import DesignSystem
import SwiftUI

/// 크기 결정 방식은 `SizingMode.fill` — 화면 전체를 채우고 레이아웃 변수를 만든다.
///
/// `LayoutMetricsReader`로 만든 레이아웃 변수를 콘텐츠 빌더의 인자로 전달한다. 이를 필요로
/// 하는 컴포넌트는 Environment가 아니라 생성자로 주입받는다.
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
                .designSystemScreenMargin()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, CGFloat(layoutMetrics.safeAreaTop))
                .padding(.bottom, CGFloat(layoutMetrics.safeAreaBottom))
        }
        .ignoresSafeArea()
        .background(Color(designSystem: background))
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
