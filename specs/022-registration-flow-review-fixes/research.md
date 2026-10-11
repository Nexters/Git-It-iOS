# 조사: 프로젝트 등록 흐름 리뷰 지적 사항 해소

**기능 브랜치**: `feature/registration-flow-review-fixes`

**날짜**: 2026-09-01

**입력**: [spec.md](./spec.md)

이 문서는 명세의 요구사항을 구현 가능한 결정으로 옮기기 위한 조사 결과다. 각 항목은 저장소의
현재 코드와 컨벤션 문서를 근거로 한다.

## R1. 구독-요청 직렬화 방식 (FR-001 ~ FR-005)

**결정**: `ProjectRegistrationFeature`의 제출 처리를 단일 `.run` Effect로 합친다. Effect 안에서
생성 결과 스트림을 먼저 확보하고, 그 다음 생성 요청을 보내고, 응답 receipt의 `projectID`로 이미
확보한 스트림을 필터링한다. 제출 Effect와 관찰 Effect의 `CancelID`를 하나로 통합한다.

**근거**:

- `LearningProjectOutcomesUseCase.callAsFunction()`은 프로젝트 필터 없이 전체 스트림을 반환하므로
  `receipt`를 얻기 전에 구독을 시작할 수 있다.
- `PushGenerationOutcomeStream.outcomes()`의 `AsyncStream { continuation in ... }` build 클로저는
  `AsyncStream` 초기화 시점에 동기 실행되어 continuation을 `state`에 등록한다. 따라서 use case
  호출이 반환된 시점이 곧 구독 확립 시점이며 별도 handshake가 필요 없다.
- TCA `.merge`는 하위 Effect의 시작 순서를 보장하지 않으므로 현재 구조를 유지한 채 두 Effect를
  병렬로 두면 FR-001을 만족할 수 없다.

**검토한 대안**:

- **replay 버퍼 / pending inbox**: Data 계층에 상태 소유자가 늘고 버퍼 만료·멱등 규칙이 추가로
  필요하다. 직렬화가 가능한 상황에서 상태를 늘릴 이유가 없다. 명확화 세션에서 기각.
- **`.effect(.observationEstablished)` handshake 후 제출**: reducer 왕복이 한 번 늘고 취소 경로가
  두 갈래가 된다. 스트림 확보가 동기라는 성질을 활용하면 불필요하다.
- **서버 상태 재조회(`GET /{projectID}/status`)**: production 구현과 배선이 없어 신규 작업이 크고,
  명세가 범위 밖으로 확정했다.

**취소 의미 변화**: 통합 후 `CancelID.registrationPipeline` 하나가 제출과 관찰을 함께 취소한다.
`retryTapped`는 재실행 전에 기존 pipeline을 취소하고, `finishWaiting`과 실패 전이는 이 단일 ID를
취소한다. 기존 `CancelID.submission`, `CancelID.generationOutcomeObservation`은 제거한다.

## R2. 메인 액터 계약 표현 (FR-010 ~ FR-012)

**결정**: 설정 화면 이동 의존성의 타입을 `@MainActor @Sendable () async -> Void`로 선언하고,
`ProjectRegistrationFeature` → `AppRootFeature` → `GitItApp` 전 경로에 동일하게 적용한다.
`GitItApp`의 구현은 `MainActor.run` 래핑 없이 그대로 `UIApplication.shared.open(url)`을 호출한다.

**근거**: 타입이 실행 문맥을 표현하면 잘못된 문맥의 호출이 컴파일 단계에서 드러난다(FR-011).
구현부에서만 `MainActor.run`으로 감싸면 계약이 구현 세부에 숨어 다른 구현이 같은 위반을 반복할 수
있다.

**검토한 대안**: 구현부 `await MainActor.run { }` 래핑 — FR-010은 만족하지만 FR-011을 만족하지
않는다.

**영향**: Feature 테스트의 `OpenNotificationSettingsSpy`도 `@MainActor`로 맞춰야 한다.

