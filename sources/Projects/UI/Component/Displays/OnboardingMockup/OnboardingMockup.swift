import DesignSystem
import SwiftUI

// MARK: - OnboardingMockup

public struct OnboardingMockup: View {

    // MARK: Lifecycle

    public init(page: Int) {
        self.page = page
    }

    // MARK: Public

    public var body: some View {
        ResourceImage(asset: asset, contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Private

    private let page: Int

    private var asset: ResourceImage.Asset {
        switch page {
        case 1: .onboarding(.mockup1)
        case 2: .onboarding(.mockup2)
        default: .onboarding(.mockup3)
        }
    }

}

// MARK: OnboardingMockup.Constant

extension OnboardingMockup {
    fileprivate enum Constant {
        static let bezelWidth: CGFloat = 8
    }
}

#Preview("Onboarding Mockup") {
    HStack(spacing: LayoutToken.margin) {
        OnboardingMockup(page: 1)
        OnboardingMockup(page: 2)
        OnboardingMockup(page: 3)
    }
    .frame(height: 400)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
