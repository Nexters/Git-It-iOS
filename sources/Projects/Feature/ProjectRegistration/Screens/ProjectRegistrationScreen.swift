import ComposableArchitecture
import DesignSystem
import DomainLearningProject
import SwiftUI
import UIComponent

@ViewAction(for: ProjectRegistrationFeature.self)
public struct ProjectRegistrationScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<ProjectRegistrationFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<ProjectRegistrationFeature>

    public var body: some View {
        ScreenContainer {
            content
        }
        .onChange(of: store.validation) { _, validation in
            guard case .validated = validation else {
                hasConfirmedRepository = false
                hasSelectedQuizLevel = false
                return
            }
        }
        .sheet(isPresented: Binding(get: { store.isNotificationOptionSheetPresented }, set: { _ in })) {
            ProjectRegistrationNotificationOptionSheet(
                onAccept: { send(.notificationOptionAccepted) },
                onDecline: { send(.notificationOptionDeclined) },
            )
            .presentationDetents([.medium])
            .interactiveDismissDisabled()
        }
    }

    // MARK: Internal

    @Environment(\.dismiss) var dismiss

    // MARK: Private

    @State private var hasConfirmedRepository = false
    @State private var hasSelectedQuizLevel = false
    @State private var isGuideExpanded = false

    @ViewBuilder
    private var content: some View {
        switch store.submission {
        case .committing,
             .awaitingGeneration:
            ProjectRegistrationGenerationProgressScreen(
                onWaitAtHome: { send(.waitAtHomeTapped) },
            )

        case .failed:
            failureContent

        case .idle:
            if case .validated(let repository) = store.validation {
                if !hasConfirmedRepository {
                    ProjectRegistrationRepositoryConfirmationScreen(
                        repository: repository,
                        onConfirm: { hasConfirmedRepository = true },
                        onReject: { send(.repositoryURLChanged(store.repositoryURLInput)) },
                        onBack: { send(.repositoryURLChanged(store.repositoryURLInput)) },
                    )
                } else if !hasSelectedQuizLevel {
                    ProjectRegistrationQuizLevelSelectionScreen(
                        selectedLevel: store.quizLevel,
                        onSelect: { send(.quizLevelSelected($0)) },
                        onNext: { hasSelectedQuizLevel = true },
                        onBack: { hasConfirmedRepository = false },
                    )
                } else {
                    ProjectRegistrationGenerationConfirmationScreen(
                        onStart: { send(.submitTapped) },
                        onBack: { hasSelectedQuizLevel = false },
                    )
                }
            } else {
                linkInputContent
            }
        }
    }

    private var linkInputContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(
                style: .largeTitle,
                onLeadingTap: { dismiss() },
            )
            .designSystemScreenMargin()

            VStack(alignment: .leading, spacing: Constant.titleFieldSpacing) {
                StyledText.subtitle1("GitHub 레포지토리\n링크를 붙여넣어 주세요")

                VStack(alignment: .leading, spacing: Constant.fieldErrorSpacing) {
                    linkField

                    if case .failed = store.validation {
                        StyledText.caption1("레포지토리를 확인할 수 없어요. 링크를 다시 확인해 주세요.", color: .error)
                    }
                }
            }
            .designSystemScreenMargin()
            .padding(.top, Constant.headerContentSpacing)

            guideSection
                .designSystemScreenMargin()
                .padding(.top, Constant.fieldGuideSpacing)

            Spacer(minLength: 0)

            ActionButton.primary(
                validateButtonTitle,
                isEnabled: canValidate,
                action: { send(.validateTapped) },
            )
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomButtonPadding)
        }
    }

    private var canValidate: Bool {
        !store.repositoryURLInput.isEmpty && store.validation != .validating
    }

    private var validateButtonTitle: String {
        store.validation == .validating ? "확인 중…" : "다음"
    }

    private var linkField: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: LayoutToken.gutter.cgFloatValue) {
                StyledText.body2("링크", color: .blue100)

                TextField(
                    "",
                    text: Binding(
                        get: { store.repositoryURLInput },
                        set: { send(.repositoryURLChanged($0)) },
                    ),
                    prompt: Text("https://github.com").foregroundStyle(Color(designSystem: .white30)),
                )
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .designSystemForeground(.grey100)
                .accessibilityLabel("GitHub 레포지토리 링크")
            }
            .frame(height: Constant.fieldHeight)

            Rectangle()
                .fill(Color(designSystem: fieldUnderlineColor))
                .frame(height: 1)
        }
    }

    private var fieldUnderlineColor: ColorToken {
        if case .failed = store.validation { return .error }
        return .blue100
    }

    private var guideSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                isGuideExpanded.toggle()
            } label: {
                HStack {
                    StyledText.body2("불러오기 방법", color: .blue100)
                    Spacer()
                    ResourceImage(asset: .icon(isGuideExpanded ? .chevronUp : .chevronDown))
                        .frame(width: 16, height: 16)
                }
                .padding(.horizontal, LayoutToken.margin.cgFloatValue)
                .padding(.vertical, LayoutToken.gutter.cgFloatValue)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("불러오기 방법")
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(isGuideExpanded ? "펼쳐짐" : "접힘")

            if isGuideExpanded {
                VStack(alignment: .leading, spacing: Constant.guideStepSpacing) {
                    ForEach(Array(Constant.guideSteps.enumerated()), id: \.offset) { index, text in
                        HStack(alignment: .top, spacing: LayoutToken.gutter.cgFloatValue) {
                            ZStack {
                                Circle()
                                    .fill(Color(designSystem: .grey500))
                                    .frame(width: 16, height: 16)
                                StyledText.caption1("\(index + 1)", color: .grey300)
                            }
                            StyledText.caption1(text)
                        }
                    }
                }
                .padding(.horizontal, LayoutToken.margin.cgFloatValue)
                .padding(.bottom, LayoutToken.gutter.cgFloatValue)
            }
        }
        .background(Color(designSystem: .grey600), in: RoundedRectangle(designSystem: .large))
    }

    private var failureContent: some View {
        VStack(spacing: LayoutToken.margin.cgFloatValue) {
            ScreenHeader(style: .largeTitle, onLeadingTap: { dismiss() })
                .designSystemScreenMargin()

            Spacer(minLength: 0)

            VStack(spacing: Constant.guideStepSpacing) {
                StyledText.subtitle1("학습 세트를 만들지 못했어요", alignment: .center)
                StyledText.body2("잠시 후 다시 시도해 주세요.", color: .grey400, alignment: .center)
            }

            Spacer(minLength: 0)

            ActionButton.primary("다시 시도하기", action: { send(.retryTapped) })
                .designSystemScreenMargin()
                .padding(.bottom, Constant.bottomButtonPadding)
        }
    }

}

extension ProjectRegistrationScreen {
    private enum Constant {
        static let fieldHeight: CGFloat = 56
        static let headerContentSpacing: CGFloat = 32
        static let titleFieldSpacing: CGFloat = 16
        static let fieldErrorSpacing: CGFloat = 8
        static let fieldGuideSpacing: CGFloat = 32
        static let guideStepSpacing: CGFloat = 10
        static let bottomButtonPadding: CGFloat = 34

        static let guideSteps = [
            "학습하고싶은 레포지토리를 발견하셨나요?",
            "GitHub 리포지토리 페이지로 이동합니다.",
            "우측 상단의 [Code] 버튼을 클릭합니다.",
            "HTTPS 탭에서 주소 옆 복사 아이콘을 누릅니다.",
            "복사한 주소를 위에 입력해주세요.",
        ]
    }
}
