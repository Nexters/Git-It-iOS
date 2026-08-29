import ComposableArchitecture
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Feature
import SwiftUI

#if DEBUG
import AppDebug
#endif

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
            AppEntryScreen(store: store.scope(state: \.appEntry, action: \.appEntry))

        case .onboarding:
            OnboardingScreen(store: store.scope(state: \.onboarding, action: \.onboarding))

        case .mainShell:
            MainShellScreen(store: store.scope(state: \.mainShell, action: \.mainShell))
                #if DEBUG
                .safeAreaInset(edge: .bottom) {
                    ResetAllButton(action: { send(.resetAllTapped) })
                }
                #endif
        }
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

    struct NoopRestoreSession: RestoreSessionUseCase {
        func callAsFunction() async -> RestoreSessionResult {
            .unauthenticated
        }
    }

    struct NoopSignIn: SignInUseCase {
        func callAsFunction(_: AuthenticationMethod) async -> SignInResult {
            .retryableFailure
        }
    }

    struct NoopSignOut: SignOutUseCase {
        func callAsFunction() async -> SignOutResult {
            .success
        }
    }

    struct NoopObserveAuthenticationOutcomes: ObserveAuthenticationOutcomesUseCase {
        func callAsFunction() async -> AsyncStream<AuthenticationOutcome> {
            AsyncStream { _ in }
        }
    }

    struct NoopFetchMemberProfile: FetchMemberProfileUseCase {
        func callAsFunction() async throws -> MemberProfile {
            MemberProfile(
                name: "미리보기",
                email: "preview@example.com",
                position: nil,
                careerLevel: nil,
                statistics: LearningStatistics(totalAnsweredCount: 0, totalCorrectCount: 0, weeklyCounts: []),
            )
        }
    }

    struct NoopCompleteCuration: CompleteCurationUseCase {
        func callAsFunction(
            position _: MemberPosition,
            careerLevel _: CareerLevel,
        ) async throws { }
    }

    struct NoopPolicyConsent: PolicyConsentUseCase {
        func requiredDocuments() async throws -> [PolicyDocument] {
            []
        }

        func storedConsentRecords() async throws -> [PolicyConsentRecord] {
            []
        }

        func saveConsentRecords(_: [PolicyConsentRecord]) async throws { }
        func clearConsentRecords() async throws { }
        func isConsentValid(
            storedRecords _: [PolicyConsentRecord],
            for _: [PolicyDocument],
        ) -> Bool {
            false
        }
    }

    struct NoopFetchLearningProjects: FetchLearningProjectsUseCase {
        func callAsFunction() async throws -> LearningProjectPage {
            throw CancellationError()
        }
    }

    struct NoopDeleteLearningProject: DeleteLearningProjectUseCase {
        func callAsFunction(projectID _: String) async throws {
            throw CancellationError()
        }
    }

    struct NoopFetchBookmarkedQuestions: FetchBookmarkedQuestionsUseCase {
        func callAsFunction(projectID _: String?) async throws -> BookmarkedQuestionCollection {
            throw CancellationError()
        }
    }

    struct NoopUpdateMemberPosition: UpdateMemberPositionUseCase {
        func callAsFunction(_: MemberPosition) async throws {
            throw CancellationError()
        }
    }

    struct NoopUpdateMemberCareerLevel: UpdateMemberCareerLevelUseCase {
        func callAsFunction(_: CareerLevel) async throws {
            throw CancellationError()
        }
    }

    struct NoopDeleteMemberAccount: DeleteMemberAccountUseCase {
        func callAsFunction() async throws {
            throw CancellationError()
        }
    }

    static func store(route: AppRootFeature.Route) -> StoreOf<AppRootFeature> {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = route
        return Store(initialState: state) {
            AppRootFeature(
                restoreSession: NoopRestoreSession(),
                signIn: NoopSignIn(),
                signOut: NoopSignOut(),
                observeAuthenticationOutcomes: NoopObserveAuthenticationOutcomes(),
                fetchMemberProfile: NoopFetchMemberProfile(),
                completeCuration: NoopCompleteCuration(),
                policyConsent: NoopPolicyConsent(),
                fetchLearningProjects: NoopFetchLearningProjects(),
                deleteLearningProject: NoopDeleteLearningProject(),
                fetchBookmarkedQuestions: NoopFetchBookmarkedQuestions(),
                updateMemberPosition: NoopUpdateMemberPosition(),
                updateMemberCareerLevel: NoopUpdateMemberCareerLevel(),
                deleteMemberAccount: NoopDeleteMemberAccount(),
            )
        }
    }

}
