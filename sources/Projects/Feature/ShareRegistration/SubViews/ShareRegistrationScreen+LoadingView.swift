import DesignSystem
import SwiftUI
import UIComponent

extension ShareRegistrationScreen {

    struct LoadingView: View {

        // MARK: Internal

        let message: String

        var body: some View {
            VStack(spacing: Constant.textSetSpacing) {
                Spacer(minLength: 0)

                ResourceAnimation(asset: .generalLoading, isLooping: true)
                    .frame(width: Constant.indicatorSize, height: Constant.indicatorSize)

                StyledText.body2(message, color: .grey400, alignment: .center)

                Spacer(minLength: 0)
            }
            .designSystemScreenMargin()
            .accessibilityElement(children: .combine)
        }

        // MARK: Private

        private enum Constant {
            static let indicatorSize: CGFloat = 120
            static let textSetSpacing: CGFloat = 16
        }

    }

}
