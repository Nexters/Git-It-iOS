import SwiftUI

#Preview("Tutorial - 1페이지 · 779:33450") {
    var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
    state.screen = .tutorial(page: 1)
    return TutorialScreen(store: OnboardingGuideFeature.previewStore(state))
}

#Preview("Tutorial - 2페이지 · 779:33529") {
    var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
    state.screen = .tutorial(page: 2)
    return TutorialScreen(store: OnboardingGuideFeature.previewStore(state))
}

#Preview("Tutorial - 3페이지 로그인 · 779:33564") {
    var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
    state.screen = .tutorial(page: 3)
    return TutorialScreen(store: OnboardingGuideFeature.previewStore(state))
}

#Preview("Tutorial - 로그인 취소") {
    var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
    state.screen = .tutorial(page: 3)
    state.authentication = .cancelled
    return TutorialScreen(store: OnboardingGuideFeature.previewStore(state))
}
