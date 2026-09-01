import Foundation

public struct GenerationWaitPolicy: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        minimumWait: TimeInterval,
        retentionLimit: TimeInterval,
    ) {
        self.minimumWait = minimumWait
        self.retentionLimit = retentionLimit
    }

    // MARK: Public

    /// 학습 세트 생성 진행 화면이 안내하는 고정 대기 시간과 같은 값입니다.
    public static let standard = GenerationWaitPolicy(
        minimumWait: 300,
        retentionLimit: 3600,
    )

    public let minimumWait: TimeInterval
    public let retentionLimit: TimeInterval

    /// 진행 화면 전이·완료 알림 발송·홈 표시 해제가 가능해지는 가장 이른 시각입니다.
    public func readyDate(for progress: GenerationProgress) -> Date {
        progress.requestedAt.addingTimeInterval(minimumWait)
    }

    /// 결과가 끝내 도착하지 않아 진행 상태를 강제로 해제해야 하는지 판정합니다.
    public func isExpired(
        _ progress: GenerationProgress,
        now: Date,
    ) -> Bool {
        now.timeIntervalSince(progress.requestedAt) > retentionLimit
    }

}
