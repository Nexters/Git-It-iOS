import Testing

@testable import UIComponent

@Suite("StyleConfigurable 계약")
struct StyleConfigurableTests {

    // MARK: Internal

    @Test
    func `스타일을 선언하지 않으면 컴포넌트 기본 스타일로 그린다`() {
        #expect(style(of: ActionButton(title: "계속하기")) == ActionButton.Style.primary)
        #expect(style(of: TagBadge(text: "완료")) == TagBadge.Style.neutral)
        #expect(style(of: IconGlassButton(icon: .bookmark, label: "저장하기")) == IconGlassButton.Style.neutral)
    }

    @Test
    func `스타일 선언은 스타일만 바꾸고 표시 값과 크기를 유지한다`() {
        let button = ActionButton(title: "계속하기").size(.medium).style(.secondary)
        let badge = TagBadge(text: "완료").size(.compact).style(.accent)
        let glassButton = IconGlassButton(icon: .bookmark, label: "저장하기").size(.medium).style(.destructive)

        #expect(style(of: button) == ActionButton.Style.secondary)
        #expect(size(of: button) == ActionButton.Size.medium)
        #expect(style(of: badge) == TagBadge.Style.accent)
        #expect(size(of: badge) == TagBadge.Size.compact)
        #expect(Mirror(reflecting: badge).descendant("text") as? String == "완료")
        #expect(style(of: glassButton) == IconGlassButton.Style.destructive)
        #expect(size(of: glassButton) == IconGlassButton.Size.medium)
        #expect(Mirror(reflecting: glassButton).descendant("label") as? String == "저장하기")
    }

    @Test
    func `스타일을 두 번 선언하면 마지막 값이 남는다`() {
        #expect(style(of: ActionButton(title: "계속하기").style(.text).style(.destructive)) == ActionButton.Style.destructive)
        #expect(style(of: TagBadge(text: "완료").style(.accent).style(.muted)) == TagBadge.Style.muted)
        let glassButton = IconGlassButton(icon: .bookmark, label: "저장하기").style(.accent).style(.neutral)
        #expect(style(of: glassButton) == IconGlassButton.Style.neutral)
    }

    // MARK: Private

    private func style<Subject: StyleConfigurable>(of subject: Subject) -> Subject.Style? {
        Mirror(reflecting: subject).descendant("style") as? Subject.Style
    }

    private func size<Subject: SizeConfigurable>(of subject: Subject) -> Subject.Size? {
        Mirror(reflecting: subject).descendant("size") as? Subject.Size
    }

}
