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
        SheetSurface {
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
                            displayModel: .init(title: document.displayName, isRequired: document.isRequired),
                            isSelected: Binding(
                                get: { store.selectedDocumentIDs.contains(document.id) },
                                set: { _ in send(.documentToggled(documentID: document.id)) },
                            ),
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
                        action: { send(.continueTapped) },
                    )
                    .enabled(store.canContinue)
                }
                .padding(.top, Constant.actionsTopSpacing)
            }
        }
        .scrollable(true)
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
