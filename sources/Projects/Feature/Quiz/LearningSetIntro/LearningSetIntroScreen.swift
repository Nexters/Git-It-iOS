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
        OverlayContainer {
            header
        } content: {
            content
        } background: {
            screenBackground
        } footer: {
            footer
        }
        .overlay {
            if case .loading = store.setLoad {
                ProgressView()
                    .tint(Color(designSystem: .blue100))
            }
        }
        .task { await send(.task).finish() }
    }

    // MARK: Private

    private var isFailed: Bool {
        if case .failed = store.setLoad {
            return true
        }
        return false
    }

    private var header: some View {
        ScreenControlBar(
            onLeadingTap: { send(.backTapped) }
        )
        .designSystemScreenMargin()
    }

    private var content: some View {
        Self.IntroContentView(
            isFailed: isFailed,
            label: store.label,
            title: store.learningSet?.title ?? "",
            description: store.learningSet?.description ?? "",
        )
    }

    @ViewBuilder
    private var footer: some View {
        if isFailed {
            FeedbackActionButton(
                title: "다시 시도하기",
                action: { send(.retryTapped) },
            )
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomButtonPadding)
        } else {
            startAction
                .designSystemScreenMargin()
        }
    }

    @ViewBuilder
    private var screenBackground: some View {
        if !isFailed {
            LinearGradient(designSystem: .backgroundGradient)
                .accessibilityHidden(true)
        }
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
                    action: { send(.startTapped) },
                )
                .enabled(store.isStartEnabled)
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
