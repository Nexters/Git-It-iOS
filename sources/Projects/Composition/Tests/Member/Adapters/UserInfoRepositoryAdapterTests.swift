import Foundation
import Synchronization
import Testing

@testable import CompositionMember
@testable import DataAuthentication
@testable import DataMember
@testable import DataShared
@testable import DomainUseCaseInterface

// MARK: - UserInfoRepositoryAdapterTests

@Suite("UserInfoRepositoryAdapter")
struct UserInfoRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `포지션과 경력이 모두 있으면 큐레이션을 만든다`() async throws {
        let context = Context(results: [Self.profileResponse(
            position: #""IOS""#,
            careerLevel: #""SENIOR""#,
        )])

        let profile = try await context.adapter.profile()

        #expect(profile.detail.name == "홍길동")
        #expect(profile.curation == Curation(
            position: .ios,
            careerLevel: .senior,
        ))
    }

    @Test
    func `포지션과 경력 중 하나만 있으면 큐레이션은 nil이다`() async throws {
        let context = Context(results: [Self.profileResponse(
            position: #""IOS""#,
            careerLevel: "null",
        )])

        #expect(try await context.adapter.profile().curation == nil)
    }

    @Test
    func `큐레이션을 완료하면 저장 기록의 큐레이션 필요 표시를 지운다`() async throws {
        let context = Context(results: [Self.emptyResponse()])
        try context.saveSession(needsCuration: true)

        try await context.adapter.updateCuration(Curation(
            position: .ios,
            careerLevel: .junior,
        ))

        #expect(try context.coding.load()?.needsCuration == false)
        #expect(try context.coding.load()?.accessToken == "access-token")
    }

    // MARK: Private

    private final class InMemorySessionStorage: SecureValueStorage, Sendable {

        // MARK: Internal

        func data(forKey key: String) throws(SecureValueStorageError) -> Data? {
            values.withLock { $0[key] }
        }

        func setData(
            _ data: Data,
            forKey key: String,
        ) throws(SecureValueStorageError) {
            values.withLock { $0[key] = data }
        }

        func removeData(forKey key: String) throws(SecureValueStorageError) {
            values.withLock { $0[key] = nil }
        }

        // MARK: Private

        private let values = Mutex<[String: Data]>([:])

    }

    private struct Context {

        // MARK: Lifecycle

        init(results: [TransportResponse]) {
            let secureStorage = InMemorySessionStorage()
            coding = SessionRecordStorageCoding(storage: secureStorage)
            adapter = UserInfoRepositoryAdapter(
                remote: MemberRemote(
                    baseURL: URL(string: "https://api.git-it.example.com")!,
                    transport: RecordingRequestTransport(results: results),
                    responseTimeout: RequestClientFactory.defaultResponseTimeout,
                    credential: { .available("test-access-token") },
                    credentialRejected: { },
                ),
                sessionStorage: secureStorage,
            )
        }

        // MARK: Internal

        let coding: SessionRecordStorageCoding
        let adapter: UserInfoRepositoryAdapter

        func saveSession(needsCuration: Bool) throws {
            try coding.save(StoredSessionRecord(
                accessToken: "access-token",
                refreshToken: "refresh-token",
                accessTokenExpiresAt: nil,
                refreshTokenExpiresAt: nil,
                needsCuration: needsCuration,
                acceptedLegalVersions: [],
                acceptedAt: nil,
            ))
        }

    }

    private static func profileResponse(
        position: String,
        careerLevel: String,
    ) -> TransportResponse {
        let envelope = """
            {"success":true,"data":{"name":"홍길동","email":"a@b.com","position":\(position),\
            "careerLevel":\(careerLevel),"thisWeekSolvedCount":1,"thisMonthSolvedCount":2,"streakDays":3,\
            "weeklyChart":[]},"code":null,"message":null,"errors":null}
            """
        return TransportResponse(
            statusCode: 200,
            body: Data(envelope.utf8),
        )
    }

    private static func emptyResponse() -> TransportResponse {
        TransportResponse(
            statusCode: 200,
            body: Data(#"{"success":true,"data":{},"code":null,"message":null,"errors":null}"#.utf8),
        )
    }

}
