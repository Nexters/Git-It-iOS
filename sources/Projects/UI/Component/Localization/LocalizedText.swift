import Foundation

// MARK: - LocalizedText

enum LocalizedText {

    enum AppleSignInButton {
        static var title: String {
            String(localized: .appleSignInButtonTitle)
        }
    }

    enum ChoiceAnswerOption {
        static var correctLabel: String {
            String(localized: .choiceAnswerOptionCorrectLabel)
        }

        static var incorrectLabel: String {
            String(localized: .choiceAnswerOptionIncorrectLabel)
        }

        static var collapseActionName: String {
            String(localized: .choiceAnswerOptionCollapseActionName)
        }

        static var expandActionName: String {
            String(localized: .choiceAnswerOptionExpandActionName)
        }
    }

    enum ChoiceResultRow {
        static var correctLabel: String {
            String(localized: .choiceResultRowCorrectLabel)
        }

        static var incorrectLabel: String {
            String(localized: .choiceResultRowIncorrectLabel)
        }
    }

    enum ContinuousProgressBar {
        static var accessibilityLabel: String {
            String(localized: .continuousProgressBarAccessibilityLabel)
        }

        static func accessibilityValue(percent: Int) -> String {
            String(localized: .continuousProgressBarAccessibilityValue(percent: percent))
        }
    }

    enum HomeProjectCard {
        static var learningEnabledAccessibilityHint: String {
            String(localized: .homeProjectCardLearningEnabledAccessibilityHint)
        }

        static var learningDisabledAccessibilityHint: String {
            String(localized: .homeProjectCardLearningDisabledAccessibilityHint)
        }

        static func accessibilityLabel(
            title: String,
            currentSetLabel: String,
        ) -> String {
            String(
                localized: .homeProjectCardAccessibilityLabel(
                    title: title,
                    currentSetLabel: currentSetLabel,
                )
            )
        }

        static func learningStartAccessibilityLabel(title: String) -> String {
            String(localized: .homeProjectCardLearningStartAccessibilityLabel(title: title))
        }
    }

    enum LabeledTextField {
        static var clearAccessibilityLabel: String {
            String(localized: .labeledTextFieldClearAccessibilityLabel)
        }
    }

    enum LearningSetRow {
        static func learningStartAccessibilityLabel(
            label: String,
            title: String,
        ) -> String {
            String(
                localized: .learningSetRowLearningStartAccessibilityLabel(
                    label: label,
                    title: title,
                )
            )
        }
    }

    enum PageIndicator {
        static var accessibilityLabel: String {
            String(localized: .pageIndicatorAccessibilityLabel)
        }

        static func accessibilityValue(
            totalPages: Int,
            currentPage: Int,
        ) -> String {
            String(
                localized: .pageIndicatorAccessibilityValue(
                    totalPages: totalPages,
                    currentPage: currentPage,
                )
            )
        }
    }

    enum PolicyAgreementRow {
        static var requiredLabel: String {
            String(localized: .policyAgreementRowRequiredLabel)
        }

        static var optionalLabel: String {
            String(localized: .policyAgreementRowOptionalLabel)
        }

        static func fullTextAccessibilityLabel(title: String) -> String {
            String(localized: .policyAgreementRowFullTextAccessibilityLabel(title: title))
        }
    }

    enum ProgressSegments {
        static func accessibilityLabel(
            total: Int,
            completed: Int,
        ) -> String {
            String(
                localized: .progressSegmentsAccessibilityLabel(
                    total: total,
                    completed: completed,
                )
            )
        }
    }

    enum ProjectRow {
        static func deleteAccessibilityLabel(name: String) -> String {
            String(localized: .projectRowDeleteAccessibilityLabel(name: name))
        }

        static func learningStartAccessibilityLabel(name: String) -> String {
            String(localized: .projectRowLearningStartAccessibilityLabel(name: name))
        }
    }

    enum SavedQuestionCard {
        static var bookmarkAccessibilityLabel: String {
            String(localized: .savedQuestionCardBookmarkAccessibilityLabel)
        }

        static var unbookmarkAccessibilityLabel: String {
            String(localized: .savedQuestionCardUnbookmarkAccessibilityLabel)
        }
    }

    enum ScreenControlBar {
        static var backAccessibilityLabel: String {
            String(localized: .screenControlBarBackAccessibilityLabel)
        }

        static var closeAccessibilityLabel: String {
            String(localized: .screenControlBarCloseAccessibilityLabel)
        }
    }

    enum WebSheet {
        static var closeAccessibilityLabel: String {
            String(localized: .webSheetCloseAccessibilityLabel)
        }
    }

}