## R3. 푸시 콜백 소유권과 부트스트랩 (FR-013, FR-013a, FR-017, FR-018)

**결정**: `FirebaseMessagingAppDelegate`의 `private static let state = Mutex<PushNotificationCallbacks?>`를
제거하고 콜백을 인스턴스 프로퍼티로 옮긴다. `GitItApp`이 `@UIApplicationDelegateAdaptor`로 소유하는
인스턴스에 콜백을 주입한다. AppDelegate는 콜백 주입 전에 도착한 payload를 인스턴스 범위의 대기
슬롯에 보관했다가 주입 직후 1회 전달한다.

**근거**:

- 아키텍처 §7.2가 전역 mutable dependency container를 금지한다. 인스턴스 소유는 수명과 소유자를
  드러낸다.
- 프로세스 진입점의 대기 슬롯은 R1이 기각한 Data 계층 버퍼와 다른 문제다. UIKit은 앱 조립이
  끝나기 전에 launch push를 전달할 수 있고, 이 구간은 직렬화로 없앨 수 없다.

**미확정 위험**: SwiftUI `App.init()` 실행 시점과 `application(_:didFinishLaunchingWithOptions:)`
실행 시점의 상대 순서는 플랫폼이 보장하지 않는다. 위 대기 슬롯 설계는 두 순서 모두에서 정확하므로
순서 확정 없이 구현할 수 있으나, 구현 단계에서 Simulator 실행으로 실제 순서와 주입 시점을 확인해
기록한다.

**검토한 대안**:

- **static 유지 + 테스트에서 reset**: 아키텍처 금지 항목이며 테스트 간 누수를 남긴다.
- **대기 슬롯 없이 주입만**: 주입 전에 도착한 launch push를 잃는다.

## R4. 리마인드 구독 확립 순서 (FR-013a)

**결정**: `GenerationCompletionReminderCoordinator.start(...)`가 구독 확립까지 마친 뒤 반환하도록
바꾸고, 부트스트랩 단계에서 이 호출을 `await`한다. `AppComposition` initializer의
`Task { await reminderCoordinator.start(...) }`는 제거한다.

**근거**: 현재는 조립 시점의 unstructured `Task`가 구독을 시작하므로 확립 시점이 비결정적이다.
`start(...)`는 이미 actor 격리 함수이므로 스트림 확보를 `observationTask` 생성 전에 수행하면
반환 시점에 구독이 확립된다.

**검토한 대안**: 등록 흐름 쪽에서만 직렬화 — 리마인드 발송 경로는 별도 구독자이므로 해결되지
않는다.

## R5. 기기 등록 소유자와 token 갱신 (FR-014 ~ FR-016)

**결정**: 기기 등록의 **시점**은 App(`AppRootFeature`)이 인증 세션 확립 사건에서 결정하고,
**조립 방법**은 Composition이 소유한다. Composition은 App에 다음 두 경계 값을 노출한다.

- `registerCurrentDevice: @Sendable () async throws -> Void` — token 획득과 `MemberDeviceInfo`
  구성을 포함한 등록 실행
- `deviceTokenRefreshes: @Sendable () -> AsyncStream<Void>` — 등록 token 갱신 신호

`AppRootFeature`는 등록 실패를 관찰 가능한 상태로 남기고, 같은 인증 세션에서 앱이 다시
활성화되거나 token 갱신 신호가 도착하면 최신 token으로 자동 재시도한다. 재시도 trigger가
동시에 도착하면 단일 등록 Effect로 직렬화하고, 인증 종료 시 실패 상태와 진행 중 Effect를
제거한다.

**근거**:

- 인증 세션의 소유자는 `AppRootFeature`다. 등록 시점 판단을 그곳에 두면 세션 확립 전 실패가
  사라지고 실패를 TCA 상태로 노출·재시도할 수 있다(FR-015).
