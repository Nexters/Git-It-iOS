import Foundation

// MARK: - LocalNotificationClient

public protocol LocalNotificationClient: Sendable {
    /// 현재 권한 상태를 확인하고, 아직 결정되지 않았다면 시스템 권한 요청 다이얼로그를
    /// 표시한다. 이미 거부된 상태라면 다이얼로그 없이 `.previouslyDenied`를 반환한다.
    func requestAuthorization() async -> LocalNotificationAuthorizationOutcome

    /// 로컬 알림을 실제로 보내기 직전에 현재 권한이 허용 상태인지 다시 확인한다.
    func isAuthorized() async -> Bool

    /// 전달받은 값 그대로 로컬 알림을 즉시 발송한다.
    func present(_ request: LocalNotificationRequest)

    /// 지정한 시각에 발송되도록 시스템에 예약한다. 이미 지난 시각이면 즉시 발송한다.
    /// 같은 식별자로 다시 예약하면 이전 예약을 대체해 1건만 남는다.
    func schedule(
        _ request: LocalNotificationRequest,
        at date: Date,
    )

    /// 아직 발송되지 않은 예약을 취소한다. 해당 식별자의 예약이 없으면 아무 일도 하지 않는다.
    func cancel(identifier: String)
}
