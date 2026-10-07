import ComposableArchitecture
import DesignSystem
import SwiftUI

extension LegalAgreementFeature.State {
    fileprivate static func preview(
        selectedDocumentIDs: Set<String> = [],
        presentedDocumentID: String? = nil,
    ) -> Self {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingPreviewSupport.requiredDocuments
        state.selectedDocumentIDs = selectedDocumentIDs
        state.presentedDocumentID = presentedDocumentID
        return state
    }
}

private func legalAgreementPreview(_ state: LegalAgreementFeature.State) -> some View {
    VStack(spacing: 0) {
        Spacer(minLength: 0)
        LegalAgreementScreen(store: Store(initialState: state) { EmptyReducer() })
    }
    .designSystemBackground(.grey700)
}

#Preview("Legal Agreement - idle · 786:38391") {
    legalAgreementPreview(.preview())
}

#Preview("Legal Agreement - 전체 선택 · 786:38391") {
    legalAgreementPreview(
        .preview(selectedDocumentIDs: Set(OnboardingPreviewSupport.requiredDocuments.map(\.identifier)))
    )
}

#Preview("Legal Agreement - 약관 웹시트") {
    legalAgreementPreview(
        .preview(presentedDocumentID: OnboardingPreviewSupport.requiredDocuments[0].identifier)
    )
}
