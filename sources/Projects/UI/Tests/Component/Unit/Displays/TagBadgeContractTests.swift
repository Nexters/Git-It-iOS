import DesignSystem
import Testing

@testable import UIComponent

@Suite("TagBadge 계약")
struct TagBadgeContractTests {
    @Test
    func `표시 값을 직접 받아 생성한다`() {
        _ = TagBadge.neutral("완료")
        _ = TagBadge.accent("진행 중")
        _ = TagBadge.selected("선택됨")
    }

    @Test
    func `스타일별 배경과 라벨 색은 색 토큰을 참조한다`() {
        #expect(TagBadge.Style.neutral.backgroundColor == ColorToken.grey500)
        #expect(TagBadge.Style.neutral.textColor == ColorToken.blue100)
        #expect(TagBadge.Style.accent.backgroundColor == ColorToken.blue400)
        #expect(TagBadge.Style.accent.textColor == ColorToken.blue100)
        #expect(TagBadge.Style.selected.backgroundColor == ColorToken.blue400)
        #expect(TagBadge.Style.selected.textColor == ColorToken.grey100)
    }

    @Test
    func `muted 스타일은 Grey500 배경과 Grey300 라벨을 쓴다`() {
        #expect(TagBadge.Style.muted.backgroundColor == ColorToken.grey500)
        #expect(TagBadge.Style.muted.textColor == ColorToken.grey300)
    }

    @Test
    func `compact 크기는 Body 3 텍스트 스타일을 쓴다`() {
        #expect(TagBadge.Size.regular.textStyle == TextStyleToken.body2)
        #expect(TagBadge.Size.compact.textStyle == TextStyleToken.body3)
    }

    @Test
    func `표시 상태를 스스로 보관하지 않는다`() {
        let stateProperties = Mirror(reflecting: TagBadge.neutral("완료")).children.filter {
            ($0.label ?? "").hasPrefix("_")
        }

        #expect(stateProperties.isEmpty)
    }
}
