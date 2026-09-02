import DesignSystem
import SwiftUI

// MARK: - EmptyState

/// 빈 상태 표시.
///
/// 규격이 정의한 2종(프로젝트 없음 · 저장 문제 없음)에만 쓴다. 네트워크 오류처럼
/// 규격 밖의 상태를 이 컴포넌트로 새로 만들지 않는다.
/// 크기 결정 방식은 `SizingMode.fill`이다 — 삽화만 규격 크기를 유지한다.
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
        VStack(spacing: Constant.illustrationSpacing) {
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
        ResourceImage(asset: .illust(.levelEntry))
    }
    .frame(width: 390, height: 420)
    .designSystemBackground(.grey700)
}
