import DesignSystem
import DomainIdentifier
import DomainQuizDetail
import SwiftUI
import UIComponent

extension SavedScreen {
    struct FilterSection: View {

        // MARK: Internal

        let projects: [QuizBookmarkProject]
        let selectedProjectID: ProjectID?
        let count: Int
        let onSelect: (ProjectID?) -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                ScrollView(.horizontal) {
                    HStack(spacing: LayoutToken.compactSpacing) {
                        Chip(
                            label: Constant.allLabel,
                            isSelected: Binding(
                                get: { selectedProjectID == nil },
                                set: { _ in onSelect(nil) },
                            ),
                        )
                        ForEach(projects) { project in
                            Chip(
                                label: project.name,
                                isSelected: Binding(
                                    get: { selectedProjectID == project.id },
                                    set: { _ in onSelect(project.id) },
                                ),
                            )
                        }
                    }
                }
                .scrollIndicators(.hidden)
                StyledText(text: "\(count)개")
                    .textStyle(.body2)
                    .foregroundColorToken(.grey400)
            }
            .designSystemCornerRadius(.small)
        }

        // MARK: Private

        private enum Constant {
            static let rowVerticalPadding: CGFloat = 10
            static let allLabel = "전체"
        }

    }
}
