import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - ShareRegistrationScreen

@ViewAction(for: ShareRegistrationFeature.self)
public struct ShareRegistrationScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<ShareRegistrationFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<ShareRegistrationFeature>

    public var body: some View {
        ScreenContainer {
            content
        }
        .task { await send(.task).finish() }
    }

    // MARK: Private

    @ViewBuilder
    private var content: some View {
        switch store.registration.phase {
        case .validating:
            Self.LoadingView(message: LocalizedText.ShareRegistration.lookupMessage)

        case .submitting:
            Self.LoadingView(message: LocalizedText.ShareRegistration.submittingMessage)

        case .ready:
            stepContent

        case .invalidURL(let reason):
            guidance(
                title: LocalizedText.ShareRegistration.invalidLinkTitle,
                message: reason,
            )

        case .signInRequired:
            guidance(
                title: LocalizedText.ShareRegistration.signInRequiredTitle,
                message: LocalizedText.ShareRegistration.signInRequiredMessage,
            )

        case .appLaunchRequired:
            guidance(
                title: LocalizedText.ShareRegistration.appLaunchRequiredTitle,
                message: LocalizedText.ShareRegistration.appLaunchRequiredMessage,
            )

        case .succeeded:
            guidance(
                title: LocalizedText.ShareRegistration.successTitle,
                message: LocalizedText.ShareRegistration.successMessage,
            )

        case .failed(let reason, _):
            Self.GuidanceView(
                title: LocalizedText.ShareRegistration.failureTitle,
                message: reason,
                retryTitle: LocalizedText.ShareRegistration.retryButtonTitle,
                dismissTitle: LocalizedText.ShareRegistration.dismissButtonTitle,
                onRetry: { send(.retryTapped) },
                onDismiss: { send(.dismissTapped) },
            )
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch store.step {
        case .repositoryConfirmation:
            RepositoryConfirmationScreen(
                store: store.scope(
                    state: \.repositoryConfirmation,
                    action: \.repositoryConfirmation,
                )
            )

        case .quizLevelSelection:
            QuizLevelSelectionScreen(
                store: store.scope(
                    state: \.quizLevelSelection,
                    action: \.quizLevelSelection,
                )
            )

        case .quizGenerationConfirmation:
            QuizGenerationConfirmationScreen(
                store: store.scope(
                    state: \.quizGenerationConfirmation,
                    action: \.quizGenerationConfirmation,
                )
            )
        }
    }

    private func guidance(
        title: String,
        message: String,
    ) -> some View {
        Self.GuidanceView(
            title: title,
            message: message,
            retryTitle: nil,
            dismissTitle: LocalizedText.ShareRegistration.dismissButtonTitle,
            onRetry: { },
            onDismiss: { send(.dismissTapped) },
        )
    }

}
