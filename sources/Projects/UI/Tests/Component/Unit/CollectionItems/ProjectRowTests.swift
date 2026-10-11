import SwiftUI
import Testing

@testable import UIComponent

@Suite("ProjectRow 상태 선언")
@MainActor
struct ProjectRowTests {

    // MARK: Internal

    @Test
    func `삭제 모드를 선언하지 않으면 일반 행으로 그린다`() {
        #expect(storedValue(of: ProjectRow(displayModel: displayModel) { EmptyView() }) == false)
    }

    @Test
    func `deleting으로 삭제 모드를 선언한다`() {
        #expect(storedValue(of: ProjectRow(displayModel: displayModel) { EmptyView() }.deleting(true)) == true)
    }

    // MARK: Private

    private let displayModel = ProjectRow<EmptyView>.DisplayModel(
        name: "Git It iOS",
        supportingText: "Swift · SwiftUI",
        progress: 0.4,
        currentSet: 1,
        setTitle: "Presentation 구조",
    )

    private func storedValue(of subject: some View) -> Bool? {
        Mirror(reflecting: subject).descendant("isDeleting") as? Bool
    }

}
