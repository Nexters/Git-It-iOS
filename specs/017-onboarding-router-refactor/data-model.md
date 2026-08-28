# 1단계 데이터 모델: Onboarding Router 리팩토링

이 문서는 [research.md](./research.md)의 결정을 바탕으로 각 Feature의 State·전이를
정리한다. 여기 나온 타입 이름·필드는 구현 시 확정할 설계 초안이며, 정확한 Swift
선언은 구현 단계(`/speckit-tasks` → `/speckit-implement`)에서 완성한다.

## AppRootFeature.State (App 패키지, 기존 타입 갱신)

| 필드 | 타입 | 비고 |
|---|---|---|
| `route` | `Route` | 기존 `restoring`/`onboarding`/`mainShell` 유지 |
| `appEntry` | `AppEntryFeature.State` | 신규 — `route == .restoring`일 때 활성 |
| `onboarding` | `OnboardingRouterFeature.State` | 기존 `onboarding` 필드, 타입만 교체 |
| `mainShell` | `MainShellFeature.State` | 변경 없음 |

**전이**: `.appEntry(.delegate(.destinationDecided(let destination)))`을 받으면
`destination`에 따라 `route`를 `.onboarding`(진입 지점 포함해 `onboarding` State 재구성)
또는 `.mainShell`로 바꾼다. 그 밖의 전이(`.onboarding(.delegate(.mainShellRequested))`
→ `.mainShell`, `.mainShell(.delegate(.loggedOut))` → 재진입)는 기존과 동일하게
유지한다.

## AppEntryFeature (Feature 패키지, 신규)

| 필드 | 타입 | 비고 |
|---|---|---|
| `authentication` | `AuthenticationStatus`(`idle`/`restoring`/`retryableFailure`) | 기존 `OnboardingFeature`의 동명 상태 축소 이전 |
| `requestID` | `Int` | 교체 가능 요청 식별 (기존 관례 유지) |

**Action 분류**:
- `view`: `task`, `retryTapped`
- `effect`: `restoreSessionFinished(requestID:result:)`,
  `memberProfileFetchFinished(requestID:result:)`
- `delegate`: `destinationDecided(Destination)`

**`Destination`** (연관값 enum):
- `.mainShell`
- `.onboarding(startingAt: OnboardingEntryPoint)` — `OnboardingEntryPoint`는
  `.guide`(미인증) 또는 `.curation`(인증됐지만 포지션·경력 미보유)

**전이 요약** (기존 `OnboardingFeature`의 `restoreSessionFinished`·
`memberProfileFetchFinished` 분기를 그대로 이전):
- `restoreSessionFinished(.unauthenticated)` → `delegate(.destinationDecided(.onboarding(startingAt: .guide)))`
- `restoreSessionFinished(.recoverableFailure)` → `authentication = .retryableFailure`(재시도 UI)
- `restoreSessionFinished(.authenticated)` → `fetchMemberProfile` 호출
- `memberProfileFetchFinished(profile: position/careerLevel 모두 있음)` →
  `delegate(.destinationDecided(.mainShell))`
- `memberProfileFetchFinished(profile: 하나라도 없음)` →
  `delegate(.destinationDecided(.onboarding(startingAt: .curation)))`
- `memberProfileFetchFinished(.memberUnavailable)` → 로컬 정리(`signOut`) 후
  `delegate(.destinationDecided(.onboarding(startingAt: .guide)))`

## OnboardingRouterFeature.State (Feature 패키지, 기존 `OnboardingFeature.swift` 대체)

| 필드 | 타입 | 비고 |
|---|---|---|
| `activeScreen` | `ActiveScreen` | 어느 화면 Feature가 활성인지 + 그 내부 세부 화면(연관값) |
| `guide` | `OnboardingGuideFeature.State` | 항상 보유(초기화 시점 진입 지점에 맞춰 구성) |
| `curation` | `CurationFeature.State` | 항상 보유 |
| `exit` | `OnboardingExitFeature.State` | 항상 보유 |
| `transitionLog` | `[ScreenTransitionEvent]` | 테스트에서 조회하는 이동 이벤트 목록(FR-006) |

**`ActiveScreen`** (연관값 enum, "완료" case 없음):
- `.guide(OnboardingGuideFeature.Screen)` — 내부 세부 화면(튜토리얼 페이지/약관 동의/
  로그인 진행 상태)을 연관값으로 포함
- `.curation(CurationFeature.Screen)` — 포지션/경력 선택 세부 화면을 연관값으로 포함

