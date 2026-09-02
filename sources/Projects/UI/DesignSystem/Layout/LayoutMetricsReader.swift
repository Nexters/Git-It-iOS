import SwiftUI

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
