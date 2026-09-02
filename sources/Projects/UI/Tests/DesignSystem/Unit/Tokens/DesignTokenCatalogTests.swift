import Testing

@testable import DesignSystem

@Suite("디자인 토큰 카탈로그")
struct DesignTokenCatalogTests {
    @Test
    func `신설 카테고리는 규격 개수만큼 토큰을 노출한다`() {
        #expect(BorderToken.all.count == 5)
        #expect(OpacityToken.all.count == 6)
        #expect(EffectToken.all.count == 2)
    }

    @Test
    func `빈 배열인 토큰 카테고리가 하나도 없다`() {
        let set = DesignTokenSet.current
        let counts = [
            set.colors.count,
            set.semanticColors.count,
            set.gradients.count,
            set.fontFamilies.count,
            set.textStyles.count,
            set.layouts.count,
            set.opacities.count,
            set.cornerRadii.count,
            set.borders.count,
            set.effects.count,
            set.controlSizes.count,
        ]

        #expect(counts.allSatisfy { $0 > 0 })
    }

    @Test
    func `시트 그림자는 두 레이어를 가까운 것부터 담는다`() {
        let layers = EffectToken.sheetElevation.layers

        #expect(layers.count == 2)
        #expect(layers.first?.colorToken == ColorToken.black45)
        #expect(layers.first?.blur == 6)
        #expect(layers.last?.colorToken == ColorToken.black35)
        #expect(layers.last?.blur == 34)
    }

    @Test
    func `카드 그림자는 한 레이어에 spread를 갖는다`() {
        let layers = EffectToken.cardElevation.layers

        #expect(layers.count == 1)
        #expect(layers.first?.colorToken == ColorToken.black25)
        #expect(layers.first?.offset == EffectToken.Offset(x: 4, y: 4))
        #expect(layers.first?.blur == 15)
        #expect(layers.first?.spread == 10)
    }

    @Test
    func `테두리 토큰은 규격 이름과 굵기를 그대로 노출한다`() {
        let widths = Dictionary(
            uniqueKeysWithValues: BorderToken.all.map { ($0.name, $0.width) }
        )

        #expect(widths["Default"] == 1)
        #expect(widths["Focus"] == 1)
        #expect(widths["Highlight"] == 1)
        #expect(widths["Error"] == 1)
        #expect(widths["LoadingTrack"] == 4)
    }

    @Test
    func `불투명도 토큰은 규격 이름과 값을 그대로 노출한다`() {
        let percents = Dictionary(
            uniqueKeysWithValues: OpacityToken.all.map { ($0.name, $0.percent) }
        )

        #expect(percents["SubtleSurface"] == 5)
        #expect(percents["TabSurface"] == 10)
        #expect(percents["Track"] == 15)
        #expect(percents["Border"] == 24)
        #expect(percents["Disabled"] == 30)
        #expect(percents["Scrim"] == 70)
    }

    @Test
    func `규격이 추가한 원시 색과 역할 색이 모두 존재한다`() {
        let colorNames = Set(ColorToken.all.map(\.name))
        let semanticNames = Set(SemanticColorToken.all.map(\.name))

        #expect(colorNames.isSuperset(of: [
            "Black25",
            "Black35",
            "Black45",
            "Blue300Alpha10",
            "Blue300Alpha24",
        ]))
        #expect(semanticNames.isSuperset(of: [
            "SelectedSurface",
            "Grabber",
            "DisabledText",
        ]))
    }

    @Test
    func `규격이 추가한 간격 반경 크기 토큰이 모두 존재한다`() {
        let layouts = Dictionary(uniqueKeysWithValues: LayoutToken.all.map { ($0.name, $0.value) })

        #expect(layouts["CardHorizontalPadding"] == 18)
        #expect(layouts["CardTopPadding"] == 14)
        #expect(layouts["IconSpacing"] == 6)
        #expect(layouts["TightSpacing"] == 4)
        #expect(CornerRadiusToken.all.contains { $0.name == "Pill" && $0.value == 999 })
        #expect(ControlSizeToken.all.contains { $0.name == "MinimumTouch" && $0.value == 44 })
    }

    @Test
    func `그라디언트 목록은 규격 5종과 일치한다`() {
        #expect(GradientToken.all.map(\.name) == [
            "Gradient 1",
            "Gradient 2",
            "Gradient 3",
            "TopEdgeScrim",
            "BottomEdgeScrim",
        ])
    }
}
