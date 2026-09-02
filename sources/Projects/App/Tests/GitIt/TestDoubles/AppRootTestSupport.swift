import ComposableArchitecture
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation
import Synchronization
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

// MARK: - NoopRequestGenerationReminderUseCase

struct NoopRequestGenerationReminderUseCase: RequestGenerationReminderUseCase {
    func callAsFunction(projectID _: String) async -> NotificationAuthorizationOutcome {
        .authorized
    }

    func isAuthorized() async -> Bool {
        true
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
    authenticationOutcomes: AuthenticationOutcomesUseCaseMock = AuthenticationOutcomesUseCaseMock(),
    resetAllForTesting: (@Sendable () async -> Void)? = nil,
    observeGenerationOutcomes: ObserveGenerationOutcomesUseCaseMock =
        ObserveGenerationOutcomesUseCaseMock(),
    requestGenerationReminder: NoopRequestGenerationReminderUseCase = NoopRequestGenerationReminderUseCase(),
    trackGenerationProgress: TrackGenerationProgressSpy = TrackGenerationProgressSpy(),
    waitPolicy: GenerationWaitPolicy = .standard,
    now: @escaping @Sendable () -> Date = { Date() },
    registerCurrentDevice: RegisterCurrentDeviceSpy = RegisterCurrentDeviceSpy(),
    deviceTokenRefreshes: DeviceTokenRefreshStream = DeviceTokenRefreshStream(),
    state: AppRootFeature.State = AppRootFeature.State(bundleVersion: "1.0.0"),
) -> TestStoreOf<AppRootFeature> {
    TestStore(initialState: state) {
        AppRootFeature(
            restoreSession: restoreSession,
            signIn: NoopSignInUseCase(),
            signOut: signOut,
            authenticationOutcomes: authenticationOutcomes,
            fetchMemberProfile: fetchMemberProfile,
            completeCuration: NoopCompleteCurationUseCase(),
            policyConsent: NoopPolicyConsentUseCase(),
            fetchLearningProjects: NoopFetchLearningProjectsUseCase(),
            deleteLearningProject: NoopDeleteLearningProjectUseCase(),
            fetchBookmarkedQuestions: NoopFetchBookmarkedQuestionsUseCase(),
            updateMemberPosition: NoopUpdateMemberPositionUseCase(),
            updateMemberCareerLevel: NoopUpdateMemberCareerLevelUseCase(),
            deleteMemberAccount: NoopDeleteMemberAccountUseCase(),
            fetchExternalRepository: NoopFetchExternalRepositoryUseCase(),
            createLearningProject: NoopCreateLearningProjectUseCase(),
            observeGenerationOutcomes: observeGenerationOutcomes,
            requestGenerationReminder: requestGenerationReminder,
            trackGenerationProgress: trackGenerationProgress,
            waitPolicy: waitPolicy,
            now: now,
            registerCurrentDevice: { try await registerCurrentDevice() },
            deviceTokenRefreshes: { deviceTokenRefreshes.makeStream() },
            resetAllForTesting: resetAllForTesting,
        )
    }
}

// MARK: - TrackGenerationProgressSpy

actor TrackGenerationProgressSpy: TrackGenerationProgressUseCase {

    // MARK: Lifecycle

    init(stored: GenerationProgress? = nil) {
        self.stored = stored
    }

    // MARK: Internal

    private(set) var beganCount = 0
    private(set) var endedCount = 0

    func begin(
        projectID: String,
        requestedAt: Date,
    ) async {
        beganCount += 1
        stored = GenerationProgress(projectID: projectID, requestedAt: requestedAt)
    }

    func current() async -> GenerationProgress? {
        stored
    }

    func end() async {
        endedCount += 1
        stored = nil
    }

    // MARK: Private

    private var stored: GenerationProgress?

}

// MARK: - RegisterCurrentDeviceSpy

actor RegisterCurrentDeviceSpy {

    // MARK: Lifecycle

    init(results: [Result<Void, any Error>] = [.success(())]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var callCount = 0

    func callAsFunction() async throws {
        callCount += 1
        guard suspends else { try nextResult().get()
            return
        }
        try await withCheckedThrowingContinuation { continuation in
            continuations.append((continuation, nextResult()))
        }
    }

    func setSuspends(_ suspends: Bool) {
        self.suspends = suspends
    }

    func resumeOldest() {
        guard !continuations.isEmpty else { return }
        let (continuation, result) = continuations.removeFirst()
        continuation.resume(with: result)
    }

    // MARK: Private

    private var results: [Result<Void, any Error>]
    private var suspends = false
    private var continuations = [(CheckedContinuation<Void, any Error>, Result<Void, any Error>)]()

    private func nextResult() -> Result<Void, any Error> {
        guard !results.isEmpty else { return .success(()) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}

// MARK: - DeviceTokenRefreshStream

final class DeviceTokenRefreshStream: Sendable {

    // MARK: Internal

    func makeStream() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        self.continuation.withLock { $0 = continuation }
        return stream
    }

    func emit() {
        continuation.withLock { $0?.yield(()) }
    }

    func finish() {
        continuation.withLock { $0?.finish() }
    }

    // MARK: Private

    private let continuation = Mutex<AsyncStream<Void>.Continuation?>(nil)

}

// MARK: - DeviceRegistrationTestError

enum DeviceRegistrationTestError: Error {
    case failed
}
