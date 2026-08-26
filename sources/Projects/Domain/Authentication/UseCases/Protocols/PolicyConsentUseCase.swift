public protocol PolicyConsentUseCase: Sendable {
    /// 앱 번들 정책 manifest에서 현재 필수 정책 문서 목록을 조회한다.
    func requiredDocuments() async throws -> [PolicyDocument]

    /// 설치 단위로 저장된 정책 동의 기록을 조회한다.
    func storedConsentRecords() async throws -> [PolicyConsentRecord]

    /// 새로 선택한 동의 기록을 설치 단위로 저장한다.
    func saveConsentRecords(_ records: [PolicyConsentRecord]) async throws

    /// 저장 기록이 필수 문서마다 ID·version 모두 일치할 때만 유효로 판정한다.
    func isConsentValid(
        storedRecords: [PolicyConsentRecord],
        for requiredDocuments: [PolicyDocument],
    ) -> Bool
}
