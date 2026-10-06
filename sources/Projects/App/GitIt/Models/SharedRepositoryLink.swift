// MARK: - SharedRepositoryLink

/// 공유 시트로 전달받은 URL 1건이다. 검증 전 외부 입력이므로 그대로 링크 입력 초기값이
/// 되고, 이후 검증은 기존 링크 검증 경로가 담당한다.
struct SharedRepositoryLink: Equatable, Sendable {

    // MARK: Internal

    let url: String

}
