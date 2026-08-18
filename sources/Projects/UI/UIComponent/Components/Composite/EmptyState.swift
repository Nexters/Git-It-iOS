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
                .frame(
                    width: Constant.illustrationSize,
                    height: Constant.illustrationSize,
                )

            VStack(spacing: Constant.textSpacing) {
                StyledText
                    .subtitle1(
                        viewModel.title,
                        alignment: .center,
                    )
                StyledText
                    .body2(
                        viewModel.message,
                        color: .grey400,
                        alignment: .center,
                    )
            }
            .frame(maxWidth: Constant.textMaxWidth)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private enum Constant {
        static var illustrationSize: CGFloat {
            128
        }

        static var textSpacing: CGFloat {
            8
        }

        static var textMaxWidth: CGFloat {
            320
        }
    }

    private let viewModel: ViewModel
    private let illustration: Illustration

}

#Preview("Empty State") {
    EmptyState(
        viewModel: .init(
            title: "projects = []",
            message:
            """
            아직 저장한 항목이 없습니다.
            다시 확인할 내용을 저장해 보세요.
            """,
        )
    ) {
        ResourceImage(viewModel: .init(asset: .emptyState))
    }
    .frame(width: 390, height: 420)
    .designSystemBackground(.grey700)
}
