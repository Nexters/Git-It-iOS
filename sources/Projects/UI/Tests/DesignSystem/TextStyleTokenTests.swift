import Testing

@testable import DesignSystem

@Suite("TextStyleToken")
struct TextStyleTokenTests {

    @Test
    func `11개 텍스트 스타일의 굵기·크기·행간이 명세 값과 일치한다`() {
        let expected: [(String, TextStyleToken.Weight, Double, Double)] = [
            ("Headline 1", .bold, 30, 124),
            ("Headline 2", .bold, 28, 130),
            ("Subtitle 1", .bold, 22, 148),
            ("Subtitle 2", .bold, 18, 148),
            ("Subtitle 3", .bold, 16, 148),
            ("Body 1", .medium, 16, 150),
            ("Body 2", .medium, 14, 150),
            ("Body 3", .medium, 12, 150),
            ("Caption 1", .regular, 12, 150),
            ("Caption 2", .medium, 10, 150),
            ("Tab Item", .regular, 10, 150),
        ]
        for (name, weight, size, lineHeightPercent) in expected {
            let token = TextStyleToken.all.first { $0.name == name }
            #expect(token != nil, "\(name) 토큰이 존재해야 한다")
            #expect(token?.weight == weight)
            #expect(token?.size == size)
            #expect(token?.lineHeightPercent == lineHeightPercent)
        }
    }

    @Test
    func `자간·문단 간격·문단 들여쓰기는 모두 0이다`() {
        for token in TextStyleToken.all {
            #expect(token.letterSpacing == 0)
            #expect(token.paragraphSpacing == 0)
            #expect(token.paragraphIndent == 0)
        }
    }

    @Test
    func `텍스트 스타일 토큰 총 개수는 11개다`() {
        #expect(TextStyleToken.all.count == 11)
    }

}
