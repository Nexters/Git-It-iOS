import Foundation

// MARK: - LocalizedText.Settings

extension LocalizedText {
    enum Settings {
        enum LearningSection {
            static var title: String {
                String(localized: .settingsLearningSectionTitle)
            }
        }

        enum NotificationSection {
            static var title: String {
                String(localized: .settingsNotificationSectionTitle)
            }
        }

        enum GeneralSection {
            static var title: String {
                String(localized: .settingsGeneralSectionTitle)
            }
        }

        enum Notification {
            enum On {
                static var value: String {
                    String(localized: .settingsNotificationOnValue)
                }
            }

            enum Off {
                static var value: String {
                    String(localized: .settingsNotificationOffValue)
                }
            }

            static var title: String {
                String(localized: .settingsNotificationTitle)
            }
        }

        enum Terms {
            static var title: String {
                String(localized: .settingsTermsTitle)
            }
        }

        enum SignOut {
            static var buttonTitle: String {
                String(localized: .settingsSignOutButtonTitle)
            }
        }

        enum DeleteAccount {
            static var buttonTitle: String {
                String(localized: .settingsDeleteAccountButtonTitle)
            }
        }

        enum AccountActionFailure {
            static var message: String {
                String(localized: .settingsAccountActionFailureMessage)
            }
        }

        enum ProfileFailure {
            static var message: String {
                String(localized: .settingsProfileFailureMessage)
            }
        }

        enum AccountDeletion {
            enum Confirm {
                static var buttonTitle: String {
                    String(localized: .settingsAccountDeletionConfirmButtonTitle)
                }
            }

            enum First {
                static var paragraph: String {
                    String(localized: .settingsAccountDeletionFirstParagraph)
                }
            }

            enum Second {
                static var paragraph: String {
                    String(localized: .settingsAccountDeletionSecondParagraph)
                }
            }

            enum Third {
                static var paragraph: String {
                    String(localized: .settingsAccountDeletionThirdParagraph)
                }
            }

            enum Failure {
                static var message: String {
                    String(localized: .settingsAccountDeletionFailureMessage)
                }
            }

            static var title: String {
                String(localized: .settingsAccountDeletionTitle)
            }
        }

        enum CareerLevel {
            enum Unselected {
                static var title: String {
                    String(localized: .settingsCareerLevelUnselectedTitle)
                }
            }

            enum Entry {
                static var title: String {
                    String(localized: .settingsCareerLevelEntryTitle)
                }

                static var description: String {
                    String(localized: .settingsCareerLevelEntryDescription)
                }
            }

            enum Junior {
                static var title: String {
                    String(localized: .settingsCareerLevelJuniorTitle)
                }

                static var description: String {
                    String(localized: .settingsCareerLevelJuniorDescription)
                }
            }

            enum Middle {
                static var title: String {
                    String(localized: .settingsCareerLevelMiddleTitle)
                }

                static var description: String {
                    String(localized: .settingsCareerLevelMiddleDescription)
                }
            }

            enum Senior {
                static var title: String {
                    String(localized: .settingsCareerLevelSeniorTitle)
                }

                static var description: String {
                    String(localized: .settingsCareerLevelSeniorDescription)
                }
            }

            static var title: String {
                String(localized: .settingsCareerLevelTitle)
            }
        }

        enum CareerLevelSelection {
            enum Failure {
                static var message: String {
                    String(localized: .settingsCareerLevelSelectionFailureMessage)
                }
            }

            static var title: String {
                String(localized: .settingsCareerLevelSelectionTitle)
            }
        }

        enum Position {
            enum Unselected {
                static var title: String {
                    String(localized: .settingsPositionUnselectedTitle)
                }
            }

            static var title: String {
                String(localized: .settingsPositionTitle)
            }
        }

        enum PositionSelection {
            enum Failure {
                static var message: String {
                    String(localized: .settingsPositionSelectionFailureMessage)
                }
            }

            static var title: String {
                String(localized: .settingsPositionSelectionTitle)
            }
        }

        enum Profile {
            enum StatisticsSection {
                static var title: String {
                    String(localized: .settingsProfileStatisticsSectionTitle)
                }
            }

            enum Weekly {
                enum Empty {
                    static var title: String {
                        String(localized: .settingsProfileWeeklyEmptyTitle)
                    }
                }

                enum Solved {
                    static func title(count: Int) -> String {
                        String(localized: .settingsProfileWeeklySolvedTitle(count: count))
                    }
                }
            }

            enum Monday {
                static var label: String {
                    String(localized: .settingsProfileMondayLabel)
                }
            }

            enum Tuesday {
                static var label: String {
                    String(localized: .settingsProfileTuesdayLabel)
                }
            }

            enum Wednesday {
                static var label: String {
                    String(localized: .settingsProfileWednesdayLabel)
                }
            }

            enum Thursday {
                static var label: String {
                    String(localized: .settingsProfileThursdayLabel)
                }
            }

            enum Friday {
                static var label: String {
                    String(localized: .settingsProfileFridayLabel)
                }
            }

            enum Saturday {
                static var label: String {
                    String(localized: .settingsProfileSaturdayLabel)
                }
            }

            enum Sunday {
                static var label: String {
                    String(localized: .settingsProfileSundayLabel)
                }
            }

            enum LoadFailure {
                enum Retry {
                    static var buttonTitle: String {
                        String(localized: .settingsProfileLoadFailureRetryButtonTitle)
                    }
                }

                static var title: String {
                    String(localized: .settingsProfileLoadFailureTitle)
                }

                static var message: String {
                    String(localized: .settingsProfileLoadFailureMessage)
                }
            }

            static var title: String {
                String(localized: .settingsProfileTitle)
            }
        }

        enum StatisticsCard {
            enum ThisWeek {
                static var label: String {
                    String(localized: .settingsStatisticsCardThisWeekLabel)
                }
            }

            enum ThisMonth {
                static var label: String {
                    String(localized: .settingsStatisticsCardThisMonthLabel)
                }
            }

            enum Streak {
                enum Days {
                    static func value(days: Int) -> String {
                        String(localized: .settingsStatisticsCardStreakDaysValue(days: days))
                    }
                }

                static var label: String {
                    String(localized: .settingsStatisticsCardStreakLabel)
                }
            }

            enum SolvedCount {
                static func value(count: Int) -> String {
                    String(localized: .settingsStatisticsCardSolvedCountValue(count: count))
                }
            }
        }

        enum WeeklyChart {
            enum Section {
                static var label: String {
                    String(localized: .settingsWeeklyChartSectionLabel)
                }
            }
        }

        static var title: String {
            String(localized: .settingsTitle)
        }
    }
}
