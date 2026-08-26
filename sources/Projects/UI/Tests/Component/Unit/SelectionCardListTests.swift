import DesignSystem
import Testing

@testable import UIComponent

@Suite("SelectionCardList 계약")
struct SelectionCardListTests {
    @Test
    func `onSelect callback은 선택한 item id를 그대로 전달한다`() {
        var selectedID: String?
        let onSelect: (String) -> Void = { id in selectedID = id }

        let viewModel = SelectionCardList.ViewModel(items: [
            .init(id: "concept", title: "기술 개념은 알아요", supportingText: "흐름 중심 학습"),
            .init(id: "code", title: "일부 코드를 봤어요", supportingText: "구현 의도까지 포함"),
        ])
        _ = SelectionCardList(viewModel: viewModel, onSelect: onSelect)

        onSelect("code")
        #expect(selectedID == "code")
    }

    @Test
    func `isSelected가 true인 item만 선택 상태이고 나머지는 비선택 상태다`() {
        let viewModel = SelectionCardList.ViewModel(items: [
            .init(id: "concept", title: "기술 개념은 알아요", supportingText: "흐름 중심 학습", isSelected: false),
            .init(id: "code", title: "일부 코드를 봤어요", supportingText: "구현 의도까지 포함", isSelected: true),
        ])

        #expect(viewModel.items[0].isSelected == false)
        #expect(viewModel.items[1].isSelected == true)
    }

    @Test
    func `isSelected 기본값은 false다`() {
        let item = SelectionCardList.Item(id: "concept", title: "기술 개념은 알아요", supportingText: "흐름 중심 학습")

        #expect(item.isSelected == false)
    }

    @Test
    func `불변 ViewModel로 생성하고 onSelect 기본값은 생략할 수 있다`() {
        let viewModel = SelectionCardList.ViewModel(items: [
            .init(id: "concept", title: "기술 개념은 알아요", supportingText: "흐름 중심 학습")
        ])

        _ = SelectionCardList(viewModel: viewModel)
        #expect(viewModel.items.count == 1)
    }
}
