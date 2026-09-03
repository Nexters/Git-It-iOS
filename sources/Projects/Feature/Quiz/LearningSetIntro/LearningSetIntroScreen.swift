import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - LearningSetIntroScreen

@ViewAction(for: LearningSetIntroFeature.self)
struct LearningSetIntroScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<LearningSetIntroFeature>

    var body: some View {
        Group {
            if case .failed = store.setLoad {
                ErrorView(
                    bottomButtonPadding: Constant.bottomButtonPadding,
                    onBack: { send(.backTapped) },
                    onRetry: { send(.retryTapped) },
                )
            } else {
                content
            }
        }
        .task { await store.send(.view(.task)).finish() }
    }

    // MARK: Private

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(style: .largeTitle, onLeadingTap: { send(.backTapped) })
                .designSystemScreenMargin()

            VStack(alignment: .leading, spacing: Constant.textSpacing) {
                TagBadge.neutral(store.label)
                StyledText.subtitle1(store.learningSet?.title ?? "")
                StyledText.body2(store.learningSet?.description ?? "", color: .grey400)
            }
            .designSystemScreenMargin()
            .padding(.top, Constant.textTopPadding)

            Spacer(minLength: 0)

            if store.isEmptySetReported {
                StyledText.body2("아직 풀 수 있는 문제가 없어요.", color: .grey400, alignment: .center)
                    .designSystemScreenMargin()
                    .padding(.bottom, Constant.textSpacing)
            }

            ActionButton.primary(
                "시작하기",
                isEnabled: store.isStartEnabled,
                action: { send(.startTapped) },
            )
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomButtonPadding)
        }
        .overlay {
            if case .loading = store.setLoad {
                ProgressView()
                    .tint(Color(designSystem: .blue100))
            }
        }
    }

}

// MARK: LearningSetIntroScreen.Constant

extension LearningSetIntroScreen {
    fileprivate enum Constant {
        static let textTopPadding: CGFloat = 24
        static let textSpacing: CGFloat = 12
        static let bottomButtonPadding: CGFloat = 34
    }
}
