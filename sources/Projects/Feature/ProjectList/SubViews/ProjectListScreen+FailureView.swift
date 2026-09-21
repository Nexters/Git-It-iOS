import DesignSystem
import SwiftUI
import UIComponent

extension ProjectListScreen {
    struct FailureView: View {

        // MARK: Internal

        let onRetry: () -> Void

        var body: some View {
            VStack(spacing: LayoutToken.margin) {
                VStack(alignment: .leading, spacing: Constant.headerTitleSpacing) {
                    Spacer(minLength: 0)
                        .frame(height: Constant.headerControlRowHeight)

                    ScreenHeaderTitle(displayModel: .init(title: "프로젝트"))
                }
                .padding(.bottom, Constant.headerBottomPadding)
                .frame(height: Constant.headerHeight, alignment: .top)
                .designSystemScreenMargin()

                Spacer(minLength: 0)

                VStack(spacing: Constant.textSpacing) {
                    StyledText(text: "프로젝트를 불러오지 못했어요")
                        .textStyle(.subtitle1)
                        .multilineTextAlignment(.center)
                    StyledText(text: "잠시 후 다시 시도해 주세요.")
                        .textStyle(.body2)
                        .foregroundColorToken(.grey400)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 0)

                FeedbackActionButton(title: "다시 시도하기", action: onRetry)
                    .designSystemScreenMargin()
                    .padding(.bottom, Constant.bottomButtonPadding)
            }
        }

        // MARK: Private

        private enum Constant {
            static let textSpacing: CGFloat = 10
            static let bottomButtonPadding: CGFloat = 24
            static let headerControlRowHeight: CGFloat = 40
            static let headerTitleSpacing: CGFloat = 16
            static let headerBottomPadding: CGFloat = 10
            static let headerHeight: CGFloat = 99
        }

    }
}
