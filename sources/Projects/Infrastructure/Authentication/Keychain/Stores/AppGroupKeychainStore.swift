import Foundation

// MARK: - AppGroupKeychainStore

public enum AppGroupKeychainStore {

    // MARK: Public

    public static let accessGroup = KeychainAccessGroup(
        "\(teamIdentifierPrefix)com.nexters.hytime.gitit.shared"
    )

    public static func makeShared() -> KeychainStore {
        KeychainStore(accessGroup: accessGroup)
    }

    // MARK: Private

    private static let teamIdentifierPrefix = "6924CABL23."

}
