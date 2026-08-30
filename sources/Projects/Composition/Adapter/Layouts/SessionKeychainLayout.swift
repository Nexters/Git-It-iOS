import InfrastructureAuthentication

enum SessionKeychainLayout {
    enum Key: String {
        case sessionRecord
    }

    static let namespace = KeychainNamespace("com.nexters.hytime.gitit.session")
}
