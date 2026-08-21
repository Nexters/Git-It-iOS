import DesignSystem
import Testing

@testable import UIComponent

@Suite("LearningSetRow 계약")
struct LearningSetRowTests {
    @Test
    func `크기는 320×130pt를 유지한다`() {
        #expect(LearningSetRow.width == 320)
        #expect(LearningSetRow.height == 130)
    }

    @Test
    func `불변 ViewModel로 생성한다`() {
        let viewModel = LearningSetRow.ViewModel(
            title: "Presentation 구조",
            questionCount: 12,
            progress: 0.4,
        )

        _ = LearningSetRow(viewModel: viewModel)
        #expect(viewModel.title == "Presentation 구조")
        #expect(viewModel.questionCount == 12)
        #expect(viewModel.progress == 0.4)
        #expect(viewModel.isCompleted == false)
    }
}
