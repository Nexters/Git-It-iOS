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
                ScreenContainer {
                    ErrorView(
                        bottomButtonPadding: Constant.bottomButtonPadding,
                        onBack: { send(.backTapped) },
                        onRetry: { send(.retryTapped) },
                    )
                }
            } else {
                content
            }
        }
        .task { await store.send(.view(.task)).finish() }
    }

    // MARK: Private

    private var content: some View {
        OverlayContainer {
            ScreenControlBar(
                onLeadingTap: { send(.backTapped) }
            )
            .designSystemScreenMargin()
        } content: {
            VStack(alignment: .leading, spacing: Constant.textSpacing) {
                StyledText(text: store.label)
                    .textStyle(.subtitle3)
                    .foregroundColorToken(.blue100)
                StyledText(text: store.learningSet?.title ?? "")
                    .textStyle(.subtitle1)
                StyledText(text: store.learningSet?.description ?? "")
                    .textStyle(.body2)
                    .foregroundColorToken(.grey400)
                    .padding(.top, Constant.descriptionTopPadding)
            }
            .designSystemScreenMargin()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } background: {
            screenBackground
        } footer: {
            startAction
                .designSystemScreenMargin()
        }
        .overlay {
            if case .loading = store.setLoad {
                ProgressView()
                    .tint(Color(designSystem: .blue100))
            }
        }
    }

    private var screenBackground: some View {
        LinearGradient(designSystem: .backgroundGradient)
            .accessibilityHidden(true)
    }

    private var startAction: some View {
        BottomActionBar {
            VStack(spacing: Constant.textSpacing) {
                if store.isEmptySetReported {
                    StyledText(text: "아직 풀 수 있는 문제가 없어요.")
                        .textStyle(.body2)
                        .foregroundColorToken(.grey400)
                        .multilineTextAlignment(.center)
                }

                FeedbackActionButton(
                    title: "시작하기",
                    isEnabled: store.isStartEnabled,
                    action: { send(.startTapped) },
                )
            }
        }
    }

}

// MARK: LearningSetIntroScreen.Constant

extension LearningSetIntroScreen {
    fileprivate enum Constant {
        static let textTopPadding: CGFloat = 24
        static let textSpacing: CGFloat = 8
        static let descriptionTopPadding: CGFloat = 8
        static let bottomButtonPadding: CGFloat = 24
    }
}
