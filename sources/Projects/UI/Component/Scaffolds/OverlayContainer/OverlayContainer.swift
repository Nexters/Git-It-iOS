import DesignSystem
import SwiftUI

// MARK: - OverlayContainer

public struct OverlayContainer<
    Header: View,
    Content: View,
    Background: View,
    Footer: View,
>: View {

    // MARK: Lifecycle

    public init(
        @ViewBuilder header: @escaping (LayoutMetrics) -> Header = { _ in EmptyView() },
        @ViewBuilder content: @escaping (LayoutMetrics) -> Content,
        @ViewBuilder background: @escaping (LayoutMetrics) -> Background,
        @ViewBuilder footer: @escaping (LayoutMetrics) -> Footer = { _ in EmptyView() },
    ) {
        self.init(
            screenBackground: .screenBackground,
            header: header,
            content: content,
            background: background,
            footer: footer,
        )
    }

    private init(
        screenBackground: SemanticColorToken,
        header: @escaping (LayoutMetrics) -> Header,
        content: @escaping (LayoutMetrics) -> Content,
        background: @escaping (LayoutMetrics) -> Background,
        footer: @escaping (LayoutMetrics) -> Footer,
    ) {
        self.screenBackground = screenBackground
        self.header = header
        self.content = content
        self.background = background
        self.footer = footer
    }

    // MARK: Public

    public var body: some View {
        LayoutMetricsReader { layoutMetrics in
            ZStack(alignment: .top) {
                scrollingContent(layoutMetrics)

                VStack(spacing: 0) {
                    header(layoutMetrics)

                    Spacer(minLength: 0)

                    footer(layoutMetrics)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(designSystem: screenBackground).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: Private

    private let screenBackground: SemanticColorToken
    private let header: (LayoutMetrics) -> Header
    private let content: (LayoutMetrics) -> Content
    private let background: (LayoutMetrics) -> Background
    private let footer: (LayoutMetrics) -> Footer

    private func scrollingContent(_ layoutMetrics: LayoutMetrics) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                occlusionSpacer { header(layoutMetrics) }

                content(layoutMetrics)

                occlusionSpacer { footer(layoutMetrics) }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, CGFloat(layoutMetrics.safeAreaTop))
            .background(alignment: .top) { background(layoutMetrics) }
        }
        .ignoresSafeArea(edges: .top)
    }

    private func occlusionSpacer(matching view: () -> some View) -> some View {
        view()
            .hidden()
            .accessibilityHidden(true)
    }

}

// MARK: 색 토큰 배경

extension OverlayContainer where Background == EmptyView {

    public init(
        screenBackground: SemanticColorToken = .screenBackground,
        @ViewBuilder header: @escaping (LayoutMetrics) -> Header = { _ in EmptyView() },
        @ViewBuilder content: @escaping (LayoutMetrics) -> Content,
        @ViewBuilder footer: @escaping (LayoutMetrics) -> Footer = { _ in EmptyView() },
    ) {
        self.init(
            screenBackground: screenBackground,
            header: header,
            content: content,
            background: { _ in EmptyView() },
            footer: footer,
        )
    }

}

#Preview("Overlay Container") {
    OverlayContainer { layoutMetrics in
        ScreenOverlayHeader(
            title: "오버레이 헤더",
            style: .largeTitle,
            layoutMetrics: layoutMetrics,
        )
    } content: { _ in
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            ForEach(0..<20, id: \.self) { index in
                LabeledCard.neutral(label: "항목 \(index)", text: "스크롤하면 헤더 뒤로 지나갑니다.")
            }
        }
        .designSystemScreenMargin()
    } background: { layoutMetrics in
        LinearGradient(designSystem: .topEdgeScrim)
            .frame(height: CGFloat(layoutMetrics.topScrimHeight(headerStyle: .largeTitle)))
    } footer: { layoutMetrics in
        ScreenOverlayFooter(layoutMetrics: layoutMetrics) {
            ActionButton.primary("계속하기")
        }
    }
}
