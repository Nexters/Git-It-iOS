import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("ForegroundColorConfigurable 계약")
struct ForegroundColorConfigurableTests {

    // MARK: Internal

    @Test
    func `StyledText 전경색을 선언하지 않으면 Grey100으로 그린다`() {
        #expect(foregroundColor(of: StyledText(text: "본문")) == ColorToken.grey100)
    }

    @Test
    func `StyledText 전경색 선언은 전경색만 바꾸고 문구와 텍스트 스타일을 유지한다`() {
        let original = StyledText(text: "제목").textStyle(.subtitle2)

        let colored = original.foregroundColorToken(.error)

        #expect(foregroundColor(of: colored) == ColorToken.error)
        #expect(colored.text == "제목")
        #expect(Mirror(reflecting: colored).descendant("textStyle") as? TextStyleToken == TextStyleToken.subtitle2)
    }

    @Test
    func `StyledText 전경색을 두 번 선언하면 마지막 값이 남는다`() {
        let colored = StyledText(text: "제목").foregroundColorToken(.grey400).foregroundColorToken(.blue100)

        #expect(foregroundColor(of: colored) == ColorToken.blue100)
    }

    @Test
    func `IconPlainButton 전경색을 선언하지 않으면 White로 그린다`() {
        #expect(foregroundColor(of: IconPlainButton(icon: .play, label: "학습 시작")) == ColorToken.white)
    }

    @Test
    func `IconPlainButton 전경색 선언은 전경색만 바꾸고 배경색과 레이블을 유지한다`() {
        let original = IconPlainButton(icon: .play, label: "학습 시작").backgroundColorToken(.blue100)

        let colored = original.foregroundColorToken(.grey700)

        #expect(foregroundColor(of: colored) == ColorToken.grey700)
        #expect(Mirror(reflecting: colored).descendant("backgroundColor") as? ColorToken == ColorToken.blue100)
        #expect(Mirror(reflecting: colored).descendant("label") as? String == "학습 시작")
    }

    @Test
    func `LabeledProgressBar 값 전경색을 선언하지 않으면 Grey400으로 그린다`() {
        #expect(foregroundColor(of: LabeledProgressBar(displayModel: progressModel)) == ColorToken.grey400)
    }

    @Test
    func `LabeledProgressBar 전경색 선언은 전경색만 바꾸고 표시 값 모델을 유지한다`() {
        let colored = LabeledProgressBar(displayModel: progressModel).foregroundColorToken(.blue100)

        #expect(foregroundColor(of: colored) == ColorToken.blue100)
        #expect(Mirror(reflecting: colored).descendant("displayModel") as? LabeledProgressBar.DisplayModel == progressModel)
    }

    // MARK: Private

    private let progressModel = LabeledProgressBar.DisplayModel(label: "학습 진행률", progress: 0.6, valueText: "6 / 10")

    private func foregroundColor(of subject: some View) -> ColorToken? {
        Mirror(reflecting: subject).descendant("foregroundColor") as? ColorToken
    }

}
