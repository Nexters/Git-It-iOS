import Foundation

// MARK: - LocalizedText.AppEntry

extension LocalizedText {
    enum AppEntry {
        static var recoverableErrorTitle: String {
            String(localized: .AppEntry.appEntryRecoverableErrorTitle)
        }

        static var recoverableErrorMessage: String {
            String(localized: .AppEntry.appEntryRecoverableErrorMessage)
        }

        static var retryButtonTitle: String {
            String(localized: .AppEntry.appEntryRetryButtonTitle)
        }
    }
}
