import Foundation
import Testing

@testable import DataLegalConsent

@Suite("PolicyConsentRecordDTO")
struct PolicyConsentRecordDTOTests {

    @Test
    func `문서별 기록을 인코딩하고 디코딩해도 값이 보존된다`() throws {
        let record = PolicyConsentRecordDTO(
            documentIdentifier: "privacy-policy",
            version: "1",
            acceptedAt: Date(timeIntervalSince1970: 1_700_000_000),
        )

        let data = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(PolicyConsentRecordDTO.self, from: data)

        #expect(decoded == record)
    }

    @Test
    func `회원 ID나 Apple 계정 ID 같은 계정 식별자 필드를 포함하지 않는다`() throws {
        let record = PolicyConsentRecordDTO(
            documentIdentifier: "terms-of-service",
            version: "1",
            acceptedAt: Date(timeIntervalSince1970: 1_700_000_000),
        )

        let data = try JSONEncoder().encode(record)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let keys = Set(object?.keys.map { $0 } ?? [])

        #expect(keys == Set(["documentIdentifier", "version", "acceptedAt"]))
    }

}
