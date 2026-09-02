import Foundation

// MARK: - SharedRepositoryLinkContainer

enum SharedRepositoryLinkContainer {

    // MARK: Internal

    static let appGroupIdentifier = "group.com.nexters.hytime.gitit"
    static let storageKey = "sharedRepositoryURL"
    static let containerAppURL = "gitit://shared-link"

    static func store(_ urlString: String) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        defaults.set(urlString, forKey: storageKey)
    }

}
