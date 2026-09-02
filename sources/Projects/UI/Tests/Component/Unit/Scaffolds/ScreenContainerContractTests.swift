import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("ScreenContainer 계약")
struct ScreenContainerContractTests {
    @Test
    func `기본 레이아웃 변수는 주력 기기 규격을 따른다`() {
        let metrics = LayoutMetrics.default

        #expect(metrics.screenWidth == 402)
        #expect(metrics.screenHeight == 874)
        #expect(metrics.safeAreaTop == 62)
        #expect(metrics.safeAreaBottom == 34)
    }

    @Test
    func `화면 좌우 여백은 화면 여백 토큰 하나만 쓴다`() {
        #expect(LayoutToken.margin.value == 20)
    }

    @Test
    func `배경 역할 색을 받아 생성한다`() {
        _ = ScreenContainer { _ in
            StyledText.body1("콘텐츠")
        }
        _ = ScreenContainer(background: .cardBackground) { _ in
            StyledText.body1("콘텐츠")
        }
    }
}
