import DesignSystem
import SwiftUI

#Preview("Legal Agreement - idle · 786:38391") {
    var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
    state.screen = .legalAgreement
    state.legal.requiredDocuments = OnboardingPreviewSupport.requiredDocuments
    return VStack(spacing: 0) {
        Spacer(minLength: 0)
        LegalAgreementScreen(store: OnboardingGuideFeature.previewStore(state))
    }
    .designSystemBackground(.grey700)
}

#Preview("Legal Agreement - 전체 선택 · 786:38391") {
    var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
    state.screen = .legalAgreement
    state.legal.requiredDocuments = OnboardingPreviewSupport.requiredDocuments
    state.legal.selectedDocumentIDs = Set(OnboardingPreviewSupport.requiredDocuments.map(\.identifier))
    return VStack(spacing: 0) {
        Spacer(minLength: 0)
        LegalAgreementScreen(store: OnboardingGuideFeature.previewStore(state))
    }
    .designSystemBackground(.grey700)
}

#Preview("Legal Agreement - 약관 웹시트") {
    var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
    state.screen = .legalAgreement
    state.legal.requiredDocuments = OnboardingPreviewSupport.requiredDocuments
    state.legal.presentedDocumentID = OnboardingPreviewSupport.requiredDocuments[0].identifier
    return VStack(spacing: 0) {
        Spacer(minLength: 0)
        LegalAgreementScreen(store: OnboardingGuideFeature.previewStore(state))
    }
    .designSystemBackground(.grey700)
}
