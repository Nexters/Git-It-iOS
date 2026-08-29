import ComposableArchitecture
import SwiftUI

// MARK: - OnboardingScreen

@ViewAction(for: OnboardingRouterFeature.self)
public struct OnboardingScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<OnboardingRouterFeature>) {
        self.store = store
    }

    // MARK: Public

    public var body: some View {
        content
            .accessibilityElement(children: .contain)
    }

    // MARK: Private

    @Bindable public var store: StoreOf<OnboardingRouterFeature>

    @ViewBuilder
    private var content: some View {
        switch store.activeScreen {
        case .guide:
            OnboardingGuideScreen(store: store.scope(state: \.guide, action: \.guide))

        case .curation:
            CurationScreen(store: store.scope(state: \.curation, action: \.curation))

        case .curationSplash:
            CurationSplashScreen(onCompletion: { send(.curationSplashFinished) })
        }
    }

}
