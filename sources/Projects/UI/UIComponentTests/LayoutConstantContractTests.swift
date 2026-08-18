import Testing
@testable import UIComponent

struct LayoutConstantContractTests {
    @Test
    func `action button sizes match figma`() {
        #expect(ActionButton.Size.large.surfaceHeight == 54)
        #expect(ActionButton.Size.small.surfaceHeight == 40)
    }

    @Test
    func `icon glass button sizes match figma`() {
        #expect(IconGlassButton.Size.medium.surfaceSize == 40)
        #expect(IconGlassButton.Size.small.surfaceSize == 36)
    }
}
