import Foundation

// MARK: - LocalizedText.ShareRegistration

extension LocalizedText {
    enum ShareRegistration {
        enum Lookup {
            enum Failure {
                static var reason: String {
                    String(localized: .shareRegistrationLookupFailureReason)
                }
            }

            static var message: String {
                String(localized: .shareRegistrationLookupMessage)
            }
        }

        enum Submitting {
            static var message: String {
                String(localized: .shareRegistrationSubmittingMessage)
            }
        }

        enum InvalidLink {
            static var title: String {
                String(localized: .shareRegistrationInvalidLinkTitle)
            }

            static var reason: String {
                String(localized: .shareRegistrationInvalidLinkReason)
            }
        }

        enum SignInRequired {
            static var title: String {
                String(localized: .shareRegistrationSignInRequiredTitle)
            }

            static var message: String {
                String(localized: .shareRegistrationSignInRequiredMessage)
            }
        }

        enum AppLaunchRequired {
            static var title: String {
                String(localized: .shareRegistrationAppLaunchRequiredTitle)
            }

            static var message: String {
                String(localized: .shareRegistrationAppLaunchRequiredMessage)
            }
        }

        enum Success {
            static var title: String {
                String(localized: .shareRegistrationSuccessTitle)
            }

            static var message: String {
                String(localized: .shareRegistrationSuccessMessage)
            }
        }

        enum Failure {
            static var title: String {
                String(localized: .shareRegistrationFailureTitle)
            }
        }

        enum Retry {
            static var buttonTitle: String {
                String(localized: .shareRegistrationRetryButtonTitle)
            }
        }

        enum Dismiss {
            static var buttonTitle: String {
                String(localized: .shareRegistrationDismissButtonTitle)
            }
        }

        enum SharedItemUnavailable {
            static var reason: String {
                String(localized: .shareRegistrationSharedItemUnavailableReason)
            }
        }

        enum InvalidRequest {
            static var reason: String {
                String(localized: .shareRegistrationInvalidRequestReason)
            }
        }

        enum DuplicateRequest {
            static var reason: String {
                String(localized: .shareRegistrationDuplicateRequestReason)
            }
        }

        enum TemporarilyUnavailable {
            static var reason: String {
                String(localized: .shareRegistrationTemporarilyUnavailableReason)
            }
        }

        enum RegistrationFailure {
            static var reason: String {
                String(localized: .shareRegistrationRegistrationFailureReason)
            }
        }

        enum Offline {
            static var reason: String {
                String(localized: .shareRegistrationOfflineReason)
            }
        }

        enum GenerationInProgress {
            static var title: String {
                String(localized: .shareRegistrationGenerationInProgressTitle)
            }

            static var message: String {
                String(localized: .shareRegistrationGenerationInProgressMessage)
            }
        }

        enum GenerationUnverified {
            static var title: String {
                String(localized: .shareRegistrationGenerationUnverifiedTitle)
            }

            static var reason: String {
                String(localized: .shareRegistrationGenerationUnverifiedReason)
            }
        }
    }
}
