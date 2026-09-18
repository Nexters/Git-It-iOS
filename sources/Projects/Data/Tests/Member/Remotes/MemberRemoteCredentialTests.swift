import DataShared
import Foundation
import InfrastructureNetworkClient
import Synchronization
import Testing

@testable import DataMember

@Suite("MemberRemote 인증 정보")
struct MemberRemoteCredentialTests {

    // MARK: Internal

    @Test
    func `로그아웃 상태면 요청을 보내지 않고 unauthorized를 던진다`() async throws {
        let transport = StubHTTPTransport(results: [])
        let rejections = Mutex(0)
        let remote = Self.makeRemote(
            transport: transport,
            credential: { .signedOut },
            credentialRejected: { rejections.withLock { $0 += 1 } },
        )

        await #expect(throws: MemberServiceError.unauthorized) {
            _ = try await remote.fetchProfile()
        }
        #expect(await transport.recordedRequests.isEmpty)
        #expect(rejections.withLock { $0 } == 0)
    }

    @Test
    func `응답이 401이면 인증 정보 거부를 한 번 알리고 재요청하지 않는다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(Self.jsonResponse(
                statusCode: 401,
                envelope: #"{"success":false,"data":null,"code":"AUTH-001","message":"unauthorized","errors":null}"#,
            ))
        ])
        let rejections = Mutex(0)
        let remote = Self.makeRemote(
            transport: transport,
            credential: { .available("expired-token") },
            credentialRejected: { rejections.withLock { $0 += 1 } },
        )

        await #expect(throws: MemberServiceError.unauthorized) {
            _ = try await remote.fetchProfile()
        }
        #expect(await transport.recordedRequests.count == 1)
        #expect(rejections.withLock { $0 } == 1)
    }

    // MARK: Private

    private static func makeRemote(
        transport: StubHTTPTransport,
        credential: @escaping @Sendable () async -> RequestCredential,
        credentialRejected: @escaping @Sendable () async -> Void,
    ) -> MemberRemote {
        MemberRemote(
            client: HTTPClient(
                baseURL: URL(string: "https://api.git-it.example.com")!,
                bodyCoding: JSONBodyCoding(),
                transport: transport,
            ),
            credential: credential,
            credentialRejected: credentialRejected,
        )
    }

    private static func jsonResponse(
        statusCode: Int,
        envelope: String,
    ) -> HTTPTransportResponse {
        HTTPTransportResponse(statusCode: statusCode, headers: [:], body: Data(envelope.utf8))
    }

}
