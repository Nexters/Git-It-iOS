import DesignSystem
import Testing

@testable import UIComponent

@Suite("ContinuousProgressBar 계약")
struct ContinuousProgressBarContractTests {
    @Test
    func `진행률은 0부터 1 사이로 제한한다`() {
        #expect(ContinuousProgressBar.ViewModel(progress: -0.1).progress == 0)
        #expect(ContinuousProgressBar.ViewModel(progress: 0).progress == 0)
        #expect(ContinuousProgressBar.ViewModel(progress: 0.45).progress == 0.45)
        #expect(ContinuousProgressBar.ViewModel(progress: 1).progress == 1)
        #expect(ContinuousProgressBar.ViewModel(progress: 1.1).progress == 1)
    }

    @Test
    func `표면 높이는 6pt이고 track과 fill 의미 토큰을 사용한다`() {
        #expect(ContinuousProgressBar.surfaceHeight == 6)
        #expect(ContinuousProgressBar.trackColorToken == .progressTrack)
        #expect(ContinuousProgressBar.fillColorToken == .progressFill)
    }

    @Test
    func `불변 ViewModel로 생성한다`() {
        let viewModel = ContinuousProgressBar.ViewModel(progress: 0.25)

        _ = ContinuousProgressBar(viewModel: viewModel)
        #expect(viewModel.progress == 0.25)
    }
}
