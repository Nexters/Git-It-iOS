import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("UIComponent 직접 입력 공개 계약")
struct ComponentDirectInputContractTests {

    // MARK: Internal

    @Test
    func `모든 public component는 ViewModel 없이 직접 입력으로 생성한다`() {
        let menuItem = ActionMenu.Item(
            id: "delete",
            title: "삭제",
            accessibilityLabel: "프로젝트 삭제",
        )
        let selectionItem = SelectionCardList.Item(
            id: "beginner",
            title: "초급",
            supportingText: "기초를 학습합니다",
        )

        _ = ActionButton(title: "시작", style: .primary, size: .medium, isEnabled: true)
        _ = ContinuousProgressBar(progress: 0.5)
        _ = IconGlassButton(symbol: "chevron.left", label: "뒤로", style: .neutral, size: .small)
        _ = IconPlainButton(symbol: "ic-play-1", label: "시작")
        _ = ProgressSegments(completed: 2, total: 5)
        _ = ResourceAnimation(asset: .generalLoading)
        _ = ResourceImage(asset: .illust(.knowledgeBasic))
        _ = ScreenEdgeScrim.top()
        _ = StyledText(text: "직접 입력", style: .body1)
        _ = TagBadge(text: "진행 중", style: .accent)
        _ = ActionMenu(items: [menuItem]) { _ in }
        _ = BottomActionBar { EmptyView() }
        _ = EmptyState(title: "비어 있음", message: "새 항목을 추가하세요") { EmptyView() }
        _ = HomeProjectCard(title: "Git It", technologies: "Swift", progress: 0.5, currentSet: 1, setTitle: "1세트", variant: .purple)
        _ = OnboardingMockup(page: 1)
        _ = ProjectRow(name: "Git It", supportingText: "Swift", progress: 0.5, currentSet: 1, setTitle: "1세트") { EmptyView() }
        _ = SavedQuestionCard(metadata: "오늘", prompt: "질문", actionTitle: "답변") { }
        _ = ScreenContainer { EmptyView() }
        _ = ScreenHeader(title: "제목")
        _ = SelectionCard(title: "선택", isSelected: true)
        _ = SelectionCardList(items: [selectionItem]) { _ in }
        _ = SheetSurface { EmptyView() }
        _ = TabShell(selected: FixtureTab.home, onSelect: { _ in }) { EmptyView() }
    }

    @Test
    func `직접 입력 API는 기본값을 제공한다`() {
        _ = ActionButton(title: "기본 버튼")
        _ = IconGlassButton(symbol: "xmark", label: "닫기")
        _ = ResourceImage(asset: .icon(.user))
        _ = TagBadge(text: "기본")
    }

    // MARK: Private

    private enum FixtureTab: String, CaseIterable, TabShellItem {
        case home

        var id: String {
            rawValue
        }

        var tabTitle: String {
            "홈"
        }

        var tabSystemImage: String {
            "ic-home"
        }
    }

}
