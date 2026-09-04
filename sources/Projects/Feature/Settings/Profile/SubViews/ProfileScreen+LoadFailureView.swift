import SwiftUI
import UIComponent

extension ProfileScreen {
    /// 프로필 조회 실패 시 재시도 가능한 오류 안내(FR-007).
    struct LoadFailureView: View {

        // MARK: Internal

        let onRetry: () -> Void

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: Constant.messageSpacing) {
                    StyledText.subtitle3(Constant.title)
                    StyledText.caption1(Constant.message, color: .grey400)
                }
                Spacer()
                ActionButton.secondary(Constant.retryTitle, size: .small, action: onRetry)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(minHeight: Constant.minHeight)
        }

        // MARK: Private

        private enum Constant {
            static let title = "프로필을 불러오지 못했어요"
            static let message = "잠시 후 다시 시도해 주세요."
            static let retryTitle = "다시 시도"
            static let messageSpacing: CGFloat = 4
            static let minHeight: CGFloat = 88
        }

    }
}
