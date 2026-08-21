import DesignSystem
import Testing

@testable import UIComponent

@Suite("ContinuousProgressBar 계약")
struct ContinuousProgressBarContractTests {
    @Test
    func `진행률은 0부터 1 사이로 제한한다`() {
        #expect(ContinuousProgressBar.clampedProgress(-0.1) == 0)
        #expect(ContinuousProgressBar.clampedProgress(0) == 0)
        #expect(ContinuousProgressBar.clampedProgress(0.45) == 0.45)
        #expect(ContinuousProgressBar.clampedProgress(1) == 1)
        #expect(ContinuousProgressBar.clampedProgress(1.1) == 1)
    }

    @Test
    func `표면 높이는 6pt이고 track과 fill 의미 토큰을 사용한다`() {
        #expect(ContinuousProgressBar.surfaceHeight == 6)
        #expect(ContinuousProgressBar.trackColorToken == .progressTrack)
        #expect(ContinuousProgressBar.fillColorToken == .progressFill)
    }

    @Test
    func `진행률을 직접 입력으로 생성한다`() {
        _ = ContinuousProgressBar(progress: 0.25)
    }
}
