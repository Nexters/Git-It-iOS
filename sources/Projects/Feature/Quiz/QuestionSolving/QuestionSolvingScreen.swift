import ComposableArchitecture
import DesignSystem
import DomainQuizDetail
import SwiftUI
import UIComponent

// MARK: - QuestionSolvingScreen

@ViewAction(for: QuestionSolvingFeature.self)
struct QuestionSolvingScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<QuestionSolvingFeature>

    var body: some View {
        content
            .contentShape(Rectangle())
            .onTapGesture { isEssayFieldFocused = false }
            .overlay {
                ModalOverlay(
                    isPresented: Binding(
                        get: { store.isSourceSheetPresented },
                        set: { isPresented in
                            if !isPresented {
                                send(.sourceSheetDismissed)
                            }
                        },
                    )
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

    @FocusState private var isEssayFieldFocused: Bool

    private var content: some View {
        OverlayContainer {
            ScreenControlBar(
                onLeadingTap: { send(.backTapped) }
            ).designSystemScreenMargin()
        } content: {
            VStack(
                alignment: .leading,
                spacing: Constant.sectionSpacing,
            ) {
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
        } footer: {
            bottomActions
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
                StyledText(text: LocalizedText.Quiz.QuestionSolving.Source.buttonTitle)
                    .textStyle(.body2)
                    .foregroundColorToken(.blue100)

                ResourceImage(
                    asset: .icon(.chevronRight),
                    contentMode: .fit,
                )
                .designSystemForeground(.blue100)
                .frame(
                    width: Constant.sourceButtonChevronGlyphSize,
                    height: Constant.sourceButtonChevronGlyphSize,
                )
                .frame(
                    width: Constant.sourceButtonChevronSize,
                    height: Constant.sourceButtonChevronSize,
                )
            }
            .padding(.leading, Constant.sourceButtonLeadingPadding)
            .padding(.trailing, Constant.sourceButtonTrailingPadding)
            .padding(.vertical, Constant.sourceButtonVerticalPadding)
        }
        .background(
            Color(designSystem: .grey600),
            in: RoundedRectangle(designSystem: .small),
        )
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var answerSection: some View {
        switch store.question.content {
        case .choice:
            ChoiceSection(
                questionID: store.question.id,
                options: choiceOptions,
                isEnabled: store.answerOutcome == nil && !store.isSubmitting,
                isGraded: store.answerOutcome != nil,
                onSelect: { send(.choiceSelected($0)) },
            )

            if case .choice(let grading) = store.answerOutcome {
                LabeledCard(displayModel: .init(
                    label: LocalizedText.Quiz.QuestionSolving.ChoiceExplanation.label,
                    text: grading.explanation,
                ))
                .style(.accent)
            }

        case .essay:
            if case .essay(let grading) = store.answerOutcome {
                EssayResultSection(
                    myAnswer: store.draftEssayText,
                    aiAnswer: grading.explanation,
                    criteria: grading.rubric,
                )
            } else {
                AnswerEditor(
                    text: essayTextBinding,
                    isFocused: $isEssayFieldFocused,
                    placeholder: LocalizedText.Quiz.QuestionSolving.Essay.placeholder,
                    characterLimit: QuestionSolvingFeature.essayCharacterLimit,
                    isDisabled: store.isSubmitting,
                )
            }
        }
    }

    private var choiceOptions: [ChoiceOptionDisplay] {
        guard case .choice(let choices, _) = store.question.content else { return [] }
        guard case .choice(let grading) = store.answerOutcome else {
            return ChoiceOptionDisplay.editing(
                choices: choices,
                selectedIndex: store.draftChoiceIndex,
            )
        }
        return ChoiceOptionDisplay.answered(
            choices: choices,
            selectedIndex: store.draftChoiceIndex,
            grading: grading,
        )
    }

    @ViewBuilder
    private var primaryAction: some View {
        if store.answerOutcome == nil {
            FeedbackActionButton(
                title: store.submissionError == nil
                    ? LocalizedText.Quiz.QuestionSolving.Submit.buttonTitle
                    : LocalizedText.Quiz.QuestionSolving.Resubmit.buttonTitle,
                action: { send(.submitAnswerTapped) },
            )
            .enabled(store.isSubmitEnabled)
        } else {
            FeedbackActionButton(
                title: store.advanceActionTitle,
                action: { send(.advanceTapped) },
            )
        }
    }

    private var submissionFailureNotice: some View {
        StyledText(text: LocalizedText.Quiz.QuestionSolving.SubmissionFailure.message)
            .textStyle(.body2)
            .foregroundColorToken(.grey400)
    }

    private var bottomActions: some View {
        BottomActionBar {
            HStack(spacing: LayoutToken.compactSpacing) {
                BookmarkButton(
                    isSaved: Binding(
                        get: { store.isBookmarked },
                        set: { _ in send(.bookmarkToggleTapped) },
                    )
                )

                primaryAction
            }
            .designSystemScreenMargin()
        }
    }

}

// MARK: QuestionSolvingScreen.Constant

extension QuestionSolvingScreen {
    fileprivate enum Constant {
        static let sectionSpacing: CGFloat = 24
        static let contentVerticalPadding: CGFloat = 20
        static let sourceButtonSpacing: CGFloat = 2
        static let sourceButtonChevronGlyphSize: CGFloat = 16
        static let sourceButtonChevronSize: CGFloat = 16
        static let sourceButtonLeadingPadding: CGFloat = 16
        static let sourceButtonTrailingPadding: CGFloat = 8
        static let sourceButtonVerticalPadding: CGFloat = 8
    }
}
