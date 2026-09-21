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

    @Bindable public var store: StoreOf<OnboardingRouterFeature>

    public var body: some View {
        content
            .accessibilityElement(children: .contain)
    }

    // MARK: Private

    private var content: some View {
        FlowNavigationStack(path: pushedScreens) {
            guideContent
        } destination: { screen in
            pushedScreen(screen)
        }
    }

    private var pushedScreens: [OnboardingRouterFeature.ActiveScreen] {
        switch store.activeScreen {
        case .guide:
            []

        case .curation(.positionSelection):
            [.curation(.positionSelection)]

        case .curation(.careerSelection):
            [.curation(.positionSelection), .curation(.careerSelection)]

        case .curationSplash:
            [.curation(.positionSelection), .curation(.careerSelection), .curationSplash]
        }
    }

    private var guideContent: some View {
        TutorialScreen(store: store.scope(state: \.tutorial, action: \.tutorial))
            .overlay {
                ModalOverlay(
                    isPresented: Binding(
                        get: { store.tutorial.signIn.isLegalAgreementPresented },
                        set: { isPresented in
                            if !isPresented {
                                store.send(.tutorial(.signIn(.view(.legalAgreementDismissed))))
                            }
                        },
                    )
                ) {
                    LegalAgreementScreen(
                        store: store.scope(
                            state: \.tutorial.signIn.legalAgreement,
                            action: \.tutorial.signIn.legalAgreement,
                        )
                    )
                }
            }
            .overlay {
                ModalOverlay(
                    isPresented: Binding(
                        get: { store.tutorial.signIn.legalAgreement.presentedDocument != nil },
                        set: { isPresented in
                            if !isPresented {
                                store.send(.tutorial(.signIn(.view(.legalDocumentSheetDismissed))))
                            }
                        },
                    )
                ) {
                    if let document = store.tutorial.signIn.legalAgreement.presentedDocument {
                        WebSheet(
                            displayModel: .init(title: document.displayName, url: document.approvedURL),
                            onDismiss: { store.send(.tutorial(.signIn(.view(.legalDocumentSheetDismissed)))) },
                        )
                    }
                }
            }
    }

    @ViewBuilder
    private func pushedScreen(_ screen: OnboardingRouterFeature.ActiveScreen) -> some View {
        switch screen {
        case .guide:
            EmptyView()

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

}
