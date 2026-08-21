import Testing

@testable import UIComponent

@Suite("ActionMenu 계약")
struct ActionMenuContractTests {
    @Test
    func `두 항목은 내부 가용 높이를 채워 181x126pt와 내부 여백을 보존한다`() {
        #expect(ActionMenu.menuWidth == 181)
        #expect(ActionMenu.menuHeight == 126)
        #expect(ActionMenu.topPadding == 8)
        #expect(ActionMenu.horizontalPadding == 14)
        #expect(ActionMenu.bottomPadding == 9)
        #expect(ActionMenu.availableContentHeight == 109)
        #expect(ActionMenu.itemMinimumHeight(itemCount: 2) == 54.5)
        #expect(ActionMenu.contentMinimumHeight(itemCount: 2) == 109)
        #expect(ActionMenu.menuMinimumHeight(itemCount: 2) == 126)
    }

    @Test
    func `항목 수가 늘면 각 항목의 44pt 터치 영역을 보존하며 메뉴가 확장된다`() {
        #expect(ActionMenu.itemMinimumHeight(itemCount: 3) == 44)
        #expect(ActionMenu.contentMinimumHeight(itemCount: 3) == 132)
        #expect(ActionMenu.menuMinimumHeight(itemCount: 3) == 149)
    }

    @Test
    func `불변 항목과 선택 콜백을 직접 초기화 인자로 받는다`() {
        let item = ActionMenu.Item(
            id: "delete",
            title: "프로젝트 삭제",
            accessibilityLabel: "학습 프로젝트 삭제 모드 열기",
        )
        _ = ActionMenu(
            items: [item],
            onSelect: { _ in },
        )
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
}
