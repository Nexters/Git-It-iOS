public protocol ExternalRepositoryURLParser: Sendable {
    /// 외부 저장소 URL 문자열을 소유자와 저장소 이름으로 해석한다. 해석할 수 없으면 `nil`이다.
    func location(from url: String) -> ExternalRepositoryLocation?
}
