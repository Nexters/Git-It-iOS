import Foundation
import Testing

@testable import DomainAuthentication

@Suite("정책 동의 유효성")
struct PolicyConsentTests {
    @Test
    func `필수 문서마다 ID와 version이 모두 일치해야 유효하다`() throws {
        let privacy = PolicyDocument(
            identifier: "privacy-policy",
            displayName: "개인정보 처리방침",
            version: "1",
            approvedURL: try #require(URL(string: "https://example.com/privacy")),
            isRequired: true,
        )
        let terms = PolicyDocument(
            identifier: "terms-of-service",
            displayName: "서비스 이용 약관",
            version: "1",
            approvedURL: try #require(URL(string: "https://example.com/terms")),
            isRequired: true,
        )
        let matchingRecords = [
            PolicyConsentRecord(documentIdentifier: "privacy-policy", version: "1", acceptedAt: .distantPast),
            PolicyConsentRecord(documentIdentifier: "terms-of-service", version: "1", acceptedAt: .distantPast),
        ]

        #expect(PolicyConsentRecord.isConsentValid(storedRecords: matchingRecords, for: [privacy, terms]))
    }

    @Test
    func `한 문서의 version이 바뀌면 그 문서 기록만 무효화된다`() throws {
        let privacy = PolicyDocument(
            identifier: "privacy-policy",
            displayName: "개인정보 처리방침",
            version: "2",
            approvedURL: try #require(URL(string: "https://example.com/privacy")),
            isRequired: true,
        )
        let terms = PolicyDocument(
            identifier: "terms-of-service",
            displayName: "서비스 이용 약관",
            version: "1",
            approvedURL: try #require(URL(string: "https://example.com/terms")),
            isRequired: true,
        )
        let staleRecords = [
            PolicyConsentRecord(documentIdentifier: "privacy-policy", version: "1", acceptedAt: .distantPast),
            PolicyConsentRecord(documentIdentifier: "terms-of-service", version: "1", acceptedAt: .distantPast),
        ]

        #expect(!PolicyConsentRecord.isConsentValid(storedRecords: staleRecords, for: [privacy, terms]))
    }

    @Test
    func `계정 식별자를 포함하지 않는다`() {
        let record = PolicyConsentRecord(documentIdentifier: "privacy-policy", version: "1", acceptedAt: .distantPast)
        let fieldNames = Set(Mirror(reflecting: record).children.compactMap(\.label))

        #expect(fieldNames == ["documentIdentifier", "version", "acceptedAt"])
    }
}
