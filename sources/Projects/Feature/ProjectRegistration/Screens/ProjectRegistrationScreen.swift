import ComposableArchitecture
import DesignSystem
import DomainLearningProject
import SwiftUI
import UIComponent

// MARK: - ProjectRegistrationScreen

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
        .sheet(isPresented: Binding(get: { store.isGenerationReminderSheetPresented }, set: { _ in })) {
            GenerationReminderSheet(
                onAccept: { send(.generationReminderAccepted) },
                onDecline: { send(.generationReminderDeclined) },
            )
            .presentationDetents([.medium])
            .interactiveDismissDisabled()
        }
    }

    // MARK: Internal

    @Environment(\.dismiss) var dismiss

    // MARK: Private

    @State private var isGuideExpanded = false

    @FocusState private var isLinkFieldFocused: Bool

    @ViewBuilder
    private var content: some View {
        switch store.progress {
        case .submitting,
             .awaitingOutcome:
            QuizGenerationProgressScreen(
                onWaitAtHome: { send(.waitAtHomeTapped) }
            )

        case .failed:
            failureContent

        case .idle:
            if case .validated(let repository) = store.validation {
                switch store.step {
                case .repositoryConfirmation:
                    RepositoryConfirmationScreen(
                        repository: repository,
                        onConfirm: { send(.repositoryConfirmed) },
                        onReject: { send(.repositoryURLChanged(store.repositoryURLInput)) },
                        onBack: { send(.repositoryURLChanged(store.repositoryURLInput)) },
                    )

                case .quizLevelSelection:
                    QuizLevelSelectionScreen(
                        selectedLevel: store.quizLevel,
                        onSelect: { send(.quizLevelSelected($0)) },
                        onNext: { send(.quizLevelConfirmed) },
                        onBack: { send(.stepBackTapped) },
                    )

                case .generationConfirmation:
                    QuizGenerationConfirmationScreen(
                        onStart: { send(.submitTapped) },
                        onBack: { send(.stepBackTapped) },
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

                LabeledTextField(
                    label: "링크",
                    placeholder: "https://github.com",
                    text: Binding(
                        get: { store.repositoryURLInput },
                        set: { send(.repositoryURLChanged($0)) },
                    ),
                    supportingText: isValidationFailed ? "올바른 GitHub 레포지토리 링크를 입력해 주세요." : nil,
                    isError: isValidationFailed,
                    keyboardType: .URL,
                    textInputAutocapitalization: .never,
                    autocorrectionDisabled: true,
                    accessibilityLabel: "GitHub 레포지토리 링크",
                    focus: $isLinkFieldFocused,
                )
            }
            .designSystemScreenMargin()
            .padding(.top, Constant.headerContentSpacing)

            guideSection
                .padding(.top, Constant.fieldGuideSpacing)
                .padding(.horizontal, 20)

            Spacer(minLength: 0)

            ActionButton.primary(
                validateButtonTitle,
                isEnabled: canValidate,
                action: { send(.validateTapped) },
            )
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomButtonPadding)
        }
        // 배경 레이어에만 해제 제스처를 두어 안내 패널·입력 지우기·액션 버튼의 히트 테스트를
        // 가로채지 않는다.
        .background(keyboardDismissLayer)
        // 키보드가 오르내려도 하단 액션 버튼의 화면 내 위치를 고정한다.
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // 화면이 나타난 사실만 알리고, 자동 검증 여부는 Feature 상태가 판단한다.
        .task { send(.task) }
    }

    private var keyboardDismissLayer: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { isLinkFieldFocused = false }
    }

    private var canValidate: Bool {
        !store.repositoryURLInput.isEmpty && store.validation != .validating
    }

    private var validateButtonTitle: String {
        store.validation == .validating ? "확인 중…" : "다음"
    }

    private var isValidationFailed: Bool {
        if case .failed = store.validation {
            return true
        }
        return false
    }

    private var guideSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                isGuideExpanded.toggle()
            } label: {
                HStack {
                    StyledText.body2("불러오기 방법", color: .blue100)
                    Spacer()
                    ResourceImage(asset: .icon(isGuideExpanded ? .chevronUp : .chevronDown), contentMode: .fit)
                        .frame(width: 12, height: 12)
                }
                .padding(.horizontal, LayoutToken.margin.cgFloatValue)
                .padding(.vertical, LayoutToken.gutter.cgFloatValue)
                .frame(height: 54)
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
                                StyledText.caption2("\(index + 1)", color: .grey300)
                            }
                            StyledText.caption1(text, color: .grey100)
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

// MARK: ProjectRegistrationScreen.Constant

extension ProjectRegistrationScreen {
    private enum Constant {
        static let headerContentSpacing: CGFloat = 32
        static let titleFieldSpacing: CGFloat = 16
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
