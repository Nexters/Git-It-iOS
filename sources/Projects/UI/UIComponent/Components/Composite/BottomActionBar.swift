import DesignSystem
import SwiftUI

// MARK: - BottomActionBar

public struct BottomActionBar<Content: View>: View {

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
        content
            .frame(maxWidth: .infinity)
            .padding(.top, Constant.topPadding)
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomPadding)
    }

    // MARK: Private

    private let content: Content

}

// MARK: - Constant

/// 제네릭 타입은 static 저장 프로퍼티를 소유할 수 없으므로 파일 범위에 둡니다.
private enum Constant {
    static let topPadding: CGFloat = 4
    static let bottomPadding: CGFloat = 24
}

#Preview("Bottom Action Bar") {
    VStack(spacing: 0) {
        Spacer()

        BottomActionBar {
            ActionButton.primary("계속하기")
        }
        .designSystemBackground(.cardBackground)
    }
    .frame(width: 390, height: 240)
    .designSystemBackground(.grey700)
}
