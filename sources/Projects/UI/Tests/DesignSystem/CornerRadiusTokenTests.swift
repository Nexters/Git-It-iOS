import Testing

@testable import DesignSystem

@Suite("CornerRadiusToken")
struct CornerRadiusTokenTests {

    @Test
    func `모서리 반경 토큰 6종이 명세 값과 일치한다`() {
        let expected: [(String, Double)] = [
            ("Micro", 3),
            ("Compact", 6),
            ("Small", 8),
            ("Medium", 10),
            ("Large", 12),
            ("ExtraLarge", 16),
        ]
        for (name, value) in expected {
            let token = CornerRadiusToken.all.first { $0.name == name }
            #expect(token != nil, "\(name) 토큰이 존재해야 한다")
            #expect(token?.value == value)
        }
    }

    @Test
    func `모서리 반경 토큰 총 개수는 6개다`() {
        #expect(CornerRadiusToken.all.count == 6)
    }

}
