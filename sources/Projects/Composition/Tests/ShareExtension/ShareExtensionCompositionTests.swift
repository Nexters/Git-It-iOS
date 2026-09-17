import Foundation
import Testing
@testable import CompositionAuthentication
@testable import CompositionShareExtension
@testable import DataAuthentication
@testable import DataLearningProject
@testable import DataNotification
@testable import DomainAccount
@testable import DomainAuthentication
@testable import DomainProjectGeneration

// MARK: - ShareExtensionCompositionTests

@Suite("ShareExtensionComposition")
struct ShareExtensionCompositionTests {

    // MARK: Internal

    @Test
    func `마커가 없으면 앱 실행 필요로 판정한다`() async throws {
        let context = try Context()

        #expect(await context.composition.resolveSessionAvailability() == .appLaunchRequired)
    }

    @Test
    func `저장된 세션이 있으면 갱신 없이 접근 토큰을 사용한다`() async throws {
        let context = try Context()
        await context.markerCoding.save(isSignedIn: true)
        try context.saveSession(accessToken: "shared-token")

        #expect(await context.composition.resolveSessionAvailability() == .available(accessToken: "shared-token"))
    }

    @Test
    func `알림 권한 상태를 조회만 하고 요청하지 않는다`() async throws {
        let context = try Context(isNotificationAuthorized: true)

        #expect(await context.composition.isNotificationAuthorized() == true)
        #expect(context.reminderNotifier.authorizationRequestCount == 0)
    }

    @Test
    func `등록한 프로젝트를 본 앱이 흡수할 대기 목록에 남긴다`() async throws {
        let context = try Context()

        await context.composition.enqueueGenerationReminder("project-1")

        let pendingGenerations = PendingGenerationRepositoryAdapter(
            store: LocalPendingGenerationStore(storage: context.sharedStorage)
        )
        #expect(await pendingGenerations.drainReminderProjectIDs() == ["project-1"])
    }

    @Test
    func `만료된 로그인 기록이면 로그인이 필요하다고 판정한다`() async throws {
        let context = try Context()
        await context.markerCoding.save(isSignedIn: true)
        try context.saveSession(accessToken: "expired-token", accessTokenExpiresAt: Date(timeIntervalSince1970: 0))

        #expect(await context.composition.signInAvailability() == .signInRequired)
    }

    @Test
    func `생성 요청이 실패하면 진행 중 기록과 알림 대기열을 남기지 않는다`() async throws {
        let context = try Context()
        await context.markerCoding.save(isSignedIn: true)
        try context.saveSession(accessToken: "shared-token")

        await #expect(throws: (any Error).self) {
            _ = try await context.composition.projectGeneration.request(
                ProjectGenerationRequest(repositoryURL: "https://github.com/owner/repo", quizLevel: .l2)
            )
        }

        let pendingGenerations = ProjectGenerationPendingRepositoryAdapter(
            store: LocalPendingGenerationStore(storage: context.sharedStorage)
        )
        #expect(await pendingGenerations.pendingState().records.isEmpty)
        #expect(await pendingGenerations.drainReminderProjectIDs().isEmpty)
    }

    @Test
    func `공유 저장소를 사용할 수 없으면 앱 실행 필요로 판정한다`() async throws {
        let composition = ShareExtensionComposition.live(
            try Context.environment(),
            secureStorage: InMemorySecureValueStorage(),
            sharedStorage: nil,
            reminderNotifier: SpyLocalReminderNotifier(isAuthorized: false),
        )

        #expect(await composition.resolveSessionAvailability() == .appLaunchRequired)
    }

    // MARK: Private

    private struct Context {

        // MARK: Lifecycle

        init(isNotificationAuthorized: Bool = false) throws {
            secureStorage = InMemorySecureValueStorage()
            let sharedStorage = InMemoryKeyValueStorage()
            self.sharedStorage = sharedStorage
            markerCoding = SharedSessionStateMarkerCoding(storage: sharedStorage)
            let reminderNotifier = SpyLocalReminderNotifier(isAuthorized: isNotificationAuthorized)
            self.reminderNotifier = reminderNotifier
            composition = ShareExtensionComposition.live(
                try Self.environment(),
                secureStorage: secureStorage,
                sharedStorage: sharedStorage,
                reminderNotifier: reminderNotifier,
            )
        }

        // MARK: Internal

        let sharedStorage: InMemoryKeyValueStorage
        let secureStorage: InMemorySecureValueStorage
        let markerCoding: SharedSessionStateMarkerCoding
        let reminderNotifier: SpyLocalReminderNotifier
        let composition: ShareExtensionComposition

        static func environment() throws -> ShareExtensionComposition.Environment {
            ShareExtensionComposition.Environment(
                apiBaseURL: try #require(URL(string: "https://api.git-it.example.com")),
                externalRepositoryBaseURL: try #require(URL(string: "https://api.github.com")),
            )
        }

        func saveSession(
            accessToken: String,
            accessTokenExpiresAt: Date? = nil,
        ) throws {
            try SessionRecordCoding(secureStorage: secureStorage).save(
                SessionRecord(
                    tokens: SessionTokens(
                        accessToken: accessToken,
                        refreshToken: "refresh",
                        accessTokenExpiresAt: accessTokenExpiresAt,
                        refreshTokenExpiresAt: nil,
                    ),
                    onboarding: LocalOnboardingState(
                        needsCuration: false,
                        acceptedLegalVersions: [],
                        acceptedAt: nil,
                    ),
                )
            )
        }

    }

}
