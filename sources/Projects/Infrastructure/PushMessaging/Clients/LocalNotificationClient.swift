// MARK: - LocalNotificationClient

public protocol LocalNotificationClient: Sendable {
    /// 현재 권한 상태를 확인하고, 아직 결정되지 않았다면 시스템 권한 요청 다이얼로그를
    /// 표시한다. 이미 거부된 상태라면 다이얼로그 없이 `.previouslyDenied`를 반환한다.
    func requestAuthorization() async -> LocalNotificationAuthorizationOutcome

    /// 로컬 알림을 실제로 보내기 직전에 현재 권한이 허용 상태인지 다시 확인한다.
    func isAuthorized() async -> Bool

    /// 지정한 프로젝트의 생성 완료를 안내하는, 사용자에게 보이는 로컬 알림을 즉시 발송한다.
    func presentGenerationCompletedNotification(projectID: String)
}

// MARK: - LocalNotificationAuthorizationOutcome

public enum LocalNotificationAuthorizationOutcome: Sendable, Equatable {
    case authorized
    case declined
    case previouslyDenied
}
