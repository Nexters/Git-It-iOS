import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - QuizGenerationConfirmationScreen

@ViewAction(for: QuizGenerationConfirmationFeature.self)
struct QuizGenerationConfirmationScreen: View {

    @Bindable var store: StoreOf<QuizGenerationConfirmationFeature>

    var body: some View {
        VStack(spacing: 0) {
            ScreenControlBar(onLeadingTap: { send(.backTapped) })
                .designSystemScreenMargin()

            Spacer(minLength: 0)

            VStack(spacing: Constant.textSetSpacing) {
                StyledText.subtitle1("입력해주신 정보로\n학습 세트를 만들게요", alignment: .center)
                StyledText.body2("1~5분의 시간이 소요돼요", color: .grey400, alignment: .center)
            }
            .designSystemScreenMargin()

            Spacer(minLength: 0)

            ActionButton.primary("시작하기", action: { send(.startTapped) })
                .designSystemScreenMargin()
                .padding(.bottom, Constant.bottomButtonPadding)
        }
    }

}

// MARK: QuizGenerationConfirmationScreen.Constant

extension QuizGenerationConfirmationScreen {
    fileprivate enum Constant {
        static let textSetSpacing: CGFloat = 16
        static let bottomButtonPadding: CGFloat = 24
    }
}
