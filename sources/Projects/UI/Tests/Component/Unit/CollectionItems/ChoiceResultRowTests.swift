import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("ChoiceResultRow 계약")
struct ChoiceResultRowTests {
    @Test
    func `판정은 값으로, 펼침 여부는 Binding으로 받는다`() {
        _ = ChoiceResultRow(
            displayModel: .init(
                text: "본문",
                explanation: "해설",
            ),
            judgement: .correct,
            isExpanded: .constant(false),
        )
        _ = ChoiceResultRow(
            displayModel: .init(
                text: "본문",
                explanation: "해설",
            ),
            judgement: .incorrect,
            isExpanded: .constant(true),
        )
    }

    @Test
    func `펼침 여부를 State로 보관하지 않고 Binding으로 참조한다`() {
        let row = ChoiceResultRow(
            displayModel: .init(
                text: "본문",
                explanation: "해설",
            ),
            judgement: .correct,
            isExpanded: .constant(false),
        )
        let children = Mirror(reflecting: row).children
        let stateProperties = children.filter {
            String(describing: type(of: $0.value)).hasPrefix("State<")
        }

        #expect(stateProperties.isEmpty)
        #expect(children.first { $0.label == "_isExpanded" }?.value is Binding<Bool>)
    }

    @Test
    func `행을 탭하면 펼침 여부 Binding을 반전한다`() {
        var isExpanded = false
        let row = ChoiceResultRow(
            displayModel: .init(
                text: "본문",
                explanation: "해설",
            ),
            judgement: .correct,
            isExpanded: Binding(
                get: { isExpanded },
                set: { isExpanded = $0 },
            ),
        )

        row.toggle()

        #expect(isExpanded)
    }

    @Test
    func `접근성 라벨에 판정을 접미로 붙인다`() {
        #expect(
            ChoiceResultRow.accessibilityLabel(
                text: "본문",
                judgement: .correct,
            ) == "본문, 정답"
        )
        #expect(
            ChoiceResultRow.accessibilityLabel(
                text: "본문",
                judgement: .incorrect,
            ) == "본문, 오답"
        )
    }

    @Test
    func `판정별 배경은 색 토큰을 참조한다`() {
        #expect(ChoiceResultRow.Judgement.correct.backgroundColor == ColorToken.correct)
        #expect(ChoiceResultRow.Judgement.incorrect.backgroundColor == ColorToken.incorrect)
    }
}