- App은 Infrastructure를 의존할 수 없다(아키텍처 §3.1). 따라서 Composition이 Infrastructure 타입을
  노출하지 않는 Swift 표준 타입 경계 값으로 감싼다.
- `FirebaseMessagingPushClient`는 현재 `MessagingDelegate.didReceiveRegistrationToken`에서 대기 중인
  continuation만 재개하고 갱신을 알리지 않는다. `PushMessagingClient`에 갱신 스트림을 추가해야
  FR-016을 만족한다.
- 명시적 retry UI를 추가하지 않고 앱 수명 사건을 사용하면 새 제품 UI 범위 없이 자동 복구할 수
  있다. 단일 Effect 식별자로 중복 호출을 방지해 `registerCurrentDevice()`의 비멱등 계약을 App이
  책임진다.

**검토한 대안**:

- **Composition이 계속 소유**: 인증 상태를 알 수 없고 오류 소유자가 없어 현재 결함이 그대로 남는다.
- **App이 token까지 직접 다룸**: App → Infrastructure 금지 의존성이 된다.
- **사용자 retry UI**: 새 UI 상태와 제품 결정을 추가하며 앱 활성화·token 갱신으로 자동 복구할 수 있는
  현재 범위에서 불필요하다.
- **지수 backoff**: 백그라운드 실행 수명·최대 재시도 · network 가용성 정책이 추가로 필요해 이 기능의
  복구 조건보다 범위가 커진다.

## R6. 등록 흐름 단계 상태 (FR-019, FR-023)

**결정**: `ProjectRegistrationFeature.State`에 배타적 단계 enum `RegistrationStep`을 추가한다
(`.repositoryConfirmation`, `.quizLevelSelection`, `.generationConfirmation`).
`ProjectRegistrationScreen`의 `@State hasConfirmedRepository`, `@State hasSelectedQuizLevel`을
제거하고 이 단계를 읽는다. `@State isGuideExpanded`는 손실돼도 흐름이 바뀌지 않으므로 유지한다.

`SubmissionStatus`는 제출 이후 생성 결과 판정까지 소유하므로 `RegistrationProgress`로 바꾸고
`.committing` → `.submitting`, `.awaitingGeneration` → `.awaitingOutcome`으로 정렬한다.

**근거**: TCA 컨벤션 §4.4가 손실 시 제품 흐름이 바뀌는 값의 View 로컬 보관을 금지한다.

**검토한 대안**: 제출 상태와 생성 상태를 두 타입으로 분리 — 오류·재시도 책임이 실제로 분리돼야
정당하나, 현재 재시도는 제출 재실행 하나뿐이라 분리 근거가 약하다. 이름 정렬만 수행한다.

## R7. Home 조회 중 생성 결과 처리 (FR-020, FR-021)

**결정**: `HomeFeature.State`에 `isProjectRefreshPending: Bool`과 `appliedOutcomeProjectIDs: Set<String>`를
추가한다. 조회 중 outcome 수신 시 `isProjectRefreshPending = true`로 기록하고,
`projectsLoadFinished` 처리 끝에서 pending이면 재조회를 시작한 뒤 해제한다. 이미 반영한
`projectID`의 동일 결과가 다시 오면 재조회하지 않는다.

**근거**: FR-020은 폐기 금지를, FR-021은 중복 재조회 금지를 요구하므로 두 상태가 모두 필요하다.

**검토한 대안**: outcome을 직접 목록에 병합 — Home이 서버 정본 대신 부분 상태를 만들게 되어
아키텍처 §7.3의 책임 경계에 어긋난다.

## R8. 경계별 어휘와 형태 폴더 (FR-022 ~ FR-022c, FR-027)

**결정**: 명확화 세션의 결정(Domain = `GenerationOutcome`, Data = `QuizGeneration*`)을 적용하고,
Data의 프로세스 내 소스를 `Remotes/`에서 새 형태 폴더 `Sources/`로 옮긴다. 같은 작업 단위에서
[`docs/conventions/file-vocabulary.md`](../../docs/conventions/file-vocabulary.md) §3의 `Data/<관심사>/`
행에 `Sources/`(외부에서 주입되는 프로세스 내 데이터 소스 구현)를 추가한다.

