import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("PolicyAgreementRow 계약")
struct PolicyAgreementRowTests {
    @Test
    func `체크 영역을 탭하면 선택 여부 Binding을 반전한다`() {
        var isSelected = false
        let row = PolicyAgreementRow(
            displayModel: .init(
                title: "개인정보 처리방침",
                isRequired: true,
            ),
            isSelected: Binding(
                get: { isSelected },
                set: { isSelected = $0 },
            ),
        )

        row.toggle()
        #expect(isSelected)
    }

    @Test
    func `onOpenLink callback을 호출하면 그대로 전달된다`() {
        var opened = false
        let onOpenLink: () -> Void = { opened = true }
        _ = PolicyAgreementRow(
            displayModel: .init(
                title: "서비스 이용 약관",
                isRequired: true,
            ),
            isSelected: .constant(false),
            onOpenLink: onOpenLink,
        )

        onOpenLink()
        #expect(opened)
    }

    @Test
    func `열기 진입점은 44pt 최소 hit area를 갖는다`() {
        #expect(PolicyAgreementRow.minimumHitArea == 44)
    }
}
