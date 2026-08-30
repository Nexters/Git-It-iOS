import DesignSystem
import SwiftUI

extension ScreenHeader {
    public struct Control: Sendable, Equatable {
        public init(
            symbol: String,
            label: String,
        ) {
            self.symbol = symbol
            self.label = label
        }

        public static let back = Control(
            symbol: "chevron.left",
            label: "뒤로 가기",
        )
        public static let close = Control(
            symbol: "xmark",
            label: "닫기",
        )

        public let symbol: String
        public let label: String
    }
}
