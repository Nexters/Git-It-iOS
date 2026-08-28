import ComposableArchitecture
import SwiftUI

// MARK: - OnboardingScreen

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

    @Bindable private var store: StoreOf<OnboardingRouterFeature>

    @ViewBuilder
    private var content: some View {
        switch store.activeScreen {
        case .guide:
            OnboardingGuideScreen(store: store.scope(state: \.guide, action: \.guide))

        case .curation:
            CurationScreen(store: store.scope(state: \.curation, action: \.curation))
        }
    }

}
