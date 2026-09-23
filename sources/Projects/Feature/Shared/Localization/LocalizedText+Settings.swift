import Foundation

// MARK: - LocalizedText.Settings

extension LocalizedText {
    enum Settings {
        static var title: String {
            String(localized: .Settings.settingsTitle)
        }

        static var learningSectionTitle: String {
            String(localized: .Settings.settingsLearningSectionTitle)
        }

        static var notificationSectionTitle: String {
            String(localized: .Settings.settingsNotificationSectionTitle)
        }

        static var generalSectionTitle: String {
            String(localized: .Settings.settingsGeneralSectionTitle)
        }

        static var positionTitle: String {
            String(localized: .Settings.settingsPositionTitle)
        }

        static var careerLevelTitle: String {
            String(localized: .Settings.settingsCareerLevelTitle)
        }

        static var notificationTitle: String {
            String(localized: .Settings.settingsNotificationTitle)
        }

        static var notificationOnValue: String {
            String(localized: .Settings.settingsNotificationOnValue)
        }

        static var notificationOffValue: String {
            String(localized: .Settings.settingsNotificationOffValue)
        }

        static var termsTitle: String {
            String(localized: .Settings.settingsTermsTitle)
        }

        static var signOutButtonTitle: String {
            String(localized: .Settings.settingsSignOutButtonTitle)
        }

        static var deleteAccountButtonTitle: String {
            String(localized: .Settings.settingsDeleteAccountButtonTitle)
        }

        static var accountActionFailureMessage: String {
            String(localized: .Settings.settingsAccountActionFailureMessage)
        }

        static var profileFailureMessage: String {
            String(localized: .Settings.settingsProfileFailureMessage)
        }

        static var profileTitle: String {
            String(localized: .Settings.profileTitle)
        }

        static var profileStatisticsSectionTitle: String {
            String(localized: .Settings.profileStatisticsSectionTitle)
        }

        static var profileSettingsAccessibilityLabel: String {
            String(localized: .Settings.profileSettingsAccessibilityLabel)
        }

        static var profileWeeklyEmptyTitle: String {
            String(localized: .Settings.profileWeeklyEmptyTitle)
        }

        static var profileMondayLabel: String {
            String(localized: .Settings.profileMondayLabel)
        }

        static var profileTuesdayLabel: String {
            String(localized: .Settings.profileTuesdayLabel)
        }

        static var profileWednesdayLabel: String {
            String(localized: .Settings.profileWednesdayLabel)
        }

        static var profileThursdayLabel: String {
            String(localized: .Settings.profileThursdayLabel)
        }

        static var profileFridayLabel: String {
            String(localized: .Settings.profileFridayLabel)
        }

        static var profileSaturdayLabel: String {
            String(localized: .Settings.profileSaturdayLabel)
        }

        static var profileSundayLabel: String {
            String(localized: .Settings.profileSundayLabel)
        }

        static var profileLoadFailureTitle: String {
            String(localized: .Settings.profileLoadFailureTitle)
        }

        static var profileLoadFailureMessage: String {
            String(localized: .Settings.profileLoadFailureMessage)
        }

        static var profileLoadFailureRetryButtonTitle: String {
            String(localized: .Settings.profileLoadFailureRetryButtonTitle)
        }

        static var statisticsCardThisWeekLabel: String {
            String(localized: .Settings.statisticsCardThisWeekLabel)
        }

        static var statisticsCardThisMonthLabel: String {
            String(localized: .Settings.statisticsCardThisMonthLabel)
        }

        static var statisticsCardStreakLabel: String {
            String(localized: .Settings.statisticsCardStreakLabel)
        }

        static var weeklyChartSectionLabel: String {
            String(localized: .Settings.weeklyChartSectionLabel)
        }

        static var accountDeletionTitle: String {
            String(localized: .Settings.accountDeletionTitle)
        }

        static var accountDeletionConfirmButtonTitle: String {
            String(localized: .Settings.accountDeletionConfirmButtonTitle)
        }

        static var accountDeletionFirstParagraph: String {
            String(localized: .Settings.accountDeletionFirstParagraph)
        }

        static var accountDeletionSecondParagraph: String {
            String(localized: .Settings.accountDeletionSecondParagraph)
        }

        static var accountDeletionThirdParagraph: String {
            String(localized: .Settings.accountDeletionThirdParagraph)
        }

        static var accountDeletionFailureMessage: String {
            String(localized: .Settings.accountDeletionFailureMessage)
        }

        static var positionSelectionTitle: String {
            String(localized: .Settings.positionSelectionTitle)
        }

        static var positionSelectionFailureMessage: String {
            String(localized: .Settings.positionSelectionFailureMessage)
        }

        static var careerLevelSelectionTitle: String {
            String(localized: .Settings.careerLevelSelectionTitle)
        }

        static var careerLevelSelectionFailureMessage: String {
            String(localized: .Settings.careerLevelSelectionFailureMessage)
        }

        static var careerLevelUnselectedTitle: String {
            String(localized: .Settings.careerLevelUnselectedTitle)
        }

        static var careerLevelEntryTitle: String {
            String(localized: .Settings.careerLevelEntryTitle)
        }

        static var careerLevelJuniorTitle: String {
            String(localized: .Settings.careerLevelJuniorTitle)
        }

        static var careerLevelMiddleTitle: String {
            String(localized: .Settings.careerLevelMiddleTitle)
        }

        static var careerLevelSeniorTitle: String {
            String(localized: .Settings.careerLevelSeniorTitle)
        }

        static var careerLevelEntryDescription: String {
            String(localized: .Settings.careerLevelEntryDescription)
        }

        static var careerLevelJuniorDescription: String {
            String(localized: .Settings.careerLevelJuniorDescription)
        }

        static var careerLevelMiddleDescription: String {
            String(localized: .Settings.careerLevelMiddleDescription)
        }

        static var careerLevelSeniorDescription: String {
            String(localized: .Settings.careerLevelSeniorDescription)
        }

        static var positionUnselectedTitle: String {
            String(localized: .Settings.positionUnselectedTitle)
        }

        static func profileWeeklySolvedTitle(count: Int) -> String {
            String(localized: .Settings.profileWeeklySolvedTitle(count: count))
        }

        static func statisticsCardSolvedCountValue(count: Int) -> String {
            String(localized: .Settings.statisticsCardSolvedCountValue(count: count))
        }

        static func statisticsCardStreakDaysValue(days: Int) -> String {
            String(localized: .Settings.statisticsCardStreakDaysValue(days: days))
        }

        static func weeklyChartBarAccessibilityLabel(
            dayLabel: String,
            count: Int,
        ) -> String {
            String(
                localized: .Settings.weeklyChartBarAccessibilityLabel(
                    dayLabel: dayLabel,
                    count: count,
                )
            )
        }
    }
}
