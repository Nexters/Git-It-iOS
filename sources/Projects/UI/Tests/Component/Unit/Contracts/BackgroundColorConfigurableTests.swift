import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("BackgroundColorConfigurable 계약")
struct BackgroundColorConfigurableTests {

    // MARK: Internal

    @Test
    func `배경색을 선언하지 않으면 컴포넌트 기본 배경색으로 그린다`() {
        #expect(backgroundColor(of: IconPlainButton(
            icon: .play
        )) == ColorToken.clear)
        #expect(backgroundColor(of: screenContainer) == ColorToken.grey700)
        #expect(screenBackground(of: overlayContainer) == ColorToken.grey700)
    }

    @Test
    func `배경색 선언은 배경색만 바꾸고 전경색과 표시 값을 유지한다`() {
        let button = IconPlainButton(
            icon: .play
        )
        .foregroundColorToken(.grey700)
        .backgroundColorToken(.blue100)

        #expect(backgroundColor(of: button) == ColorToken.blue100)
        #expect(Mirror(reflecting: button).descendant("foregroundColor") as? ColorToken == ColorToken.grey700)
        #expect(Mirror(reflecting: button).descendant("icon") as? IconPlainButton.Icon == .play)
        #expect(backgroundColor(of: screenContainer.backgroundColorToken(.grey600)) == ColorToken.grey600)
        #expect(screenBackground(of: overlayContainer.backgroundColorToken(.grey600)) == ColorToken.grey600)
    }

    @Test
    func `배경색을 두 번 선언하면 마지막 값이 남는다`() {
        let button = IconPlainButton(
            icon: .play
        )
        .backgroundColorToken(.grey600)
        .backgroundColorToken(.blue100)
        let container = screenContainer.backgroundColorToken(.grey600).backgroundColorToken(.grey500)
        let overlay = overlayContainer.backgroundColorToken(.grey600).backgroundColorToken(.grey500)

        #expect(backgroundColor(of: button) == ColorToken.blue100)
        #expect(backgroundColor(of: container) == ColorToken.grey500)
        #expect(screenBackground(of: overlay) == ColorToken.grey500)
    }

    @Test
    func `전경색 선언과 호출 순서를 바꿔도 결과가 같다`() {
        let backgroundFirst = IconPlainButton(
            icon: .play
        )
        .backgroundColorToken(.blue100)
        .foregroundColorToken(.grey700)
        let foregroundFirst = IconPlainButton(
            icon: .play
        )
        .foregroundColorToken(.grey700)
        .backgroundColorToken(.blue100)

        #expect(backgroundColor(of: backgroundFirst) == backgroundColor(of: foregroundFirst))
        #expect(
            Mirror(reflecting: backgroundFirst).descendant("foregroundColor") as? ColorToken
                == Mirror(reflecting: foregroundFirst).descendant("foregroundColor") as? ColorToken
        )
    }

    // MARK: Private

    private var screenContainer: ScreenContainer<StyledText> {
        ScreenContainer {
            StyledText(text: "콘텐츠")
        }
    }

    private var overlayContainer: OverlayContainer<EmptyView, StyledText, EmptyView, EmptyView> {
        OverlayContainer(content: {
            StyledText(text: "본문")
        })
    }

    private func backgroundColor(of subject: some View) -> ColorToken? {
        Mirror(reflecting: subject).descendant("backgroundColor") as? ColorToken
    }

    private func screenBackground(of subject: some View) -> ColorToken? {
        Mirror(reflecting: subject).descendant("screenBackground") as? ColorToken
    }

}
