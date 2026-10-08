// MARK: - SessionStorageLayout

public enum SessionStorageLayout {

    // MARK: Public

    public enum Key: String {
        case sessionRecord
    }

    public static let namespace = "com.nexters.hytime.gitit.session"

    public static let sharedSessionNamespace = "com.nexters.hytime.gitit.sharedSession"

}
