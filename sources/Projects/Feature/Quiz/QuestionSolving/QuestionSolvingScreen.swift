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
        content
            .overlay {
                ModalOverlay(
                    isPresented: store.isSourceSheetPresented,
                    onDismiss: { send(.sourceSheetDismissed) },
                ) {
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

    private var content: some View {
        OverlayContainer { layoutMetrics in
            ScreenOverlayHeader(
                layoutMetrics: layoutMetrics,
                onLeadingTap: { send(.backTapped) },
            )
        } content: { _ in
            VStack(alignment: .leading, spacing: Constant.sectionSpacing) {
                QuestionPrompt(
                    questionNumber: store.questionNumber,
                    prompt: store.question.prompt,
                )

                answerSection

                if store.submissionError != nil {
                    submissionFailureNotice
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
        } footer: { layoutMetrics in
            bottomActions(layoutMetrics: layoutMetrics)
        }
    }

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
                    .frame(width: Constant.sourceButtonChevronGlyphSize, height: Constant.sourceButtonChevronGlyphSize)
                    .frame(width: Constant.sourceButtonChevronSize, height: Constant.sourceButtonChevronSize)
            }
            .padding(.leading, Constant.sourceButtonLeadingPadding)
            .padding(.trailing, Constant.sourceButtonTrailingPadding)
            .padding(.vertical, Constant.sourceButtonVerticalPadding)
            .background(Color(designSystem: .grey600), in: RoundedRectangle(designSystem: .large))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("출처 보기")
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
                LabeledCard.accent(label: "AI 해설", text: result.explanation)
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

    private var submissionFailureNotice: some View {
        StyledText.body2(Constant.submissionFailureMessage, color: .grey400)
    }

    private func bottomActions(layoutMetrics: LayoutMetrics) -> some View {
        ScreenOverlayFooter(layoutMetrics: layoutMetrics) {
            HStack(spacing: LayoutToken.gutter.cgFloatValue) {
                BookmarkButton(
                    isSaved: store.isBookmarked,
                    accessibilityLabel: store.isBookmarked ? "저장 해제하기" : "저장하기",
                    onTap: { send(.bookmarkToggleTapped) },
                )

                primaryAction
            }
        }
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
        static let sourceButtonChevronGlyphSize: CGFloat = 10
        static let sourceButtonChevronSize: CGFloat = 16
        static let sourceButtonLeadingPadding: CGFloat = 16
        static let sourceButtonTrailingPadding: CGFloat = 8
        static let sourceButtonVerticalPadding: CGFloat = 8
    }
}
