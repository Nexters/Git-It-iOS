import DesignSystem
import DomainLearningProject
import SwiftUI
import UIComponent

extension SavedScreen {
    struct FilterSection: View {

        // MARK: Internal

        let projects: [BookmarkedProject]
        let selectedProjectID: String?
        let count: Int
        let onSelect: (String?) -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView(.horizontal) {
                    HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                        Chip(label: Constant.allLabel, isSelected: selectedProjectID == nil) {
                            onSelect(nil)
                        }
                        ForEach(projects) { project in
                            Chip(label: project.name, isSelected: selectedProjectID == project.id) {
                                onSelect(project.id)
                            }
                        }
                    }
                    .designSystemScreenMargin()
                }
                .scrollIndicators(.hidden)
                .padding(.vertical, Constant.rowVerticalPadding)

                StyledText.body2("\(count)개", color: .grey400)
                    .designSystemScreenMargin()
                    .padding(.vertical, Constant.rowVerticalPadding)
            }
        }

        // MARK: Private

        private enum Constant {
            static let rowVerticalPadding: CGFloat = 10
            static let allLabel = "전체"
        }

    }
}
