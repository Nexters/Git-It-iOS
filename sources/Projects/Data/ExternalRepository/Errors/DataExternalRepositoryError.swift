public enum DataExternalRepositoryError: CaseIterable, Equatable, Error, Sendable {
    /// 네트워크 연결 실패를 표현합니다. 실제 기술 오류 매핑은 Composition이 담당합니다.
    case offline
    /// 연결 실패 외의 모든 실패를 표현합니다. 실제 기술 오류 매핑은 Composition이 담당합니다.
    case other
}
