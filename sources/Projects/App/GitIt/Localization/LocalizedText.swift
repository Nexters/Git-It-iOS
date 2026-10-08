import Foundation

// MARK: - LocalizedText

enum LocalizedText {

    enum GenerationReminder {
        enum Completed {
            static var title: String {
                String(localized: .generationReminderCompletedTitle)
            }

            static var body: String {
                String(localized: .generationReminderCompletedBody)
            }
        }

        enum Failed {
            static var title: String {
                String(localized: .generationReminderFailedTitle)
            }

            static var body: String {
                String(localized: .generationReminderFailedBody)
            }
        }
    }

}
