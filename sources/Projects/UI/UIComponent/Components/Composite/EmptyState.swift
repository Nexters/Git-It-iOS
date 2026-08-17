import DesignSystem
import SwiftUI

// MARK: - EmptyState

public struct EmptyState<Illustration: View>: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        @ViewBuilder illustration: () -> Illustration,
    ) {
        self.viewModel = viewModel
        self.illustration = illustration()
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(
            title: String,
            message: String,
        ) {
            self.title = title
            self.message = message
        }

        public let title: String
        public let message: String
    }

    public var body: some View {
        VStack(spacing: LayoutToken.margin.cgFloatValue) {
            illustration
                .frame(width: Constant.illustrationSize, height: Constant.illustrationSize)

            VStack(spacing: Constant.textSpacing) {
                StyledText.subtitle1(viewModel.title, alignment: .center)
                StyledText.body2(viewModel.message, color: .grey400, alignment: .center)
            }
            .frame(maxWidth: Constant.textMaxWidth)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private let viewModel: ViewModel
    private let illustration: Illustration

}

// MARK: - Constant

/// 제네릭 타입은 static 저장 프로퍼티를 소유할 수 없으므로 파일 범위에 둡니다.
private enum Constant {
    static let illustrationSize: CGFloat = 128
    static let textSpacing: CGFloat = 8
    static let textMaxWidth: CGFloat = 320
}

#Preview("Empty State") {
    EmptyState(
        viewModel: .init(
            title: "Nothing saved yet.",
            message: "아직 저장한 항목이 없습니다.\n다시 확인할 내용을 저장해 보세요.",
        )
    ) {
        ResourceImage(viewModel: .init(asset: .emptyState))
    }
    .frame(width: 390, height: 420)
    .designSystemBackground(.grey700)
}
