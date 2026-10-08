import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("SelectionCardList 계약")
struct SelectionCardListTests {
    @Test
    func `카드를 선택하면 선택한 item id를 selection에 쓴다`() {
        var selectedID: String?
        let selection = Binding<String?>(
            get: { selectedID },
            set: { selectedID = $0 },
        )

        let items: [SelectionCardList.Item] = [
            .init(
                id: "concept",
                displayModel: .init(
                    title: "기술 개념은 알아요",
                    supportingText: "흐름 중심 학습",
                ),
            ),
            .init(
                id: "code",
                displayModel: .init(
                    title: "일부 코드를 봤어요",
                    supportingText: "구현 의도까지 포함",
                ),
            ),
        ]
        let list = SelectionCardList(
            items: items,
            selection: selection,
        )

        list.select(items[1])
        #expect(selectedID == "code")
    }

    @Test
    func `selection과 id가 같은 item만 선택 상태이고 나머지는 비선택 상태다`() {
        let items: [SelectionCardList.Item] = [
            .init(
                id: "concept",
                displayModel: .init(
                    title: "기술 개념은 알아요",
                    supportingText: "흐름 중심 학습",
                ),
            ),
            .init(
                id: "code",
                displayModel: .init(
                    title: "일부 코드를 봤어요",
                    supportingText: "구현 의도까지 포함",
                ),
            ),
        ]
        let list = SelectionCardList(
            items: items,
            selection: .constant("code"),
        )

        #expect(list.isSelected(items[0]) == false)
        #expect(list.isSelected(items[1]) == true)
    }

    @Test
    func `selection이 nil이면 모든 item이 비선택 상태다`() {
        let item = SelectionCardList.Item(
            id: "concept",
            displayModel: .init(
                title: "기술 개념은 알아요",
                supportingText: "흐름 중심 학습",
            ),
        )
        let list = SelectionCardList(
            items: [item],
            selection: .constant(nil),
        )

        #expect(list.isSelected(item) == false)
    }

    @Test
    func `각 item은 자신에게 지정된 illust를 유지한다`() {
        let items: [SelectionCardList.Item] = [
            .init(
                id: "basic",
                displayModel: .init(
                    title: "기초",
                    illust: .knowledgeBasic,
                ),
            ),
            .init(
                id: "advanced",
                displayModel: .init(
                    title: "심화",
                    illust: .knowledgeAdvanced,
                ),
            ),
        ]

        #expect(items[0].displayModel.illust == .knowledgeBasic)
        #expect(items[1].displayModel.illust == .knowledgeAdvanced)
    }
}
