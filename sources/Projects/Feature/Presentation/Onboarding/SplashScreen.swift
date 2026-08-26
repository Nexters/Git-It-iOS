import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - SplashScreen

/// launch 자동 세션 복구의 loading·오류·retry를 보여준다. `phase`가 `splash`·`restoreError`일
/// 때만 표시되며 나머지 phase는 `OnboardingScreen`이 다른 화면으로 대체한다.
@ViewAction(for: OnboardingFeature.self)
struct SplashScreen: View {

    // MARK: Lifecycle

    init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    // MARK: Public

    var body: some View {
        ScreenContainer {
            VStack(spacing: Constant.contentSpacing) {
                Spacer()

                if case .restoreError = store.phase {
                    errorContent
                } else {
                    loadingContent
                }

                Spacer()
            }
            .designSystemScreenMargin()
        }
        .task { send(.task) }
    }

    // MARK: Private

    private enum Constant {
        static let contentSpacing: CGFloat = 16
    }

    @Bindable var store: StoreOf<OnboardingFeature>

    @ViewBuilder
    private var loadingContent: some View {
        ProgressView()
            .tint(Color(designSystem: .blue100))
            .accessibilityHidden(true)

        StyledText.body2("세션을 확인하고 있어요", alignment: .center)
            .accessibilityLabel("세션 확인 중")
    }

    @ViewBuilder
    private var errorContent: some View {
        StyledText.subtitle2("세션을 확인하지 못했어요", alignment: .center)
        StyledText.body2("네트워크 상태를 확인한 뒤 다시 시도해 주세요.", color: .grey400, alignment: .center)

        ActionButton.primary("다시 시도", action: { send(.retryRestoreTapped) })
    }

}

#Preview("Splash - 세션 확인 중") {
    SplashScreen(store: OnboardingFeature.previewStore(.init(bundleVersion: "1.0.0")))
}

#Preview("Splash - 복구 오류") {
    var state = OnboardingFeature.State(bundleVersion: "1.0.0")
    state.phase = .restoreError
    return SplashScreen(store: OnboardingFeature.previewStore(state))
}
