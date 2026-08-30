import DesignSystem
import SwiftUI

extension ActionMenu {
    public struct Item: Identifiable, Sendable, Equatable {
        public init(
            id: String,
            title: String,
            accessibilityLabel: String,
        ) {
            self.id = id
            self.title = title
            self.accessibilityLabel = accessibilityLabel
        }

        public let id: String
        public let title: String
        public let accessibilityLabel: String
    }
}
