import ComposableArchitecture
import SwiftUI

#Preview("Onboarding - guide") {
    OnboardingRouter(
        store: Store(
            initialState: OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        ) { EmptyReducer() }
    )
}

#Preview("Onboarding - curation") {
    OnboardingRouter(
        store: Store(
            initialState: OnboardingRouterFeature.State(startingAt: .curation, bundleVersion: "1.0.0")
        ) { EmptyReducer() }
    )
}
