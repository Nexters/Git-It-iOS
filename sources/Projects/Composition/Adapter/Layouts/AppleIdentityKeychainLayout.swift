import InfrastructureAuthentication

enum AppleIdentityKeychainLayout {
    enum Key: String {
        case appleUserID
    }

    static let namespace = KeychainNamespace("com.nexters.hytime.gitit.authentication")
}
