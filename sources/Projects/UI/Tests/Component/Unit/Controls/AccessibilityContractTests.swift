import DesignSystem
import Testing

@testable import UIComponent

@Suite("접근성 계약")
struct AccessibilityContractTests {
    @Test
    func `아이콘 전용 버튼의 히트 영역은 최소 터치 크기를 따른다`() {
        #expect(IconGlassButton.Size.small.touchSize == ControlSizeToken.minimumTouch.cgFloatValue)
        #expect(IconGlassButton.Size.medium.touchSize == ControlSizeToken.minimumTouch.cgFloatValue)
    }

    @Test
    func `조작 컴포넌트의 히트 영역은 44 이상이다`() {
        #expect(ControlSizeToken.minimumTouch.value == 44)
        #expect(ActionButton.Size.large.touchHeight >= 44)
        #expect(ActionButton.Size.medium.touchHeight >= 44)
        #expect(ActionButton.Size.small.touchHeight >= 44)
        #expect(HomeProjectCard.minimumTouchArea >= 44)
    }

    @Test
    func `탭 항목은 선택 여부에 따라 색 토큰을 바꾼다`() {
        #expect(TabShellPreviewItem.tabColor(isSelected: true) == ColorToken.blue100)
        #expect(TabShellPreviewItem.tabColor(isSelected: false) == ColorToken.grey400)
    }
}
