/// 기기 안에만 남기는 진단 이벤트다. 토큰, 원본 URL 전체, 사용자 식별자를 값으로 갖지
/// 않으며 원격으로 전송하지 않는다.
public enum ShareRegistrationDiagnosticEvent: Equatable, Sendable {
    /// 공유 항목에서 사용할 수 있는 URL을 얻지 못했다.
    case sharedItemUnavailable
    /// 로컬 판정에서 GitHub 저장소 경로가 아니라고 확인했다.
    case repositoryLinkRejected
    /// 세션 확인 결과. 토큰 값은 포함하지 않는다.
    case sessionResolved(ShareRegistrationSessionState)
    /// 저장소 조회가 실패했다.
    case repositoryLookupFailed(reason: String)
    /// 등록 요청이 실패했다.
    case registrationFailed(reason: String)
    /// 등록에 성공했다.
    case registrationSucceeded
    /// 알림 권한이 허용되어 리마인더 대기 목록에 남겼다.
    case generationReminderEnqueued
}
