import SwiftUI
import UIComponent

extension SettingsScreen {
    struct SectionView<Rows: View>: View {

        // MARK: Lifecycle

        init(
            title: String,
            @ViewBuilder rows: () -> Rows,
        ) {
            self.title = title
            self.rows = rows()
        }

        // MARK: Internal

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                StyledText.caption2(title, color: .grey400)
                VStack(spacing: 1) {
                    rows.background(Color(designSystem: .grey600), in: Rectangle())
                }
                .designSystemBackground(.grey500)
                .designSystemCornerRadius(.large)
            }
        }

        // MARK: Private

        private let title: String
        private let rows: Rows

    }
}
