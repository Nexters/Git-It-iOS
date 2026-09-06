import DesignSystem
import Testing

@testable import UIComponent

@Suite("접근성 계약")
struct AccessibilityContractTests {
    @Test
    func `아이콘 전용 버튼은 접근성 라벨을 생략할 수 없다`() {
        _ = IconPlainButton(icon: .play, label: "학습 시작")
        _ = IconGlassButton(icon: .menu, label: "더 보기")
        _ = BookmarkButton(isSaved: false, accessibilityLabel: "저장하기") { }
    }

    @Test
    func `아이콘 전용 버튼의 히트 영역은 최소 터치 크기를 따른다`() {
        #expect(IconGlassButton.Size.small.touchSize == ControlSizeToken.minimumTouch.cgFloatValue)
        #expect(IconGlassButton.Size.medium.touchSize == ControlSizeToken.minimumTouch.cgFloatValue)
    }

    @Test
    func `조작 컴포넌트의 히트 영역은 44 이상이다`() {
        #expect(ControlSizeToken.minimumTouch.value == 44)
        #expect(ActionButton.Size.large.touchHeight >= 44)
        #expect(ActionButton.Size.medium.touchHeight >= 44)
        #expect(ActionButton.Size.small.touchHeight >= 44)
        #expect(HomeProjectCard.minimumTouchArea >= 44)
    }

    @Test
    func `탭 항목은 선택 여부에 따라 역할 색을 바꿔 색만으로 상태를 전달하지 않는다`() {
        #expect(TabShellPreviewItem.tabColor(isSelected: true) == SemanticColorToken.brandAccent)
        #expect(TabShellPreviewItem.tabColor(isSelected: false) == SemanticColorToken.mutedText)
    }

    @Test
    func `판정 결과는 접근성 라벨에 문자로도 실린다`() {
        #expect(ChoiceResultRow.accessibilityLabel(text: "본문", judgement: .correct).hasSuffix("정답"))
        #expect(ChoiceResultRow.accessibilityLabel(text: "본문", judgement: .incorrect).hasSuffix("오답"))
        #expect(ChoiceAnswerOption.State.correct.accessibilitySuffix == "정답")
        #expect(ChoiceAnswerOption.State.incorrect.accessibilitySuffix == "오답")
    }
}
