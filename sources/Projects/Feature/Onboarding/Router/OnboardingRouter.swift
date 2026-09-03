import ComposableArchitecture
import SwiftUI
import UIComponent

@ViewAction(for: OnboardingRouterFeature.self)
public struct OnboardingRouter: View {

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
        case .guide(let screen):
            guideContent(screen)

        case .curation(.positionSelection):
            PositionSelectionScreen(
                store: store.scope(state: \.positionSelection, action: \.positionSelection)
            )

        case .curation(.careerSelection):
            CareerSelectionScreen(
                store: store.scope(state: \.careerSelection, action: \.careerSelection)
            )

        case .curationSplash:
            Self.CurationSplashView(onCompletion: { send(.curationSplashFinished) })
        }
    }

    private func guideContent(_ screen: OnboardingRouterFeature.ActiveScreen.Guide) -> some View {
        TutorialScreen(store: store.scope(state: \.tutorial, action: \.tutorial))
            .overlay {
                ModalOverlay(
                    isPresented: screen == .legalAgreement,
                    onDismiss: { send(.legalAgreementDismissed) },
                ) {
                    LegalAgreementScreen(
                        store: store.scope(state: \.legalAgreement, action: \.legalAgreement)
                    )
                }
            }
            .overlay {
                ModalOverlay(
                    isPresented: store.legalAgreement.presentedDocument != nil,
                    onDismiss: { send(.legalDocumentSheetDismissed) },
                ) {
                    if let document = store.legalAgreement.presentedDocument {
                        WebSheet(
                            title: document.displayName,
                            url: document.approvedURL,
                            onDismiss: { send(.legalDocumentSheetDismissed) },
                        )
                    }
                }
            }
    }

}
