import Foundation

// MARK: - LocalizedText.ProjectRegistration

extension LocalizedText {
    enum ProjectRegistration {
        enum Checklist {
            enum RepositoryInfo {
                static var title: String {
                    String(localized: .projectRegistrationChecklistRepositoryInfoTitle)
                }
            }

            enum CodeStructureAnalysis {
                static var title: String {
                    String(localized: .projectRegistrationChecklistCodeStructureAnalysisTitle)
                }
            }

            enum LearningOutlineComposition {
                static var title: String {
                    String(localized: .projectRegistrationChecklistLearningOutlineCompositionTitle)
                }
            }

            enum QuizGeneration {
                static var title: String {
                    String(localized: .projectRegistrationChecklistQuizGenerationTitle)
                }
            }

            enum Verification {
                static var title: String {
                    String(localized: .projectRegistrationChecklistVerificationTitle)
                }
            }
        }

        enum GenerationReminderSheet {
            enum Enable {
                static var buttonTitle: String {
                    String(localized: .projectRegistrationGenerationReminderSheetEnableButtonTitle)
                }
            }

            enum Dismiss {
                static var buttonTitle: String {
                    String(localized: .projectRegistrationGenerationReminderSheetDismissButtonTitle)
                }
            }

            static var title: String {
                String(localized: .projectRegistrationGenerationReminderSheetTitle)
            }

            static var message: String {
                String(localized: .projectRegistrationGenerationReminderSheetMessage)
            }
        }

        enum GuideSection {
            enum First {
                static var step: String {
                    String(localized: .projectRegistrationGuideSectionFirstStep)
                }
            }

            enum Second {
                static var step: String {
                    String(localized: .projectRegistrationGuideSectionSecondStep)
                }
            }

            enum Third {
                static var step: String {
                    String(localized: .projectRegistrationGuideSectionThirdStep)
                }
            }

            enum Fourth {
                static var step: String {
                    String(localized: .projectRegistrationGuideSectionFourthStep)
                }
            }

            enum Fifth {
                static var step: String {
                    String(localized: .projectRegistrationGuideSectionFifthStep)
                }
            }

            static var title: String {
                String(localized: .projectRegistrationGuideSectionTitle)
            }
        }

        enum QuizGenerationConfirmation {
            enum Duration {
                static var message: String {
                    String(localized: .projectRegistrationQuizGenerationConfirmationDurationMessage)
                }
            }

            enum Start {
                static var buttonTitle: String {
                    String(localized: .projectRegistrationQuizGenerationConfirmationStartButtonTitle)
                }
            }

            static var title: String {
                String(localized: .projectRegistrationQuizGenerationConfirmationTitle)
            }
        }

        enum QuizGenerationFailure {
            enum Retry {
                static var buttonTitle: String {
                    String(localized: .projectRegistrationQuizGenerationFailureRetryButtonTitle)
                }
            }

            static var title: String {
                String(localized: .projectRegistrationQuizGenerationFailureTitle)
            }

            static var message: String {
                String(localized: .projectRegistrationQuizGenerationFailureMessage)
            }
        }

        enum QuizGenerationProgress {
            enum Duration {
                static var message: String {
                    String(localized: .projectRegistrationQuizGenerationProgressDurationMessage)
                }
            }

            enum WaitAtHome {
                static var buttonTitle: String {
                    String(localized: .projectRegistrationQuizGenerationProgressWaitAtHomeButtonTitle)
                }
            }

            static var title: String {
                String(localized: .projectRegistrationQuizGenerationProgressTitle)
            }
        }

        enum QuizLevelSelection {
            enum Next {
                static var buttonTitle: String {
                    String(localized: .projectRegistrationQuizLevelSelectionNextButtonTitle)
                }
            }

            enum Basic {
                static var title: String {
                    String(localized: .projectRegistrationQuizLevelSelectionBasicTitle)
                }

                static var description: String {
                    String(localized: .projectRegistrationQuizLevelSelectionBasicDescription)
                }
            }

            enum Intermediate {
                static var title: String {
                    String(localized: .projectRegistrationQuizLevelSelectionIntermediateTitle)
                }

                static var description: String {
                    String(localized: .projectRegistrationQuizLevelSelectionIntermediateDescription)
                }
            }

            enum Advanced {
                static var title: String {
                    String(localized: .projectRegistrationQuizLevelSelectionAdvancedTitle)
                }

                static var description: String {
                    String(localized: .projectRegistrationQuizLevelSelectionAdvancedDescription)
                }
            }

            static var title: String {
                String(localized: .projectRegistrationQuizLevelSelectionTitle)
            }
        }

        enum RepositoryConfirmation {
            enum Next {
                static var buttonTitle: String {
                    String(localized: .projectRegistrationRepositoryConfirmationNextButtonTitle)
                }
            }

            enum Reject {
                static var buttonTitle: String {
                    String(localized: .projectRegistrationRepositoryConfirmationRejectButtonTitle)
                }
            }

            static var title: String {
                String(localized: .projectRegistrationRepositoryConfirmationTitle)
            }
        }

        enum RepositoryLinkInput {
            enum Field {
                static var label: String {
                    String(localized: .projectRegistrationRepositoryLinkInputFieldLabel)
                }
            }

            enum ValidationError {
                static var message: String {
                    String(localized: .projectRegistrationRepositoryLinkInputValidationErrorMessage)
                }
            }

            enum Validating {
                static var buttonTitle: String {
                    String(localized: .projectRegistrationRepositoryLinkInputValidatingButtonTitle)
                }
            }

            enum Next {
                static var buttonTitle: String {
                    String(localized: .projectRegistrationRepositoryLinkInputNextButtonTitle)
                }
            }

            static var title: String {
                String(localized: .projectRegistrationRepositoryLinkInputTitle)
            }
        }
    }
}
