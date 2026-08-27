import Testing

@testable import DesignSystem

@Suite("DesignTokenSet 무결성")
struct DesignTokenSetIntegrityTests {

    @Test
    func `현재 토큰 집합은 화면 렌더링 없이 검증 오류가 0건이다`() {
        let errors = DesignTokenSet.current.validate()
        #expect(errors.isEmpty, "\(errors)")
    }

    @Test
    func `카테고리 내부에 같은 이름의 토큰이 있으면 중복으로 감지된다`() {
        let duplicated = DesignTokenSet(
            colors: [ColorToken.blue500, ColorToken.blue500],
            semanticColors: [],
            gradients: [],
            fontFamilies: [],
            textStyles: [],
            layouts: [],
            opacities: [],
            cornerRadii: [],
            borders: [],
            effects: [],
            controlSizes: [],
        )
        let errors = duplicated.validate()
        #expect(errors.contains {
            if
                case .duplicateName(
                    _,
                    "Blue500",
                ) = $0
            {
                true
            } else {
                false
            }
        })
    }

    @Test
    func `그라데이션 정지점 위치가 0~1 범위를 벗어나면 값 범위 오류로 감지된다`() {
        let invalidGradient = GradientToken(
            name: "Invalid Gradient",
            start: .init(
                x: 0.5,
                y: 0,
            ),
            end: .init(
                x: 0.5,
                y: 1,
            ),
            stops: [
                .init(
                    position: -0.1,
                    hex: "#000000",
                ),
                .init(
                    position: 1,
                    hex: "#FFFFFF",
                ),
            ],
        )
        let invalidSet = DesignTokenSet(
            colors: [],
            semanticColors: [],
            gradients: [invalidGradient],
            fontFamilies: [],
            textStyles: [],
            layouts: [],
            opacities: [],
            cornerRadii: [],
            borders: [],
            effects: [],
            controlSizes: [],
        )
        let errors = invalidSet.validate()
        #expect(errors.contains {
            if case .outOfRange = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test
    func `제어 크기 값이 44 미만이면 값 범위 오류로 감지된다`() {
        let invalidSet = DesignTokenSet(
            colors: [],
            semanticColors: [],
            gradients: [],
            fontFamilies: [],
            textStyles: [],
            layouts: [],
            opacities: [],
            cornerRadii: [],
            borders: [],
            effects: [],
            controlSizes: [ControlSizeToken(
                name: "TooSmall",
                value: 32,
            )],
        )
        let errors = invalidSet.validate()
        #expect(errors.contains {
            if case .outOfRange = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test
    func `SemanticColorToken이 존재하지 않는 색상 이름을 참조하면 참조 무결성 오류로 감지된다`() {
        let invalidSet = DesignTokenSet(
            colors: [ColorToken.blue500],
            semanticColors: [SemanticColorToken(
                name: "Broken",
                colorToken: ColorToken(
                    name: "NotARealColor",
                    group: .state,
                    hex: "#000000",
                ),
            )],
            gradients: [],
            fontFamilies: [],
            textStyles: [],
            layouts: [],
            opacities: [],
            cornerRadii: [],
            borders: [],
            effects: [],
            controlSizes: [],
        )
        let errors = invalidSet.validate()
        #expect(errors.contains {
            if case .danglingReference = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test
    func `BorderToken이 존재하지 않는 색상 이름을 참조하면 참조 무결성 오류로 감지된다`() {
        let invalidSet = DesignTokenSet(
            colors: [ColorToken.blue500],
            semanticColors: [],
            gradients: [],
            fontFamilies: [],
            textStyles: [],
            layouts: [],
            opacities: [],
            cornerRadii: [],
            borders: [BorderToken(
                name: "Broken",
                width: 1,
                colorToken: ColorToken(
                    name: "NotARealColor",
                    group: .state,
                    hex: "#000000",
                ),
            )],
            effects: [],
            controlSizes: [],
        )
        let errors = invalidSet.validate()
        #expect(errors.contains {
            if case .danglingReference = $0 {
                true
            } else {
                false
            }
        })
    }

}
