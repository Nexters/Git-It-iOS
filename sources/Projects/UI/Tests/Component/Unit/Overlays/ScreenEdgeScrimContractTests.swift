import DesignSystem
import Testing

@testable import UIComponent

@Suite("ScreenEdgeScrim 계약")
struct ScreenEdgeScrimContractTests {

    // MARK: Internal

    @Test
    func `top과 bottom 변형은 각 방향의 GradientToken에 대응한다`() {
        #expect(ScreenEdgeScrim.Style.top(headerStyle: .plain).gradientToken == .topEdgeScrim)
        #expect(ScreenEdgeScrim.Style.bottom(hasTabBar: false).gradientToken == .bottomEdgeScrim)
    }

    @Test
    func `시각 표현은 사용자 상호작용을 가로채지 않는다`() {
        #expect(!ScreenEdgeScrim.allowsHitTesting)

        _ = ScreenEdgeScrim.top()
        _ = ScreenEdgeScrim.bottom()
    }

    @Test
    func `상단 스크림 높이는 헤더 종류별 계산값을 따른다`() {
        #expect(ScreenEdgeScrim.Style.top(headerStyle: .plain).height(layoutMetrics: Self.metrics) == 70)
        #expect(ScreenEdgeScrim.Style.top(headerStyle: .inlineTitle).height(layoutMetrics: Self.metrics) == 63)
        #expect(ScreenEdgeScrim.Style.top(headerStyle: .inlineUser).height(layoutMetrics: Self.metrics) == 94)
        #expect(ScreenEdgeScrim.Style.top(headerStyle: .largeTitle).height(layoutMetrics: Self.metrics) == 119)
    }

    @Test
    func `하단 스크림 높이는 탭바 유무에 따라 계산값을 따른다`() {
        #expect(ScreenEdgeScrim.Style.bottom(hasTabBar: false).height(layoutMetrics: Self.metrics) == 0)
        #expect(ScreenEdgeScrim.Style.bottom(hasTabBar: true).height(layoutMetrics: Self.metrics) == 92)
    }

    @Test
    func `정본 고정값이 아니라 화면 크기에서 유도한 높이를 쓴다`() {
        let large = LayoutMetrics(screenWidth: 440, screenHeight: 956, safeAreaTop: 62, safeAreaBottom: 34)

        #expect(ScreenEdgeScrim.Style.top(headerStyle: .plain).height(layoutMetrics: large) == 112)
        #expect(ScreenEdgeScrim.Style.bottom(hasTabBar: true).height(layoutMetrics: large) == 126)
    }

    // MARK: Private

    private static let metrics = LayoutMetrics(
        screenWidth: 375,
        screenHeight: 667,
        safeAreaTop: 20,
        safeAreaBottom: 0,
    )

}
