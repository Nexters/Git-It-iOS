import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("ForegroundColorConfigurable 계약")
struct ForegroundColorConfigurableTests {

    // MARK: Internal

    @Test
    func `StyledText 전경색을 선언하지 않으면 Grey100으로 그린다`() {
        #expect(foregroundColor(of: StyledText(text: "본문")) == ColorToken.grey100)
    }

    @Test
    func `StyledText 전경색 선언은 전경색만 바꾸고 문구와 텍스트 스타일을 유지한다`() {
        let original = StyledText(text: "제목").textStyle(.subtitle2)

        let colored = original.foregroundColorToken(.error)

        #expect(foregroundColor(of: colored) == ColorToken.error)
        #expect(colored.text == "제목")
        #expect(Mirror(reflecting: colored).descendant("textStyle") as? TextStyleToken == TextStyleToken.subtitle2)
    }

    @Test
    func `StyledText 전경색을 두 번 선언하면 마지막 값이 남는다`() {
        let colored = StyledText(text: "제목").foregroundColorToken(.grey400).foregroundColorToken(.blue100)

        #expect(foregroundColor(of: colored) == ColorToken.blue100)
    }

    // MARK: Private

    private func foregroundColor(of subject: some View) -> ColorToken? {
        Mirror(reflecting: subject).descendant("foregroundColor") as? ColorToken
    }

}
