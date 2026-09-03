import ComposableArchitecture
import DesignSystem
import DomainLearningProject
import SwiftUI
import UIComponent

// MARK: - QuestionSolvingScreen

@ViewAction(for: QuestionSolvingFeature.self)
struct QuestionSolvingScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<QuestionSolvingFeature>

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(style: .default, onLeadingTap: { send(.backTapped) })
                .designSystemScreenMargin().designSystemBackground(.clear)

            ScrollView {
                VStack(alignment: .leading, spacing: Constant.sectionSpacing) {
                    QuestionPrompt(
                        questionNumber: store.questionNumber,
                        prompt: store.question.prompt,
                    )

                    answerSection

                    if let error = store.submissionError {
                        submissionFailureNotice(error: error)
                    }
                    
                    if store.isSourceControlPresented {
                        HStack {
                            Spacer()

                            sourceButton
                        }
                    }

                }
                .designSystemScreenMargin()
                .padding(.vertical, Constant.contentVerticalPadding)
                
            }

            bottomActions
        }
        .overlay {
            ModalOverlay(isPresented: store.isSourceSheetPresented, onDismiss: { send(.sourceSheetDismissed) }) {
                SourceSheet(
                    questionNumber: store.questionNumber,
                    sources: QuestionSourceDisplay.list(sources: store.question.sources),
                    onLinkTap: { send(.sourceLinkTapped($0)) },
                    onClose: { send(.sourceSheetDismissed) },
                )
            }
        }
    }

    // MARK: Private

    private var essayTextBinding: Binding<String> {
        Binding(
            get: { store.draftEssayText },
            set: { send(.essayTextChanged($0)) },
        )
    }

    private var sourceButton: some View {
        Button(action: { send(.sourceTapped) }) {
            HStack(spacing: Constant.sourceButtonSpacing) {
                StyledText.body1("출처", color: .blue100)

                ResourceImage(asset: .icon(.chevronRight), contentMode: .fit)
                    .designSystemForeground(.blue100)
                    .frame(width: 10, height: 10)
                    .frame(width: 16, height: 16)
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, Constant.sourceButtonVerticalPadding)
            .background(Color(designSystem: .grey600), in: RoundedRectangle(designSystem: .large))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("출처 보기")
    }

    private func explanationCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: Constant.explanationTitleSpacing) {
            StyledText.caption1("AI 해설", color: .blue100)
            StyledText.body2(text, color: .grey100)
        }
        .padding(Constant.explanationPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .designSystemBackground(.accentSurface)
        .designSystemCornerRadius(.large)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var answerSection: some View {
        switch store.question.format {
        case .multipleChoice:
            ChoiceSection(
                questionID: store.question.questionID,
                options: choiceOptions,
                isEnabled: store.answerOutcome == nil && !store.isSubmitting,
                isGraded: store.answerOutcome != nil,
                onSelect: { send(.choiceSelected($0)) },
            )

            if case .choice(let result) = store.answerOutcome {
                explanationCard(text: result.explanation)
            }

        case .essay:
            if case .essay(let result) = store.answerOutcome {
                EssayResultSection(
                    myAnswer: store.draftEssayText,
                    aiAnswer: result.explanation,
                    criteria: result.rubric.criteria,
                )
            } else {
                AnswerEditor(
                    text: essayTextBinding,
                    placeholder: Constant.essayPlaceholder,
                    characterLimit: QuestionSolvingFeature.essayCharacterLimit,
                    isDisabled: store.isSubmitting,
                )
            }
        }
    }

    private var choiceOptions: [ChoiceOptionDisplay] {
        let choices = store.question.choices ?? []
        guard case .choice(let result) = store.answerOutcome else {
            return ChoiceOptionDisplay.editing(choices: choices, selectedIndex: store.draftChoiceIndex)
        }
        return ChoiceOptionDisplay.answered(
            choices: choices,
            selectedIndex: store.draftChoiceIndex,
            result: result,
        )
    }

    private var bottomActions: some View {
        BottomActionBar {
            HStack(spacing: LayoutToken.gutter.cgFloatValue) {
                BookmarkButton(
                    isSaved: store.isBookmarked,
                    accessibilityLabel: store.isBookmarked ? "저장 해제하기" : "저장하기",
                    onTap: { send(.bookmarkToggleTapped) },
                )

                primaryAction
            }
            .designSystemScreenMargin()
        }
        .designSystemBackground(.screenBackground)
    }

    @ViewBuilder
    private var primaryAction: some View {
        if store.answerOutcome == nil {
            ActionButton.primary(
                store.submissionError == nil ? "제출하기" : "다시 제출하기",
                isEnabled: store.isSubmitEnabled,
                action: { send(.submitAnswerTapped) },
            )
        } else {
            ActionButton.primary(
                store.advanceActionTitle,
                action: { send(.advanceTapped) },
            )
        }
    }

    private func submissionFailureNotice(error _: LearningProjectError) -> some View {
        StyledText.body2(Constant.submissionFailureMessage, color: .grey400)
    }

}

// MARK: QuestionSolvingScreen.Constant

extension QuestionSolvingScreen {
    fileprivate enum Constant {
        static let sectionSpacing: CGFloat = 24
        static let contentVerticalPadding: CGFloat = 16
        static let essayPlaceholder = "답안을 서술해주세요"
        static let submissionFailureMessage = "답안을 제출하지 못했어요. 다시 시도해 주세요."
        static let sourceButtonSpacing: CGFloat = 2
        static let sourceButtonChevronSize: CGFloat = 16
        static let sourceButtonHorizontalPadding: CGFloat = 16
        static let sourceButtonVerticalPadding: CGFloat = 8
        static let explanationTitleSpacing: CGFloat = 8
        static let explanationPadding: CGFloat = 16
    }
}
