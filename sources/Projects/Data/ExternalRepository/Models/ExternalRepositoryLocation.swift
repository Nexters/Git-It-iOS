// MARK: - ExternalRepositoryLocation

/// URL 문자열에서 해석한 외부 저장소의 소유자와 저장소 이름이다.
public struct ExternalRepositoryLocation: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        owner: String,
        name: String,
    ) {
        self.owner = owner
        self.name = name
    }

    // MARK: Public

    public let owner: String
    public let name: String

}
