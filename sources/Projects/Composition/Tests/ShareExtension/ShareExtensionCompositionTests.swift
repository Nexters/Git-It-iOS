import Foundation
import Testing
@testable import CompositionAuthentication
@testable import CompositionLearningProject
@testable import CompositionShareExtension
@testable import DataAuthentication
@testable import DataLearningProject
@testable import DomainUseCaseInterface

// MARK: - ShareExtensionCompositionTests

@Suite("ShareExtensionComposition")
struct ShareExtensionCompositionTests {

    // MARK: Internal

    @Test
    func `마커가 없으면 앱 실행 필요로 판정한다`() async throws {
        let context = try Context()

        #expect(await context.composition.signInAvailability() == .appLaunchRequired)
    }

    @Test
    func `저장된 세션이 있으면 로그인된 상태로 판정한다`() async throws {
        let context = try Context()
        await context.markerCoding.save(isSignedIn: true)
        try context.saveSession(accessToken: "shared-token")

        #expect(await context.composition.signInAvailability() == .signedIn)
    }

    @Test
    func `만료된 로그인 기록이면 로그인이 필요하다고 판정한다`() async throws {
        let context = try Context()
        await context.markerCoding.save(isSignedIn: true)
        try context.saveSession(
            accessToken: "expired-token",
            accessTokenExpiresAt: Date(timeIntervalSince1970: 0),
        )

        #expect(await context.composition.signInAvailability() == .signInRequired)
    }

    @Test
    func `생성 요청이 실패하면 진행 중 기록을 남기지 않는다`() async throws {
        let context = try Context()
        await context.markerCoding.save(isSignedIn: true)
        try context.saveSession(accessToken: "shared-token")

        await #expect(throws: (any Error).self) {
            _ = try await context.composition.projectGeneration.request(
                ProjectGenerationRequest(
                    repositoryURL: "https://github.com/owner/repo",
                    quizLevel: .l2,
                )
            )
        }

        let pendingGenerations = PendingGenerationRepositoryAdapter(
            store: LocalPendingGenerationStore(storage: context.sharedStorage)
        )
        #expect(await pendingGenerations.pendingState().records.isEmpty)
    }

    @Test
    func `공유 저장소를 사용할 수 없으면 앱 실행 필요로 판정한다`() async throws {
        let composition = ShareExtensionComposition.live(
            try Context.environment(),
            secureStorage: InMemorySecureValueStorage(),
            sharedStorage: nil,
        )

        #expect(await composition.signInAvailability() == .appLaunchRequired)
    }

    // MARK: Private

    private struct Context {

        // MARK: Lifecycle

        init() throws {
            secureStorage = InMemorySecureValueStorage()
            let sharedStorage = InMemoryKeyValueStorage()
            self.sharedStorage = sharedStorage
            markerCoding = SharedSessionStateMarkerCoding(storage: sharedStorage)
            composition = ShareExtensionComposition.live(
                try Self.environment(),
                secureStorage: secureStorage,
                sharedStorage: sharedStorage,
            )
        }

        // MARK: Internal

        let sharedStorage: InMemoryKeyValueStorage
        let secureStorage: InMemorySecureValueStorage
        let markerCoding: SharedSessionStateMarkerCoding
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
            try SessionRecordStorageCoding(storage: secureStorage).save(
                StoredSessionRecord(
                    accessToken: accessToken,
                    refreshToken: "refresh",
                    accessTokenExpiresAt: accessTokenExpiresAt,
                    refreshTokenExpiresAt: nil,
                    needsCuration: false,
                    acceptedLegalVersions: [],
                    acceptedAt: nil,
                )
            )
        }

    }

}
