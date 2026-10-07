import DesignSystem
import SwiftUI
import UIComponent

extension TutorialScreen {
    struct PageView: View {

        // MARK: Internal

        let page: Int

        var body: some View {
            VStack(spacing: 0) {
                StyledText.subtitle1(Constant.title(for: page), alignment: .center)
                    .padding(.top, Constant.titleTopInset)

                Spacer(minLength: LayoutToken.margin.cgFloatValue)

                OnboardingMockup(page: page)
                    .frame(width: Constant.mockupWidth)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .designSystemScreenMargin()
        }

        // MARK: Private

        private enum Constant {
            static let titleTopInset: CGFloat = 68
            static let mockupWidth: CGFloat = 212

            static func title(for page: Int) -> String {
                switch page {
                case 1: "오픈소스를 문제화하고\n나만의 덱으로 만들어보세요"
                case 2: "복잡한 코드말고 자연어로\n언제 어디서든 가볍게!"
                default: "다시보고 싶은 문제는\n저장하고 나중에 확인해요"
                }
            }
        }

    }
}
