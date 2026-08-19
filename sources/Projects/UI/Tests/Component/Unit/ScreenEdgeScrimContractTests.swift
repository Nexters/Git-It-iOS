import DesignSystem
import Testing

@testable import UIComponent

@Suite("ScreenEdgeScrim 계약")
struct ScreenEdgeScrimContractTests {
    @Test
    func `top과 bottom 변형은 각 방향의 GradientToken에 대응한다`() {
        #expect(ScreenEdgeScrim.Style.top.gradientToken == .topEdgeScrim)
        #expect(ScreenEdgeScrim.Style.bottom.gradientToken == .bottomEdgeScrim)
    }

    @Test
    func `시각 표현은 사용자 상호작용을 가로채지 않는다`() {
        #expect(!ScreenEdgeScrim.allowsHitTesting)

        _ = ScreenEdgeScrim.top()
        _ = ScreenEdgeScrim.bottom()
    }
}
