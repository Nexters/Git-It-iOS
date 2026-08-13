import Testing
import UIKit

@testable import DesignSystem

@Suite("FontRegistration")
struct FontRegistrationTests {

    @Test
    func `번들 폰트 6종이 등록되어 사용 가능하다`() {
        _ = FontRegistration.registerBundledFonts
        let postScriptNames = [
            "NotoSansKR-Regular",
            "NotoSansKR-Medium",
            "NotoSansKR-Bold",
            "PlusJakartaSans-Regular",
            "PlusJakartaSans-Medium",
            "PlusJakartaSans-Bold",
        ]
        for name in postScriptNames {
            #expect(UIFont(
                name: name,
                size: 12
            ) != nil, "\(name) 폰트가 등록되어야 한다")
        }
    }

}
