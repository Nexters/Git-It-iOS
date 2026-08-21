import InfrastructureAuthentication

/// `LoginSessionRepositoryAdapter`가 저장한 `SessionRecord`를 다른 조립 진입점(예: 인증 헤더
/// 구성)이 같은 namespace·key로 읽을 수 있도록 공유하는 레이아웃입니다. token pair와
/// onboarding state는 한 key 아래 단일 JSON blob으로 저장되어 부분 갱신이 생기지 않는다
/// (GAP-014-008, GAP-014-009).
enum SessionKeychainLayout {
    enum Key: String {
        case sessionRecord
    }

    static let namespace = KeychainNamespace("com.nexters.hytime.gitit.session")
}
