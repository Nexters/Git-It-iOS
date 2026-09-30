import Foundation
import Testing
@testable import DataLearningProject

// MARK: - GenerationReminderStorageCoordinateTests

@Suite("생성 리마인드 저장 좌표")
struct GenerationReminderStorageCoordinateTests {

    @Test
    func `생성 대기 상태는 기존 App Group 네임스페이스와 키를 그대로 쓴다`() {
        #expect(LocalPendingGenerationStore.namespace == "com.nexters.hytime.gitit.sharedSession")
        #expect(LocalPendingGenerationStore.stateKey == "generationState")
    }

}
