import DesignSystem
import SwiftUI

public struct OnboardingMockup: View {

    // MARK: Lifecycle

    public init(page: Int) {
        self.page = page
    }

    // MARK: Public

    public var body: some View {
        ResourceImage(asset: asset, contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(designSystem: .extraLarge))
            .overlay {
                RoundedRectangle(designSystem: .extraLarge)
                    .stroke(Color(designSystem: .raisedBackground), lineWidth: Constant.bezelWidth)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("앱 화면 미리보기")
    }

    // MARK: Private

    private enum Constant {
        static let bezelWidth: CGFloat = 8
    }

    private let page: Int

    private var asset: ResourceImage.Asset {
        switch page {
        case 1: .onboardingMockup1
        case 2: .onboardingMockup2
        default: .onboardingMockup3
        }
    }

}

#Preview("Onboarding Mockup") {
    HStack(spacing: LayoutToken.margin.cgFloatValue) {
        OnboardingMockup(page: 1)
        OnboardingMockup(page: 2)
        OnboardingMockup(page: 3)
    }
    .frame(height: 400)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
