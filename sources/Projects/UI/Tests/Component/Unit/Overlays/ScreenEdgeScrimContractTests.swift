import DesignSystem
import Testing

@testable import UIComponent

@Suite("ScreenEdgeScrim 계약")
struct ScreenEdgeScrimContractTests {
    @Test
    func `시각 표현은 사용자 상호작용을 가로채지 않는다`() {
        #expect(!ScreenEdgeScrim.allowsHitTesting)

        _ = ScreenEdgeScrim.top(height: 70)
        _ = ScreenEdgeScrim.bottom(height: 92)
    }
}
