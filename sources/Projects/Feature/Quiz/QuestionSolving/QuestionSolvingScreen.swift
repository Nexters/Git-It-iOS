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
                .designSystemScreenMargin()

            ScrollView {
                VStack(alignment: .leading, spacing: Constant.sectionSpacing) {
                    QuestionPrompt(
                        questionNumber: store.questionNumber,
                        questionCount: store.questionCount,
                        prompt: store.question.prompt,
                    )

                    answerSection

                    if let error = store.submissionError {
                        submissionFailureNotice(error: error)
                    }
                }
                .designSystemScreenMargin()
                .padding(.vertical, Constant.contentVerticalPadding)
            }

            bottomActions
        }
        .sheet(isPresented: sourceSheetBinding) {
            SourceSheet(
                sources: QuestionSourceDisplay.list(sources: store.question.sources),
                onLinkTap: { send(.sourceLinkTapped($0)) },
                onClose: { send(.sourceSheetDismissed) },
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: Private

    private var sourceSheetBinding: Binding<Bool> {
        Binding(
            get: { store.isSourceSheetPresented },
            set: { isPresented in
                guard !isPresented else { return }
                send(.sourceSheetDismissed)
            },
        )
    }

    private var essayTextBinding: Binding<String> {
        Binding(
            get: { store.draftEssayText },
            set: { send(.essayTextChanged($0)) },
        )
    }

    @ViewBuilder
    private var answerSection: some View {
        switch store.question.format {
        case .multipleChoice:
            ChoiceSection(
                options: choiceOptions,
                isEnabled: store.answerOutcome == nil && !store.isSubmitting,
                onSelect: { send(.choiceSelected($0)) },
            )

            if case .choice(let result) = store.answerOutcome {
                StyledText.body2(result.explanation, color: .grey300)
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

                if store.isSourceControlPresented {
                    IconGlassButton.neutral(
                        symbol: "doc.text",
                        label: "출처 보기",
                        action: { send(.sourceTapped) },
                    )
                }

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
    }
}
