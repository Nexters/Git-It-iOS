import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - OnboardingScreen

/// 현재 `phase`에 맞는 화면을 정확히 하나만 렌더링하는 onboarding 진입점이다. App은 이 화면
/// 하나만 생성하며 내부 phase 전환은 이 컨테이너가 조정한다.
public struct OnboardingScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    // MARK: Public

    public var body: some View {
        content
            .accessibilityElement(children: .contain)
    }

    // MARK: Private

    @Bindable private var store: StoreOf<OnboardingFeature>

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .splash, .restoreError:
            SplashScreen(store: store)

        case .tutorial, .legalAgreement:
            TutorialScreen(store: store)

        case .position:
            PositionSelectionScreen(store: store)

        case .career:
            CareerSelectionScreen(store: store)

        case .completing:
            completingContent
        }
    }

    @ViewBuilder
    private var completingContent: some View {
        ScreenContainer {
            VStack(spacing: LayoutToken.margin.cgFloatValue) {
                Spacer()

                ProgressView()
                    .tint(Color(designSystem: .blue100))
                    .accessibilityHidden(true)

                StyledText.body2("시작 준비를 마무리하고 있어요", alignment: .center)
                    .accessibilityLabel("시작 준비 중")

                Spacer()
            }
            .designSystemScreenMargin()
        }
    }

}

#Preview("Onboarding - splash") {
    OnboardingScreen(store: OnboardingFeature.previewStore(.init(bundleVersion: "1.0.0")))
}

#Preview("Onboarding - completing") {
    var state = OnboardingFeature.State(bundleVersion: "1.0.0")
    state.phase = .completing
    return OnboardingScreen(store: OnboardingFeature.previewStore(state))
}
