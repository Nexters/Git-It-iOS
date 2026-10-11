import Foundation

// MARK: - LocalizedText.AppEntry

extension LocalizedText {
    enum AppEntry {
        enum RecoverableError {
            static var title: String {
                String(localized: .appEntryRecoverableErrorTitle)
            }

            static var message: String {
                String(localized: .appEntryRecoverableErrorMessage)
            }
        }

        enum Retry {
            static var buttonTitle: String {
                String(localized: .appEntryRetryButtonTitle)
            }
        }
    }
}
