import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("ScreenContainer 계약")
struct ScreenContainerContractTests {
    @Test
    func `화면 좌우 여백은 화면 여백 토큰 하나만 쓴다`() {
        #expect(LayoutToken.margin == 20)
    }

    @Test
    func `배경 색 토큰을 받아 생성한다`() {
        _ = ScreenContainer {
            StyledText(text: "콘텐츠", style: .body1)
        }
        _ = ScreenContainer(background: .grey600) {
            StyledText(text: "콘텐츠", style: .body1)
        }
    }
}
