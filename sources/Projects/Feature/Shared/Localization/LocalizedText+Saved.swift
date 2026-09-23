import Foundation

// MARK: - LocalizedText.Saved

extension LocalizedText {
    enum Saved {
        static var title: String {
            String(localized: .Saved.savedTitle)
        }

        static var retryButtonTitle: String {
            String(localized: .Saved.savedRetryButtonTitle)
        }

        static var loadFailureTitle: String {
            String(localized: .Saved.savedLoadFailureTitle)
        }

        static var loadFailureMessage: String {
            String(localized: .Saved.savedLoadFailureMessage)
        }

        static var emptyTitle: String {
            String(localized: .Saved.savedEmptyTitle)
        }

        static var emptyMessage: String {
            String(localized: .Saved.savedEmptyMessage)
        }

        static var filterAllLabel: String {
            String(localized: .Saved.savedFilterAllLabel)
        }

        static var questionActionTitle: String {
            String(localized: .Saved.savedQuestionActionTitle)
        }

        static func filterCount(count: Int) -> String {
            String(localized: .Saved.savedFilterCount(count: count))
        }

        static func questionMetadata(
            projectName: String,
            setLabel: String,
            problemNumber: Int,
        ) -> String {
            String(
                localized: .Saved.savedQuestionMetadata(
                    projectName: projectName,
                    setLabel: setLabel,
                    problemNumber: problemNumber,
                )
            )
        }
    }
}
