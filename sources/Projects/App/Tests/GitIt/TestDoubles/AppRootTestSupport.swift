import ComposableArchitecture
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation
@testable import GitIt

// MARK: - FetchMemberProfileUseCaseMock

actor FetchMemberProfileUseCaseMock: FetchMemberProfileUseCase {

    // MARK: Lifecycle

    init(results: [Result<MemberProfile, MemberError>] = [.success(AppRootTestFixture.incompleteProfile)]) {
        self.results = results
    }

    // MARK: Internal

    func callAsFunction() async throws -> MemberProfile {
        callCount += 1
        return try nextResult().get()
    }

    func snapshot() -> Int {
        callCount
    }

    // MARK: Private

    private var results: [Result<MemberProfile, MemberError>]
    private var callCount = 0

    private func nextResult() -> Result<MemberProfile, MemberError> {
        guard !results.isEmpty else { return .failure(.temporarilyUnavailable) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}

// MARK: - ResetAllForTestingSpy

actor ResetAllForTestingSpy {
    private(set) var callCount = 0

    func callAsFunction() {
        callCount += 1
    }
}

// MARK: - AppRootTestFixture

enum AppRootTestFixture {
    static let authenticatedUser = AuthenticatedUser(id: "member-1", availability: .available, displayName: "테스터")

    static let incompleteProfile = MemberProfile(
        name: "테스터",
        email: "tester@example.com",
        position: nil,
        careerLevel: nil,
        statistics: LearningStatistics(totalAnsweredCount: 0, totalCorrectCount: 0, weeklyCounts: []),
    )

    static let completeProfile = MemberProfile(
        name: "테스터",
        email: "tester@example.com",
        position: .ios,
        careerLevel: .junior,
        statistics: LearningStatistics(totalAnsweredCount: 0, totalCorrectCount: 0, weeklyCounts: []),
    )
}

func makeAppRootStore(
    restoreSession: RestoreSessionUseCaseMock = RestoreSessionUseCaseMock(),
    fetchMemberProfile: FetchMemberProfileUseCaseMock = FetchMemberProfileUseCaseMock(),
    signOut: SignOutUseCaseMock = SignOutUseCaseMock(),
    observeAuthenticationOutcomes: ObserveAuthenticationOutcomesUseCaseMock = ObserveAuthenticationOutcomesUseCaseMock(),
    resetAllForTesting: (@Sendable () async -> Void)? = nil,
    state: AppRootFeature.State = AppRootFeature.State(bundleVersion: "1.0.0"),
) -> TestStoreOf<AppRootFeature> {
    TestStore(initialState: state) {
        AppRootFeature(
            restoreSession: restoreSession,
            signIn: NoopSignInUseCase(),
            signOut: signOut,
            observeAuthenticationOutcomes: observeAuthenticationOutcomes,
            fetchMemberProfile: fetchMemberProfile,
            completeCuration: NoopCompleteCurationUseCase(),
            policyConsent: NoopPolicyConsentUseCase(),
            fetchLearningProjects: NoopFetchLearningProjectsUseCase(),
            deleteLearningProject: NoopDeleteLearningProjectUseCase(),
            fetchBookmarkedQuestions: NoopFetchBookmarkedQuestionsUseCase(),
            updateMemberPosition: NoopUpdateMemberPositionUseCase(),
            updateMemberCareerLevel: NoopUpdateMemberCareerLevelUseCase(),
            deleteMemberAccount: NoopDeleteMemberAccountUseCase(),
            resetAllForTesting: resetAllForTesting,
        )
    }
}
