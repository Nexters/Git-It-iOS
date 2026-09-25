import Foundation

// MARK: - LocalizedText.ProjectList

extension LocalizedText {
    enum ProjectList {
        enum DeletingMode {
            static var title: String {
                String(localized: .projectListDeletingModeTitle)
            }
        }

        enum Deletion {
            enum MenuItem {
                static var title: String {
                    String(localized: .projectListDeletionMenuItemTitle)
                }
            }

            enum Dialog {
                static var title: String {
                    String(localized: .projectListDeletionDialogTitle)
                }

                static var message: String {
                    String(localized: .projectListDeletionDialogMessage)
                }
            }

            enum DialogConfirm {
                static var buttonTitle: String {
                    String(localized: .projectListDeletionDialogConfirmButtonTitle)
                }
            }

            enum DialogCancel {
                static var buttonTitle: String {
                    String(localized: .projectListDeletionDialogCancelButtonTitle)
                }
            }
        }

        enum Retry {
            static var buttonTitle: String {
                String(localized: .projectListRetryButtonTitle)
            }
        }

        enum NextPageFooter {
            enum Failure {
                static var message: String {
                    String(localized: .projectListNextPageFooterFailureMessage)
                }
            }

            enum Retry {
                static var buttonTitle: String {
                    String(localized: .projectListNextPageFooterRetryButtonTitle)
                }
            }
        }

        enum ProjectCollection {
            enum LoadFailure {
                static var title: String {
                    String(localized: .projectListProjectCollectionLoadFailureTitle)
                }

                static var message: String {
                    String(localized: .projectListProjectCollectionLoadFailureMessage)
                }
            }

            enum Empty {
                static var title: String {
                    String(localized: .projectListProjectCollectionEmptyTitle)
                }

                static var message: String {
                    String(localized: .projectListProjectCollectionEmptyMessage)
                }
            }
        }

        static var title: String {
            String(localized: .projectListTitle)
        }
    }
}
