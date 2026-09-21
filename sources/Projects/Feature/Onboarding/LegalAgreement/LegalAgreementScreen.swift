import ComposableArchitecture
import DesignSystem
import DomainAccount
import SwiftUI
import UIComponent

// MARK: - LegalAgreementScreen

@ViewAction(for: LegalAgreementFeature.self)
struct LegalAgreementScreen: View {

    @Bindable var store: StoreOf<LegalAgreementFeature>

    var body: some View {
        SheetSurface(isScrollable: true) {
            VStack(alignment: .leading, spacing: 0) {
                StyledText(text: "약관 동의")
                    .textStyle(.subtitle1)
                    .padding(.top, LayoutToken.gutter)
                    .padding(.bottom, Constant.titleBottomSpacing)

                Self.AllAgreementRow(
                    isSelected: store.isAllSelected,
                    onToggle: { send(.allDocumentsToggled) },
                )

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(store.requiredDocuments, id: \.id) { document in
                        PolicyAgreementRow(
                            title: document.displayName,
                            isRequired: document.isRequired,
                            isSelected: store.selectedDocumentIDs.contains(document.id),
                            onToggle: { send(.documentToggled(documentID: document.id)) },
                            onOpenLink: { send(.documentLinkTapped(documentID: document.id)) },
                        )
                        .padding(.leading, Constant.documentRowLeadingPadding)
                    }
                }
                .padding(.top, Constant.documentsTopSpacing)

                HStack(spacing: LayoutToken.compactSpacing) {
                    FeedbackActionButton(title: "취소", action: { send(.cancelTapped) })
                        .style(.secondary)

                    FeedbackActionButton(
                        title: "다음",
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
