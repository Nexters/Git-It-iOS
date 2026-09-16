import InfrastructureAuthentication

// MARK: - AppleIdentityStorageLayout

public enum AppleIdentityStorageLayout {

    // MARK: Public

    public enum Key: String {
        case appleUserID
    }

    public static let namespace = KeychainNamespace("com.nexters.hytime.gitit.authentication")

}
