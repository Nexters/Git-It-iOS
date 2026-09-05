import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - ShareRegistrationScreen

/// 공유 시트에서 진입했을 때의 등록 화면이다. 본 앱의 등록 화면들을 그대로 사용하고,
/// 링크 입력 화면만 공유로 대체한다.
@ViewAction(for: ShareRegistrationFeature.self)
public struct ShareRegistrationScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<ShareRegistrationFeature>) {
        self.store = store
    }

    // MARK: Public

    public var body: some View {
        ScreenContainer {
            content
        }
        .task { await send(.task).finish() }
    }

    @Bindable public var store: StoreOf<ShareRegistrationFeature>

    // MARK: Private

    @ViewBuilder
    private var content: some View {
        switch store.status {
        case .validating:
            Self.LoadingView(message: Self.lookupMessage)

        case .submitting:
            Self.LoadingView(message: Self.submittingMessage)

        case .repositoryConfirmation:
            RepositoryConfirmationScreen(
                store: store.scope(state: \.repositoryConfirmation, action: \.repositoryConfirmation)
            )

        case .quizLevelSelection:
            QuizLevelSelectionScreen(
                store: store.scope(state: \.quizLevelSelection, action: \.quizLevelSelection)
            )

        case .quizGenerationConfirmation:
            QuizGenerationConfirmationScreen(
                store: store.scope(state: \.quizGenerationConfirmation, action: \.quizGenerationConfirmation)
            )

        case .invalidURL(let reason):
            guidance(title: Self.invalidURLTitle, message: reason)

        case .signInRequired:
            guidance(title: Self.signInTitle, message: Self.signInGuidance)

        case .appLaunchRequired:
            guidance(title: Self.appLaunchTitle, message: Self.appLaunchGuidance)

        case .succeeded:
            guidance(title: Self.successTitle, message: Self.successGuidance)

        case .failed(let reason, _):
            Self.GuidanceView(
                title: Self.failureTitle,
                message: reason,
                retryTitle: Self.retryTitle,
                onRetry: { send(.retryTapped) },
                onDismiss: { send(.dismissTapped) },
            )
        }
    }

    private func guidance(title: String, message: String) -> some View {
        Self.GuidanceView(
            title: title,
            message: message,
            retryTitle: nil,
            onRetry: { },
            onDismiss: { send(.dismissTapped) },
        )
    }

}
