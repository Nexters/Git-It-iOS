import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("OverlayContainer 계약")
struct OverlayContainerContractTests {
    @Test
    func `헤더와 본문과 푸터를 각각 받아 생성한다`() {
        _ = OverlayContainer {
            ScreenOverlayHeader()
        } content: {
            StyledText.body1("본문")
        } footer: {
            ScreenOverlayFooter {
                ActionButton.primary("계속하기")
            }
        }
    }

    @Test
    func `헤더와 배경과 푸터를 각각 생략할 수 있다`() {
        _ = OverlayContainer(content: {
            StyledText.body1("본문")
        })
    }

    @Test
    func `본문과 함께 스크롤되는 배경을 받는다`() {
        _ = OverlayContainer {
            ScreenOverlayHeader()
        } content: {
            StyledText.body1("본문")
        } background: {
            LinearGradient(designSystem: .topEdgeScrim)
        }
    }

    @Test
    func `화면 배경 토큰을 바꿔 받는다`() {
        _ = OverlayContainer(screenBackground: .cardBackground, content: {
            StyledText.body1("본문")
        })
    }

    @Test
    func `헤더와 푸터 자리에 임의의 View를 주입한다`() {
        _ = OverlayContainer {
            StyledText.subtitle1("직접 만든 헤더")
        } content: {
            StyledText.body1("본문")
        } footer: {
            StyledText.body2("직접 만든 푸터")
        }
    }
}
