import ComposableArchitecture
import SwiftUI

// MARK: - OnboardingGuideScreen

struct OnboardingGuideScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<OnboardingGuideFeature>

    var body: some View {
        switch store.screen {
        case .tutorial,
             .legalAgreement:
            TutorialScreen(store: store)
        }
    }

}
