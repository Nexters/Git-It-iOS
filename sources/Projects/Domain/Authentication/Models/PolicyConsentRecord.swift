import Foundation

public struct PolicyConsentRecord: Equatable, Sendable {

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

    /// 필수 문서마다 ID와 version이 모두 일치하는 저장 기록이 있을 때만 전체 동의가 유효하다.
    /// 한 문서의 version이 바뀌면 그 문서 기록만 무효화되어 다른 문서 기록에는 영향이 없다.
    public static func isConsentValid(
        storedRecords: [PolicyConsentRecord],
        for requiredDocuments: [PolicyDocument],
    ) -> Bool {
        requiredDocuments.allSatisfy { document in
            guard document.isRequired else { return true }
            return storedRecords.contains {
                $0.documentIdentifier == document.identifier && $0.version == document.version
            }
        }
    }

    public let documentIdentifier: String
    public let version: String
    public let acceptedAt: Date

}
