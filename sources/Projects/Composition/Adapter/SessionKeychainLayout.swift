import InfrastructureAuthentication

// MARK: - SessionKeychainLayout

/// `LoginSessionRepositoryAdapter`가 저장한 세션 값을 다른 조립 진입점(예: 인증 헤더 구성)이
/// 같은 namespace·key로 읽을 수 있도록 공유하는 레이아웃입니다.
enum SessionKeychainLayout {
    enum Key: String {
        case accessToken
        case refreshToken
        case userID
    }

    static let namespace = KeychainNamespace("com.nexters.hytime.gitit.session")
}
