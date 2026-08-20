import Testing

@testable import DesignSystem

@Suite("ColorToken")
struct ColorTokenTests {

    @Test
    func `Figma 색 변수 25개의 이름 hex 불투명도가 전부 일치한다`() {
        let expected: [(
            figmaName: String,
            tokenName: String,
            group: ColorToken.Group,
            hex: String,
            opacity: Double,
        )] = [
            ("Blue/Blue500", "Blue500", .blue, "#2F3853", 1),
            ("Blue/Blue400", "Blue400", .blue, "#506381", 1),
            ("Blue/Blue300", "Blue300", .blue, "#7E94BB", 1),
            ("Blue/Blue200", "Blue200", .blue, "#8BB5EF", 1),
            ("Blue/Blue100", "Blue100", .blue, "#B9D6FE", 1),
            ("Purple/Purple500", "Purple500", .purple, "#3B3749", 1),
            ("Purple/Purple400", "Purple400", .purple, "#585B6F", 1),
            ("Purple/Purple300", "Purple300", .purple, "#898DA6", 1),
            ("Purple/Purple200", "Purple200", .purple, "#A4A9C7", 1),
            ("Purple/Purple100", "Purple100", .purple, "#BDC2DC", 1),
            ("Grey/Grey700", "Grey700", .grey, "#141414", 1),
            ("Grey/Grey600", "Grey600", .grey, "#242425", 1),
            ("Grey/Grey500", "Grey500", .grey, "#3B3B3B", 1),
            ("Grey/Grey400", "Grey400", .grey, "#919191", 1),
            ("Grey/Grey300", "Grey300", .grey, "#BCBCBC", 1),
            ("Grey/Grey200", "Grey200", .grey, "#ECECEC", 1),
            ("Grey/Grey100", "Grey100", .grey, "#FFFFFF", 1),
            ("Opacity/white 5", "white 5", .opacity, "#FFFFFF", 0.05),
            ("Opacity/white 15", "white 15", .opacity, "#FFFFFF", 0.15),
            ("Opacity/white 30", "white 30", .opacity, "#FFFFFF", 0.3),
            ("Opacity/white 70", "white 70", .opacity, "#FFFFFF", 0.7),
            ("Opacity/Black 70", "Black 70", .opacity, "#000000", 0.7),
            ("State/Error", "Error", .state, "#FF3721", 1),
            ("State/Caution", "Caution", .state, "#ECBD23", 1),
            ("State/Success", "Success", .state, "#249900", 1),
        ]

        #expect(expected.count == 25)
        for expectation in expected {
            let token = ColorToken.all.first {
                $0.name == expectation.tokenName && $0.group == expectation.group
            }
            #expect(token != nil, "\(expectation.figmaName)에 대응하는 토큰이 존재해야 한다")
            #expect(token.map { "\($0.group.rawValue)/\($0.name)" } == expectation.figmaName)
            #expect(token?.hex == expectation.hex)
            #expect(
                token?.opacityPercent.map { $0 / 100 } ?? 1 == expectation.opacity,
                "\(expectation.figmaName)의 불투명도가 일치해야 한다",
            )
        }
    }

    @Test
    func `저장소 전용 토큰 4종은 Figma 색 변수 집합과 분리된다`() {
        let expected: [(
            name: String,
            group: ColorToken.Group,
            hex: String,
            opacity: Double,
        )] = [
            ("Clear", .opacity, "#000000", 0),
            ("White", .opacity, "#FFFFFF", 1),
            ("Correct", .state, "#3E85FF", 1),
            ("Incorrect", .state, "#FF5656", 1),
        ]
        let repositoryOnlyNames = Set(expected.map(\.name))
        let figmaTokens = ColorToken.all.filter { !repositoryOnlyNames.contains($0.name) }

        #expect(figmaTokens.count == 25)
        #expect(Set(ColorToken.all.filter { repositoryOnlyNames.contains($0.name) }.map(\.name)) == repositoryOnlyNames)
        for expectation in expected {
            let token = ColorToken.all.first { $0.name == expectation.name }
            #expect(token?.group == expectation.group)
            #expect(token?.hex == expectation.hex)
            #expect(token?.opacityPercent.map { $0 / 100 } ?? 1 == expectation.opacity)
        }
    }

    @Test
    func `색상 토큰 총 개수는 Figma 25종과 저장소 전용 4종을 합한 29개다`() {
        #expect(ColorToken.all.count == 29)
    }

}
