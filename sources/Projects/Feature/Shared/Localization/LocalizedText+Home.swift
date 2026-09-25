import Foundation

// MARK: - LocalizedText.Home

extension LocalizedText {
    enum Home {
        enum ProfileHeader {
            enum LoadFailure {
                static var title: String {
                    String(localized: .homeProfileHeaderLoadFailureTitle)
                }

                static var message: String {
                    String(localized: .homeProfileHeaderLoadFailureMessage)
                }
            }

            enum Retry {
                static var buttonTitle: String {
                    String(localized: .homeProfileHeaderRetryButtonTitle)
                }
            }
        }

        enum ProjectSection {
            enum ShowAll {
                static var buttonTitle: String {
                    String(localized: .homeProjectSectionShowAllButtonTitle)
                }
            }

            enum Empty {
                static var message: String {
                    String(localized: .homeProjectSectionEmptyMessage)
                }
            }

            enum SignInRequired {
                static var message: String {
                    String(localized: .homeProjectSectionSignInRequiredMessage)
                }
            }

            enum LoadFailure {
                static var message: String {
                    String(localized: .homeProjectSectionLoadFailureMessage)
                }
            }

            enum Retry {
                static var buttonTitle: String {
                    String(localized: .homeProjectSectionRetryButtonTitle)
                }
            }

            static var title: String {
                String(localized: .homeProjectSectionTitle)
            }
        }

        enum RegistrationPanel {
            enum Title {
                enum First {
                    static var line: String {
                        String(localized: .homeRegistrationPanelTitleFirstLine)
                    }
                }

                enum Second {
                    static var line: String {
                        String(localized: .homeRegistrationPanelTitleSecondLine)
                    }
                }
            }

            enum Register {
                static var buttonTitle: String {
                    String(localized: .homeRegistrationPanelRegisterButtonTitle)
                }
            }

            enum GenerationInProgress {
                static var label: String {
                    String(localized: .homeRegistrationPanelGenerationInProgressLabel)
                }
            }

            static var caption: String {
                String(localized: .homeRegistrationPanelCaption)
            }
        }

        enum SignInSection {
            enum SignIn {
                static var buttonTitle: String {
                    String(localized: .homeSignInSectionSignInButtonTitle)
                }
            }

            static var title: String {
                String(localized: .homeSignInSectionTitle)
            }

            static var caption: String {
                String(localized: .homeSignInSectionCaption)
            }
        }
    }
}
