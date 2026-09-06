import DesignSystem
import SwiftUI
import UIComponent

extension ProjectListScreen {
    struct EmptyProjectsView: View {

        // MARK: Internal

        var body: some View {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: Constant.headerTitleSpacing) {
                    Spacer(minLength: 0)
                        .frame(height: Constant.headerControlRowHeight)

                    ScreenHeaderTitle(title: "프로젝트")
                }
                .padding(.bottom, Constant.headerBottomPadding)
                .frame(height: Constant.headerHeight, alignment: .top)
                .designSystemScreenMargin()

                Spacer(minLength: 0)

                EmptyState(
                    title: "projects = []",
                    message: "아직 등록한 프로젝트가 없어요.\n관심 있는 오픈소스를 가져와 문제로 만들어보세요.",
                ) {
                    ResourceAnimation(asset: .projectEmpty, isLooping: true)
                }
                .designSystemScreenMargin()

                Spacer(minLength: 0)
            }
        }

        // MARK: Private

        private enum Constant {
            static let headerControlRowHeight: CGFloat = 40
            static let headerTitleSpacing: CGFloat = 16
            static let headerBottomPadding: CGFloat = 10
            static let headerHeight: CGFloat = 99
        }

    }
}
