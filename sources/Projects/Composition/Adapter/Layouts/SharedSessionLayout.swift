import Foundation
import InfrastructureAuthentication

public enum SharedSessionLayout {

    // MARK: Public

    public static let appGroupIdentifier = "group.com.nexters.hytime.gitit"

    public static let keychainAccessGroup = KeychainAccessGroup(
        "\(teamIdentifierPrefix)com.nexters.hytime.gitit.shared"
    )

    public static func makeSharedKeychainStore() -> KeychainStore {
        KeychainStore(accessGroup: keychainAccessGroup)
    }

    public static func makeLegacyKeychainStore() -> KeychainStore {
        KeychainStore()
    }

    public static func makeSharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: Internal

    static let teamIdentifierPrefix = "6924CABL23."

    static let namespace = "com.nexters.hytime.gitit.sharedSession"
    static let stateMarkerKey = "stateMarker"
    static let pendingGenerationRemindersKey = "pendingGenerationReminders"
    static let repositoryCreationStatesKey = "repositoryCreationStates"
    static let markerSchemaVersion = 1
    static let pendingReminderLimit = 32

}
