import SwiftUI

#Preview("Onboarding - guide") {
    OnboardingScreen(
        store: OnboardingRouterFeature.previewStore(
            .init(startingAt: .guide, bundleVersion: "1.0.0")
        )
    )
}

#Preview("Onboarding - curation") {
    OnboardingScreen(
        store: OnboardingRouterFeature.previewStore(
            .init(startingAt: .curation, bundleVersion: "1.0.0")
        )
    )
}