**`ScreenTransitionEvent`**:

| 필드 | 타입 | 설명 |
|---|---|---|
| `from` | `ActiveScreen` | 전환 이전 화면 |
| `to` | `ActiveScreen` | 전환 이후 화면 |
| `trigger` | 액션을 식별할 수 있는 값(예: 문자열 케이스 이름 또는 전용 enum) | 전환을 유발한 액션 |

**초기화**: `OnboardingRouterFeature.State.init(startingAt: OnboardingEntryPoint)` —
`AppEntryFeature`가 결정한 진입 지점에 따라 `activeScreen`을 `.guide(.tutorial(page: 1))`
또는 `.curation(.position)`으로 초기화한다.

**전이 요약**:
- `guide`의 `delegate(.signInSucceeded(needsCuration: true))` →
  `activeScreen`이 `.curation(.position)`으로 바뀌고, 이 전환이
  `ScreenTransitionEvent(from: .guide(...), to: .curation(.position), ...)`로 기록된다.
- `curation`의 `delegate(.exitRequested)`(뒤로 가기 후 로그아웃 완료) →
  `activeScreen`이 `.guide(.tutorial(page: 3))`로 되돌아가고 `curation` State는
  `CurationFeature.State()`로 초기화된다.
- `exit`의 `delegate(.shouldExit)` → Router가 자신의 `delegate(.mainShellRequested)`를
  상위(App Root)로 전달한다. `activeScreen`은 바뀌지 않으므로 이 전이는 이동 이벤트를
  남기지 않는다(FR-007).

## OnboardingGuideFeature (Feature 패키지, 신규)

| 필드 | 타입 | 비고 |
|---|---|---|
| `screen` | `Screen`(`.tutorial(page:)`/`.legalAgreement`/`.signIn` 성격의 진행 상태) | 기존 `Phase`의 해당 부분 이전 |
| `legal` | 기존 `LegalAgreementState`와 동일한 필드 구성 | 그대로 이전 |
| `authentication` | 로그인 관련 상태(`idle`/`signingIn`/`cancelled`/`retryableFailure`) | 기존 `AuthenticationStatus`의 로그인 관련 부분 |
| `requestID` | `Int` | 교체 가능 요청 식별 |

**Action 분류**: `view`(`tutorialAppeared`, `tutorialPageChanged`, `appleSignInTapped`,
`legalDocumentToggled` 등 기존 대응 액션), `effect`(`legalDocumentsLoaded`,
`signInFinished`), `delegate`(`signInSucceeded(needsCuration: Bool)`).

## CurationFeature (Feature 패키지, 신규)

| 필드 | 타입 | 비고 |
|---|---|---|
| `screen` | `Screen`(`.position`/`.career`) | 기존 `Phase`의 해당 부분 이전 |
| `selection` | 기존 `CurationSelection`과 동일한 필드 구성 | 그대로 이전 |
| `exitStatus` | 기존 `ExitStatus`(포지션 화면 뒤로 가기 로그아웃 진행 상태) | 그대로 이전 |

**Action 분류**: `view`(`positionSelected`, `positionNextTapped`, `positionBackTapped`,
`careerLevelSelected`, `careerBackTapped`, `curationSubmitTapped`),
`effect`(`positionExitSignOutFinished`, `curationFinished`),
`delegate`(`curationSucceeded`, `exitRequested`).

## OnboardingExitFeature (Feature 패키지, 신규)

| 필드 | 타입 | 비고 |
|---|---|---|
| (없음 또는 최소 플래그) | — | 자체 화면·정본 상태를 갖지 않는 얇은 판단 Feature |

**Action 분류**: `input`(`curationSucceeded`), `delegate`(`shouldExit`).

## 상태 소유권 요약 (FR-012 관련)

| 값 | 정본 소유자 | Onboarding Router 재생성 시 처리 |
|---|---|---|
| 인증 세션 | Keychain(Infrastructure), 변경 없음 | Router 재생성과 무관 — 다시 필요하면 `AppEntryFeature`가 `restoreSession`으로 재확인 |
| 회원 프로필 | 서버(Data), 변경 없음 | 필요한 Feature가 자신의 `fetchMemberProfile`로 재조회 |
| Router 자신의 진행 상태(선택한 포지션 등) | `OnboardingRouterFeature.State` | 재생성 시 초기화됨(의도된 동작 — 온보딩 재진입은 처음부터) |

`@Shared`·`Binding`·`inout` 기반 참조는 어느 State에도 등장하지 않는다.
