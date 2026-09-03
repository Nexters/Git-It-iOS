import ComposableArchitecture
import SwiftUI
import UIComponent

@ViewAction(for: HomeFeature.self)
public struct HomeScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<HomeFeature>

    public var body: some View {
        ScreenContainer { layoutMetrics in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Self.ProfileHeaderView(
                        display: HomeProfileDisplay(store.profileLoad),
                        onRetry: { send(.profileRetryTapped) },
                    )
                    .padding(.top, Constant.profileTopPadding)

                    Self.GreetingView()
                        .padding(.top, Constant.greetingTopPadding)

                    Self.RegistrationPanelView(
                        isGenerationInProgress: store.isGenerationInProgress,
                        onRegister: { send(.projectRegistrationTapped) },
                    )
                    .padding(.top, Constant.registrationPanelTopPadding)
                }
                .designSystemScreenMargin()
                .padding(.bottom, Constant.projectSectionTopPadding)

                Self.ProjectSection(
                    state: HomeProjectSectionState(store.projectLoad),
                    layoutMetrics: layoutMetrics,
                    cardListLeadingX: $cardListLeadingX,
                    onShowAllTapped: { send(.showAllProjectsTapped) },
                    onProjectRetryTapped: { send(.projectRetryTapped) },
                    onProjectCardTapped: { send(.projectCardTapped(projectID: $0)) },
                    onLearningTapped: { send(.learningTapped(projectID: $0)) },
                )
            }
            .scrollIndicators(.hidden)
        }
        .task { await send(.task).finish() }
    }

    // MARK: Private

    @State private var cardListLeadingX: CGFloat?

}

private extension HomeScreen {
    enum Constant {
        static let profileTopPadding: CGFloat = 12
        static let greetingTopPadding: CGFloat = 16
        static let registrationPanelTopPadding: CGFloat = 24
        static let projectSectionTopPadding: CGFloat = 32
    }
}
