import Foundation

/// 설치 단위로 저장하는 문서별 정책 동의 기록이다. 회원 ID·Apple 계정 ID·email과 같은 계정
/// 식별자는 포함하지 않는다.
public struct PolicyConsentRecordDTO: Codable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        documentIdentifier: String,
        version: String,
        acceptedAt: Date,
    ) {
        self.documentIdentifier = documentIdentifier
        self.version = version
        self.acceptedAt = acceptedAt
    }

    // MARK: Public

    public let documentIdentifier: String
    public let version: String
    public let acceptedAt: Date

}
