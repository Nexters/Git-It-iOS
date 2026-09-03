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
                ScreenContainer { _ in
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
        OverlayContainer { layoutMetrics in
            ScreenOverlayHeader(
                style: .largeTitle,
                layoutMetrics: layoutMetrics,
                onLeadingTap: { send(.backTapped) },
            )
        } content: { _ in
            VStack(alignment: .leading, spacing: Constant.textSpacing) {
                StyledText.subtitle2(store.label, color: .blue100)
                StyledText.subtitle1(store.learningSet?.title ?? "")
                StyledText.body2(store.learningSet?.description ?? "", color: .grey400)
                    .padding(.top, Constant.descriptionTopPadding)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .designSystemScreenMargin()
            .padding(.top, Constant.textTopPadding)
        } footer: { layoutMetrics in
            startAction(layoutMetrics: layoutMetrics)
        }
        .overlay {
            if case .loading = store.setLoad {
                ProgressView()
                    .tint(Color(designSystem: .blue100))
            }
        }
    }

    private func startAction(layoutMetrics: LayoutMetrics) -> some View {
        ScreenOverlayFooter(layoutMetrics: layoutMetrics) {
            VStack(spacing: Constant.textSpacing) {
                if store.isEmptySetReported {
                    StyledText.body2("아직 풀 수 있는 문제가 없어요.", color: .grey400, alignment: .center)
                }

                ActionButton.primary(
                    "시작하기",
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
        static let descriptionTopPadding: CGFloat = 10
        static let bottomButtonPadding: CGFloat = 34
    }
}
