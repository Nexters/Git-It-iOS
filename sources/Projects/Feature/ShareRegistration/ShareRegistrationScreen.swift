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
            Self.LoadingView(message: LocalizedText.ShareRegistration.Lookup.message)

        case .submitting:
            Self.LoadingView(message: LocalizedText.ShareRegistration.Submitting.message)

        case .ready:
            stepContent

        case .invalidURL(let reason):
            guidance(
                title: LocalizedText.ShareRegistration.InvalidLink.title,
                message: reason,
            )

        case .signInRequired:
            guidance(
                title: LocalizedText.ShareRegistration.SignInRequired.title,
                message: LocalizedText.ShareRegistration.SignInRequired.message,
            )

        case .appLaunchRequired:
            guidance(
                title: LocalizedText.ShareRegistration.AppLaunchRequired.title,
                message: LocalizedText.ShareRegistration.AppLaunchRequired.message,
            )

        case .succeeded:
            guidance(
                title: LocalizedText.ShareRegistration.Success.title,
                message: LocalizedText.ShareRegistration.Success.message,
            )

        case .failed(let reason, _):
            Self.GuidanceView(
                title: LocalizedText.ShareRegistration.Failure.title,
                message: reason,
                retryTitle: LocalizedText.ShareRegistration.Retry.buttonTitle,
                dismissTitle: LocalizedText.ShareRegistration.Dismiss.buttonTitle,
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
            dismissTitle: LocalizedText.ShareRegistration.Dismiss.buttonTitle,
            onRetry: { },
            onDismiss: { send(.dismissTapped) },
        )
    }

}
