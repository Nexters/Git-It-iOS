import Foundation

// MARK: - LocalizedText.Quiz

extension LocalizedText {
    enum Quiz {
        static var learningCompletionTitle: String {
            String(localized: .Quiz.learningCompletionTitle)
        }

        static var learningCompletionMessage: String {
            String(localized: .Quiz.learningCompletionMessage)
        }

        static var learningCompletionConfirmButtonTitle: String {
            String(localized: .Quiz.learningCompletionConfirmButtonTitle)
        }

        static var learningSetIntroRetryButtonTitle: String {
            String(localized: .Quiz.learningSetIntroRetryButtonTitle)
        }

        static var learningSetIntroEmptyMessage: String {
            String(localized: .Quiz.learningSetIntroEmptyMessage)
        }

        static var learningSetIntroStartButtonTitle: String {
            String(localized: .Quiz.learningSetIntroStartButtonTitle)
        }

        static var introContentLoadFailureTitle: String {
            String(localized: .Quiz.introContentLoadFailureTitle)
        }

        static var introContentLoadFailureMessage: String {
            String(localized: .Quiz.introContentLoadFailureMessage)
        }

        static var questionSolvingSourceButtonTitle: String {
            String(localized: .Quiz.questionSolvingSourceButtonTitle)
        }

        static var questionSolvingSourceAccessibilityLabel: String {
            String(localized: .Quiz.questionSolvingSourceAccessibilityLabel)
        }

        static var questionSolvingChoiceExplanationLabel: String {
            String(localized: .Quiz.questionSolvingChoiceExplanationLabel)
        }

        static var questionSolvingSubmitButtonTitle: String {
            String(localized: .Quiz.questionSolvingSubmitButtonTitle)
        }

        static var questionSolvingResubmitButtonTitle: String {
            String(localized: .Quiz.questionSolvingResubmitButtonTitle)
        }

        static var questionSolvingBookmarkAccessibilityLabel: String {
            String(localized: .Quiz.questionSolvingBookmarkAccessibilityLabel)
        }

        static var questionSolvingUnbookmarkAccessibilityLabel: String {
            String(localized: .Quiz.questionSolvingUnbookmarkAccessibilityLabel)
        }

        static var questionSolvingEssayPlaceholder: String {
            String(localized: .Quiz.questionSolvingEssayPlaceholder)
        }

        static var questionSolvingSubmissionFailureMessage: String {
            String(localized: .Quiz.questionSolvingSubmissionFailureMessage)
        }

        static var questionSolvingNextQuestionButtonTitle: String {
            String(localized: .Quiz.questionSolvingNextQuestionButtonTitle)
        }

        static var questionSolvingCompleteButtonTitle: String {
            String(localized: .Quiz.questionSolvingCompleteButtonTitle)
        }

        static var essayResultSectionMyAnswerLabel: String {
            String(localized: .Quiz.essayResultSectionMyAnswerLabel)
        }

        static var essayResultSectionExplanationLabel: String {
            String(localized: .Quiz.essayResultSectionExplanationLabel)
        }

        static var sourceSheetCloseButtonTitle: String {
            String(localized: .Quiz.sourceSheetCloseButtonTitle)
        }

        static var sourceSheetTitle: String {
            String(localized: .Quiz.sourceSheetTitle)
        }

        static var choiceOptionSelectedLabel: String {
            String(localized: .Quiz.choiceOptionSelectedLabel)
        }

        static var choiceOptionCorrectLabel: String {
            String(localized: .Quiz.choiceOptionCorrectLabel)
        }

        static var choiceOptionIncorrectLabel: String {
            String(localized: .Quiz.choiceOptionIncorrectLabel)
        }

        static var questionSourceLinkLabel: String {
            String(localized: .Quiz.questionSourceLinkLabel)
        }

        static var questionSourceDefaultTitle: String {
            String(localized: .Quiz.questionSourceDefaultTitle)
        }

        static func learningCompletionScoreAccessibilityLabel(
            choiceQuestionCount: Int,
            correctChoiceCount: Int,
        ) -> String {
            String(
                localized: .Quiz.learningCompletionScoreAccessibilityLabel(
                    choiceQuestionCount: choiceQuestionCount,
                    correctChoiceCount: correctChoiceCount,
                )
            )
        }

        static func questionPromptNumberBadge(questionNumber: Int) -> String {
            String(localized: .Quiz.questionPromptNumberBadge(questionNumber: questionNumber))
        }

        static func sourceSheetNumberedTitle(questionNumber: Int) -> String {
            String(localized: .Quiz.sourceSheetNumberedTitle(questionNumber: questionNumber))
        }

        static func choiceOptionNumberLabel(number: Int) -> String {
            String(localized: .Quiz.choiceOptionNumberLabel(number: number))
        }

        static func questionSourceLineRange(
            start: Int,
            end: Int,
        ) -> String {
            String(localized: .Quiz.questionSourceLineRange(
                start: start,
                end: end,
            ))
        }

        static func questionSourceStartLine(start: Int) -> String {
            String(localized: .Quiz.questionSourceStartLine(start: start))
        }

        static func questionSourceEndLine(end: Int) -> String {
            String(localized: .Quiz.questionSourceEndLine(end: end))
        }
    }
}
