import DesignSystem
import SwiftUI

// MARK: - EmptyState

public struct EmptyState<Illustration: View>: View {

    // MARK: Lifecycle

    public init(
        displayModel: DisplayModel,
        @ViewBuilder illustration: () -> Illustration,
    ) {
        self.displayModel = displayModel
        self.illustration = illustration()
    }

    // MARK: Public

    public var body: some View {
        VStack(spacing: Constant.illustrationSpacing) {
            illustration
                .frame(
                    width: Constant.illustrationSize,
                    height: Constant.illustrationSize,
                )

            VStack(spacing: Constant.textSpacing) {
                StyledText(text: displayModel.title)
                    .textStyle(.subtitle1)
                    .foregroundColorToken(.grey200)
                    .multilineTextAlignment(.center)
                StyledText(text: displayModel.message)
                    .textStyle(.body2)
                    .foregroundColorToken(.grey400)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: Constant.textMaxWidth)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Private

    private enum Constant {
        static var illustrationSize: CGFloat {
            128
        }

        static var illustrationSpacing: CGFloat {
            16
        }

        static var textSpacing: CGFloat {
            8
        }

        static var textMaxWidth: CGFloat {
            320
        }
    }

    private let displayModel: DisplayModel
    private let illustration: Illustration

}

// MARK: EmptyState.DisplayModel

extension EmptyState {
    public struct DisplayModel: Sendable, Equatable {
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
}

#Preview("Empty State") {
    EmptyState(
        displayModel: .init(
            title: "projects = []",
            message:
            """
            아직 저장한 항목이 없습니다.
            다시 확인할 내용을 저장해 보세요.
            """,
        )
    ) {
        ResourceImage(asset: .illust(.levelEntry))
    }
    .frame(
        width: 390,
        height: 420,
    )
    .designSystemBackground(.grey700)
}
