import ComposableArchitecture
import DomainUseCaseInterface
import Feature
import Foundation
import SwiftUI

// MARK: - AppRootView

@ViewAction(for: AppRootFeature.self)
struct AppRootView: View {

    // MARK: Internal

    @Bindable var store: StoreOf<AppRootFeature>

    var body: some View {
        content
            .task { send(.task) }
    }

    // MARK: Private

    @ViewBuilder
    private var content: some View {
        switch store.route {
        case .restoring:
            AppEntryScreen(store: store.scope(
                state: \.appEntry,
                action: \.appEntry,
            ))

        case .onboarding:
            OnboardingRouter(store: store.scope(
                state: \.onboarding,
                action: \.onboarding,
            ))

        case .mainShell:
            MainShellRouter(store: store.scope(
                state: \.mainShell,
                action: \.mainShell,
            ))
            .fullScreenCover(
                item: $store.scope(
                    state: \.projectRegistration,
                    action: \.projectRegistration,
                )
            ) { projectRegistrationStore in
                ProjectRegistrationRouter(store: projectRegistrationStore)
            }
            .fullScreenCover(
                item: $store.scope(
                    state: \.projectDetail,
                    action: \.projectDetail,
                )
            ) { projectDetailStore in
                ProjectDetailRouter(store: projectDetailStore)
                    .overlay { QuizRouterOverlay(store: quizStore) }
            }
            .transaction(value: store.projectDetail != nil) { $0.disablesAnimations = true }
        }
    }

    private var quizStore: StoreOf<QuizRouterFeature>? {
        store.scope(
            state: \.quiz,
            action: \.quiz.presented,
        )
    }

}

#Preview("AppRoot - restoring") {
    AppRootView(store: AppRootPreviewSupport.store(route: .restoring))
}

#Preview("AppRoot - onboarding") {
    AppRootView(store: AppRootPreviewSupport.store(route: .onboarding))
}

#Preview("AppRoot - mainShell") {
    AppRootView(store: AppRootPreviewSupport.store(route: .mainShell))
}

// MARK: - AppRootPreviewSupport

private enum AppRootPreviewSupport {

    struct NoopAccount: AccountUseCase {
        func signIn(with _: SignInMethod) async -> SignInResult {
            .retryableFailure
        }

        func signOut() async -> SignOutResult {
            .signedOut
        }

        func signInStates() async -> AsyncStream<SignInState> {
            AsyncStream { $0.finish() }
        }

        func restoreSignIn() async -> SignInRestoration {
            .signedOut
        }

        func verifySignIn() async -> SignInVerification {
            .valid
        }

        func signInAvailability() async -> SignInAvailability {
            .signInRequired
        }

        func policyConsentStatus() async throws -> PolicyConsentStatus {
            PolicyConsentStatus(
                documents: [],
                consents: [],
                isSatisfied: true,
            )
        }

        func consent(to _: [PolicyDocumentID]) async throws { }

        func withdraw() async throws {
            throw CancellationError()
        }
    }

    struct NoopUserInfo: UserInfoUseCase {
        func detail() async throws -> UserDetail {
            UserDetail(
                name: "미리보기",
                email: "preview@example.com",
                statistics: LearningStatistics(
                    thisWeekSolvedCount: 0,
                    thisMonthSolvedCount: 0,
                    streakDays: 0,
                    weeklyCounts: [],
                ),
            )
        }

        func curation() async throws -> Curation? {
            nil
        }

        func updateCuration(_: Curation) async throws {
            throw CancellationError()
        }

        func updatePosition(_: MemberPosition) async throws {
            throw CancellationError()
        }

        func updateCareerLevel(_: CareerLevel) async throws {
            throw CancellationError()
        }
    }

    struct NoopAppSetting: AppSettingUseCase {
        func notificationAuthorization() async -> NotificationAuthorizationStatus {
            .notDetermined
        }

        func requestNotificationAuthorization() async -> NotificationAuthorizationStatus {
            .denied
        }

        func registerDevice() async throws { }

        func updateDeviceToken(_: DeviceToken) async throws { }
    }

    struct NoopExternalRepository: ExternalRepositoryUseCase {
        func repository(at _: ExternalRepositoryURL) async throws -> ExternalRepository {
            throw CancellationError()
        }
    }

    struct NoopQuizDetail: QuizDetailUseCase {
        func quizSet(
            _: QuizSetID,
            in _: ProjectID,
        ) async throws -> QuizSet {
            throw CancellationError()
        }

        func grade(_: ChoiceAnswer) async throws -> ChoiceGrading {
            throw CancellationError()
        }

        func grade(_: EssayAnswer) async throws -> EssayGrading {
            throw CancellationError()
        }

        func bookmark(
            _: QuizID,
            in _: ProjectID,
        ) async throws -> QuizBookmarkState {
            throw CancellationError()
        }

        func unbookmark(
            _: QuizID,
            in _: ProjectID,
        ) async throws -> QuizBookmarkState {
            throw CancellationError()
        }

        func bookmarks(_: QuizBookmarkFilter) async throws -> QuizBookmarkList {
            throw CancellationError()
        }
    }

    struct NoopProject: ProjectUseCase {
        func projects() async -> AsyncStream<ProjectList> {
            AsyncStream { $0.finish() }
        }

        func refresh() async throws {
            throw CancellationError()
        }

        func refreshReplacingInFlightRequest() async throws {
            throw CancellationError()
        }

        func requestNextPage() async throws {
            throw CancellationError()
        }

        func detail(of _: ProjectID) async throws -> ProjectDetail {
            throw CancellationError()
        }

        func delete(_: ProjectID) async throws {
            throw CancellationError()
        }
    }

    struct NoopProjectGeneration: ProjectGenerationUseCase {
        func request(_: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt {
            throw CancellationError()
        }

        func states() async -> AsyncStream<ProjectGenerationState> {
            AsyncStream { $0.finish() }
        }

        func currentState() async throws(ProjectGenerationError) -> ProjectGenerationState {
            ProjectGenerationState(requests: [])
        }

        func outcomeArrivals() async -> AsyncStream<ProjectID> {
            AsyncStream { $0.finish() }
        }

        func synchronize() async { }

        func release(_: ProjectID) async { }
    }

    static func store(route: AppRootFeature.Route) -> StoreOf<AppRootFeature> {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = route
        return Store(initialState: state) {
            AppRootFeature(
                account: NoopAccount(),
                userInfo: NoopUserInfo(),
                appSetting: NoopAppSetting(),
                externalRepository: NoopExternalRepository(),
                quizDetail: NoopQuizDetail(),
                project: NoopProject(),
                projectGeneration: NoopProjectGeneration(),
                deviceTokenRefreshes: { AsyncStream { $0.finish() } },
            )
        }
    }

}
