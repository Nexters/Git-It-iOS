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
    func `라벨과 제목과 문제 수와 완료 수를 표시 값으로 직접 받는다`() {
        _ = LearningSetRow(
            label: "Set 1",
            title: "아이디어 PT 핵심 내용 확인하기",
            questionCount: 7,
            completedCount: 3,
        )
    }

    @Test
    func `시작 버튼의 터치 대상은 44pt 이상이다`() {
        #expect(LearningSetRow.minimumTouchArea >= 44)
    }

    @Test
    func `완료 수가 문제 수를 넘으면 문제 수로 제한한다`() {
        #expect(LearningSetRow.clampedCompletedCount(completed: 9, total: 7) == 7)
    }

    @Test
    func `완료 수가 음수이면 0으로 제한한다`() {
        #expect(LearningSetRow.clampedCompletedCount(completed: -1, total: 7) == 0)
    }

    @Test
    func `문제가 없는 세트는 완료 수를 0으로 제한한다`() {
        #expect(LearningSetRow.clampedCompletedCount(completed: 3, total: 0) == 0)
    }

}
