import Foundation
import Testing
@testable import CompositionAdapter
@testable import CompositionShareExtension
@testable import DomainAuthentication
@testable import InfrastructureAuthentication
@testable import InfrastructureLocalNotification

// MARK: - ShareExtensionCompositionTests

@Suite("ShareExtensionComposition")
struct ShareExtensionCompositionTests {

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
        #expect(context.localNotificationClient.authorizationRequestCount == 0)
    }

    @Test
    func `등록한 프로젝트를 본 앱이 흡수할 대기 목록에 남긴다`() async throws {
        let context = try Context()

        await context.composition.enqueueGenerationReminder("project-1")

        let coding = PendingGenerationReminderCoding(userDefaults: context.userDefaults)
        #expect(await coding.drainProjectIDs() == ["project-1"])
    }

    @Test
    func `공유 저장소를 사용할 수 없으면 앱 실행 필요로 판정한다`() async throws {
        let composition = ShareExtensionComposition.live(
            try Context.environment(),
            keychainStore: KeychainStore(backend: KeychainStore.InMemoryBackend()),
            sharedDefaults: nil,
            localNotificationClient: SpyLocalNotificationClient(isAuthorized: false),
        )

        #expect(await composition.resolveSessionAvailability() == .appLaunchRequired)
    }

    // MARK: Private

    private struct Context {

        // MARK: Lifecycle

        init(isNotificationAuthorized: Bool = false) throws {
            userDefaults = try #require(
                UserDefaults(suiteName: "ShareExtensionCompositionTests.\(UUID().uuidString)")
            )
            keychainStore = KeychainStore(backend: KeychainStore.InMemoryBackend())
            markerCoding = SharedSessionStateMarkerCoding(userDefaults: userDefaults)
            let localNotificationClient = SpyLocalNotificationClient(isAuthorized: isNotificationAuthorized)
            self.localNotificationClient = localNotificationClient
            composition = ShareExtensionComposition.live(
                try Self.environment(),
                keychainStore: keychainStore,
                sharedDefaults: userDefaults,
                localNotificationClient: localNotificationClient,
            )
        }

        // MARK: Internal

        let userDefaults: UserDefaults
        let keychainStore: KeychainStore
        let markerCoding: SharedSessionStateMarkerCoding
        let localNotificationClient: SpyLocalNotificationClient
        let composition: ShareExtensionComposition

        static func environment() throws -> ShareExtensionComposition.Environment {
            ShareExtensionComposition.Environment(
                apiBaseURL: try #require(URL(string: "https://api.git-it.example.com")),
                externalRepositoryBaseURL: try #require(URL(string: "https://api.github.com")),
            )
        }

        func saveSession(accessToken: String) throws {
            try SessionRecordKeychainCoding(keychainStore: keychainStore).save(
                SessionRecord(
                    tokens: SessionTokens(
                        accessToken: accessToken,
                        refreshToken: "refresh",
                        accessTokenExpiresAt: nil,
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
