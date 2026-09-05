/// Share Extension이 등록을 진행할 수 있는지 판정한 결과다. 토큰 자체를 화면으로
/// 전달하지 않고 이 값으로만 상태를 결정한다.
public enum SessionAvailability: Equatable, Sendable {
    /// 공유 저장소에서 읽은 유효한 접근 토큰이 있다.
    case available(accessToken: String)
    /// 로그아웃 상태이거나 토큰이 없거나 만료되었다. 갱신은 시도하지 않는다.
    case signInRequired
    /// 본 앱이 아직 한 번도 실행되지 않아 세션이 공유 저장소로 이전되지 않았다.
    case appLaunchRequired
}
