import DesignSystem
import SwiftUI
import UIComponent

extension SavedScreen {
    struct QuestionRow: View {

        // MARK: Internal

        let prompt: String
        let actionTitle: String
        let onSolveTap: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: Constant.contentSpacing) {
                StyledText.subtitle3(prompt)

                HStack {
                    Spacer(minLength: 0)

                    Button(action: onSolveTap) {
                        StyledText.body2(actionTitle, color: .grey700, alignment: .center)
                            .frame(height: Constant.actionHeight)
                            .frame(maxWidth: Constant.actionMaximumWidth)
                            .designSystemBackground(.blue100)
                            .designSystemCornerRadius(.small)
                    }
                    .buttonStyle(.plain)
                    .designSystemControlSize(.minimumTouch)
                    .accessibilityLabel(actionTitle)
                }
            }
            .padding(Constant.contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .designSystemBackground(.cardBackground)
            .designSystemCornerRadius(.large)
        }

        // MARK: Private

        private enum Constant {
            static let contentSpacing: CGFloat = 16
            static let contentPadding: CGFloat = 16
            static let actionHeight: CGFloat = 44
            static let actionMaximumWidth: CGFloat = 120
        }

    }
}
