import Foundation

// MARK: - LocalizedText.Saved

extension LocalizedText {
    enum Saved {
        enum Retry {
            static var buttonTitle: String {
                String(localized: .savedRetryButtonTitle)
            }
        }

        enum LoadFailure {
            static var title: String {
                String(localized: .savedLoadFailureTitle)
            }

            static var message: String {
                String(localized: .savedLoadFailureMessage)
            }
        }

        enum Empty {
            static var title: String {
                String(localized: .savedEmptyTitle)
            }

            static var message: String {
                String(localized: .savedEmptyMessage)
            }
        }

        enum Filter {
            enum All {
                static var label: String {
                    String(localized: .savedFilterAllLabel)
                }
            }

            static func count(count: Int) -> String {
                String(localized: .savedFilterCount(count: count))
            }
        }

        enum Question {
            enum Action {
                static var title: String {
                    String(localized: .savedQuestionActionTitle)
                }
            }

            static func metadata(
                projectName: String,
                setLabel: String,
                problemNumber: Int,
            ) -> String {
                String(
                    localized: .savedQuestionMetadata(
                        projectName: projectName,
                        setLabel: setLabel,
                        problemNumber: problemNumber,
                    )
                )
            }
        }

        static var title: String {
            String(localized: .savedTitle)
        }
    }
}
