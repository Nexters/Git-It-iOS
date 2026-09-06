import DesignSystem
import SwiftUI

// MARK: - SheetSurface

public struct SheetSurface<Content: View>: View {

    // MARK: Lifecycle

    public init(
        isScrollable: Bool = false,
        @ViewBuilder content: () -> Content,
    ) {
        self.isScrollable = isScrollable
        self.content = content()
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

    @State private var contentHeight: CGFloat?

    private let isScrollable: Bool
    private let content: Content

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
            VStack(spacing: LayoutToken.margin.cgFloatValue) {
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
            VStack(spacing: LayoutToken.margin.cgFloatValue) {
                ForEach(0..<8, id: \.self) { index in
                    StyledText.body1("정책 문서 \(index + 1)")
                }
                ActionButton.primary("계속하기")
            }
        }
    }
    .frame(width: 390, height: 320)
    .designSystemBackground(.grey700)
}
