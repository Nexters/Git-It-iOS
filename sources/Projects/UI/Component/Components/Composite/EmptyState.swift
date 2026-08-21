import DesignSystem
import SwiftUI

// MARK: - EmptyState

public struct EmptyState<Illustration: View>: View {

    // MARK: Lifecycle

    public init(
        title: String,
        message: String,
        @ViewBuilder illustration: () -> Illustration,
    ) {
        self.title = title
        self.message = message
        self.illustration = illustration()
    }

    // MARK: Public

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
                        title,
                        alignment: .center,
                    )
                StyledText
                    .body2(
                        message,
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

    private let title: String
    private let message: String
    private let illustration: Illustration

}

#Preview("Empty State") {
    EmptyState(
        title: "projects = []",
        message:
        """
        아직 저장한 항목이 없습니다.
        다시 확인할 내용을 저장해 보세요.
        """,
    ) {
        ResourceAnimation(asset: .projectEmpty, isLooping: false)
    }
    .frame(width: 390, height: 420)
    .designSystemBackground(.grey700)
}
