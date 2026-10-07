import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("ScreenContainer 계약")
struct ScreenContainerContractTests {
    @Test
    func `화면 좌우 여백은 화면 여백 토큰 하나만 쓴다`() {
        #expect(LayoutToken.margin.value == 20)
    }

    @Test
    func `배경 역할 색을 받아 생성한다`() {
        _ = ScreenContainer {
            StyledText.body1("콘텐츠")
        }
        _ = ScreenContainer(background: .cardBackground) {
            StyledText.body1("콘텐츠")
        }
    }
}
