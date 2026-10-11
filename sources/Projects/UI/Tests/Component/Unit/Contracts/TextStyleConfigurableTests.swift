import DesignSystem
import Testing

@testable import UIComponent

@Suite("TextStyleConfigurable 계약")
struct TextStyleConfigurableTests {

    // MARK: Internal

    @Test
    func `텍스트 스타일을 선언하지 않으면 Body 1로 그린다`() {
        #expect(textStyle(of: StyledText(text: "본문")) == TextStyleToken.body1)
    }

    @Test
    func `텍스트 스타일 선언은 텍스트 스타일만 바꾸고 문구와 전경색을 유지한다`() {
        let original = StyledText(text: "제목").foregroundColorToken(.grey400)

        let styled = original.textStyle(.subtitle1)

        #expect(textStyle(of: styled) == TextStyleToken.subtitle1)
        #expect(styled.text == "제목")
        #expect(foregroundColor(of: styled) == ColorToken.grey400)
    }

    @Test
    func `텍스트 스타일을 두 번 선언하면 마지막 값이 남는다`() {
        let styled = StyledText(text: "제목").textStyle(.headline1).textStyle(.caption2)

        #expect(textStyle(of: styled) == TextStyleToken.caption2)
    }

    @Test
    func `전경색 선언과 호출 순서를 바꿔도 결과가 같다`() {
        let textStyleFirst = StyledText(text: "제목").textStyle(.body2).foregroundColorToken(.blue100)
        let foregroundColorFirst = StyledText(text: "제목").foregroundColorToken(.blue100).textStyle(.body2)

        #expect(textStyleFirst == foregroundColorFirst)
    }

    // MARK: Private

    private func textStyle(of styledText: StyledText) -> TextStyleToken? {
        Mirror(reflecting: styledText).descendant("textStyle") as? TextStyleToken
    }

    private func foregroundColor(of styledText: StyledText) -> ColorToken? {
        Mirror(reflecting: styledText).descendant("foregroundColor") as? ColorToken
    }

}
