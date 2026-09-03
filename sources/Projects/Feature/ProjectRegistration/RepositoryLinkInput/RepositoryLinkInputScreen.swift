import ComposableArchitecture
import SwiftUI
import UIComponent

@ViewAction(for: RepositoryLinkInputFeature.self)
struct RepositoryLinkInputScreen: View {

    init(store: StoreOf<RepositoryLinkInputFeature>) {
        self.store = store
    }

    @Bindable var store: StoreOf<RepositoryLinkInputFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(
                style: .largeTitle,
                onLeadingTap: { send(.dismissTapped) },
            )
            .designSystemScreenMargin()

            VStack(alignment: .leading, spacing: Constant.titleFieldSpacing) {
                StyledText.subtitle1("GitHub 레포지토리\n링크를 붙여넣어 주세요")

                LabeledTextField(
                    label: "링크",
                    placeholder: "https://github.com",
                    text: repositoryURLInput,
                    supportingText: store.isValidationFailed ? "올바른 GitHub 레포지토리 링크를 입력해 주세요." : nil,
                    isError: store.isValidationFailed,
                    keyboardType: .URL,
                    textInputAutocapitalization: .never,
                    autocorrectionDisabled: true,
                    accessibilityLabel: "GitHub 레포지토리 링크",
                    focus: $isLinkFieldFocused,
                )
            }
            .designSystemScreenMargin()
            .padding(.top, Constant.headerContentSpacing)

            Self.GuideSectionView()
                .padding(.top, Constant.fieldGuideSpacing)
                .padding(.horizontal, Constant.guideHorizontalPadding)

            Spacer(minLength: 0)

            ActionButton.primary(
                store.validateButtonTitle,
                isEnabled: store.canValidate,
                action: { send(.validateTapped) },
            )
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomButtonPadding)
        }
        .background(Self.KeyboardDismissLayer(onTap: { isLinkFieldFocused = false }))
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .task { send(.task) }
    }

    @FocusState private var isLinkFieldFocused: Bool

    private var repositoryURLInput: Binding<String> {
        Binding(
            get: { store.repositoryURLInput },
            set: { send(.repositoryURLChanged($0)) },
        )
    }


}

private extension RepositoryLinkInputScreen {
    enum Constant {
        static let titleFieldSpacing: CGFloat = 16
        static let headerContentSpacing: CGFloat = 32
        static let fieldGuideSpacing: CGFloat = 32
        static let guideHorizontalPadding: CGFloat = 20
        static let bottomButtonPadding: CGFloat = 34
    }
}
