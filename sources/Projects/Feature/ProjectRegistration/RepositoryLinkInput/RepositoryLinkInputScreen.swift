import ComposableArchitecture
import SwiftUI
import UIComponent

// MARK: - RepositoryLinkInputScreen

@ViewAction(for: RepositoryLinkInputFeature.self)
struct RepositoryLinkInputScreen: View {

    // MARK: Lifecycle

    init(store: StoreOf<RepositoryLinkInputFeature>) {
        self.store = store
    }

    // MARK: Internal

    @Bindable var store: StoreOf<RepositoryLinkInputFeature>

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0,
        ) {
            ScreenControlBar(
                onLeadingTap: { send(.dismissTapped) }
            )
            .designSystemScreenMargin()

            VStack(
                alignment: .leading,
                spacing: Constant.titleFieldSpacing,
            ) {
                StyledText(text: "GitHub 레포지토리\n링크를 붙여넣어 주세요")
                    .textStyle(.subtitle1)

                LabeledTextField(
                    displayModel: .init(
                        label: "링크",
                        placeholder: "https://github.com",
                        supportingText: store.isValidationFailed ? "올바른 GitHub 레포지토리 링크를 입력해 주세요." : nil,
                    ),
                    text: repositoryURLInput,
                    accessibilityLabel: "GitHub 레포지토리 링크",
                    focus: $isLinkFieldFocused,
                )
                .error(store.isValidationFailed)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            }
            .designSystemScreenMargin()
            .padding(.top, Constant.headerContentSpacing)

            Self.GuideSectionView()
                .padding(.top, Constant.fieldGuideSpacing)
                .padding(.horizontal, Constant.guideHorizontalPadding)

            Spacer(minLength: 0)

            FeedbackActionButton(
                title: store.validateButtonTitle,
                action: { send(.validateTapped) },
            )
            .enabled(store.canValidate)
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomButtonPadding)
        }
        .background(Self.KeyboardDismissLayer(onTap: { isLinkFieldFocused = false }))
        .ignoresSafeArea(
            .keyboard,
            edges: .bottom,
        )
    }

    // MARK: Private

    @FocusState private var isLinkFieldFocused: Bool

    private var repositoryURLInput: Binding<String> {
        Binding(
            get: { store.repositoryURLInput },
            set: { send(.repositoryURLChanged($0)) },
        )
    }

}

// MARK: RepositoryLinkInputScreen.Constant

extension RepositoryLinkInputScreen {
    fileprivate enum Constant {
        static let titleFieldSpacing: CGFloat = 16
        static let headerContentSpacing: CGFloat = 18
        static let fieldGuideSpacing: CGFloat = 32
        static let guideHorizontalPadding: CGFloat = 20
        static let bottomButtonPadding: CGFloat = 24
    }
}
