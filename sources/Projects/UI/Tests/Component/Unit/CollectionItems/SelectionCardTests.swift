import SwiftUI
import Testing

@testable import UIComponent

@Suite("SelectionCard 상태 선언")
@MainActor
struct SelectionCardTests {

    // MARK: Internal

    @Test
    func `선택 여부를 선언하지 않으면 선택되지 않은 카드로 그린다`() {
        #expect(storedValue(of: SelectionCard(displayModel: .init(title: "Front-end"))) == false)
    }

    @Test
    func `selected로 선택을 선언해도 compact 기본 스타일을 유지한다`() {
        let card = SelectionCard(displayModel: .init(title: "Front-end")).selected(true)

        #expect(storedValue(of: card) == true)
        #expect(Mirror(reflecting: card).descendant("style") as? SelectionCard<EmptyView>.Style == .compact)
    }

    // MARK: Private

    private func storedValue(of subject: some View) -> Bool? {
        Mirror(reflecting: subject).descendant("isSelected") as? Bool
    }

}
