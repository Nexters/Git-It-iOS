import InfrastructureAuthentication

// MARK: - SessionKeychainLayout

public enum SessionKeychainLayout {

    // MARK: Public

    public enum Key: String {
        case sessionRecord
    }

    public static let namespace = KeychainNamespace("com.nexters.hytime.gitit.session")

}
