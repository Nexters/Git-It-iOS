import Foundation

// MARK: - LocalizedText.MainShell

extension LocalizedText {
    enum MainShell {
        enum Tab {
            enum Home {
                static var title: String {
                    String(localized: .mainShellTabHomeTitle)
                }
            }

            enum Projects {
                static var title: String {
                    String(localized: .mainShellTabProjectsTitle)
                }
            }

            enum Saved {
                static var title: String {
                    String(localized: .mainShellTabSavedTitle)
                }
            }

            enum Settings {
                static var title: String {
                    String(localized: .mainShellTabSettingsTitle)
                }
            }
        }

        enum SingleQuestion {
            enum Failure {
                static var title: String {
                    String(localized: .mainShellSingleQuestionFailureTitle)
                }

                static var message: String {
                    String(localized: .mainShellSingleQuestionFailureMessage)
                }
            }

            enum FailureConfirm {
                static var buttonTitle: String {
                    String(localized: .mainShellSingleQuestionFailureConfirmButtonTitle)
                }
            }

            enum Advance {
                static var buttonTitle: String {
                    String(localized: .mainShellSingleQuestionAdvanceButtonTitle)
                }
            }
        }

        enum SignInRequired {
            enum SignIn {
                static var buttonTitle: String {
                    String(localized: .mainShellSignInRequiredSignInButtonTitle)
                }
            }

            enum Close {
                static var buttonTitle: String {
                    String(localized: .mainShellSignInRequiredCloseButtonTitle)
                }
            }

            static var title: String {
                String(localized: .mainShellSignInRequiredTitle)
            }

            static var message: String {
                String(localized: .mainShellSignInRequiredMessage)
            }
        }
    }
}
