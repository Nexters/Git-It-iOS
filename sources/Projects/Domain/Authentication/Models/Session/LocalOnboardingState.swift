import Foundation

public struct LocalOnboardingState: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        needsCuration: Bool,
        acceptedLegalVersions: [String],
        acceptedAt: Date?,
    ) {
        self.needsCuration = needsCuration
        self.acceptedLegalVersions = acceptedLegalVersions
        self.acceptedAt = acceptedAt
    }

    // MARK: Public

    public let needsCuration: Bool
    public let acceptedLegalVersions: [String]
    public let acceptedAt: Date?

}
