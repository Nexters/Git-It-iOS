import DesignSystem
import SwiftUI
import UIComponent

extension SettingsScreen {
    struct SettingRowContent: View {

        // MARK: Lifecycle

        init(
            icon: Icon,
            title: String,
            color: ColorToken = .grey100,
        ) {
            self.icon = icon
            self.title = title
            self.color = color
        }

        // MARK: Internal

        typealias Icon = ResourceImage.Asset.Icon

        var body: some View {
            HStack(spacing: Constant.iconTitleSpacing) {
                ResourceImage(asset: .icon(icon))
                    .frame(width: Constant.iconSize, height: Constant.iconSize)
                StyledText.body2(title, color: color)
            }
        }

        // MARK: Private

        private enum Constant {
            static let iconSize: CGFloat = 16
            static let iconTitleSpacing: CGFloat = 10
        }

        private let icon: Icon
        private let title: String
        private let color: ColorToken

    }
}
