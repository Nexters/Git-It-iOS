import ComposableArchitecture
import DesignSystem
import DomainAuthentication
import SwiftUI
import UIComponent

// MARK: - LegalAgreementScreen

@ViewAction(for: OnboardingGuideFeature.self)
struct LegalAgreementScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<OnboardingGuideFeature>

    var body: some View {
        SheetSurface(isScrollable: true) {
            VStack(alignment: .leading, spacing: 0) {
                StyledText.subtitle1("약관 동의")
                    .padding(.top, LayoutToken.gutter.cgFloatValue)
                    .padding(.bottom, LayoutToken.gutter.cgFloatValue)

                allAgreementRow

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(store.legal.requiredDocuments, id: \.identifier) { document in
                        PolicyAgreementRow(
                            title: document.displayName,
                            isRequired: document.isRequired,
                            isSelected: store.legal.selectedDocumentIDs.contains(document.identifier),
                            onToggle: { send(.legalDocumentToggled(documentID: document.identifier)) },
                            onOpenLink: { send(.legalDocumentLinkTapped(documentID: document.identifier)) },
                        )
                        .padding(.leading, 19)
                    }
                }

                HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                    ActionButton.secondary("취소", action: { send(.legalSheetCancelTapped) })

                    ActionButton.primary(
                        "다음",
                        isEnabled: store.legal.canContinue,
                        action: { send(.legalContinueTapped) },
                    )
                }
                .padding(.top, Constant.actionsTopSpacing)
            }
        }
    }

    // MARK: Private

    private enum Constant {
        static let actionsTopSpacing: CGFloat = 25
        static let rowHeight: CGFloat = 54
        static let checkSize: CGFloat = 24
        static let checkSpacing: CGFloat = 12
        static let rowHorizontalPadding: CGFloat = 17
    }

    private var allAgreementRow: some View {
        Button(action: { send(.legalAllDocumentsToggled) }) {
            HStack(spacing: Constant.checkSpacing) {
                Image(systemName: store.legal.isAllSelected ? "checkmark.circle.fill" : "circle")
                    .designSystemForeground(store.legal.isAllSelected ? .blue100 : .grey400)
                    .frame(width: Constant.checkSize, height: Constant.checkSize)
                StyledText.body1("전체 동의")
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Constant.rowHorizontalPadding)
            .frame(height: Constant.rowHeight)
            .frame(maxWidth: .infinity)
            .designSystemBackground(.raisedBackground)
            .designSystemCornerRadius(.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}
