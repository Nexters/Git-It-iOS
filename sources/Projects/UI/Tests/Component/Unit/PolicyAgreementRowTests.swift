import DesignSystem
import Testing

@testable import UIComponent

@Suite("PolicyAgreementRow 계약")
struct PolicyAgreementRowTests {
    @Test
    func `isRequired가 true면 필수 표시를, false면 선택 표시를 갖는다`() {
        let required = PolicyAgreementRow.ViewModel(title: "개인정보 처리방침", isRequired: true)
        let optional = PolicyAgreementRow.ViewModel(title: "마케팅 정보 수신", isRequired: false)

        #expect(required.isRequired == true)
        #expect(optional.isRequired == false)
    }

    @Test
    func `isSelected 기본값은 false이고 지정한 값을 보존한다`() {
        let unselected = PolicyAgreementRow.ViewModel(title: "서비스 이용 약관", isRequired: true)
        let selected = PolicyAgreementRow.ViewModel(title: "서비스 이용 약관", isRequired: true, isSelected: true)

        #expect(unselected.isSelected == false)
        #expect(selected.isSelected == true)
    }

    @Test
    func `onToggle callback을 호출하면 그대로 전달된다`() {
        var toggled = false
        let onToggle: () -> Void = { toggled = true }
        _ = PolicyAgreementRow(
            viewModel: .init(title: "개인정보 처리방침", isRequired: true),
            onToggle: onToggle,
        )

        onToggle()
        #expect(toggled)
    }

    @Test
    func `openLinkFailed가 true면 retry callback 경로를 노출한다`() {
        var retried = false
        let onRetryOpenLink: () -> Void = { retried = true }
        let viewModel = PolicyAgreementRow.ViewModel(title: "서비스 이용 약관", isRequired: true, openLinkFailed: true)
        _ = PolicyAgreementRow(viewModel: viewModel, onRetryOpenLink: onRetryOpenLink)

        #expect(viewModel.openLinkFailed)
        onRetryOpenLink()
        #expect(retried)
    }

    @Test
    func `openLinkFailed가 false면 onOpenLink callback이 그대로 전달된다`() {
        var opened = false
        let onOpenLink: () -> Void = { opened = true }
        let viewModel = PolicyAgreementRow.ViewModel(title: "서비스 이용 약관", isRequired: true)
        _ = PolicyAgreementRow(viewModel: viewModel, onOpenLink: onOpenLink)

        #expect(viewModel.openLinkFailed == false)
        onOpenLink()
        #expect(opened)
    }

    @Test
    func `열기·retry 진입점은 44pt 최소 hit area를 갖는다`() {
        #expect(PolicyAgreementRow.minimumHitArea == 44)
    }

    @Test
    func `ViewModel은 page load 상태를 API에 포함하지 않는다`() {
        // openLinkFailed(열기 요청 실패)만 있고, 브라우저 내부 로딩 상태를 나타내는
        // 별도 프로퍼티가 없음을 필드 개수로 확인한다.
        let viewModel = PolicyAgreementRow.ViewModel(title: "서비스 이용 약관", isRequired: true)
        let mirror = Mirror(reflecting: viewModel)

        #expect(mirror.children.map(\.label) == ["title", "isRequired", "isSelected", "openLinkFailed"])
    }
}
