import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("Chip 계약")
struct ChipTests {
    @Test
    func `라벨은 값으로, 선택 여부는 Binding으로 받는다`() {
        _ = Chip(label: "전체", isSelected: .constant(true))
        _ = Chip(label: "SwiftUI", isSelected: .constant(false))
    }

    @Test
    func `선택 여부를 State로 보관하지 않고 Binding으로 참조한다`() {
        let children = Mirror(reflecting: Chip(label: "전체", isSelected: .constant(false))).children
        let stateProperties = children.filter {
            String(describing: type(of: $0.value)).hasPrefix("State<")
        }

        #expect(stateProperties.isEmpty)
        #expect(children.first { $0.label == "_isSelected" }?.value is Binding<Bool>)
    }

    @Test
    func `탭하면 선택 여부 Binding을 반전한다`() {
        var isSelected = false
        let chip = Chip(label: "전체", isSelected: Binding(get: { isSelected }, set: { isSelected = $0 }))

        chip.toggle()

        #expect(isSelected)
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
