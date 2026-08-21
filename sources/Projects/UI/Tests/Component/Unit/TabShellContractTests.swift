import SwiftUI
import Testing

@testable import UIComponent

@Suite("TabShell controlled selection 계약")
struct TabShellContractTests {

    // MARK: Internal

    @Test
    func `선택값과 selection callback을 직접 입력으로 받는다`() {
        var selectedItems = [FixtureTab]()

        _ = TabShell(selected: FixtureTab.home, onSelect: { selectedItems.append($0) }) {
            EmptyView()
        }

        #expect(selectedItems.isEmpty)
    }

    @Test
    func `production selection은 Binding constant가 아닌 controlled callback으로 표현한다`() {
        _ = TabShell(selected: FixtureTab.settings, onSelect: { _ in }) {
            Text("선택 콘텐츠")
        }
    }

    // MARK: Private

    private enum FixtureTab: String, CaseIterable, TabShellItem {
        case home
        case settings

        var id: String {
            rawValue
        }

        var tabTitle: String {
            rawValue
        }

        var tabSystemImage: String {
            "ic-home"
        }
    }

}
