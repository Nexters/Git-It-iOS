import DesignSystem
import SwiftUI
import UIComponent

extension ProjectListScreen {
    struct ProjectCollectionView<Row: View, ListFooter: View>: View {

        // MARK: Lifecycle

        init(
            projects: [ProjectListDisplay],
            isFailed: Bool,
            @ViewBuilder row: @escaping (ProjectListDisplay) -> Row,
            @ViewBuilder listFooter: () -> ListFooter,
        ) {
            self.projects = projects
            self.isFailed = isFailed
            self.row = row
            self.listFooter = listFooter()
        }

        // MARK: Internal

        var body: some View {
            switch (isFailed, projects.isEmpty) {
            case (true, _):
                centered {
                    VStack(spacing: Constant.failureTextSpacing) {
                        StyledText(text: "프로젝트를 불러오지 못했어요")
                            .textStyle(.subtitle1)
                            .multilineTextAlignment(.center)
                        StyledText(text: "잠시 후 다시 시도해 주세요.")
                            .textStyle(.body2)
                            .foregroundColorToken(.grey400)
                            .multilineTextAlignment(.center)
                    }
                }

            case (false, true):
                centered {
                    EmptyState(
                        displayModel: .init(
                            title: "projects = []",
                            message: "아직 등록한 프로젝트가 없어요.\n관심 있는 오픈소스를 가져와 문제로 만들어보세요.",
                        )
                    ) {
                        ResourceAnimation(asset: .projectEmpty)
                    }
                    .designSystemScreenMargin()
                }

            case (false, false):
                list
            }
        }

        // MARK: Private

        private enum Constant {
            static var failureTextSpacing: CGFloat {
                10
            }

            static var listVerticalPadding: CGFloat {
                16
            }
        }

        private let projects: [ProjectListDisplay]
        private let isFailed: Bool
        private let row: (ProjectListDisplay) -> Row
        private let listFooter: ListFooter

        private var list: some View {
            LazyVStack(spacing: LayoutToken.compactSpacing) {
                ForEach(projects) { project in
                    row(project)
                }

                listFooter
            }
            .designSystemScreenMargin()
            .padding(.vertical, Constant.listVerticalPadding)
        }

        private func centered(@ViewBuilder content: () -> some View) -> some View {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                content()

                Spacer(minLength: 0)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
            )
        }

    }
}
