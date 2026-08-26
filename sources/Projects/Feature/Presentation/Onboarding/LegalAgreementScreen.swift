import ComposableArchitecture
import DesignSystem
import DomainAuthentication
import SwiftUI
import UIComponent

// MARK: - LegalAgreementScreen

/// 필수 정책 동의 sheet. 문서 열기는 외부 브라우저로 위임하고 열기 요청 성공·실패만
/// `Action`으로 되돌려 받는다. sheet 취소는 저장이나 로그인을 호출하지 않는다.
@ViewAction(for: OnboardingFeature.self)
struct LegalAgreementScreen: View {

    // MARK: Lifecycle

    init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    // MARK: Public

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            SheetSurface(viewModel: .init(isScrollable: true)) {
                VStack(spacing: LayoutToken.margin.cgFloatValue) {
                    StyledText.subtitle2("서비스 이용을 위해 아래 약관에 동의해 주세요", alignment: .center)

                    VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                        ForEach(store.legal.requiredDocuments, id: \.identifier) { document in
                            PolicyAgreementRow(
                                viewModel: .init(
                                    title: document.displayName,
                                    isRequired: document.isRequired,
                                    isSelected: store.legal.selectedDocumentIDs.contains(document.identifier),
                                    openLinkFailed: store.legal.linkStatus[document.identifier] == .openFailed,
                                ),
                                onToggle: { send(.legalDocumentToggled(documentID: document.identifier)) },
                                onOpenLink: { openLink(document) },
                                onRetryOpenLink: { openLink(document) },
                            )
                        }
                    }

                    ActionButton.primary(
                        "계속하기",
                        isEnabled: store.legal.canContinue,
                        action: { send(.legalContinueTapped) },
                    )

                    ActionButton.text("닫기", action: { send(.legalSheetCancelTapped) })
                }
            }
        }
        .designSystemBackground(.grey700)
    }

    // MARK: Private

    @Bindable var store: StoreOf<OnboardingFeature>
    @Environment(\.openURL) private var openURL

    private func openLink(_ document: PolicyDocument) {
        send(.legalDocumentLinkTapped(documentID: document.identifier))
        openURL(document.approvedURL) { accepted in
            send(.legalDocumentLinkOpenResult(documentID: document.identifier, success: accepted))
        }
    }

}

// Figma 786:38332 (idle)
#Preview("Legal Agreement - idle") {
    var state = OnboardingFeature.State(bundleVersion: "1.0.0")
    state.phase = .legalAgreement
    state.legal.requiredDocuments = OnboardingPreviewSupport.requiredDocuments
    return LegalAgreementScreen(store: OnboardingFeature.previewStore(state))
}

#Preview("Legal Agreement - error") {
    var state = OnboardingFeature.State(bundleVersion: "1.0.0")
    state.phase = .legalAgreement
    state.legal.requiredDocuments = OnboardingPreviewSupport.requiredDocuments
    state.legal.selectedDocumentIDs = [OnboardingPreviewSupport.requiredDocuments[0].identifier]
    state.legal.linkStatus[OnboardingPreviewSupport.requiredDocuments[1].identifier] = .openFailed
    return LegalAgreementScreen(store: OnboardingFeature.previewStore(state))
}
