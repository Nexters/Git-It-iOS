import SwiftUI
import Testing

@testable import UIComponent

@Suite("SheetSurface 상태 선언")
@MainActor
struct SheetSurfaceTests {

    // MARK: Internal

    @Test
    func `스크롤 여부를 선언하지 않으면 콘텐츠 높이에 맞춘다`() {
        #expect(storedValue(of: SheetSurface { EmptyView() }) == false)
    }

    @Test
    func `scrollable로 스크롤을 선언한다`() {
        #expect(storedValue(of: SheetSurface { EmptyView() }.scrollable(true)) == true)
    }

    // MARK: Private

    private func storedValue(of subject: some View) -> Bool? {
        Mirror(reflecting: subject).descendant("isScrollable") as? Bool
    }

}
