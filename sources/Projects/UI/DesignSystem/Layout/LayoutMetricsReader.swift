import SwiftUI

/// 화면 크기와 safe area를 읽어 `LayoutMetrics`를 만들고 콘텐츠 빌더의 인자로 전달한다.
///
/// 레이아웃 변수를 Environment로 흘려보내지 않고, 이를 필요로 하는 컴포넌트가 생성자로
/// 주입받게 하는 유일한 측정 지점이다.
public struct LayoutMetricsReader<Content: View>: View {

    // MARK: Lifecycle

    public init(@ViewBuilder content: @escaping (LayoutMetrics) -> Content) {
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        GeometryReader { proxy in
            content(Self.layoutMetrics(proxy: proxy))
        }
    }

    // MARK: Internal

    /// 다른 기기 값을 직접 읽지 않고 전달받은 proxy만으로 레이아웃 변수를 만든다.
    static func layoutMetrics(proxy: GeometryProxy) -> LayoutMetrics {
        LayoutMetrics(
            screenWidth: proxy.size.width,
            screenHeight: proxy.size.height,
            safeAreaTop: proxy.safeAreaInsets.top,
            safeAreaBottom: proxy.safeAreaInsets.bottom,
        )
    }

    // MARK: Private

    private let content: (LayoutMetrics) -> Content

}
