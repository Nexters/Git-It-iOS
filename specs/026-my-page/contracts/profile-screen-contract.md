# 화면 계약: ProfileScreen / SettingsScreen(+선택·확인 서브뷰)

**입력**: [spec.md](../spec.md)의 기능 요구사항, [data-model.md](../data-model.md)

## 1. ProfileFeature / ProfileScreen (신규)

```swift
@Reducer
struct ProfileFeature {
    init(fetchMemberProfile: any FetchMemberProfileUseCase)
    struct State { var profileLoad: ProfileLoad = .idle }
    enum Action { case view(View); case effect(EffectEvent) }
}

struct ProfileScreen: View {
    init(store: StoreOf<ProfileFeature>)
}
```

| UIComponent | 표시 값 | 콜백 | Action |
|---|---|---|---|
| `ScreenHeader` 또는 커스텀 헤더 | 제목 "마이" | 설정 아이콘 탭 → Router `activeScreen = .settings(.list)`(Router가 처리, ProfileFeature Action 아님) | — |
| 아바타/이름/이메일/배지 표시 (SubViews) | `ProfileDisplay.name`/`email`/`positionBadgeText`/`careerLevelBadgeText` | — | — |
| 통계 카드 3개 (SubViews) | `ProfileDisplay.thisWeekSolvedCount`/`thisMonthSolvedCount`/`streakDays` | — | — |
| 주간 추이 (SubViews) | `ProfileDisplay.weeklyCounts` | — | — |
| 실패 표시 | 오류 문구 | `onRetry` | `.view(.task)` 재전송 |

`task` modifier로 화면 진입 시 `.view(.task)`를 보내 `fetchMemberProfile()`을 1회
호출한다.

## 2. SettingsScreen(목록) — 기존 SettingsFeature 재사용

| UIComponent | 표시 값 | 콜백 | 대응 `SettingsFeature.Action` |
|---|---|---|---|
| `SettingRow`(아이콘 포함 variant 필요 시 UI 조사 결과에 따름) | "개발 분야", value=현재 직군 문구(`nil`이면 "선택 안 함") | `onTap` | Router가 `.settings(.positionSelection)`로 전환(SettingsFeature Action 아님) |
| `SettingRow` | "개발 수준", value=현재 연차 문구 | `onTap` | Router가 `.settings(.careerLevelSelection)`로 전환 |
| `SettingRow` | "서비스 약관 및 정책" | `onTap` | 정적 콘텐츠 표시(신규 Action 불필요 — 화면 전환만, 구현 단계에서 정적 화면/외부 링크 여부 확정) |
| `AccountActionRow` | "로그아웃" | `onTap` | `.view(.signOutTapped)` |
| `SettingRow` | "계정 삭제" | `onTap` | `.view(.deleteAccountTapped)` + Router가 `.settings(.accountDeletion)`로 전환 |

## 3. 개발 분야/개발 수준 선택 서브뷰

`SelectionCardList`(직군: `.compact`, 연차: 기본 `.detailed`)를 사용한다. 옵션 선택 시
`.view(.positionSelected(_:))`/`.view(.careerLevelSelected(_:))`를 보낸다.
`positionMutation`/`careerLevelMutation`이 `.committing`인 동안 카드 선택을
비활성화한다(FR-011). `.failed`로 전이하면 이전 값을 유지한 채 재시도 가능한 오류
문구를 표시한다(FR-007).

## 4. 계정 삭제 확인 서브뷰

`accountAction == .confirmingDeletion`일 때 표시하는 전체 화면. 경고 문구와 "회원
탈퇴" 버튼을 `.view(.deleteAccountConfirmed)`에, 뒤로가기를
`.view(.deleteAccountCancelled)` + Router `activeScreen = .settings(.list)`에 연결한다.

## 5. FR-013 확장(약관) 계약 참고

"서비스 약관 및 정책" 행의 목적지(정적 인앱 화면 vs 외부 브라우저 링크)는 이번
계약에서 확정하지 않는다. 구현 단계에서 Figma 노드를 조회해 확정하고, 새 Action이
필요하면 이 계약과 `SettingsFeature`에 추가한다(정적 콘텐츠이므로 새 Domain 계약은
필요하지 않을 것으로 예상).
