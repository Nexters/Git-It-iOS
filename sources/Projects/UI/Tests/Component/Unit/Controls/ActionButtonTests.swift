import SwiftUI
import Testing

@testable import UIComponent

@Suite("ActionButton 상태 선언")
@MainActor
struct ActionButtonTests {

    // MARK: Internal

    @Test
    func `활성 여부를 선언하지 않으면 활성 상태로 그린다`() {
        #expect(storedValue(of: ActionButton(title: "계속하기")) == true)
    }

    @Test
    func `enabled로 비활성을 선언하면 다른 시각 속성과 함께 반영한다`() {
        #expect(storedValue(of: ActionButton(title: "계속하기").style(.secondary).enabled(false)) == false)
    }

    // MARK: Private

    private func storedValue(of subject: some View) -> Bool? {
        Mirror(reflecting: subject).descendant("isEnabled") as? Bool
    }

}
