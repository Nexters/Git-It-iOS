# 화면 계약: SettingsRouter

**입력**: [spec.md](../spec.md)의 기능 요구사항, [data-model.md](../data-model.md) §3

이 기능은 외부 API를 새로 노출하지 않는다. 여기서 정의하는 계약은 신규
`SettingsRouter`(View)/`SettingsRouterFeature`(Reducer)가 `ProfileFeature`(신규)와
기존 `SettingsFeature`(변경 없음) 사이에 맺는 경계다.

## 1. 조립 계약

```swift
@Reducer
struct SettingsRouterFeature {
    struct State { var profile = ProfileFeature.State(); var settings = SettingsFeature.State(); var activeScreen: ActiveScreen = .profile }
    enum Action { case profile(ProfileFeature.Action); case settings(SettingsFeature.Action); case view(View); case delegate(Delegate) }
}

struct SettingsRouter: View {
    init(store: StoreOf<SettingsRouterFeature>)
}
```

- `MainShellRouter`가 `store.scope(state: \.settings, action: \.settings)`로 생성한
  `StoreOf<SettingsRouterFeature>`를 전달받는다. (`MainShellRouterFeature.State.settings`의
  타입이 `SettingsFeature.State`에서 `SettingsRouterFeature.State`로 바뀐다 — 아래
  "MainShellRouterFeature 연동" 참고.)
- `body`는 `Scope(state: \.profile, action: \.profile) { ProfileFeature(...) }`와
  `Scope(state: \.settings, action: \.settings) { SettingsFeature(...) }`를 조합한다.

## 2. 화면 전환 계약

| View 이벤트 | Router 처리 |
|---|---|
| 프로필 화면의 설정 아이콘 탭 | `activeScreen = .settings(.list)` |
| 설정 목록의 뒤로가기 | `activeScreen = .profile` |
| 설정 목록의 "개발 분야" 행 탭 | `activeScreen = .settings(.positionSelection)` |
| 설정 목록의 "개발 수준" 행 탭 | `activeScreen = .settings(.careerLevelSelection)` |
| 설정 목록의 "계정 삭제" 행 탭 | `activeScreen = .settings(.accountDeletion)`(동시에 `settings(.view(.deleteAccountTapped))`를 보내 `accountAction`을 `.confirmingDeletion`으로 전이) |
| 선택/확인 화면의 뒤로가기 | `activeScreen = .settings(.list)` |

전환은 `ActiveScreen`을 바꾸는 상태 전이이며 `NavigationStack`/`StackState`를 쓰지
않는다([TCA Navigation 컨벤션 §2.3](../../../docs/conventions/tca/navigation.md#23-router-feature와-화면-전환-소유)).

## 3. Delegate 계약 (기존 배선 유지)

`settings(.delegate(.signedOut))`, `settings(.delegate(.accountDeleted))`는 Router가
자신의 `delegate`로 그대로 올리고, `MainShellRouterFeature`가 기존과 동일하게 수신해
App으로 전달한다.

## 4. MainShellRouterFeature 연동

- `MainShellRouterFeature.State.settings`의 타입을 `SettingsFeature.State`에서
  `SettingsRouterFeature.State`로 바꾼다.
- `MainShellRouterFeature`의 `Scope(state: \.settings, action: \.settings)`가
  `SettingsRouterFeature(...)`를 생성하도록 바꾸고, 기존에 직접 주입하던 5개 UseCase
  (`signOut`, `fetchMemberProfile`, `updateMemberPosition`, `updateMemberCareerLevel`,
  `deleteMemberAccount`)는 `SettingsRouterFeature`가 받아 `ProfileFeature`와
  `SettingsFeature`에 각각 필요한 것만 나눠 전달한다(`ProfileFeature`는
  `fetchMemberProfile`만, `SettingsFeature`는 기존 5개 그대로).
- `MainShellRouterFeature.Action.settings`의 페이로드 타입도
  `SettingsRouterFeature.Action`으로 바뀐다. `case .settings(.delegate(.signedOut)),
  .settings(.delegate(.accountDeleted)):` 패턴 매칭 경로는
  `.settings(.delegate(.signedOut))`(Router의 delegate)로 갱신한다.
