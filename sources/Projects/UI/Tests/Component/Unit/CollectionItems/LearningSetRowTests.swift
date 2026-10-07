import DesignSystem
import Testing

@testable import UIComponent

@Suite("LearningSetRow 계약")
struct LearningSetRowTests {
    @Test
    func `크기는 320×130pt를 유지한다`() {
        #expect(LearningSetRow.height == 130)
    }

    @Test
    func `표시 값을 직접 받아 생성한다`() {
        _ = LearningSetRow(title: "Presentation 구조", questionCount: 12, progress: 0.4)
    }
}
