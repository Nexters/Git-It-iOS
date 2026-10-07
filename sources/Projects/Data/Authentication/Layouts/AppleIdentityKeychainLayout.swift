import InfrastructureAuthentication

// MARK: - AppleIdentityKeychainLayout

public enum AppleIdentityKeychainLayout {

    // MARK: Public

    public enum Key: String {
        case appleUserID
    }

    public static let namespace = KeychainNamespace("com.nexters.hytime.gitit.authentication")

}
