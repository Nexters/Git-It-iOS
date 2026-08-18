import DesignSystem
import SwiftUI

public struct OnboardingMockup: View {

    // MARK: Lifecycle

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(page: Int) {
            self.page = page
        }

        public let page: Int

        /// 목업 이미지는 페이지 1·2·3만 제공하므로 그 밖의 값은 3번 이미지로 수렴합니다.
        var asset: ResourceImage.Asset {
            switch page {
            case 1: .onboardingMockup1
            case 2: .onboardingMockup2
            default: .onboardingMockup3
            }
        }
    }

    public var body: some View {
        ResourceImage(viewModel: .init(asset: viewModel.asset, contentMode: .fill))
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

    private let viewModel: ViewModel

}

#Preview("Onboarding Mockup") {
    HStack(spacing: LayoutToken.margin.cgFloatValue) {
        OnboardingMockup(viewModel: .init(page: 1))
        OnboardingMockup(viewModel: .init(page: 2))
        OnboardingMockup(viewModel: .init(page: 3))
    }
    .frame(height: 400)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
