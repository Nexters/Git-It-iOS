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
        self.header = header()
        self.content = content()
        self.background = background()
        self.footer = footer()
    }

    // MARK: Public

    public var body: some View {
        ZStack(alignment: .top) {
            scrollingContent

            VStack(alignment: .leading) {
                header
                    .background {
                        LinearGradient(designSystem: .overlayHeaderScrim)
                            .ignoresSafeArea(edges: .top)
                    }

                Spacer()
                footer
                    .padding(.top, 12)
                    .background {
                        LinearGradient(designSystem: .overlayFooterScrim)
                            .ignoresSafeArea(edges: .bottom)
                    }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(designSystem: screenBackground).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: Private

    private let screenBackground: SemanticColorToken
    private let header: Header
    private let content: Content
    private let background: Background
    private let footer: Footer

    private var scrollingContent: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    occlusionSpacer { header }
                    content
                    occlusionSpacer { footer }
                }
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
                .padding(.top, proxy.safeAreaInsets.top)
                .background(alignment: .top) { background }
            }
            .scrollBounceBehavior(.basedOnSize)
            .ignoresSafeArea(edges: .top)
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
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 0)
                .frame(height: 40)

            ScreenHeaderTitle(title: "오버레이 헤더")
        }
        .padding(.bottom, 10)
        .frame(height: 99, alignment: .top)
        .designSystemScreenMargin()
    } content: {
        VStack(spacing: LayoutToken.gutter) {
            ForEach(0..<20, id: \.self) { index in
                LabeledCard.neutral(label: "항목 \(index)", text: "스크롤하면 헤더 뒤로 지나갑니다.")
            }
        }
        .designSystemScreenMargin()
    } footer: {
        BottomActionBar {
            ActionButton.primary("계속하기")
                .designSystemScreenMargin()
        }
    }
}
