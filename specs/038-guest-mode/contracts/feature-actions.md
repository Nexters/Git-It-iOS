# 계약: Feature 공개 Action·State 변경

**기능**: [spec.md](../spec.md) | **모델**: [data-model.md](../data-model.md)

App(`AppRootFeature`)과 Feature 사이, 그리고 Feature 내부 부모·자식 사이의 공개 계약이다. 기존 case는
이름과 의미를 바꾸지 않는다(FR-015).

## TutorialFeature

| 종류 | 추가 | 동작 |
| --- | --- | --- |
| `Action.View` | `guestAccessTapped` | `authentication == .signingIn`이면 무시, 아니면 `delegate(.guestAccessRequested)` |
| `Action.Delegate` | `guestAccessRequested` | 부모(OnboardingRouter)가 해석 |

## OnboardingRouterFeature

| 종류 | 추가 | 동작 |
| --- | --- | --- |
| `State.init` | `curationExit: CurationExit = .returnToTutorial` | 중단 시 목적지 |
| `Action.Delegate` | `guestAccessRequested` | `tutorial(.delegate(.guestAccessRequested))`를 전달 |
| `Action.Delegate` | `curationAbandoned` | `curationExit == .returnToCaller`일 때 `positionSelection(.delegate(.exitRequested))` 대신 보냄 |

`curationExit == .returnToTutorial`이면 기존 동작(튜토리얼 마지막 면 복귀)을 그대로 유지한다.

## HomeFeature

| 종류 | 추가 | 동작 |
| --- | --- | --- |
| `Action.View` | `signInTapped` | 로그인 섹션의 `로그인` 버튼 → `delegate(.signInRequested)` |
| `Action.View` | `signInRequiredAlertSignInTapped` | 알럿 닫고 `delegate(.signInRequested)` |
| `Action.View` | `signInRequiredAlertDismissed` | 알럿 닫기 |
| `Action.Input` | `accessChanged(MainShellAccess)` | `access` 갱신. `member`로 바뀌면 프로필·프로젝트 적재 시작 |
| `Action.Delegate` | `signInRequested` | 부모(MainShellRouter)가 로그인 흐름 시작 |
| `Action.Delegate` | `allProjectsRequested` | 전체보기 선택을 부모에 알림. 부모(MainShellRouter)가 프로젝트 탭을 선택 |

기존 case의 비로그인 동작:

| 기존 case | `access == .guest`일 때 |
| --- | --- |
| `view(.task)` | Effect 없음 |
| `input(.learningProjectsReloadRequested)` | Effect 없음 |
| `view(.projectRegistrationTapped)` | `isSignInRequiredAlertPresented = true`, delegate 없음 |
| `view(.profileRetryTapped)`, `view(.projectRetryTapped)` | Effect 없음 |
| `view(.showAllProjectsTapped)` | Effect 없음(`delegate(.allProjectsRequested)`를 보내지 않음) |

`access == .member`이면 `view(.showAllProjectsTapped)`는 `delegate(.allProjectsRequested)`를 보낸다. 기존에는 Home이
아무 것도 하지 않고 MainShellRouter가 자식의 View Action을 직접 가로챘으나, 이는 "자식은 `delegate`로만 상위 의도를
알린다"는 [Router 컨벤션](../../../docs/conventions/tca/navigation/router.md)에 어긋나므로 이 기능에서 delegate로 바꾼다.
로그인 사용자에게 관찰되는 동작(프로젝트 탭 선택과 재조회)은 같다(FR-015).

## GuestSignInFeature (새 Reducer)

생성자 의존성(Domain 계약의 최소 subset, 생성자 주입):

```text
signIn: @Sendable (SignInMethod) async -> SignInResult
policyConsentStatus: @Sendable () async throws -> PolicyConsentStatus
consent: @Sendable ([PolicyDocumentID]) async throws -> Void
```

`policyConsentStatus`와 `consent`는 자식 `LegalAgreementFeature` 생성에만 전달한다. GuestSignInFeature는 약관 판정을
위한 별도 조회 Effect를 만들지 않고 자식의 기존 Action으로 판정한다.

