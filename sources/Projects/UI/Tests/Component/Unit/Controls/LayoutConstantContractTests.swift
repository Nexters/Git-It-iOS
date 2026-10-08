import DesignSystem
import Testing
@testable import UIComponent

struct LayoutConstantContractTests {
    @Test
    func `action button sizes match figma`() {
        #expect(ActionButton.Size.large.surfaceHeight == 54)
        #expect(ActionButton.Size.medium.surfaceHeight == 40)
        #expect(ActionButton.Size.small.surfaceHeight == 36)
    }

    @Test
    func `primary text 스타일은 배경 없이 Blue100 라벨을 쓴다`() {
        #expect(ActionButton.Style.primaryText.titleColor(isEnabled: true) == .blue100)
        #expect(ActionButton.Style.text.titleColor(isEnabled: true) == .grey100)
        #expect(ActionButton.Style.primaryText.titleColor(isEnabled: false) == .white30)
    }

    @Test
    func `icon glass button sizes match figma`() {
        #expect(IconGlassButton.Size.medium.surfaceSize == 40)
        #expect(IconGlassButton.Size.small.surfaceSize == 36)
    }
}
