import DesignSystem
import Testing

@testable import UIComponent

@Suite("ActionButton 크기 계약")
struct ActionButtonSizeContractTests {
    @Test
    func `LG MD SM 표면 높이는 각각 54 40 36pt다`() {
        #expect(ActionButton.Size.large.surfaceHeight == 54)
        #expect(ActionButton.Size.medium.surfaceHeight == 40)
        #expect(ActionButton.Size.small.surfaceHeight == 36)
    }

    @Test
    func `모든 크기는 44pt 최소 터치 영역을 구성한다`() {
        let sizes: [ActionButton.Size] = [.large, .medium, .small]

        #expect(sizes.allSatisfy { $0.minimumHitArea == 44 })
    }

    @Test
    func `String과 StyledText 생성 경로를 모두 보존한다`() {
        let styledText = StyledText(text: "서식 라벨")
            .textStyle(.subtitle2)

        _ = ActionButton(title: "문자열 라벨", style: .primary, size: .medium)
        _ = ActionButton(styledText: styledText, style: .secondary, size: .small)
    }
}
