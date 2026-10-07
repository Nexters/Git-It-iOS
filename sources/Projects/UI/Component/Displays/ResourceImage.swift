import DesignSystem
import SwiftUI

// MARK: - ResourceImage

public struct ResourceImage: View {

    // MARK: Lifecycle

    public init(
        asset: Asset,
        contentMode: ContentMode = .fit,
    ) {
        self.asset = asset
        self.contentMode = contentMode
    }

    // MARK: Public

    public enum Asset: Sendable, Equatable {
        case icon(Icon)
        case illust(Illust)
        case logo(Logo)
        case onboarding(Onboarding)

        // MARK: Public

        public enum Logo: String, Sendable, Equatable, CaseIterable {
            case app = "app-logo-image"
        }

        public enum Icon: String, Sendable, Equatable, CaseIterable {
            case bookmark = "ic-bookmark"
            case bookmarkFilled = "ic-bookmark-filled"
            case cancel = "ic-cancel"
            case chevronDown = "ic-chevron-down"
            case chevronLeft = "ic-chevron-left"
            case chevronRight = "ic-chevron-right"
            case chevronUp = "ic-chevron-up"
            case chevronLeftWhite = "ic-chevron-left-white"
            case chevronRightWhite = "ic-chevron-right-white"
            case close = "ic-close"
            case edit = "ic-edit"
            case fileText = "ic-file-text"
            case home = "ic-home"
            case link = "ic-link"
            case menu = "ic-menu"
            case minus = "ic-minus"
            case play = "ic-play-1"
            case playLarge = "ic-play-2"
            case playSmall = "ic-play-3"
            case profile = "ic-profile"
            case setting = "ic-setting"
            case settingAlert = "ic-setting-alert"
            case settingChevron = "ic-setting-chevron"
            case settingDelete = "ic-setting-delete"
            case settingDevelop = "ic-setting-develop"
            case settingLevel = "ic-setting-level"
            case settingLogout = "ic-setting-logout"
            case settingPolicy = "ic-setting-policy"
            case star = "ic-star"
            case statusCheck = "ic-status-check"
            case statusDisabled = "ic-status-disabled"
            case statusLoading = "ic-status-loading"
            case statusLoadingDisabled = "ic-status-loading-disable"
            case user = "ic-user"
        }

        public enum Illust: String, Sendable, Equatable, CaseIterable {
            case knowledgeAdvanced = "illust_knowledge_advanced"
            case knowledgeBasic = "illust_knowledge_basic"
            case knowledgeIntermediate = "illust_knowledge_intermediate"
            case levelEntry = "illust_level_entry"
            case levelJunior = "illust_level_junior"
            case levelMiddle = "illust_level_middle"
            case levelSenior = "illust_level_senior"
        }

        public enum Onboarding: String, Sendable, Equatable, CaseIterable {
            case mockup1 = "onboarding-mockup-1"
            case mockup2 = "onboarding-mockup-2"
            case mockup3 = "onboarding-mockup-3"
        }

        // MARK: Fileprivate

        fileprivate var resourceName: String {
            switch self {
            case .icon(let asset): asset.rawValue
            case .illust(let asset): asset.rawValue
            case .logo(let asset): asset.rawValue
            case .onboarding(let asset): asset.rawValue
            }
        }
    }

    public var body: some View {
        Image.resizable(asset)
            .aspectRatio(contentMode: contentMode)
    }

    // MARK: Private

    private let asset: Asset
    private let contentMode: ContentMode

}

#Preview("Resource Image") {
    HStack(spacing: LayoutToken.gutter) {
        ResourceImage(asset: .illust(.knowledgeBasic), contentMode: .fill)
            .frame(width: 96, height: 96)
            .designSystemCornerRadius(.extraLarge)

        ResourceImage(asset: .icon(.user), contentMode: .fill)
            .frame(width: 96, height: 96)
            .clipShape(Circle())

        ResourceImage(asset: .illust(.levelEntry))
            .frame(width: 96, height: 96)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}

extension Image {
    public static func resizable(_ asset: ResourceImage.Asset) -> Image {
        Image(asset.resourceName, bundle: .module)
            .resizable()
    }
}
