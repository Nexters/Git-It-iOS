# 데이터 모델: 비로그인(게스트) 모드

**기능**: [spec.md](spec.md) | **조사**: [research.md](research.md)

이 기능은 영속 데이터를 추가하지 않는다(FR-003). 아래는 Feature 상태 모델이다.

## 1. MainShellAccess (Feature, 새 공개 enum)

메인 화면이 로그인 사용자로 동작하는지 비로그인 사용자로 동작하는지 나타낸다. 명세의 "세션 모드" 엔터티다.

| case | 의미 |
| --- | --- |
| `member` | 로그인 사용자. 모든 탭과 홈 기능이 활성화된다(기존 동작) |
| `guest` | 비로그인 사용자. 계정 기능을 비활성화하거나 로그인 안내로 대체한다 |

- 경로: `sources/Projects/Feature/MainShell/Router/MainShellAccess.swift`
- 소유: `MainShellRouterFeature.State.access`(정본), `HomeFeature.State.access`(전파받은 값). App은 생성
  (`State(access:)`)과 `input(.memberAccessGranted)`로만 지시하고 가드에서 읽기만 한다. Router가 정본을 갖는 근거
  (전환 상태이며 수명이 Router State와 같음)는 [research R1](research.md#r1-세션-모드메인-화면-접근-수준를-어디에-둘-것인가)
- 위치: Router가 소유하는 값 타입이므로 `MainShell/Router/`에 둔다. Home 흐름은 부모 Router가 전파한 값으로만 이
  타입을 사용하고 Router의 다른 선언을 참조하지 않는다.
- 파생 규칙:
  - `MainShellTab`의 선택 가능 여부: `guest`이면 `.projects`, `.saved`는 선택할 수 없다.

### 상태 전환

```text
(App) onboarding.guestAccessRequested ──► guest
guest ──(input.memberAccessGranted)──► member
member ──(settings 로그아웃·계정 삭제)──► MainShellRouter.State 초기화 후 App이 onboarding으로 이동(기존)
```

`member → guest` 전환은 없다(명확화 Q2: 로그아웃하면 튜토리얼로 돌아감).

## 2. OnboardingRouterFeature.CurationExit (Feature, 새 공개 enum)

직군·연차 단계를 중단했을 때 어디로 갈지 나타낸다.

| case | 의미 | 사용처 |
| --- | --- | --- |
| `returnToTutorial` | 튜토리얼 마지막 면으로 되돌아감(기존 동작, 기본값) | 첫 로그인, 앱 복원 |
| `returnToCaller` | `delegate(.curationAbandoned)`로 호출자(App)에 알림 | 비로그인 메인 화면에서 로그인 |

- 경로: `sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature+CurationExit.swift`
- `OnboardingRouterFeature.State.init(startingAt:bundleVersion:curationExit:)`에 기본값 `.returnToTutorial`로
  추가한다.

## 3. GuestSignInFeature.State (Feature, 새 Reducer)

| 필드 | 타입 | 규칙 |
| --- | --- | --- |
| `phase` | `Phase` | 아래 상태 전환 참조 |
| `legalAgreement` | `LegalAgreementFeature.State` | 항상 보유(비 optional). 표시 여부는 `phase`가 정본이며 `agreeingToPolicies`일 때만 표시 |
| `requestID` | `Int` | 로그인 결과 응답의 최신 여부 판정([TCA State §4](../../docs/conventions/tca/state.md)) |

- 경로: `sources/Projects/Feature/MainShell/Router/GuestSignInFeature.swift`,
  `GuestSignInFeature+Phase.swift`(화면 없는 관심사 Feature — `OnboardingExitFeature` 선례)
- `legalAgreement`를 항상 보유하는 것은 [State 형태 컨벤션](../../docs/conventions/tca/state/shape.md)의 예외다.
  근거와 영향은 [research R3](research.md#r3-비로그인-상태의-로그인-흐름그-자리에서-apple-로그인).

`Phase`:

| case | 의미 |
| --- | --- |
| `idle` | 진행 중인 로그인 없음 |
| `checkingConsent` | 자식 `legalAgreement`가 약관 문서와 동의 기록을 불러오는 중 |
| `agreeingToPolicies` | 약관 동의 화면 표시 중 |
| `signingIn` | Apple 로그인 진행 중 |
| `failed` | 재시도 가능한 실패. 실패 알럿 표시 |

파생값: `isLegalAgreementPresented = phase == .agreeingToPolicies`, `isFailureAlertPresented = phase == .failed`.

### 상태 전환

```text
idle ──start──► checkingConsent
checkingConsent ──동의 충족──► signingIn
checkingConsent ──미충족──► agreeingToPolicies
agreeingToPolicies ──consentCompleted──► signingIn
agreeingToPolicies ──cancelled──► idle
signingIn ──signedIn──► idle + delegate.signedIn(needsCuration:)
signingIn ──cancelled──► idle
signingIn ──retryableFailure──► failed
failed ──failureDismissed──► idle
(idle 이외 상태에서 start) ──► 무시(중복 로그인 방지)
```

## 4. HomeFeature.State 추가 필드

| 필드 | 타입 | 규칙 |
| --- | --- | --- |
| `access` | `MainShellAccess` | 기본 `member`. `guest`이면 프로필·프로젝트 요청을 만들지 않음 |
| `isSignInRequiredAlertPresented` | `Bool` | `guest`에서 프로젝트 생성 선택 시 `true` |

`HomeProjectSectionState`에 `signInRequired` case를 추가한다. `access == .guest`이면 `projectLoad`와 무관하게
`signInRequired`다. `HomeProfileDisplay`는 바꾸지 않는다. 프로필 섹션과 로그인 섹션의 선택은 `HomeScreen`이
`access`로 분기한다.

## 5. MainShellRouterFeature.State 추가 필드

| 필드 | 타입 | 규칙 |
| --- | --- | --- |
| `access` | `MainShellAccess` | `init(access: MainShellAccess = .member)`. `home.access`와 같은 값을 유지 |
| `guestSignIn` | `GuestSignInFeature.State` | 비로그인 로그인 흐름 상태 |
