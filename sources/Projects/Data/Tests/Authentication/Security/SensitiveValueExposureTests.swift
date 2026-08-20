import Foundation
import Testing

@testable import DataAuthentication

@Suite("Data 민감 값 비노출")
struct SensitiveValueExposureTests {
    @Test
    func `payload와 token을 설명 및 디버그 문자열에 노출하지 않는다`() {
        let payloadMarker = "payload-marker-9384"
        let accessMarker = "access-marker-5821"
        let refreshMarker = "refresh-marker-7492"
        let payload = AuthenticationEvidence.OpaquePayload(bytes: Array(payloadMarker.utf8))
        let user = LoginSessionResponseDTO.User(
            id: "user-1",
            availability: .available,
            displayName: nil,
        )
        let values: [Any] = [
            payload,
            LoginSessionStartRequestDTO(
                methodIdentifier: "social-provider",
                opaquePayload: payload,
            ),
            LoginSessionResponseDTO(
                user: user,
                accessToken: accessMarker,
                refreshToken: refreshMarker,
                accessExpiresAt: Date(timeIntervalSince1970: 100),
            ),
            RefreshRequestDTO(refreshToken: refreshMarker),
            RefreshResponseDTO(
                accessToken: accessMarker,
                accessExpiresAt: Date(timeIntervalSince1970: 200),
                replacementRefreshToken: refreshMarker,
            ),
            StoredLoginSession(
                accessToken: accessMarker,
                refreshToken: refreshMarker,
                accessExpiresAt: Date(timeIntervalSince1970: 100),
                user: user,
            ),
        ]

        for value in values {
            let descriptions = [String(describing: value), String(reflecting: value)]
            for description in descriptions {
                #expect(!description.contains(payloadMarker))
                #expect(!description.contains(accessMarker))
                #expect(!description.contains(refreshMarker))
            }
        }

        for error in DataAuthenticationError.allCases {
            let description = String(reflecting: error)
            #expect(!description.contains(payloadMarker))
            #expect(!description.contains(accessMarker))
            #expect(!description.contains(refreshMarker))
        }
    }
}