**근거**: `file-vocabulary.md` §3이 형태 폴더 어휘의 정본이며 `Remotes/`를 "네트워크 계약 구현"으로
정의한다. 표에 없는 형태를 쓰려면 같은 PR에서 표를 갱신하라고 같은 문서가 규정한다.

**화면 이름(FR-028)**: `GenerationConfirmationScreen`, `GenerationProgressScreen`은
`QuizGenerationConfirmationScreen`, `QuizGenerationProgressScreen`으로 바꾼다. Domain에 이미
`Models/Quiz/`가 있어 `Quiz`는 Data 전용 어휘가 아니며, FR-022c가 금지하는 것은 생성 결과 타입
이름의 `LearningSet` 사용이다. 알림 시트는 FR-024에 따라 `GenerationReminderSheet`로 바꾼다.

**검토한 대안**:

- `LearningSetGenerationOutcome` 전면 적용(NR-002 원안) — `LearningSet`이 set 식별자로 조회되는
  별개 Domain 모델로 이미 존재하고 이 이벤트는 `projectID`로만 식별되므로 기각. 명확화 세션 기록.
- `Remotes/` 유지 — 타입 이름만 바꾸면 폴더 정의와 어긋난 채 남는다.

## R9. Home 재조회 Action 분류 (FR-026)

**결정**: `HomeFeature.Action.View.reloadRequested`를 `Action.Input.learningProjectsReloadRequested`로
옮긴다. `HomeFeature.Action`에 `input(Input)` 분류를 새로 추가한다.

**근거**: [`docs/conventions/tca/action.md`](../../docs/conventions/tca/action.md) §2가 "부모 Feature 또는
App"이 보내는 외부 조정 신호를 `input`으로 규정한다. 현재는 `AppRootFeature`가
`.mainShell(.home(.view(.reloadRequested)))`로 View Action을 직접 보내 출처 분류를 위반한다.

**검토한 대안**: `view`에 남기고 이름만 `learningProjectsReloadRequested`로 변경 — 대상은
드러나지만 출처 위반은 남는다.

## R10. MainShell delegate 정규화 (FR-030)

**결정**: `MainShellFeature.Action.Delegate.projectSelected(projectID:)`를 제거하고
`projectDetailRequested(projectID:)` 하나로 통합한다. child의 `projectList` delegate는 그대로 두고
MainShell이 변환한다.

**근거**: `AppRootFeature.swift:195-197`이 두 case를 같은 목적지·payload로 처리한다. child의 UI
사건 이름은 달라도 MainShell이 외부에 내보내는 의미는 하나여야 한다.

## R11. formatter 위반 (FR-031)

**결정**: 아래 2건을 해당 패키지 작업 단위에서 함께 해소한다.

- `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubRequestGenerationReminderUseCase.swift:7`
- `sources/Projects/Infrastructure/PushMessaging/Local/Models/LocalNotificationRequest.swift:7`

**근거**: 두 파일 모두 이 명세가 수정하는 패키지에 속한다. 마지막 단위 직전에 포맷 훅이 다시
실행되므로 별도 정리 단위를 두지 않는다.

## R12. `AllTests` runner `Early unexpected exit` (FR-032)

**결정**: 이 명세 작성 시점에는 재검증하지 않았다. 구현 첫 단위 전에 현재 HEAD에서
`test-without-building`을 1회 실행해 재현 여부를 확인하고, 재현되면 원인을 분리한 뒤
[`docs/spec-kit`](../../docs/spec-kit) 기록 여부를 판단한다.

**근거**: 리포트는 `7bbc8d2` 기준이고 이후 브랜치 2개가 병합됐다. 재현하지 않는 실패를 작업으로
만들면 범위가 부정확해진다.
