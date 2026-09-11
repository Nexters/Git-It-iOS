import DesignSystem
import SwiftUI
import UIComponent

extension ProjectListScreen {
    struct NextPageFooter: View {

        // MARK: Internal

        let pagination: ProjectListFeature.Pagination
        let onRetry: () -> Void

        var body: some View {
            switch pagination {
            case .loading:
                ProgressView()
                    .tint(Color(designSystem: .blue100))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Constant.verticalPadding)

            case .failed:
                VStack(spacing: Constant.textSpacing) {
                    StyledText.body2("프로젝트를 더 불러오지 못했어요", color: .grey400, alignment: .center)

                    ActionButton.text("다시 시도하기", size: .small, action: onRetry)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constant.verticalPadding)

            case .idle,
                 .exhausted:
                EmptyView()
            }
        }

        // MARK: Private

        private enum Constant {
            static let verticalPadding: CGFloat = 16
            static let textSpacing: CGFloat = 8
        }

    }
}
