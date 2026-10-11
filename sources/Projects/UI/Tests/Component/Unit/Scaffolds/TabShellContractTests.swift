import SwiftUI
import Testing

@testable import UIComponent

@Suite("TabShell 계약")
struct TabShellContractTests {
    @Test
    func `사용 가능 여부를 지정하지 않으면 모든 탭 항목이 활성이다`() {
        let shell = TabShell(selected: .constant(TabShellPreviewItem.home)) { _ in
            EmptyView()
        }

        #expect(TabShellPreviewItem.allCases.allSatisfy { shell.isEnabled($0) })
    }

    @Test
    func `지정한 판정 함수의 항목별 결과를 그대로 따른다`() {
        let shell = TabShell(
            selected: .constant(TabShellPreviewItem.home),
            isEnabled: { $0 != .project && $0 != .saved },
        ) { _ in
            EmptyView()
        }

        #expect(shell.isEnabled(.home))
        #expect(!shell.isEnabled(.project))
        #expect(!shell.isEnabled(.saved))
        #expect(shell.isEnabled(.profile))
    }
}
