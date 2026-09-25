import Foundation

// MARK: - LocalizedText.ProjectDetail

extension LocalizedText {
    enum ProjectDetail {
        enum Deletion {
            enum Dialog {
                static var title: String {
                    String(localized: .projectDetailDeletionDialogTitle)
                }

                static var message: String {
                    String(localized: .projectDetailDeletionDialogMessage)
                }
            }

            enum DialogConfirm {
                static var buttonTitle: String {
                    String(localized: .projectDetailDeletionDialogConfirmButtonTitle)
                }
            }

            enum DialogCancel {
                static var buttonTitle: String {
                    String(localized: .projectDetailDeletionDialogCancelButtonTitle)
                }
            }

            enum MenuItem {
                static var title: String {
                    String(localized: .projectDetailDeletionMenuItemTitle)
                }
            }
        }

        enum Retry {
            static var buttonTitle: String {
                String(localized: .projectDetailRetryButtonTitle)
            }
        }

        enum SavedQuestionsMenuItem {
            static var title: String {
                String(localized: .projectDetailSavedQuestionsMenuItemTitle)
            }
        }

        enum RepositoryLinkMenuItem {
            static var title: String {
                String(localized: .projectDetailRepositoryLinkMenuItemTitle)
            }
        }

        enum SingleQuestion {
            enum Failure {
                static var title: String {
                    String(localized: .projectDetailSingleQuestionFailureTitle)
                }

                static var message: String {
                    String(localized: .projectDetailSingleQuestionFailureMessage)
                }
            }

            enum FailureConfirm {
                static var buttonTitle: String {
                    String(localized: .projectDetailSingleQuestionFailureConfirmButtonTitle)
                }
            }

            enum Advance {
                static var buttonTitle: String {
                    String(localized: .projectDetailSingleQuestionAdvanceButtonTitle)
                }
            }
        }

        enum DetailContent {
            enum LoadFailure {
                static var title: String {
                    String(localized: .projectDetailDetailContentLoadFailureTitle)
                }

                static var message: String {
                    String(localized: .projectDetailDetailContentLoadFailureMessage)
                }
            }
        }

        enum RepositorySummary {
            enum OverallProgress {
                static var label: String {
                    String(localized: .projectDetailRepositorySummaryOverallProgressLabel)
                }
            }
        }

        enum SetListSection {
            enum Empty {
                static var title: String {
                    String(localized: .projectDetailSetListSectionEmptyTitle)
                }

                static var message: String {
                    String(localized: .projectDetailSetListSectionEmptyMessage)
                }
            }

            static var title: String {
                String(localized: .projectDetailSetListSectionTitle)
            }
        }
    }
}
