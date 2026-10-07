import DesignSystem
import Testing

@testable import UIComponent

@Suite("Chip 계약")
struct ChipTests {
    @Test
    func `라벨과 선택 여부와 탭 콜백을 모두 값으로 받는다`() {
        _ = Chip(label: "전체", isSelected: true) { }
        _ = Chip(label: "SwiftUI", isSelected: false) { }
    }

    @Test
    func `선택 여부를 스스로 보관하지 않는다`() {
        let mirror = Mirror(reflecting: Chip(label: "전체", isSelected: false) { })
        let stateProperties = mirror.children.filter {
            ($0.label ?? "").hasPrefix("_")
        }

        #expect(stateProperties.isEmpty)
    }

    @Test
    func `규격 높이와 반경 토큰을 쓴다`() {
        #expect(Chip.Constant.height == 36)
        #expect(CornerRadiusToken.small.value == 8)
    }

    @Test
    func `라벨은 한 줄로 고정한다`() {
        #expect(Chip.Constant.labelLineLimit == 1)
    }
}
