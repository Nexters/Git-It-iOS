import ComposableArchitecture
import SwiftUI
import UIComponent

// MARK: - HomeScreen

@ViewAction(for: HomeFeature.self)
public struct HomeScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<HomeFeature>

    public var body: some View {
        OverlayContainer(content: { content })
            .scrollIndicators(.hidden)
            .task { await send(.task).finish() }
    }

    // MARK: Private

    @State private var cardListLeadingX: CGFloat?

    private var content: some View {
        VStack(
            alignment: .leading,
            spacing: 0,
        ) {
            summarySection

            Self.ProjectSection(
                state: ProjectSectionState(
                    store.projectSummaries.load,
                    access: store.access,
                ),
                isShowAllAvailable: store.access == .member,
                cardListLeadingX: $cardListLeadingX,
                onShowAllTapped: { send(.showAllProjectsTapped) },
                onProjectRetryTapped: { send(.projectRetryTapped) },
                onProjectCardTapped: { send(.projectCardTapped(projectID: $0)) },
                onLearningTapped: { send(.learningTapped(projectID: $0)) },
            )
        }
    }

    private var summarySection: some View {
        VStack(
            alignment: .leading,
            spacing: 0,
        ) {
            if store.access == .guest {
                Self.SignInSectionView(onSignIn: { send(.signInTapped) })
            } else {
                Self.ProfileHeaderView(
                    display: HomeProfileDisplay(store.profile.load),
                    onRetry: { send(.profileRetryTapped) },
                )
            }

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
    }

}

// MARK: HomeScreen.Constant

extension HomeScreen {
    fileprivate enum Constant {
        static let profileTopPadding: CGFloat = 12
        static let greetingTopPadding: CGFloat = 16
        static let registrationPanelTopPadding: CGFloat = 24
        static let projectSectionTopPadding: CGFloat = 32
    }
}
