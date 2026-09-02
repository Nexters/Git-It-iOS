import SwiftUI

/// 화면 크기와 safe area를 읽어 `LayoutMetrics`를 만들고 콘텐츠 빌더의 인자로 전달한다.
///
/// 레이아웃 변수를 Environment로 흘려보내지 않고, 이를 필요로 하는 컴포넌트가 생성자로
/// 주입받게 하는 유일한 측정 지점이다.
///
/// `ignoresSafeArea()`를 적용하면 안 된다. safe area를 소비한 `GeometryReader`는 inset을
/// 0으로 보고하므로 측정이 무의미해진다.
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
    ///
    /// `proxy.size`는 safe area를 뺀 크기이므로 inset을 더해 화면 전체 크기로 되돌린다.
    static func layoutMetrics(proxy: GeometryProxy) -> LayoutMetrics {
        let insets = proxy.safeAreaInsets
        return LayoutMetrics(
            screenWidth: proxy.size.width + insets.leading + insets.trailing,
            screenHeight: proxy.size.height + insets.top + insets.bottom,
            safeAreaTop: insets.top,
            safeAreaBottom: insets.bottom,
        )
    }

    // MARK: Private

    private let content: (LayoutMetrics) -> Content

}
