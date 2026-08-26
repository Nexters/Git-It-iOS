import DesignSystem
import SwiftUI

// MARK: - SheetSurface

public struct SheetSurface<Content: View>: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel = .init(),
        @ViewBuilder content: () -> Content,
    ) {
        self.viewModel = viewModel
        self.content = content()
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        /// `isScrollable`이 `true`면 Dynamic Type이 크거나 화면이 작아 content가 sheet
        /// 높이를 넘어도 스크롤로 접근할 수 있습니다(예: 정책 목록과 CTA). 기본값 `false`는
        /// 기존 고정 레이아웃 호출자의 시각적 결과를 그대로 유지합니다.
        public init(isScrollable: Bool = false) {
            self.isScrollable = isScrollable
        }

        public let isScrollable: Bool
    }

    public var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(designSystem: .grey400))
                .frame(width: Constant.grabberWidth, height: Constant.grabberHeight)
                .padding(.top, Constant.grabberTopPadding)
                .padding(.bottom, Constant.grabberBottomPadding)

            if viewModel.isScrollable {
                ScrollView {
                    content
                }
                .contentMargins(.all, 0, for: .scrollContent)
                .scrollBounceBehavior(.basedOnSize)
            } else {
                content
            }
        }
        .designSystemScreenMargin()
        .padding(.bottom, Constant.bottomPadding)
        .background(
            Color(designSystem: .cardBackground),
            in: UnevenRoundedRectangle(designSystemTopCorners: .extraLarge),
        )
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

    private let viewModel: ViewModel
    private let content: Content

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

        SheetSurface(viewModel: .init(isScrollable: true)) {
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
