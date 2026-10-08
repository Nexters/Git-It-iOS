# Feature 경계 계약: Onboarding Router

이 문서는 [016 기능의 `onboarding-flow.md`](../../016-onboarding-login-tutorial-app-integration/contracts/onboarding-flow.md)가
정의했던 "App root는 `restoring`/`onboarding`/`mainShell`만 소유하고 복구 가능한 실패는
onboarding 내부 `restoreError`로 간다"는 경계를 이번 리팩토링에 맞게 갱신한다. 세부
State·필드는 [data-model.md](../data-model.md)를 따른다.

## Root 입력과 출력 (갱신)

- App은 launch 시 production graph를 한 번 만들고 root(`AppRootFeature`)에 Domain
  UseCase protocol을 명시 주입한다 — 변경 없음.
- `AppRootFeature`는 여전히 `restoring`, `onboarding`, `mainShell`만 소유한다. 다만
  `restoring` 동안 실제로 `RestoreSessionUseCase`를 호출하고 복구 가능한 실패에 재시도
  UI를 보여주는 주체는 **`AppRootFeature` 자신이 아니라 그 Child인
  `AppEntryFeature`**다. `AppRootFeature`는 `AppEntryFeature`의 `delegate`만 받아
  `route`를 전환한다.
- 인증 결과 뒤 `FetchMemberProfileUseCase` 호출과 그 결과 해석(404 → 세션 정리 후
  신규 가입, nullable profile → curation부터 온보딩 진입, 완성 profile → MainShell)도
  `AppEntryFeature`가 수행한다.
- `OnboardingRouterFeature`(기존 `OnboardingFeature`)는 세션 복원을 더 이상 수행하지
  않는다. `AppEntryFeature`가 결정한 진입 지점(`OnboardingEntryPoint`: `.guide` 또는
  `.curation`)으로 초기화된 상태에서 시작한다.

## Feature initializer 계약 (갱신)

- **`AppEntryFeature`**: `RestoreSessionUseCase`, `FetchMemberProfileUseCase`,
  `SignOutUseCase`(404 로컬 정리용)를 받는다.
- **`OnboardingRouterFeature`**(및 하위 `OnboardingGuideFeature`): `SignInUseCase`,
  `SignOutUseCase`(포지션 화면 뒤로 가기), `PolicyConsentUseCase`, bundle version
  표시 값을 받는다. `RestoreSessionUseCase`·`FetchMemberProfileUseCase`는 더 이상
  받지 않는다.
- **`CurationFeature`**: `CompleteCurationUseCase`를 받는다.

View는 이 계약을 직접 호출하지 않고 각 Feature Action만 전송한다 — 변경 없음.

## AppEntryFeature 목적지 계약

```text
task
  └─ restoreSession
       ├─ unauthenticated ─> delegate(.destinationDecided(.onboarding(startingAt: .guide)))
       ├─ recoverable failure ─> authentication = .retryableFailure (재시도 UI, retryTapped로 재시도)
       └─ authenticated ─> fetchMemberProfile
            ├─ complete ─> delegate(.destinationDecided(.mainShell))
            ├─ nullable field ─> delegate(.destinationDecided(.onboarding(startingAt: .curation)))
            └─ member 404 ─> local cleanup(signOut) ─> delegate(.destinationDecided(.onboarding(startingAt: .guide)))
```

동시에 둘 이상의 목적지를 결정하지 않는다. 각 비동기 요청은 identity(`requestID`)를
가지며 현재 요청과 다른 늦은 응답은 State를 바꾸지 않는다(기존 관례 유지).

## OnboardingRouterFeature Phase 계약 (갱신)

```text
startingAt(.guide) 진입:
  guide.tutorial(page: 1)

startingAt(.curation) 진입:
  curation.position

guide.tutorial(page: 3) ─> valid consent ? signIn : legalAgreement
guide.legalAgreement ── accept all/continue ─> signIn
  └─ signIn success + needsCuration=true  ─> [이동 이벤트] curation.position
  └─ signIn success + needsCuration=false ─> exit.delegate(shouldExit) ─> Router delegate(mainShellRequested)
curation.position ── back/signOut success ─> [이동 이벤트] guide.tutorial(page: 3)
curation.career ── back ─> curation.position (selection preserved, 이동 이벤트 아님 — 같은 최상위 단위 내부 세부 화면 전환)
curation.career ── 제출 성공 ─> exit(input: curationSucceeded) ─> exit.delegate(shouldExit) ─> Router delegate(mainShellRequested)
```

`activeScreen`이 실제로 바뀌는 전환만 `ScreenTransitionEvent`로 기록한다(FR-006·
FR-007). `exit.delegate(shouldExit)` → Router `delegate(mainShellRequested)` 전이
자체는 `activeScreen` 값을 바꾸지 않으므로 이동 이벤트를 남기지 않는다.

## 중복 요청과 오류 계약 (기존 유지)

- restore, sign-in, sign-out, curation은 각각 진행 중 동일 action을 무시한다.
- restore(이제 `AppEntryFeature`)와 sign-in(`OnboardingGuideFeature`)은 request
  identity가 현재 요청과 다르면 늦은 응답을 무시한다.
- `RestoreSessionResult`·`SignInResult`·`SignOutResult`의 case 구분과 의미는 변경하지
  않는다.

## Router보다 긴 생명주기 상태 계약 (신규, FR-012)

- `OnboardingRouterFeature`, `OnboardingGuideFeature`, `CurationFeature`,
  `OnboardingExitFeature`, `AppEntryFeature` 어디에도 TCA `@Shared`, `Binding`,
  `inout` 기반 저장 프로퍼티를 두지 않는다.
- Router 재생성(`AppRootFeature`가 로그아웃 후 `onboarding` State를 새로 만드는 경우
  포함)을 넘어 유지돼야 하는 값은 Keychain(세션)·서버(프로필) 같은 정본에서 필요한
  Feature가 자신의 생성자 주입 UseCase로 다시 조회한다.
