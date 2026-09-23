import Foundation

// MARK: - LocalizedText

enum LocalizedText {

    enum GenerationReminder {
        static var completedTitle: String {
            String(localized: .generationReminderCompletedTitle)
        }

        static var completedBody: String {
            String(localized: .generationReminderCompletedBody)
        }

        static var failedTitle: String {
            String(localized: .generationReminderFailedTitle)
        }

        static var failedBody: String {
            String(localized: .generationReminderFailedBody)
        }
    }

}
