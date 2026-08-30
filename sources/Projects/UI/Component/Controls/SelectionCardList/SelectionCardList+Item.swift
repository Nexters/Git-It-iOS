import DesignSystem
import SwiftUI

extension SelectionCardList {
    public struct Item: Identifiable, Sendable, Equatable {
        public init(
            id: String,
            title: String,
            supportingText: String? = nil,
            illust: ResourceImage.Asset.Illust? = nil,
            isSelected: Bool = false,
        ) {
            self.id = id
            self.title = title
            self.supportingText = supportingText
            self.illust = illust
            self.isSelected = isSelected
        }

        public let id: String
        public let title: String
        public let supportingText: String?
        public let illust: ResourceImage.Asset.Illust?
        public let isSelected: Bool
    }
}
