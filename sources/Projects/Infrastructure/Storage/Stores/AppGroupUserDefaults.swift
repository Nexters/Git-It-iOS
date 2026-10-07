import Foundation

// MARK: - AppGroupUserDefaults

public enum AppGroupUserDefaults {

    // MARK: Public

    public static let appGroupIdentifier = "group.com.nexters.hytime.gitit"

    public static let sharedSessionNamespace = "com.nexters.hytime.gitit.sharedSession"

    public static func makeShared() -> UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

}
