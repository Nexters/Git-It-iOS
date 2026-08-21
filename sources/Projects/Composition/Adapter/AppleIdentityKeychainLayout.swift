import InfrastructureAuthentication

/// `AuthenticationRepositoryAdapter`가 저장한 Apple 안정 사용자 식별자를
/// `LoginSessionRepositoryAdapter`가 `AuthenticatedUser.id`로 재사용할 수 있도록 공유하는
/// 레이아웃입니다. Apple identity token(JWT, 매 로그인마다 값이 바뀔 수 있음)을 사용자 ID로
/// 쓰지 않기 위해 존재합니다(GAP-014-007).
enum AppleIdentityKeychainLayout {
    enum Key: String {
        case appleUserID
    }

    static let namespace = KeychainNamespace("com.nexters.hytime.gitit.authentication")
}
