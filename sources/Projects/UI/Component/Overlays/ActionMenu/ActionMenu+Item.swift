import DesignSystem
import SwiftUI

extension ActionMenu {
    public struct Item: Identifiable, Sendable, Equatable {

        // MARK: Lifecycle

        public init(
            id: String,
            title: String,
            role: Role = .normal,
            accessibilityLabel: String,
        ) {
            self.id = id
            self.title = title
            self.role = role
            self.accessibilityLabel = accessibilityLabel
        }

        // MARK: Public

        public enum Role: Sendable, Equatable {
            case normal
            case destructive

            // MARK: Internal

            var titleColor: ColorToken {
                switch self {
                case .normal: .grey100
                case .destructive: .error
                }
            }
        }

        public let id: String
        public let title: String
        public let role: Role
        public let accessibilityLabel: String

    }
}
