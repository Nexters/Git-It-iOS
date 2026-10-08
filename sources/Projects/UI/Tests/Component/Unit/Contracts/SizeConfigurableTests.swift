import Testing

@testable import UIComponent

@Suite("SizeConfigurable 계약")
struct SizeConfigurableTests {

    // MARK: Internal

    @Test
    func `크기를 선언하지 않으면 컴포넌트 기본 크기로 그린다`() {
        #expect(size(of: ActionButton(title: "계속하기")) == ActionButton.Size.large)
        #expect(size(of: TagBadge(text: "완료")) == TagBadge.Size.regular)
        #expect(size(of: IconGlassButton(
            icon: .bookmark
        )) == IconGlassButton.Size.small)
        #expect(size(of: ContinuousProgressBar(progress: 0.5)) == ContinuousProgressBar.Height.row)
    }

    @Test
    func `크기 선언은 크기만 바꾸고 스타일과 표시 값을 유지한다`() {
        let button = ActionButton(title: "계속하기").style(.secondary).size(.small)
        let badge = TagBadge(text: "완료").style(.muted).size(.compact)
        let glassButton = IconGlassButton(
            icon: .bookmark
        ).style(.accent).size(.medium)
        let progressBar = ContinuousProgressBar(progress: 0.5).size(.detail)

        #expect(size(of: button) == ActionButton.Size.small)
        #expect(Mirror(reflecting: button).descendant("style") as? ActionButton.Style == .secondary)
        #expect(size(of: badge) == TagBadge.Size.compact)
        #expect(Mirror(reflecting: badge).descendant("style") as? TagBadge.Style == .muted)
        #expect(Mirror(reflecting: badge).descendant("text") as? String == "완료")
        #expect(size(of: glassButton) == IconGlassButton.Size.medium)
        #expect(Mirror(reflecting: glassButton).descendant("style") as? IconGlassButton.Style == .accent)
        #expect(size(of: progressBar) == ContinuousProgressBar.Height.detail)
        #expect(Mirror(reflecting: progressBar).descendant("progress") as? Double == 0.5)
    }

    @Test
    func `스타일 선언과 호출 순서를 바꿔도 결과가 같다`() {
        let styleFirst = TagBadge(text: "완료").style(.accent).size(.compact)
        let sizeFirst = TagBadge(text: "완료").size(.compact).style(.accent)

        #expect(size(of: styleFirst) == size(of: sizeFirst))
        #expect(
            Mirror(reflecting: styleFirst).descendant("style") as? TagBadge.Style
                == Mirror(reflecting: sizeFirst).descendant("style") as? TagBadge.Style
        )
    }

    @Test
    func `크기를 두 번 선언하면 마지막 값이 남는다`() {
        #expect(size(of: ActionButton(title: "계속하기").size(.small).size(.medium)) == ActionButton.Size.medium)
        #expect(size(of: ContinuousProgressBar(progress: 0.5).size(.detail).size(.row)) == ContinuousProgressBar.Height.row)
    }

    // MARK: Private

    private func size<Subject: SizeConfigurable>(of subject: Subject) -> Subject.Size? {
        Mirror(reflecting: subject).descendant("size") as? Subject.Size
    }

}
