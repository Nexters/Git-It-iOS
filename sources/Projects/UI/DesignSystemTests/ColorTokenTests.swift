import Testing

@testable import DesignSystem

@Suite("ColorToken")
struct ColorTokenTests {

    @Test
    func `Blue 그룹 5종이 명세 값과 일치한다`() {
        let expected: [(String, String)] = [
            ("Blue500", "#2F3853"),
            ("Blue400", "#506381"),
            ("Blue300", "#7E94BB"),
            ("Blue200", "#8BB5EF"),
            ("Blue100", "#B9D6FE"),
        ]
        for (name, hex) in expected {
            let token = ColorToken.all.first { $0.name == name }
            #expect(token != nil, "\(name) 토큰이 존재해야 한다")
            #expect(token?.hex == hex)
            #expect(token?.group == .blue)
        }
    }

    @Test
    func `Purple 그룹 5종이 명세 값과 일치한다`() {
        let expected: [(String, String)] = [
            ("Purple500", "#3B3749"),
            ("Purple400", "#585B6F"),
            ("Purple300", "#898DA6"),
            ("Purple200", "#A4A9C7"),
            ("Purple100", "#BDC2DC"),
        ]
        for (name, hex) in expected {
            let token = ColorToken.all.first { $0.name == name }
            #expect(token?.hex == hex)
            #expect(token?.group == .purple)
        }
    }

    @Test
    func `Grey 그룹 7종이 명세 값과 일치한다`() {
        let expected: [(String, String)] = [
            ("Grey700", "#141414"),
            ("Grey600", "#242425"),
            ("Grey500", "#3B3B3B"),
            ("Grey400", "#919191"),
            ("Grey300", "#BCBCBC"),
            ("Grey200", "#ECECEC"),
            ("Grey100", "#FFFFFF"),
        ]
        for (name, hex) in expected {
            let token = ColorToken.all.first { $0.name == name }
            #expect(token?.hex == hex)
            #expect(token?.group == .grey)
        }
    }

    @Test
    func `불투명도 포함 흰색·검정 토큰 4종이 명세 값과 일치한다`() {
        let expected: [(String, String, Double)] = [
            ("white 15", "#FFFFFF", 15),
            ("white 30", "#FFFFFF", 30),
            ("white 70", "#FFFFFF", 70),
            ("Black 70", "#000000", 70),
        ]
        for (name, hex, opacity) in expected {
            let token = ColorToken.all.first { $0.name == name }
            #expect(token?.hex == hex)
            #expect(token?.opacityPercent == opacity)
            #expect(token?.group == .opacity)
        }
    }

    @Test
    func `상태 색상 토큰 3종이 명세 값과 일치한다`() {
        let expected: [(String, String)] = [
            ("Error", "#FF3721"),
            ("Caution", "#ECBD23"),
            ("Success", "#249900"),
        ]
        for (name, hex) in expected {
            let token = ColorToken.all.first { $0.name == name }
            #expect(token?.hex == hex)
            #expect(token?.group == .state)
        }
    }

    @Test
    func `색상 토큰 총 개수는 24개다`() {
        #expect(ColorToken.all.count == 24)
    }

}
