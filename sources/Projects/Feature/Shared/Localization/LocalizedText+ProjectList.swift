import Foundation

// MARK: - LocalizedText.ProjectList

extension LocalizedText {
    enum ProjectList {
        static var title: String {
            String(localized: .ProjectList.projectListTitle)
        }

        static var deletingModeTitle: String {
            String(localized: .ProjectList.projectListDeletingModeTitle)
        }

        static var menuOpenAccessibilityLabel: String {
            String(localized: .ProjectList.projectListMenuOpenAccessibilityLabel)
        }

        static var deletionMenuItemTitle: String {
            String(localized: .ProjectList.projectListDeletionMenuItemTitle)
        }

        static var deletionMenuItemAccessibilityLabel: String {
            String(localized: .ProjectList.projectListDeletionMenuItemAccessibilityLabel)
        }

        static var retryButtonTitle: String {
            String(localized: .ProjectList.projectListRetryButtonTitle)
        }

        static var deletionDialogTitle: String {
            String(localized: .ProjectList.projectListDeletionDialogTitle)
        }

        static var deletionDialogMessage: String {
            String(localized: .ProjectList.projectListDeletionDialogMessage)
        }

        static var deletionDialogConfirmButtonTitle: String {
            String(localized: .ProjectList.projectListDeletionDialogConfirmButtonTitle)
        }

        static var deletionDialogCancelButtonTitle: String {
            String(localized: .ProjectList.projectListDeletionDialogCancelButtonTitle)
        }

        static var nextPageFooterFailureMessage: String {
            String(localized: .ProjectList.nextPageFooterFailureMessage)
        }

        static var nextPageFooterRetryButtonTitle: String {
            String(localized: .ProjectList.nextPageFooterRetryButtonTitle)
        }

        static var projectCollectionLoadFailureTitle: String {
            String(localized: .ProjectList.projectCollectionLoadFailureTitle)
        }

        static var projectCollectionLoadFailureMessage: String {
            String(localized: .ProjectList.projectCollectionLoadFailureMessage)
        }

        static var projectCollectionEmptyTitle: String {
            String(localized: .ProjectList.projectCollectionEmptyTitle)
        }

        static var projectCollectionEmptyMessage: String {
            String(localized: .ProjectList.projectCollectionEmptyMessage)
        }
    }
}
