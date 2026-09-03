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
                    message: "아직 등록한 프로젝트가 없습니다.\n레포지토리를 연결해 학습을 시작해 보세요.",
                ) {
                    ResourceAnimation(asset: .storageEmpty, isLooping: false)
                }
                .designSystemScreenMargin()

                Spacer(minLength: 0)
            }
        }

    }
}
