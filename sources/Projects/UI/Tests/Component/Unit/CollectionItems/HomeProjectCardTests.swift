import Testing

@testable import UIComponent

@Suite("HomeProjectCard 계약")
struct HomeProjectCardTests {
    @Test
    func `currentSetLabel은 원문을 손실 없이 유지한다`() {
        let card = HomeProjectCard(
            title: "Git It iOS",
            technologies: "Swift · SwiftUI",
            progress: 0.4,
            currentSetLabel: "Sprint Beta",
            setTitle: "Presentation 구조",
            variant: .purple,
        )

        #expect(card.displayedCurrentSetLabel == "Sprint Beta")
    }

    @Test
    func `Domain 순서 index는 세 색 variant를 순환한다`() {
        #expect(HomeProjectCard.Variant(index: 0) == .purple)
        #expect(HomeProjectCard.Variant(index: 1) == .lightBlue)
        #expect(HomeProjectCard.Variant(index: 2) == .darkBlue)
        #expect(HomeProjectCard.Variant(index: 3) == .purple)
    }

    @Test
    func `진행률은 0과 1 사이로 제한한다`() {
        #expect(HomeProjectCard.clampedProgress(-0.1) == 0)
        #expect(HomeProjectCard.clampedProgress(0.4) == 0.4)
        #expect(HomeProjectCard.clampedProgress(1.1) == 1)
    }

    @Test
    func `본문 선택과 학습 시작은 서로 다른 callback을 전달한다`() {
        var selectedCount = 0
        var startedCount = 0
        let card = makeCard(
            onSelect: { selectedCount += 1 },
            onStart: { startedCount += 1 },
        )

        card.select()
        #expect(selectedCount == 1)
        #expect(startedCount == 0)

        card.start()
        #expect(selectedCount == 1)
        #expect(startedCount == 1)
    }

    @Test
    func `학습 비활성 상태는 시작 callback을 호출하지 않는다`() {
        var startedCount = 0
        let card = makeCard(
            isLearningEnabled: false,
            onStart: { startedCount += 1 },
        )

        card.start()

        #expect(startedCount == 0)
    }

    @Test
    func `본문과 학습 control은 44pt 최소 터치 영역을 갖는다`() {
        #expect(HomeProjectCard.minimumTouchArea == 44)
    }

    private func makeCard(
        isLearningEnabled: Bool = true,
        onSelect: @escaping () -> Void = { },
        onStart: @escaping () -> Void = { },
    ) -> HomeProjectCard {
        HomeProjectCard(
            title: "Git It iOS",
            technologies: "Swift · SwiftUI",
            progress: 0.4,
            currentSetLabel: "Set 1",
            setTitle: "Presentation 구조",
            variant: .purple,
            isLearningEnabled: isLearningEnabled,
            onSelect: onSelect,
            onStart: onStart,
        )
    }
}
