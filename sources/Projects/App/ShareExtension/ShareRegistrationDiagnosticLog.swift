import Feature
import Foundation
import os

// MARK: - ShareRegistrationDiagnosticLog

/// 진단 이벤트를 기기 안에만 기록한다. 토큰·개인정보를 남기지 않고 원격으로 전송하지
/// 않는다.
struct ShareRegistrationDiagnosticLog: Sendable {

    // MARK: Lifecycle

    init() { }

    // MARK: Internal

    func record(_ event: ShareRegistrationDiagnosticEvent) {
        Self.logger.debug("공유 등록 상태: \(Self.description(for: event), privacy: .public)")
    }

    // MARK: Private

    private static let logger = Logger(
        subsystem: "com.nexters.hytime.gitit",
        category: "ShareExtension",
    )

    private static func description(for event: ShareRegistrationDiagnosticEvent) -> String {
        switch event {
        case .sharedItemUnavailable:
            "sharedItemUnavailable"

        case .repositoryLinkRejected:
            "repositoryLinkRejected"

        case .sessionResolved(let state):
            "sessionResolved(\(state))"

        case .repositoryLookupFailed(let reason):
            "repositoryLookupFailed(\(reason))"

        case .registrationFailed(let reason):
            "registrationFailed(\(reason))"

        case .registrationSucceeded:
            "registrationSucceeded"

        case .generationReminderEnqueued:
            "generationReminderEnqueued"
        }
    }

}
