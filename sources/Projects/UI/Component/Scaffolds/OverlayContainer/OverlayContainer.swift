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
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder background: @escaping () -> Background,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
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
        header: @escaping () -> Header,
        content: @escaping () -> Content,
        background: @escaping () -> Background,
        footer: @escaping () -> Footer,
    ) {
        self.screenBackground = screenBackground
        self.header = header
        self.content = content
        self.background = background
        self.footer = footer
    }

    // MARK: Public

    public var body: some View {
        ZStack(alignment: .top) {
            scrollingContent

            VStack(spacing: 0) {
                header()

                Spacer(minLength: 0)

                footer()
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footerHeight = $0 }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(designSystem: screenBackground).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: Private

    private let screenBackground: SemanticColorToken
    private let header: () -> Header
    private let content: () -> Content
    private let background: () -> Background
    private let footer: () -> Footer

    @State private var footerHeight: CGFloat = 0

    private var scrollingContent: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    occlusionSpacer { header() }

                    content()

                    Color.clear.frame(height: footerHeight)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, proxy.safeAreaInsets.top)
                .background(alignment: .top) { background() }
            }
            .ignoresSafeArea(edges: .top)
            .onAppear {
                UIScrollView.appearance().bounces = false
            }
        }
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
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
    ) {
        self.init(
            screenBackground: screenBackground,
            header: header,
            content: content,
            background: { EmptyView() },
            footer: footer,
        )
    }

}

#Preview("Overlay Container") {
    OverlayContainer {
        ScreenOverlayHeader(title: "오버레이 헤더", style: .largeTitle)
    } content: {
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            ForEach(0..<20, id: \.self) { index in
                LabeledCard.neutral(label: "항목 \(index)", text: "스크롤하면 헤더 뒤로 지나갑니다.")
            }
        }
        .designSystemScreenMargin()
    } footer: {
        ScreenOverlayFooter {
            ActionButton.primary("계속하기")
        }
    }
}
