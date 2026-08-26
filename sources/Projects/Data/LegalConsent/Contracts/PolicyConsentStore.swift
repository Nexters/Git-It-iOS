/// 설치 단위 정책 동의 기록의 조회·저장·초기화 계약이다. 계정 식별자를 다루지 않는다.
public protocol PolicyConsentStore: Sendable {
    /// 현재 설치에 저장된 모든 문서별 동의 기록을 반환한다.
    func records() async -> [PolicyConsentRecordDTO]

    /// 문서 ID가 같은 기존 기록을 새 기록으로 교체해 저장한다.
    func saveRecord(_ record: PolicyConsentRecordDTO) async

    /// 저장된 모든 동의 기록을 제거한다.
    func removeAll() async
}
