import Testing

@testable import UIComponent

@Suite("LabeledCard 계약")
struct LabeledCardTests {

    @Test
    func `강조와 중립 두 시각 변형을 팩토리로 생성한다`() {
        _ = LabeledCard.accent(label: "AI 해설", text: "State는 값 타입 소유에 씁니다.")
        _ = LabeledCard.neutral(label: "나의 답안", text: "State는 값 타입을 소유할 때 사용합니다.")
    }

    @Test
    func `라벨과 본문을 스스로 보관하지 않는다`() {
        let mirror = Mirror(reflecting: LabeledCard.accent(label: "AI 해설", text: "설명"))
        let stateProperties = mirror.children.filter {
            ($0.label ?? "").hasPrefix("_")
        }

        #expect(stateProperties.isEmpty)
    }

}
