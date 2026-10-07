import Foundation
import Synchronization
import Testing

@testable import GitIt

// MARK: - AppLaunchSequenceTests

@Suite("AppLaunchSequence")
struct AppLaunchSequenceTests {

    @Test
    @MainActor
    func `마커 저장 푸시 활성화 AppDelegate 구성 순서로 실행한다`() async {
        let recorded = Mutex([String]())
        let sequence = AppLaunchSequence(
            recordSharedSessionState: { recorded.withLock { $0.append("recordSharedSessionState") } },
            activatePushClient: { recorded.withLock { $0.append("activatePushClient") } },
            configureAppDelegate: { recorded.withLock { $0.append("configureAppDelegate") } },
        )

        await sequence()

        #expect(recorded.withLock { $0 } == [
            "recordSharedSessionState",
            "activatePushClient",
            "configureAppDelegate",
        ])
    }

}
