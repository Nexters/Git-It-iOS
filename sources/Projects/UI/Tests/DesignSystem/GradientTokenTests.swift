import Testing

@testable import DesignSystem

@Suite("GradientToken")
struct GradientTokenTests {

    @Test
    func `기존 그라데이션 3종의 정지점 색상과 불투명도가 유지된다`() {
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
            #expect(token?.stops.first?.opacity == 1)
            #expect(token?.stops.last?.hex == endHex)
            #expect(token?.stops.last?.position == 1)
            #expect(token?.stops.last?.opacity == 1)
        }
    }

    @Test
    func `기존 세 토큰 모두 위→아래 좌표비율(0.5,0)→(0.5,1)을 유지한다`() {
        for token in [GradientToken.gradient1, .gradient2, .gradient3] {
            #expect(token.start.x == 0.5)
            #expect(token.start.y == 0)
            #expect(token.end.x == 0.5)
            #expect(token.end.y == 1)
        }
    }

    @Test
    func `정지점 불투명도 기본값은 1이다`() {
        let stop = GradientToken.Stop(
            position: 0.5,
            hex: "#FFFFFF",
        )

        #expect(stop.opacity == 1)
    }

    @Test
    func `상단 edge scrim은 아래에서 위로 향하며 Figma 정지점을 갖는다`() {
        let token = GradientToken.topEdgeScrim

        #expect(token.start == .init(x: 0.5, y: 1))
        #expect(token.end == .init(x: 0.5, y: 0))
        #expect(token.stops.map(\.position) == [0, 0.25])
        #expect(token.stops.map(\.hex) == ["#141414", "#141414"])
        #expect(token.stops.map(\.opacity) == [0, 0.5])
        #expect(GradientToken.all.contains(token))
    }

    @Test
    func `하단 edge scrim은 위에서 아래로 향하며 Figma 정지점을 갖는다`() {
        let token = GradientToken.bottomEdgeScrim

        #expect(token.start == .init(x: 0.5, y: 0))
        #expect(token.end == .init(x: 0.5, y: 1))
        #expect(token.stops.map(\.position) == [0.7, 1])
        #expect(token.stops.map(\.hex) == ["#141414", "#141414"])
        #expect(token.stops.map(\.opacity) == [0.6, 0])
        #expect(GradientToken.all.contains(token))
    }

    @Test
    func `그라데이션 토큰 총 개수는 5개다`() {
        #expect(GradientToken.all.count == 5)
    }

}
