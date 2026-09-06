import ComposableArchitecture
import DesignSystem
import DomainAuthentication
import SwiftUI
import UIComponent

// MARK: - LegalAgreementScreen

@ViewAction(for: LegalAgreementFeature.self)
struct LegalAgreementScreen: View {

    @Bindable var store: StoreOf<LegalAgreementFeature>

    var body: some View {
        SheetSurface(isScrollable: true) {
            VStack(alignment: .leading, spacing: 0) {
                StyledText.subtitle1("약관 동의")
                    .padding(.top, LayoutToken.gutter.cgFloatValue)
                    .padding(.bottom, Constant.titleBottomSpacing)

                Self.AllAgreementRow(
                    isSelected: store.isAllSelected,
                    onToggle: { send(.allDocumentsToggled) },
                )

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(store.requiredDocuments, id: \.identifier) { document in
                        PolicyAgreementRow(
                            title: document.displayName,
                            isRequired: document.isRequired,
                            isSelected: store.selectedDocumentIDs.contains(document.identifier),
                            onToggle: { send(.documentToggled(documentID: document.identifier)) },
                            onOpenLink: { send(.documentLinkTapped(documentID: document.identifier)) },
                        )
                        .padding(.leading, Constant.documentRowLeadingPadding)
                    }
                }
                .padding(.top, Constant.documentsTopSpacing)

                HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                    ActionButton.secondary("취소", action: { send(.cancelTapped) })

                    ActionButton.primary(
                        "다음",
                        isEnabled: store.canContinue,
                        action: { send(.continueTapped) },
                    )
                }
                .padding(.top, Constant.actionsTopSpacing)
            }
        }
    }

}

// MARK: LegalAgreementScreen.Constant

extension LegalAgreementScreen {
    fileprivate enum Constant {
        static let actionsTopSpacing: CGFloat = 25
        static let titleBottomSpacing: CGFloat = 10
        static let documentsTopSpacing: CGFloat = 7
        static let documentRowLeadingPadding: CGFloat = 17
    }
}
