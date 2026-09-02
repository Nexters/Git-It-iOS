import DesignSystem
import SwiftUI

// MARK: - SheetSurface

public struct SheetSurface<Content: View>: View {

    // MARK: Lifecycle

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        ViewThatFits(in: .vertical) {
            surface {
                content
            }

            surface {
                ScrollView {
                    content
                }
                .contentMargins(.all, 0, for: .scrollContent)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .frame(maxHeight: CGFloat(layoutMetrics.sheetMaximumHeight))
    }

    // MARK: Private

    @Environment(\.layoutMetrics) private var layoutMetrics

    private let content: Content

    private var grabber: some View {
        Capsule()
            .fill(Color(designSystem: .grabber))
            .frame(width: Constant.grabberWidth, height: Constant.grabberHeight)
            .padding(.top, Constant.grabberTopPadding)
            .padding(.bottom, Constant.grabberBottomPadding)
    }

    @ViewBuilder
    private func surface(@ViewBuilder body: () -> some View) -> some View {
        VStack(spacing: 0) {
            grabber

            body()
        }
        .padding(.bottom, Constant.bottomPadding)
        .background {
            UnevenRoundedRectangle(designSystemTopCorners: .extraLarge)
                .fill(Color(designSystem: .cardBackground))
                .ignoresSafeArea(edges: .bottom)
        }
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

        SheetSurface {
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