| 종류 | case | 동작 |
| --- | --- | --- |
| `Action.Input` | `start` | `phase == .idle`일 때만 `phase = .checkingConsent`, `legalAgreement(.input(.load))` 전송. 문서가 이미 있으면 즉시 판정 |
| `Action.View` | `failureDismissed` | `failed → idle` |
| `Action.View` | `legalAgreementDismissed`, `legalDocumentSheetDismissed` | 온보딩과 같은 방식으로 `legalAgreement`에 전달 |
| `Action.EffectEvent` | `signInFinished(requestID:result:)` | [data-model §3](../data-model.md) 전환 |
| `Action.Delegate` | `signedIn(needsCuration: Bool)` | 부모가 해석 |
| child | `legalAgreement(LegalAgreementFeature.Action)` | 기존 약관 Reducer. 부모 판정에 쓰는 case: `effect(.statusLoaded)` 이후 `isStoredConsentValid`로 분기(충족 → 로그인, 미충족 → `input(.prepare)` 후 `agreeingToPolicies`), `delegate(.consentCompleted)` → 로그인, `delegate(.cancelled)` → `idle` |

## MainShellRouterFeature

| 종류 | 추가 | 동작 |
| --- | --- | --- |
| `State.init` | `access: MainShellAccess = .member` | `home.access`도 같은 값으로 초기화 |
| `Action.View` | `signInTapped` | 마이 탭 로그인 화면 → `guestSignIn(.input(.start))` |
| `Action.Input` | `memberAccessGranted` | `access = .member`, `home(.input(.accessChanged(.member)))`, 프로젝트 목록 재조회. `selectedTab` 유지 |
| `Action.Delegate` | `signInSucceeded(needsCuration: Bool)` | `guestSignIn(.delegate(.signedIn))`를 App에 전달 |
| 기존 case 교체 | `home(.view(.showAllProjectsTapped))` → `home(.delegate(.allProjectsRequested))` | `selectedTab = .projects`, 프로젝트 목록 재조회(기존 동작 유지). Home이 비로그인에서 delegate를 보내지 않으므로 Router에 별도 가드가 없다 |
| child | `guestSignIn(GuestSignInFeature.Action)` | 비로그인 로그인 흐름 |

기존 case의 비로그인 동작:

| 기존 case | `access == .guest`일 때 |
| --- | --- |
| `view(.tabSelected(.projects / .saved))` | 무시(`selectedTab` 유지, 재조회 없음) |
| `view(.tabSelected(.home / .settings))` | 선택만 반영, 재조회 없음 |
| `input(.learningProjectsReloadRequested)` | 무시 |
| `home(.delegate(.signInRequested))` | `guestSignIn(.input(.start))` |

## AppRootFeature (App, 내부)

| 입력 | 비로그인 관련 처리 |
| --- | --- |
| `onboarding(.delegate(.guestAccessRequested))` | `mainShell = State(access: .guest)`, `route = .mainShell`, 기기 등록 없음 |
| `mainShell(.delegate(.signInSucceeded(needsCuration: false)))` | `mainShell(.input(.memberAccessGranted))`, 기기 등록 |
| `mainShell(.delegate(.signInSucceeded(needsCuration: true)))` | `onboarding = State(startingAt: .curation, curationExit: .returnToCaller)`, `route = .onboarding`, `mainShell` 유지 |
| `onboarding(.delegate(.mainShellRequested))` | 기존 처리 + `mainShell.access == .guest`이면 `memberAccessGranted` |
| `onboarding(.delegate(.curationAbandoned))` | `route = .mainShell`(비로그인 유지) |
| `view(.applicationBecameActive)` | `guest`이면 로그인 검증·재조회·기기 등록 재시도 없음 |
| `effect(.signInVerified(.reauthenticationRequired))` | `guest`이면 무시 |
| `effect(.deviceTokenRefreshed)` | `guest`이면 무시 |
