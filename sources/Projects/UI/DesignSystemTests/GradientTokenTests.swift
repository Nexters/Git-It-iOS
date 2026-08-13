import Testing

@testable import DesignSystem

@Suite("GradientToken")
struct GradientTokenTests {

    @Test
    func `그라데이션 3종의 정지점 색상이 명세 값과 일치한다`() {
        let expected: [(String, String, String)] = [
            ("Gradient 1", "#3B3749", "#56718A"),
            ("Gradient 2", "#141414", "#A5C4F0"),
            ("Gradient 3", "#82ACE5", "#D5E7FE"),
        ]
        for (name, startHex, endHex) in expected {
            let token = GradientToken.all.first { $0.name == name }
            #expect(token != nil, "\(name) 토큰이 존재해야 한다")
            #expect(token?.stops.count == 2)
            #expect(token?.stops.first?.hex == startHex)
            #expect(token?.stops.first?.position == 0)
            #expect(token?.stops.last?.hex == endHex)
            #expect(token?.stops.last?.position == 1)
        }
    }

    @Test
    func `세 토큰 모두 위→아래 좌표비율(0.5,0)→(0.5,1)을 갖는다`() {
        for token in GradientToken.all {
            #expect(token.start.x == 0.5)
            #expect(token.start.y == 0)
            #expect(token.end.x == 0.5)
            #expect(token.end.y == 1)
        }
    }

    @Test
    func `그라데이션 토큰 총 개수는 3개다`() {
        #expect(GradientToken.all.count == 3)
    }

}
