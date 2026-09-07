import DesignSystem
import SwiftUI

// MARK: - SheetSurface

public struct SheetSurface<Content: View, Footer: View>: View {

    // MARK: Lifecycle

    public init(
        isScrollable: Bool = false,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer = { EmptyView() },
    ) {
        self.isScrollable = isScrollable
        self.content = content()
        self.footer = footer()
    }

    // MARK: Public

    public var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(designSystem: SemanticColorToken.grabber))
                .frame(width: Constant.grabberWidth, height: Constant.grabberHeight)
                .padding(.top, Constant.grabberTopPadding)
                .padding(.bottom, Constant.grabberBottomPadding)

            if isScrollable {
                ScrollView {
                    content
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: ContentHeightPreferenceKey.self,
                                    value: proxy.size.height,
                                )
                            }
                        )
                }
                .frame(maxHeight: contentHeight)
                .contentMargins(.all, 0, for: .scrollContent)
                .scrollBounceBehavior(.basedOnSize)
                .onPreferenceChange(ContentHeightPreferenceKey.self) { contentHeight = $0 }
            } else {
                content
            }

            footer
        }
        .designSystemScreenMargin()
        .padding(.bottom, Constant.bottomPadding)
        .background {
            UnevenRoundedRectangle(designSystemTopCorners: .extraLarge)
                .fill(Color(designSystem: .cardBackground))
                .designSystemEffect(.sheetElevation)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: Private

    private enum Constant {
        static var grabberWidth: CGFloat {
            58
        }

        static var grabberHeight: CGFloat {
            4
        }

        static var grabberTopPadding: CGFloat {
            5
        }

        static var grabberBottomPadding: CGFloat {
            7
        }

        static var bottomPadding: CGFloat {
            24
        }
    }

    @State private var contentHeight: CGFloat?

    private let isScrollable: Bool
    private let content: Content
    private let footer: Footer

}

// MARK: - ContentHeightPreferenceKey

private struct ContentHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil

    static func reduce(
        value: inout CGFloat?,
        nextValue: () -> CGFloat?,
    ) {
        value = nextValue() ?? value
    }
}

#Preview("Sheet Surface") {
    VStack(spacing: 0) {
        Spacer()

        SheetSurface {
            VStack(spacing: LayoutToken.margin) {
                StyledText.subtitle2("알림을 받아보시겠어요?", alignment: .center)
                ActionButton.primary("알림 받기")
            }
        }
    }
    .frame(width: 390, height: 320)
    .designSystemBackground(.grey700)
}

#Preview("Sheet Surface Scrollable") {
    VStack(spacing: 0) {
        Spacer()

        SheetSurface(isScrollable: true) {
            VStack(spacing: LayoutToken.margin) {
                ForEach(0..<8, id: \.self) { index in
                    StyledText.body1("정책 문서 \(index + 1)")
                }
            }
        } footer: {
            ActionButton.primary("계속하기")
        }
    }
    .frame(width: 390, height: 320)
    .designSystemBackground(.grey700)
}
