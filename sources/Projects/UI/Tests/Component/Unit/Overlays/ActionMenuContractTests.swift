import Testing

@testable import UIComponent

@Suite("ActionMenu 계약")
struct ActionMenuContractTests {
    @Test
    func `메뉴 표면은 폭 160과 4pt 컨테이너 여백을 보존한다`() {
        #expect(ActionMenu.menuWidth == 160)
        #expect(ActionMenu.containerPadding == 4)
    }

    @Test
    func `행은 좌우 10 상 9 하 10 여백을 보존한다`() {
        #expect(ActionMenu.rowHorizontalPadding == 10)
        #expect(ActionMenu.rowTopPadding == 9)
        #expect(ActionMenu.rowBottomPadding == 10)
    }

    @Test
    func `항목은 선택 동작을 스스로 소유하고 선택하면 그 동작만 실행한다`() {
        var selectedIDs = [String]()
        let items = ["savedQuestions", "delete"].map { id in
            ActionMenu.Item(id: id, title: id, accessibilityLabel: id, onSelect: { selectedIDs.append(id) })
        }
        _ = ActionMenu(items: items)

        items[1].onSelect()

        #expect(selectedIDs == ["delete"])
    }

    @Test
    func `항목은 화면 문맥 없이 사용자 목적을 설명하는 VoiceOver 라벨을 소유한다`() {
        let item = ActionMenu.Item(
            id: "delete",
            title: "프로젝트 삭제",
            accessibilityLabel: "학습 프로젝트 삭제 모드 열기",
        )

        #expect(item.title == "프로젝트 삭제")
        #expect(item.accessibilityLabel == "학습 프로젝트 삭제 모드 열기")
    }

    @Test
    func `역할을 지정하지 않으면 일반 행으로 취급한다`() {
        let item = ActionMenu.Item(
            id: "close",
            title: "메뉴 닫기",
            accessibilityLabel: "메뉴 닫기",
        )

        #expect(item.role == .normal)
    }

    @Test
    func `파괴적 역할을 명시적으로 지정할 수 있다`() {
        let item = ActionMenu.Item(
            id: "delete",
            title: "삭제하기",
            role: .destructive,
            accessibilityLabel: "프로젝트 삭제",
        )

        #expect(item.role == .destructive)
    }
}
