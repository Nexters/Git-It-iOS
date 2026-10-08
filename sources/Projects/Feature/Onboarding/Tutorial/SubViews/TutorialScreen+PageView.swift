import DesignSystem
import SwiftUI
import UIComponent

extension TutorialScreen {
    struct PageView: View {

        // MARK: Internal

        let page: Int

        var body: some View {
            VStack(spacing: 0) {
                StyledText(text: title)
                    .textStyle(.subtitle1)
                    .multilineTextAlignment(.center)
                    .padding(.top, Constant.titleTopInset)

                Spacer(minLength: LayoutToken.margin)

                OnboardingMockup(page: page)
                    .frame(width: Constant.mockupWidth)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                    )
            }
            .designSystemScreenMargin()
        }

        // MARK: Private

        private enum Constant {
            static let titleTopInset: CGFloat = 68
            static let mockupWidth: CGFloat = 212
        }

        private var title: String {
            switch page {
            case 1: LocalizedText.Onboarding.Tutorial.Page.First.title
            case 2: LocalizedText.Onboarding.Tutorial.Page.Second.title
            default: LocalizedText.Onboarding.Tutorial.Page.Third.title
            }
        }

    }
}
