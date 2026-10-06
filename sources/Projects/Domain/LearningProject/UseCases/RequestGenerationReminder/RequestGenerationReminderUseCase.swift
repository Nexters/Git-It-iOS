public protocol RequestGenerationReminderUseCase: Sendable {
    func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome

    /// 시스템 권한 다이얼로그를 띄우지 않고 현재 알림 권한이 허용 상태인지 확인한다.
    func isAuthorized() async -> Bool
}
