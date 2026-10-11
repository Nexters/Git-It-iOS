import SwiftUI
import Testing

@testable import UIComponent

@Suite("PushedScreenOverlay 상태 선언")
@MainActor
struct PushedScreenOverlayTests {

    // MARK: Internal

    @Test
    func `표시 여부를 선언하지 않으면 화면을 띄우지 않는다`() {
        #expect(storedValue(of: PushedScreenOverlay { EmptyView() }) == false)
    }

    @Test
    func `presented로 표시를 선언한다`() {
        #expect(storedValue(of: PushedScreenOverlay { EmptyView() }.presented(true)) == true)
    }

    // MARK: Private

    private func storedValue(of subject: some View) -> Bool? {
        Mirror(reflecting: subject).descendant("isPresented") as? Bool
    }

}
