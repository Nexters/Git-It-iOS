import Foundation

// MARK: - LocalizedText.Onboarding

extension LocalizedText {
    enum Onboarding {
        enum AllAgreementRow {
            static var title: String {
                String(localized: .onboardingAllAgreementRowTitle)
            }
        }

        enum CareerSelection {
            enum SubmissionFailure {
                static var message: String {
                    String(localized: .onboardingCareerSelectionSubmissionFailureMessage)
                }
            }

            enum Next {
                static var buttonTitle: String {
                    String(localized: .onboardingCareerSelectionNextButtonTitle)
                }
            }

            enum Entry {
                static var title: String {
                    String(localized: .onboardingCareerSelectionEntryTitle)
                }

                static var description: String {
                    String(localized: .onboardingCareerSelectionEntryDescription)
                }
            }

            enum Junior {
                static var title: String {
                    String(localized: .onboardingCareerSelectionJuniorTitle)
                }

                static var description: String {
                    String(localized: .onboardingCareerSelectionJuniorDescription)
                }
            }

            enum Middle {
                static var title: String {
                    String(localized: .onboardingCareerSelectionMiddleTitle)
                }

                static var description: String {
                    String(localized: .onboardingCareerSelectionMiddleDescription)
                }
            }

            enum Senior {
                static var title: String {
                    String(localized: .onboardingCareerSelectionSeniorTitle)
                }

                static var description: String {
                    String(localized: .onboardingCareerSelectionSeniorDescription)
                }
            }

            static var title: String {
                String(localized: .onboardingCareerSelectionTitle)
            }

            static var guidance: String {
                String(localized: .onboardingCareerSelectionGuidance)
            }
        }

        enum LegalAgreement {
            enum Cancel {
                static var buttonTitle: String {
                    String(localized: .onboardingLegalAgreementCancelButtonTitle)
                }
            }

            enum Next {
                static var buttonTitle: String {
                    String(localized: .onboardingLegalAgreementNextButtonTitle)
                }
            }

            static var title: String {
                String(localized: .onboardingLegalAgreementTitle)
            }
        }

        enum PositionSelection {
            enum ExitFailure {
                static var message: String {
                    String(localized: .onboardingPositionSelectionExitFailureMessage)
                }
            }

            enum Next {
                static var buttonTitle: String {
                    String(localized: .onboardingPositionSelectionNextButtonTitle)
                }
            }

            static var title: String {
                String(localized: .onboardingPositionSelectionTitle)
            }
        }

        enum Tutorial {
            enum Page {
                enum First {
                    static var title: String {
                        String(localized: .onboardingTutorialPageFirstTitle)
                    }
                }

                enum Second {
                    static var title: String {
                        String(localized: .onboardingTutorialPageSecondTitle)
                    }
                }

                enum Third {
                    static var title: String {
                        String(localized: .onboardingTutorialPageThirdTitle)
                    }
                }
            }

            enum SignIn {
                enum Hint {
                    static var title: String {
                        String(localized: .onboardingTutorialSignInHintTitle)
                    }
                }

                enum GuestAccess {
                    static var buttonTitle: String {
                        String(localized: .onboardingTutorialSignInGuestAccessButtonTitle)
                    }
                }

                static func version(version: String) -> String {
                    String(localized: .onboardingTutorialSignInVersion(version: version))
                }
            }
        }
    }
}
