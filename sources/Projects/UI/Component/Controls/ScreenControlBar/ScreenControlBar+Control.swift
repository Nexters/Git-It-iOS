import DesignSystem
import SwiftUI

extension ScreenControlBar {
    public struct Control: Sendable, Equatable {

        // MARK: Lifecycle

        public init(
            icon: Icon,
            label: String,
        ) {
            self.icon = icon
            self.label = label
        }

        // MARK: Public

        public typealias Icon = ResourceImage.Asset.Icon

        public static let back = Control(
            icon: .chevronLeftWhite,
            label: "뒤로 가기",
        )
        public static let close = Control(
            icon: .x,
            label: "닫기",
        )

        public let icon: Icon
        public let label: String

    }
}
