import Testing

@testable import DesignSystem

@Suite("SemanticColorToken")
struct SemanticColorTokenTests {

    @Test
    func `역할 토큰이 참조하는 원시 색상이 명세 값과 일치한다`() {
        let expected: [(String, String)] = [
            ("ScreenBackground", "Grey700"),
            ("CardBackground", "Grey600"),
            ("RaisedBackground", "Grey500"),
            ("AccentSurface", "Blue500"),
            ("Scrim", "Black 70"),
            ("PrimaryText", "Grey100"),
            ("SecondaryText", "Grey300"),
            ("MutedText", "Grey400"),
            ("BrandAccent", "Blue100"),
            ("ProgressTrack", "Grey500"),
            ("ProgressFill", "Blue200"),
        ]
        for (name, colorName) in expected {
            let token = SemanticColorToken.all.first { $0.name == name }
            #expect(token != nil, "\(name) 토큰이 존재해야 한다")
            #expect(token?.colorToken.name == colorName)
        }
    }

    @Test
    func `모든 역할 토큰이 색상 토큰 집합 안의 이름을 참조한다`() {
        let colorNames = Set(ColorToken.all.map(\.name))
        for token in SemanticColorToken.all {
            #expect(
                colorNames.contains(token.colorToken.name),
                "\(token.name)이 참조하는 \(token.colorToken.name)이 색상 토큰에 없다",
            )
        }
    }

    @Test
    func `진행 바 역할 토큰은 트랙과 채움 원시 색상을 참조한다`() {
        #expect(SemanticColorToken.progressTrack.colorToken == .grey500)
        #expect(SemanticColorToken.progressFill.colorToken == .blue200)
        #expect(SemanticColorToken.all.contains(.progressTrack))
        #expect(SemanticColorToken.all.contains(.progressFill))
    }

    @Test
    func `역할 색상 토큰 총 개수는 11개다`() {
        #expect(SemanticColorToken.all.count == 11)
    }

}
