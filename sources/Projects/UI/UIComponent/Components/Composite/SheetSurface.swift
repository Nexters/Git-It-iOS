import DesignSystem
import SwiftUI

// MARK: - SheetSurface

public struct SheetSurface<Content: View>: View {

    // MARK: Lifecycle

    public init(
        viewModel _: ViewModel = .init(),
        @ViewBuilder content: () -> Content,
    ) {
        self.content = content()
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init() { }
    }

    public var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(designSystem: .grey400))
                .frame(width: Constant.grabberWidth, height: Constant.grabberHeight)
                .padding(.top, Constant.grabberTopPadding)
                .padding(.bottom, Constant.grabberBottomPadding)

            content
        }
        .designSystemScreenMargin()
        .padding(.bottom, Constant.bottomPadding)
        .background(
            Color(designSystem: .cardBackground),
            in: UnevenRoundedRectangle(designSystemTopCorners: .extraLarge),
        )
    }

    // MARK: Private

    private let content: Content

}

// MARK: - Constant

/// 제네릭 타입은 static 저장 프로퍼티를 소유할 수 없으므로 파일 범위에 둡니다.
private enum Constant {
    static let grabberWidth: CGFloat = 48
    static let grabberHeight: CGFloat = 4
    static let grabberTopPadding: CGFloat = 8
    static let grabberBottomPadding: CGFloat = 22
    static let bottomPadding: CGFloat = 24
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
