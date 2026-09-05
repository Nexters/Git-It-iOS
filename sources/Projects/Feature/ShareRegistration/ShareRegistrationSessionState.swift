/// Share Extension이 세션 확인 결과로 받는 값이다. 화면은 토큰을 알 필요가 없으므로
/// 진행 가능 여부와 안내 종류만 구분한다.
public enum ShareRegistrationSessionState: Equatable, Sendable {
    case available
    case signInRequired
    case appLaunchRequired
}
