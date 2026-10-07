import DesignSystem
import SwiftUI
import UIComponent

extension ProjectListScreen {
    struct EmptyProjectsView: View {

        var body: some View {
            VStack(spacing: 0) {
                ScreenHeader(title: "프로젝트", style: .largeTitle, leading: nil)
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

    }
}
