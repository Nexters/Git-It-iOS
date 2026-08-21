import DesignSystem
import SwiftUI

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

    /// `UIComponent`의 `Assets.xcassets`가 소유하는 이미지 자산 목록입니다.
    /// 호출부가 자산 이름 문자열과 리소스 번들을 직접 다루지 않도록 이 열거형이 둘을 함께 소유합니다.
    public enum Asset: String, Sendable, Equatable, CaseIterable {
        case profile
        case emptyState = "empty-state"
        case creationLoading = "creation-loading"
        case learningComplete = "learning-complete"
        case projectAndroid = "project-android"
        case projectDetail = "project-detail"
        case projectNexters = "project-nexters"
        case selectionCardThumbnail = "selection-card-thumbnail"
        case onboardingMockup1 = "onboarding-mockup-1"
        case onboardingMockup2 = "onboarding-mockup-2"
        case onboardingMockup3 = "onboarding-mockup-3"

        public var image: Image {
            Image(rawValue, bundle: .module)
        }
    }

    public var body: some View {
        asset.image
            .resizable()
            .aspectRatio(contentMode: contentMode)
    }

    // MARK: Private

    private let asset: Asset
    private let contentMode: ContentMode

}

#Preview("Resource Image") {
    HStack(spacing: LayoutToken.gutter.cgFloatValue) {
        ResourceImage(asset: .selectionCardThumbnail, contentMode: .fill)
            .frame(width: 96, height: 96)
            .designSystemCornerRadius(.extraLarge)

        ResourceImage(asset: .profile, contentMode: .fill)
            .frame(width: 96, height: 96)
            .clipShape(Circle())

        ResourceImage(asset: .emptyState)
            .frame(width: 96, height: 96)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
