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
        switch store.status {
        case .validating:
            Self.LoadingView(message: Constant.lookupMessage)

        case .submitting:
            Self.LoadingView(message: Constant.submittingMessage)

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
            guidance(title: Constant.invalidURLTitle, message: reason)

        case .signInRequired:
            guidance(title: Constant.signInTitle, message: Constant.signInGuidance)

        case .appLaunchRequired:
            guidance(title: Constant.appLaunchTitle, message: Constant.appLaunchGuidance)

        case .succeeded:
            guidance(title: Constant.successTitle, message: Constant.successGuidance)

        case .failed(let reason, _):
            Self.GuidanceView(
                title: Constant.failureTitle,
                message: reason,
                retryTitle: Constant.retryTitle,
                dismissTitle: Constant.dismissTitle,
                onRetry: { send(.retryTapped) },
                onDismiss: { send(.dismissTapped) },
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
            dismissTitle: Constant.dismissTitle,
            onRetry: { },
            onDismiss: { send(.dismissTapped) },
        )
    }

}

// MARK: ShareRegistrationScreen.Constant

extension ShareRegistrationScreen {
    fileprivate enum Constant {
        static let lookupMessage = "저장소 정보를 불러오는 중이에요."
        static let submittingMessage = "학습 세트 생성을 요청하고 있어요."

        static let invalidURLTitle = "등록할 수 없는 링크예요"

        static let signInTitle = "로그인이 필요해요"
        static let signInGuidance = "Git-It 앱에서 로그인한 뒤 다시 공유해 주세요."

        static let appLaunchTitle = "앱을 한 번 실행해 주세요"
        static let appLaunchGuidance = "Git-It 앱을 한 번 실행한 뒤 다시 공유해 주세요."

        static let successTitle = "등록을 접수했어요"
        static let successGuidance = "결과는 Git-It 앱에서 확인할 수 있어요."

        static let failureTitle = "등록하지 못했어요"
        static let retryTitle = "다시 시도하기"
        static let dismissTitle = "닫기"
    }
}
