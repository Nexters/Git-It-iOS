// MARK: - ExternalRepositoryLocation

/// 외부 저장소 1건을 가리키는 소유자와 저장소 이름이다. URL 문자열을 해석한 결과이며,
/// 해석 규칙 자체는 Domain 밖 구현이 소유한다.
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
