import DesignSystem
import Testing

@testable import UIComponent

@Suite("PolicyAgreementRow 계약")
struct PolicyAgreementRowTests {
    @Test
    func `onToggle callback을 호출하면 그대로 전달된다`() {
        var toggled = false
        let onToggle: () -> Void = { toggled = true }
        _ = PolicyAgreementRow(
            title: "개인정보 처리방침",
            isRequired: true,
            onToggle: onToggle,
        )

        onToggle()
        #expect(toggled)
    }

    @Test
    func `onOpenLink callback을 호출하면 그대로 전달된다`() {
        var opened = false
        let onOpenLink: () -> Void = { opened = true }
        _ = PolicyAgreementRow(
            title: "서비스 이용 약관",
            isRequired: true,
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
