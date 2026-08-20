public protocol ExternalRepositoryLookup: Sendable {
    /// URL 파싱은 호출자(UseCase)가 이미 끝낸 뒤 소유자·저장소 이름으로 호출한다.
    /// `.invalidURLFormat`은 이 메서드가 던지지 않는다.
    func repository(
        owner: String,
        name: String,
    ) async throws -> ExternalRepository
}
