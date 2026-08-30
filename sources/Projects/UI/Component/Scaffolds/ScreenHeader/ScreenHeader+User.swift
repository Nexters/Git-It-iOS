import DesignSystem
import SwiftUI

extension ScreenHeader {
    public struct User: Sendable, Equatable {
        public init(
            name: String,
            role: String,
        ) {
            self.name = name
            self.role = role
        }

        public let name: String
        public let role: String
    }
}
