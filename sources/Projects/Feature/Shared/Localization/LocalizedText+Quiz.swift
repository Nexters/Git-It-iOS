import Foundation

// MARK: - LocalizedText.Quiz

extension LocalizedText {
    enum Quiz {
        enum EssayResultSection {
            enum MyAnswer {
                static var label: String {
                    String(localized: .quizEssayResultSectionMyAnswerLabel)
                }
            }

            enum Explanation {
                static var label: String {
                    String(localized: .quizEssayResultSectionExplanationLabel)
                }
            }
        }

        enum IntroContent {
            enum LoadFailure {
                static var title: String {
                    String(localized: .quizIntroContentLoadFailureTitle)
                }

                static var message: String {
                    String(localized: .quizIntroContentLoadFailureMessage)
                }
            }
        }

        enum LearningCompletion {
            enum Confirm {
                static var buttonTitle: String {
                    String(localized: .quizLearningCompletionConfirmButtonTitle)
                }
            }

            static var title: String {
                String(localized: .quizLearningCompletionTitle)
            }

            static var message: String {
                String(localized: .quizLearningCompletionMessage)
            }
        }

        enum LearningSetIntro {
            enum Retry {
                static var buttonTitle: String {
                    String(localized: .quizLearningSetIntroRetryButtonTitle)
                }
            }

            enum Empty {
                static var message: String {
                    String(localized: .quizLearningSetIntroEmptyMessage)
                }
            }

            enum Start {
                static var buttonTitle: String {
                    String(localized: .quizLearningSetIntroStartButtonTitle)
                }
            }
        }

        enum QuestionPrompt {
            enum Number {
                static func badge(questionNumber: Int) -> String {
                    String(localized: .quizQuestionPromptNumberBadge(questionNumber: questionNumber))
                }
            }
        }

        enum QuestionSolving {
            enum Source {
                static var buttonTitle: String {
                    String(localized: .quizQuestionSolvingSourceButtonTitle)
                }
            }

            enum ChoiceExplanation {
                static var label: String {
                    String(localized: .quizQuestionSolvingChoiceExplanationLabel)
                }
            }

            enum Submit {
                static var buttonTitle: String {
                    String(localized: .quizQuestionSolvingSubmitButtonTitle)
                }
            }

            enum Resubmit {
                static var buttonTitle: String {
                    String(localized: .quizQuestionSolvingResubmitButtonTitle)
                }
            }

            enum Essay {
                static var placeholder: String {
                    String(localized: .quizQuestionSolvingEssayPlaceholder)
                }
            }

            enum SubmissionFailure {
                static var message: String {
                    String(localized: .quizQuestionSolvingSubmissionFailureMessage)
                }
            }

            enum NextQuestion {
                static var buttonTitle: String {
                    String(localized: .quizQuestionSolvingNextQuestionButtonTitle)
                }
            }

            enum Complete {
                static var buttonTitle: String {
                    String(localized: .quizQuestionSolvingCompleteButtonTitle)
                }
            }
        }

        enum QuestionSource {
            enum Default {
                static var title: String {
                    String(localized: .quizQuestionSourceDefaultTitle)
                }
            }

            enum Line {
                static func range(
                    start: Int,
                    end: Int,
                ) -> String {
                    String(
                        localized: .quizQuestionSourceLineRange(
                            start: start,
                            end: end,
                        )
                    )
                }
            }

            enum Start {
                static func line(start: Int) -> String {
                    String(localized: .quizQuestionSourceStartLine(start: start))
                }
            }

            enum End {
                static func line(end: Int) -> String {
                    String(localized: .quizQuestionSourceEndLine(end: end))
                }
            }
        }

        enum SourceSheet {
            enum Close {
                static var buttonTitle: String {
                    String(localized: .quizSourceSheetCloseButtonTitle)
                }
            }

            enum Numbered {
                static func title(questionNumber: Int) -> String {
                    String(localized: .quizSourceSheetNumberedTitle(questionNumber: questionNumber))
                }
            }

            static var title: String {
                String(localized: .quizSourceSheetTitle)
            }
        }
    }
}
