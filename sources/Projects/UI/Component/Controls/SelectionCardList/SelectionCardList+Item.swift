import DesignSystem
import SwiftUI

// MARK: - SelectionCardList.Item

extension SelectionCardList {
    public struct Item: Identifiable, Sendable, Equatable {
        public init(
            id: String,
            displayModel: DisplayModel,
        ) {
            self.id = id
            self.displayModel = displayModel
        }

        public let id: String
        public let displayModel: DisplayModel
    }
}

// MARK: - SelectionCardList.Item.DisplayModel

extension SelectionCardList.Item {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            title: String,
            supportingText: String? = nil,
            illust: ResourceImage.Asset.Illust? = nil,
        ) {
            self.title = title
            self.supportingText = supportingText
            self.illust = illust
        }

        public let title: String
        public let supportingText: String?
        public let illust: ResourceImage.Asset.Illust?
    }
}
