import ComposableArchitecture
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation
import Synchronization
@testable import GitIt

// MARK: - MemberAccountUseCaseMock

actor MemberAccountUseCaseMock: MemberAccountUseCase {

    // MARK: Lifecycle

    init(results: [Result<MemberProfile, MemberError>] = [.success(AppRootTestFixture.incompleteProfile)]) {
        self.results = results
    }

    // MARK: Internal

    func profile() async throws -> MemberProfile {
        callCount += 1
        return try nextResult().get()
    }

    func updatePosition(_: MemberPosition) async throws { }

    func updateCareerLevel(_: CareerLevel) async throws { }

    func completeCuration(
        position _: MemberPosition,
        careerLevel _: CareerLevel,
    ) async throws { }

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

// MARK: - NoopRequestGenerationReminderUseCase

struct NoopRequestGenerationReminderUseCase: RequestGenerationReminderUseCase {
    func callAsFunction(projectID _: String) async -> NotificationAuthorizationOutcome {
        .authorized
    }

    func requestAuthorization() async -> NotificationAuthorizationOutcome {
        .authorized
    }

    func isAuthorized() async -> Bool {
        true
    }
}

// MARK: - NoopLearningLibraryUseCase

struct NoopLearningLibraryUseCase: LearningLibraryUseCase {
    func project(id: String) async throws -> LearningProjectDetail {
        AppRootTestFixture.projectDetail(projectID: id)
    }

    func deleteProject(id _: String) async throws {
        throw CancellationError()
    }

    func learningSet(
        projectID _: String,
        setID: String,
    ) async throws -> LearningSet {
        AppRootTestFixture.learningSet(setID: setID)
    }

    func bookmarkedQuestions(projectID _: String?) async throws -> BookmarkedQuestionCollection {
        throw CancellationError()
    }
}

// MARK: - NoopSubmitChoiceAnswerUseCase

struct NoopSubmitChoiceAnswerUseCase: SubmitChoiceAnswerUseCase {
    func callAsFunction(
        projectID _: String,
        questionID _: String,
        selectedIndex _: Int,
    ) async throws -> ChoiceAnswerResult {
        ChoiceAnswerResult(correct: true, answerIndex: 0, explanation: "")
    }
}

// MARK: - NoopSubmitEssayAnswerUseCase

struct NoopSubmitEssayAnswerUseCase: SubmitEssayAnswerUseCase {
    func callAsFunction(
        projectID _: String,
        questionID _: String,
        text _: String,
    ) async throws -> EssayAnswerResult {
        EssayAnswerResult(explanation: "", rubric: Rubric(criteria: []))
    }
}

// MARK: - NoopSetQuestionBookmarkUseCase

struct NoopSetQuestionBookmarkUseCase: SetQuestionBookmarkUseCase {
    func callAsFunction(
        projectID _: String,
        questionID _: String,
        bookmarked: Bool,
    ) async throws -> BookmarkState {
        BookmarkState(bookmarked: bookmarked)
    }
}

// MARK: - OpenExternalURLSpy

actor OpenExternalURLSpy {

    private(set) var openedURLs = [URL]()

    var callCount: Int {
        openedURLs.count
    }

    func callAsFunction(_ url: URL) {
        openedURLs.append(url)
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
        statistics: LearningStatistics(thisWeekSolvedCount: 0, thisMonthSolvedCount: 0, streakDays: 0, weeklyCounts: []),
    )

    static let completeProfile = MemberProfile(
        name: "테스터",
        email: "tester@example.com",
        position: .ios,
        careerLevel: .junior,
        statistics: LearningStatistics(thisWeekSolvedCount: 0, thisMonthSolvedCount: 0, streakDays: 0, weeklyCounts: []),
    )

    static let repositoryURL = "https://github.com/owner/repo"

    static func mainShellState() -> AppRootFeature.State {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        return state
    }

    static func projectDetail(projectID: String) -> LearningProjectDetail {
        LearningProjectDetail(
            projectID: projectID,
            repositoryURL: repositoryURL,
            repositoryName: "owner/repo",
            repositoryImageURL: nil,
            starCount: 10,
            techStack: ["Swift"],
            overallProgressPercent: 40,
            nextQuestionID: nil,
            sets: [
                LearningProjectSetProgress(
                    setID: "set-1",
                    label: "CHAPTER 1",
                    title: "모듈 경계",
                    problemCount: 5,
                    completedCount: 2,
                )
            ],
        )
    }

    static func learningSet(setID: String) -> LearningSet {
        LearningSet(
            setID: setID,
            title: "모듈 경계",
            description: "세트 설명",
            questions: [],
        )
    }
}

func makeAppRootStore(
    restoreSession: RestoreSessionUseCaseMock = RestoreSessionUseCaseMock(),
    memberAccount: MemberAccountUseCaseMock = MemberAccountUseCaseMock(),
    signOut: SignOutUseCaseMock = SignOutUseCaseMock(),
    verifyAuthorization: VerifyAuthorizationUseCaseMock = VerifyAuthorizationUseCaseMock(),
    requestGenerationReminder: NoopRequestGenerationReminderUseCase = NoopRequestGenerationReminderUseCase(),
    trackGeneration: TrackGenerationUseCaseMock = TrackGenerationUseCaseMock(),
    waitPolicy: GenerationWaitPolicy = .standard,
    now: @escaping @Sendable () -> Date = { Date() },
    registerCurrentDevice: RegisterCurrentDeviceSpy = RegisterCurrentDeviceSpy(),
    deviceTokenRefreshes: DeviceTokenRefreshStream = DeviceTokenRefreshStream(),
    openExternalURL: OpenExternalURLSpy = OpenExternalURLSpy(),
    state: AppRootFeature.State = AppRootFeature.State(bundleVersion: "1.0.0"),
) -> TestStoreOf<AppRootFeature> {
    TestStore(initialState: state) {
        AppRootFeature(
            restoreSession: restoreSession,
            signIn: NoopSignInUseCase(),
            signOut: signOut,
            verifyAuthorization: verifyAuthorization,
            memberAccount: memberAccount,
            policyConsent: NoopPolicyConsentUseCase(),
            fetchLearningProjects: NoopFetchLearningProjectsUseCase(),
            learningLibrary: NoopLearningLibraryUseCase(),
            submitChoiceAnswer: NoopSubmitChoiceAnswerUseCase(),
            submitEssayAnswer: NoopSubmitEssayAnswerUseCase(),
            setQuestionBookmark: NoopSetQuestionBookmarkUseCase(),
            deleteMemberAccount: NoopDeleteMemberAccountUseCase(),
            fetchExternalRepository: NoopFetchExternalRepositoryUseCase(),
            createLearningProject: NoopCreateLearningProjectUseCase(),
            requestGenerationReminder: requestGenerationReminder,
            trackGeneration: trackGeneration,
            waitPolicy: waitPolicy,
            now: now,
            openExternalURL: { await openExternalURL($0) },
            registerCurrentDevice: { try await registerCurrentDevice() },
            deviceTokenRefreshes: { deviceTokenRefreshes.makeStream() },
        )
    }
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

    func makeStream() -> AsyncStream<String> {
        let (stream, continuation) = AsyncStream<String>.makeStream()
        self.continuation.withLock { $0 = continuation }
        return stream
    }

    func emit(_ token: String = "device-token") {
        continuation.withLock { $0?.yield(token) }
    }

    func finish() {
        continuation.withLock { $0?.finish() }
    }

    // MARK: Private

    private let continuation = Mutex<AsyncStream<String>.Continuation?>(nil)

}

// MARK: - DeviceRegistrationTestError

enum DeviceRegistrationTestError: Error {
    case failed
}
