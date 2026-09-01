---

description: "생성 리마인드 명명·경계 리팩터링 작업 목록"
---

# 작업 목록: 생성 리마인드 명명·경계 리팩터링

**입력**: `/specs/021-generation-reminder-refactoring/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 명세 시나리오 5(FR-016·FR-017)가 검증 공백 보강을 요구하므로 해당 범위의 테스트
작업을 포함한다. 그 밖의 단위는 기존 테스트를 개명·정리하는 작업만 갖는다.

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안에서 라벨로 추적한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: S1~S5 (spec.md의 변경 시나리오)
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 검증. `make tuist`의
  파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후 Git 상태를 비교하고
  추적 파일 변경이 생기면 완료로 처리하지 않는다.

## 실행 단위 순서와 근거

`docs/architecture.md` §3.1의 허용 의존성 표에서 도출한 위상 순서
(Infrastructure·Domain·UI → Data → Composition·Feature → App)를 따른다. 이 기능의 변경은
대부분 공개 API 개명이라 단일 패키지로 분리하면 중간 상태가 컴파일되지 않으므로,
`[통합]`으로 표시한 단위는 Constitution 원칙 7이 허용하는 다중 패키지 integration unit이다.

| 단위 | 성격 | 시나리오 | 순서 근거 |
| --- | --- | --- | --- |
| U0 | 기준선 (승인 필요) | — | 두 기준선 공존을 해소해야 이후 모든 단위의 "변경 전" 상태가 확정된다 |
| U1 | 통합: Infrastructure + Composition | S1 | Infrastructure는 의존성 없는 최하위. 계약 변경이 Composition을 깨뜨린다 |
| U2 | 통합: Domain + Data + Composition + Feature + App | S2 | 모델 이름이 전 계층에 노출된다. U3의 UseCase 개명이 이 모델 이름을 참조한다 |
| U3 | 통합: Domain + Composition + Feature + App | S2 | U2가 확정한 모델 이름 위에서 UseCase 계약을 바꾼다 |
| U4 | 통합: Composition + App + docs | S3 | U3가 UseCase 주입 경로를 확정한 뒤 조립 구조를 바꿔야 재작업이 없다 |
| U5 | 단일: UI | S4 | 다른 단위와 의존하지 않는다. 개명 단위 뒤에 두어 커밋 diff를 하나의 관심사로 유지 |
| U6 | 통합: Feature + App | S4 | U2·U3가 이름을 확정한 뒤 삭제해야 같은 줄을 두 번 고치지 않는다 |
| U7 | 단일: Feature 테스트 | S4 | U6이 같은 파일의 delegate 검증 구문을 먼저 제거한다 |
| U8 | 통합: Tuist manifest + Infrastructure·Composition·Feature 테스트 | S5 | 앞 단위가 만든 최종 구조 위에 테스트를 작성해야 재작성이 없다 |
| U9 | `[no-write]` 전체 검증 | 전체 | 마지막 적용 단위 뒤 |

---

## 실행 단위 U0: 기준선 정리 *(승인 필요)*

**목표**: 작업 트리에 남은 사용자 소유 미커밋 변경을 목적별로 커밋해 리팩터링 기준선을
하나로 만든다.

**소유 경로**: T002~T007이 나열하는 14개 경로

**관련 변경 시나리오**: 없음 (선행 조건)

**독립 검증**: `build`가 통과하고 `git status`의 소스 변경이 0건이 된다.

**분할 근거**: 이 14개 파일은 최소 6개의 독립적인 목적을 담고 있어
`.github/COMMIT_CONVENTION.md` §5.2("하나의 커밋에는 하나의 목적만")에 따라 하나의 커밋으로
묶을 수 없다. 아래 작업은 각각 독립적으로 리뷰·되돌리기가 가능한 커밋 단위가 되도록 목적별로
나눴으며, 순서는 각 커밋이 단독으로 컴파일되도록 배치했다.

**파일 단위 제약**: `AppComposition.swift`는 클라이언트 개명 hunk와 기기 등록 로깅 hunk를 한
파일에 함께 갖는다. 이 스킬은 hunk 단위 staging을 사용하지 않으므로 두 hunk를 분리할 수 없다.
T003이 두 hunk를 함께 커밋하며, 이 예외와 이유를 PR에 기록한다(Constitution 원칙 3).

### 승인

- [ ] T001 미커밋 소스 14건을 이 기능의 기준선 커밋으로 소비해도 되는지 사용자에게 확인한다.
      이 변경은 `feature/local-reminder-notification` 작업의 결과로 사용자가 소유하며,
      Constitution 원칙 7이 "사용자 소유 변경의 소비"를 명시적 승인 대상으로 규정한다.
      승인하지 않으면 [research.md](./research.md) R-008의 대안(커밋된 HEAD 기준)으로 전환하고
      U1부터 진행한다.

### 구현

- [X] T002 푸시 알림 빌드·의존성 구성을 커밋한다. Firebase 외부 의존성을
      Analytics·Crashlytics에서 Core·Messaging으로 교체하고, 원격 알림 배경 모드와
      APNs entitlement, Firebase 프로젝트 설정을 반영한다.
      `sources/Tuist/ProjectDescriptionHelpers/Projects/ExternalDependenciesName.swift`,
      `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`,
      `sources/Tuist/Package.swift`,
      `sources/Projects/App/GitIt.entitlements`,
      `sources/Projects/App/Config/GoogleService-Info.plist`
- [X] T003 로컬 알림 클라이언트 이름 변경을 커밋한다.
      `UNUserNotificationCenterLocalNotificationClient`를 `UserNotificationCenterLocalClient`로
      바꾸고 조립 지점의 참조를 갱신한다. 위 **파일 단위 제약**에 따라 `AppComposition.swift`의
      기기 등록 로깅 hunk도 같은 커밋에 포함된다.
      `sources/Projects/Infrastructure/PushMessaging/Clients/UNUserNotificationCenterLocalNotificationClient.swift`(삭제),
      `sources/Projects/Infrastructure/PushMessaging/Clients/UserNotificationCenterLocalClient.swift`(추가),
      `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`
- [X] T004 FCM 원격 알림 수신 경로 보완을 커밋한다. `FirebaseApp` 중복 구성 방지,
      `UNUserNotificationCenterDelegate` 연결, `Messaging.appDidReceiveMessage` 호출을 반영한다.
      `sources/Projects/Infrastructure/PushMessaging/AppDelegates/FirebaseMessagingAppDelegate.swift`,
      `sources/Projects/Infrastructure/PushMessaging/Clients/FirebaseMessagingPushClient.swift`
- [X] T005 리마인드 경로 진단 로깅 추가를 커밋한다. 권한 요청 결과, 리마인드 등록·판정 분기,
      생성 결과 payload 파싱 결과를 `os.Logger`로 남긴다.
      `sources/Projects/Composition/Adapter/Adapters/NotificationAuthorizationGatewayAdapter.swift`,
      `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`,
      `sources/Projects/Data/LearningProject/Remotes/PushProjectGenerationOutcomeRemote.swift`
- [X] T006 [P] DEBUG 전용 초기화 버튼 복구를 커밋한다. 주석 처리된 `ResetAllButton`
      `safeAreaInset`를 다시 활성화한다.
      `sources/Projects/App/GitIt/Screens/AppRootView.swift`
- [ ] T007 [P] Home 카드 스크롤 레이아웃 상수 추출을 커밋한다. 화면에 흩어진 카드 폭·간격·여백
      리터럴을 `CardLayout` 중첩 타입으로 모은다.
      `sources/Projects/Feature/Home/Screens/HomeScreen.swift`

### 검증

- [ ] T008 [no-write] `make tuist` 후 `build`를 실행해 기준선이 컴파일되는지 확인하고,
      `test` 결과를 `/tmp/gitit-baseline-tests.log`에 저장한다(SC-003 비교 대상).
      `make tuist` 실행 전후 `git status`를 비교해 추적 파일 변경이 생기지 않았는지 확인하고,
      `issue/`와 `specs/020-local-reminder-notification/**`이 untracked로 보존됐는지 확인한다.

**진행 점검**: T001~T008의 변경 파일과 검증 결과를 보고하고 U1로 연속 진행한다.

---

## 실행 단위 U1: Infrastructure 경계 복원 `[통합: Infrastructure + Composition]`

**목표**: 범용 기술 계약에서 서비스 개념과 사용자 표시 문구를 제거하고, 원격 푸시와 로컬
알림을 하위 능력 폴더로 분리한다.

**분리 불가 근거**: `LocalNotificationClient`의 연산 시그니처가 바뀌므로 유일한 소비자인
Composition의 스케줄러·게이트웨이 어댑터가 같은 변경에서 함께 바뀌지 않으면 컴파일되지
않는다.

**소유 경로**: `sources/Projects/Infrastructure/PushMessaging/**`,
`sources/Projects/Composition/Adapter/**`,
`sources/Projects/Composition/Tests/Adapter/Factories/GenerationCompletionReminderCoordinatorTests.swift`

**관련 변경 시나리오**: S1

**독립 검증**: `build` 통과 + [quickstart.md](./quickstart.md) 시나리오 1의 두 grep이 0줄.

### 구현 — Infrastructure

- [X] T009 [S1] `sources/Projects/Infrastructure/PushMessaging/Local/Models/LocalNotificationRequest.swift`를
      생성하고 `identifier`·`title`·`body`를 갖는 `public struct LocalNotificationRequest`를
      선언한다([contracts/infrastructure-push-messaging.md](./contracts/infrastructure-push-messaging.md) §1).
- [X] T010 [S1] `sources/Projects/Infrastructure/PushMessaging/Clients/LocalNotificationClient.swift`를
      `sources/Projects/Infrastructure/PushMessaging/Local/Clients/LocalNotificationClient.swift`로
      옮기고, `presentGenerationCompletedNotification(projectID:)`를
      `present(_ request: LocalNotificationRequest)`로 바꾼다
      ([contracts/infrastructure-push-messaging.md](./contracts/infrastructure-push-messaging.md) §1).
- [X] T011 [S1] `LocalNotificationAuthorizationOutcome` 열거형을 기존 위치(현재
      `sources/Projects/Infrastructure/PushMessaging/Clients/LocalNotificationClient.swift` 안)에서
      `sources/Projects/Infrastructure/PushMessaging/Local/Models/LocalNotificationAuthorizationOutcome.swift`로
      옮긴다. 이름은 바꾸지 않는다. Swift는 protocol 내부에 타입을 중첩할 수 없어(언어 제약,
      [research.md](./research.md) R-010) 프로토콜과 한 파일에 있던 이 열거형을 별도 파일로
      분리해야 "파일 하나에 타입 하나" 규칙(FR-003)을 지킬 수 있다
      ([file-vocabulary.md §2.4](../../docs/conventions/file-vocabulary.md#24-중첩할-수-없는-타입)).
- [X] T012 [S1] `sources/Projects/Infrastructure/PushMessaging/Clients/UserNotificationCenterLocalClient.swift`를
      `sources/Projects/Infrastructure/PushMessaging/Local/Clients/UserNotificationCenterLocalClient.swift`로
      옮기고, 하드코딩된 `"세트 생성 완료"`·`"학습 세트 생성이 완료됐어요. 지금 확인해보세요."`와
      `"generation-completed-\(projectID)"` 식별자를 제거한 뒤 전달받은
      `LocalNotificationRequest` 값으로 `UNNotificationRequest`를 만든다(FR-001, FR-002).
- [X] T013 [P] [S1] `sources/Projects/Infrastructure/PushMessaging/AppDelegates/FirebaseMessagingAppDelegate.swift`를
      `sources/Projects/Infrastructure/PushMessaging/Remote/AppDelegates/FirebaseMessagingAppDelegate.swift`로
      옮긴다.
- [X] T014 [P] [S1] `sources/Projects/Infrastructure/PushMessaging/Clients/PushMessagingClient.swift`를
      `sources/Projects/Infrastructure/PushMessaging/Remote/Clients/PushMessagingClient.swift`로 옮긴다.
- [X] T015 [P] [S1] `sources/Projects/Infrastructure/PushMessaging/Clients/FirebaseMessagingPushClient.swift`를
      `sources/Projects/Infrastructure/PushMessaging/Remote/Clients/FirebaseMessagingPushClient.swift`로 옮긴다.
- [X] T016 [S1] `sources/Projects/Infrastructure/PushMessaging/Models/PushNotificationHandlers.swift`를
      `sources/Projects/Infrastructure/PushMessaging/Remote/Models/PushNotificationCallbacks.swift`로
      옮기고 타입 이름을 `PushNotificationCallbacks`로 바꾼다. `Handler` 접미어는
      `docs/conventions/naming.md` §5가 금지하는 "향후 가능성" 접미어이며 실제 내용은 클로저 묶음이다.
- [X] T017 [P] [S1] `sources/Projects/Infrastructure/PushMessaging/Models/RemoteNotificationPayload.swift`를
      `sources/Projects/Infrastructure/PushMessaging/Remote/Models/RemoteNotificationPayload.swift`로
      옮기고, 공개 프로퍼티 `value`를 `userInfoStrings`로 바꾼다(naming.md §3.5 — 경계를 넘는
      `value`는 무엇의 값인지 식별되지 않는다).

### 구현 — Composition

- [X] T018 [S1] `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`에서
      알림 식별자 `"generation-completed-<projectID>"`와 제목·본문 문구를 생성해
      `LocalNotificationRequest`로 `present(_:)`에 전달하도록 바꾼다. 형식과 내용은 현재와
      동일하게 유지한다(FR-018).
- [X] T019 [S1] `sources/Projects/Composition/Adapter/Adapters/NotificationAuthorizationGatewayAdapter.swift`가
      계속 정상 동작하는지 확인한다. 이 파일은 `LocalNotificationAuthorizationOutcome`을
      이름으로 참조하지 않고 `switch`의 케이스 패턴 매칭만 사용하므로, T011이 파일 위치만
      옮기고 이름을 바꾸지 않는 한 텍스트 변경이 필요 없다.
- [X] T020 [S1] `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`와
      `sources/Projects/Composition/Adapter/Factories/PushNotificationAppDelegate.swift`가
      `PushNotificationCallbacks`를 참조하도록 바꾼다.
- [X] T021 [S1] `sources/Projects/Composition/Tests/Adapter/Factories/GenerationCompletionReminderCoordinatorTests.swift`의
      `StubLocalNotificationClient`에서 `presentGenerationCompletedNotification(projectID:)`를
      `present(_ request: LocalNotificationRequest)`로 바꾸고, `presentedProjectIDs()`가
      기록한 `LocalNotificationRequest.identifier`를 반환하도록 내부 기록 로직을 최소 변경한다.
      식별자 형식이 `"generation-completed-<projectID>"`로 바뀌므로(T018) 이를 기대하는
      `#expect(... == ["project-1"])` 두 곳도 `["generation-completed-project-1"]`로 함께
      맞춘다. 이 프로토콜 구현체가 옛 시그니처를 유지하면 `build`가 테스트 target 컴파일에서
      실패한다(`build`는 AppTests·Composition·AllTests 등 테스트 scheme도 포함해 "모든 공유
      scheme Debug 빌드"를 수행하므로 프로토콜을 구현하는 모든 타입이 같은 변경에서 갱신되어야
      한다). `LearningProjectGenerationOutcome` 관련 이름은 건드리지 않는다(U2의 별도 작업이
      담당).

### 단위 검증

- [X] T022 [no-write] [S1] `build`를 실행하고
      `grep -rniE "세트|학습|generation-completed|생성 완료" sources/Projects/Infrastructure/PushMessaging --include="*.swift"`가
      0줄임을 확인한다(SC-001).

**진행 점검**: T009~T022의 변경 파일과 검증 결과를 보고하고 U2로 연속 진행한다.

---

## 실행 단위 U2: 생성 결과 모델 어휘 통일 `[통합: Domain + Data + Composition + Feature + App]`

**목표**: 모델·저장소 계약·DTO·스트림 이름을 `GenerationOutcome` 어휘로 통일한다.

**분리 불가 근거**: `GenerationOutcome`은 Domain이 정의하고 Data(DTO 대응),
Composition(변환), Feature(Action payload), App(주입)이 모두 이름으로 참조한다. 한 패키지만
바꾸면 나머지 네 패키지가 컴파일되지 않는다.

**소유 경로**: 아래 작업이 명시하는 경로

**관련 변경 시나리오**: S2

**독립 검증**: `build`·`compile`·`test` 통과 + quickstart 시나리오 2의 옛 어휘 grep이 0줄.

### 구현 — Domain

- [ ] T023 [S2] `sources/Projects/Domain/LearningProject/Models/LearningProject/LearningProjectGenerationOutcome.swift`를
      `sources/Projects/Domain/LearningProject/Models/LearningProject/GenerationOutcome.swift`로
      옮기고 타입 이름을 `GenerationOutcome`으로 바꾼다. 필드·중첩 `Status` 케이스는 그대로 둔다.
- [ ] T024 [S2] `sources/Projects/Domain/LearningProject/Contracts/LearningProjectGenerationOutcomeRepository.swift`를
      `sources/Projects/Domain/LearningProject/Contracts/GenerationOutcomeRepository.swift`로
      옮기고 프로토콜 이름을 `GenerationOutcomeRepository`로 바꾼다.

### 구현 — Data

- [ ] T025 [P] [S2] `sources/Projects/Data/LearningProject/DTOs/ProjectGenerationOutcomeDTO.swift`를
      `sources/Projects/Data/LearningProject/DTOs/GenerationOutcomeDTO.swift`로 옮기고 타입 이름을
      `GenerationOutcomeDTO`로 바꾼다. `rawPayload` 키 `projectId`·`status`와 값
      `completed`·`failed`는 서버 소유 계약이므로 변경하지 않는다.
- [ ] T026 [S2] `sources/Projects/Data/LearningProject/Contracts/ProjectGenerationOutcomeRemote.swift`를
      `sources/Projects/Data/LearningProject/Contracts/GenerationOutcomeStream.swift`로 옮기고
      프로토콜 이름을 `GenerationOutcomeStream`으로 바꾼다. `Remote` 역할어는 네트워크를
      호출하지 않는 이 계약에 맞지 않는다(naming.md §3.2).
- [ ] T027 [S2] `sources/Projects/Data/LearningProject/Remotes/PushProjectGenerationOutcomeRemote.swift`를
      `sources/Projects/Data/LearningProject/Remotes/PushGenerationOutcomeStream.swift`로 옮기고
      타입 이름을 `PushGenerationOutcomeStream`으로 바꾼다.
- [ ] T028 [P] [S2] `sources/Projects/Data/Tests/LearningProject/DTOs/ProjectGenerationOutcomeDTOTests.swift`를
      `sources/Projects/Data/Tests/LearningProject/DTOs/GenerationOutcomeDTOTests.swift`로 옮기고
      새 타입 이름을 참조하도록 바꾼다.
- [ ] T029 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Remotes/PushProjectGenerationOutcomeRemoteTests.swift`를
      `sources/Projects/Data/Tests/LearningProject/Remotes/PushGenerationOutcomeStreamTests.swift`로
      옮기고 새 타입 이름을 참조하도록 바꾼다.

### 구현 — Composition

- [ ] T030 [S2] `sources/Projects/Composition/Adapter/Adapters/LearningProjectGenerationOutcomeRepositoryAdapter.swift`를
      `sources/Projects/Composition/Adapter/Adapters/GenerationOutcomeRepositoryAdapter.swift`로
      옮기고 타입 이름을 바꾼다. 동시에 `dto.status` `switch`의 `@unknown default` 분기를
      제거해 전수 분기로 만들고 변환 결과를 `Optional`이 아니게 한다(FR-019,
      [contracts/domain-generation-outcome.md](./contracts/domain-generation-outcome.md) §6).
- [ ] T031 [S2] `sources/Projects/Composition/Adapter/Assemblies/LearningProjectAssembly.swift`가
      새 타입 이름을 참조하도록 바꾼다.
- [ ] T032 [S2] `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`가
      `GenerationOutcome`을 참조하도록 바꾼다.
- [ ] T033 [P] [S2] `sources/Projects/Composition/Tests/Adapter/Adapters/LearningProjectGenerationOutcomeRepositoryAdapterTests.swift`를
      `sources/Projects/Composition/Tests/Adapter/Adapters/GenerationOutcomeRepositoryAdapterTests.swift`로
      옮기고 새 타입 이름과 비-Optional 변환 결과를 참조하도록 바꾼다.
- [ ] T034 [P] [S2] `sources/Projects/Composition/Tests/Adapter/Assemblies/LearningProjectAssemblyTests.swift`와
      `sources/Projects/Composition/Tests/Adapter/Factories/GenerationCompletionReminderCoordinatorTests.swift`가
      새 타입 이름을 참조하도록 바꾼다.

### 구현 — Feature

- [ ] T035 [S2] `sources/Projects/Feature/Home/Reducers/HomeFeature.swift`와
      `sources/Projects/Feature/Home/Previews/HomePreviewSupport/HomePreviewSupport.swift`가
      `GenerationOutcome`을 참조하도록 바꾼다.
- [ ] T036 [S2] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`와
      `sources/Projects/Feature/ProjectRegistration/Previews/ProjectRegistrationScreenPreviews.swift`가
      `GenerationOutcome`을 참조하도록 바꾼다. 이 파일의 `outcome.status` `switch`에 있는
      `@unknown default` 분기도 함께 제거한다(FR-019).
- [ ] T037 [P] [S2] `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureGenerationOutcomeTests.swift`,
      `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`,
      `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubLearningProjectOutcomesUseCase.swift`가
      새 타입 이름을 참조하도록 바꾼다.

### 구현 — App

- [ ] T038 [S2] `sources/Projects/App/GitIt/Screens/AppRootView.swift`와
      `sources/Projects/App/Tests/GitIt/TestDoubles/LearningProjectOutcomesUseCaseMock.swift`가
      `GenerationOutcome`을 참조하도록 바꾼다.

### 단위 검증

- [ ] T039 [no-write] [S2] `build`·`compile`·`test`를 실행하고
      `grep -rnE "LearningProjectGenerationOutcome|ProjectGenerationOutcomeDTO|ProjectGenerationOutcomeRemote" sources/Projects --include="*.swift"`가
      0줄임을 확인한다.

**진행 점검**: T023~T039의 변경 파일과 검증 결과를 보고하고 U3로 연속 진행한다.

---

## 실행 단위 U3: UseCase 관찰 이름 복원과 권한 조회 분리 `[통합: Domain + Composition + Feature + App]`

**목표**: `Observe` 접두어로 관찰 수명을 드러내고, 이름이 설명하지 않는 `isAuthorized()`를
별도 UseCase 계약으로 분리한다.

**분리 불가 근거**: UseCase 계약 개명과 계약 축소가 동시에 일어나며 주입 경로가
Composition → App → Feature로 이어져 세 패키지가 함께 바뀌어야 컴파일된다.

**소유 경로**: 아래 작업이 명시하는 경로

**관련 변경 시나리오**: S2

**독립 검증**: `build`·`compile`·`test` 통과 + `LearningProjectOutcomes` grep이 0줄.

### 구현 — Domain

- [ ] T040 [S2] `sources/Projects/Domain/LearningProject/UseCases/LearningProjectOutcomes/LearningProjectOutcomesUseCase.swift`를
      `sources/Projects/Domain/LearningProject/UseCases/ObserveGenerationOutcomes/ObserveGenerationOutcomesUseCase.swift`로
      옮기고 프로토콜 이름을 `ObserveGenerationOutcomesUseCase`로 바꾼다(naming.md §3.3 —
      무한 스트림 관찰과 1회 조회를 이름에서 구분).
- [ ] T041 [S2] `sources/Projects/Domain/LearningProject/UseCases/LearningProjectOutcomes/LearningProjectOutcomes.swift`를
      `sources/Projects/Domain/LearningProject/UseCases/ObserveGenerationOutcomes/ObserveGenerationOutcomes.swift`로
      옮기고 타입 이름과 `repository` 파라미터 타입을 바꾼다.
- [ ] T042 [P] [S2] `sources/Projects/Domain/LearningProject/Models/NotificationAuthorizationOutcome.swift`를
      `sources/Projects/Domain/LearningProject/Models/Notification/NotificationAuthorizationOutcome.swift`로
      옮긴다. 다른 모델은 모두 타입 패밀리 폴더 안에 있으므로 배치를 일관되게 한다.
- [ ] T043 [S2] `sources/Projects/Domain/LearningProject/UseCases/RequestGenerationReminder/RequestGenerationReminderUseCase.swift`에서
      `isAuthorized()`를 제거해 계약이 이름이 설명하는 책임만 갖게 한다(FR-007).
- [ ] T044 [S2] `sources/Projects/Domain/LearningProject/UseCases/RequestGenerationReminder/RequestGenerationReminder.swift`에서
      `isAuthorized()` 구현을 제거한다.
- [ ] T045 [S2] `sources/Projects/Domain/LearningProject/UseCases/NotificationAuthorizationStatus/NotificationAuthorizationStatusUseCase.swift`를
      생성하고 `func callAsFunction() async -> Bool`을 선언한다.
- [ ] T046 [S2] `sources/Projects/Domain/LearningProject/UseCases/NotificationAuthorizationStatus/NotificationAuthorizationStatus.swift`를
      생성하고 `NotificationAuthorizationGateway`에 위임하는 구현을 작성한다.
- [ ] T047 [P] [S2] `sources/Projects/Domain/Tests/LearningProject/UseCases/LearningProjectOutcomesTests.swift`를
      `sources/Projects/Domain/Tests/LearningProject/UseCases/ObserveGenerationOutcomesTests.swift`로
      옮기고 새 이름을 참조하도록 바꾼다.
- [ ] T048 [S2] `sources/Projects/Domain/Tests/LearningProject/UseCases/RequestGenerationReminderTests.swift`에서
      `isAuthorized` 검증을 제거하고,
      `sources/Projects/Domain/Tests/LearningProject/UseCases/NotificationAuthorizationStatusTests.swift`를
      생성해 게이트웨이 위임을 검증한다.

### 구현 — Composition

- [ ] T049 [S2] `sources/Projects/Composition/Adapter/Assemblies/LearningProjectAssembly.swift`의
      `learningProjectOutcomes` 프로퍼티를 `observeGenerationOutcomes`로 바꾸고 새 타입을 조립한다.
- [ ] T050 [S2] `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`의
      공개 프로퍼티 `learningProjectOutcomes`를 `observeGenerationOutcomes`로 바꾸고,
      `notificationAuthorizationStatus` 공개 프로퍼티를 추가해 새 UseCase를 노출한다.
- [ ] T051 [P] [S2] `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`와
      `sources/Projects/Composition/Tests/Adapter/**`의 관련 파일이 새 이름을 참조하도록 바꾼다.

### 구현 — Feature

- [ ] T052 [S2] `sources/Projects/Feature/Home/Reducers/HomeFeature.swift`,
      `sources/Projects/Feature/MainShell/Reducers/MainShellFeature.swift`,
      `sources/Projects/Feature/Home/Previews/HomePreviewSupport/HomePreviewSupport.swift`의
      주입 인자 이름과 타입을 `observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase`로 바꾼다.
- [ ] T053 [S2] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`가
      `observeGenerationOutcomes`와 신규 `notificationAuthorizationStatus`를 주입받고,
      `waitAtHomeTapped` 처리에서 후자를 호출하도록 바꾼다. Effect 이름
      `waitAtHomeAuthorizationChecked(isAuthorized:)`를
      `notificationAuthorizationChecked(isAuthorized:)`로 바꾼다(화면 버튼 문구가 Effect 이름에
      박혀 있음). 상태 전이 순서와 결과는 바꾸지 않는다.
- [ ] T054 [P] [S2] `sources/Projects/Feature/ProjectRegistration/Previews/ProjectRegistrationScreenPreviews.swift`,
      `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubLearningProjectOutcomesUseCase.swift`
      (→ `StubObserveGenerationOutcomesUseCase.swift`로 개명),
      `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubRequestGenerationReminderUseCase.swift`,
      `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureLoadTests.swift`,
      `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureNavigationTests.swift`,
      `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureGenerationOutcomeTests.swift`,
      `sources/Projects/Feature/Tests/MainShell/Reducers/MainShellFeatureTests.swift`,
      `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`를
      새 이름과 신규 UseCase 주입에 맞춰 갱신한다.

### 구현 — App

- [ ] T055 [S2] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`,
      `sources/Projects/App/GitIt/Screens/AppRootView.swift`,
      `sources/Projects/App/GitIt/GitItApp.swift`,
      `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`,
      `sources/Projects/App/Tests/GitIt/TestDoubles/LearningProjectOutcomesUseCaseMock.swift`
      (→ `ObserveGenerationOutcomesUseCaseMock.swift`로 개명)을 새 이름과 신규 UseCase 주입에
      맞춰 갱신한다.

### 단위 검증

- [ ] T056 [no-write] [S2] `build`·`compile`·`test`를 실행하고
      `grep -rn "LearningProjectOutcomes" sources/Projects --include="*.swift"`가 0줄임을 확인한다.
      `GenerationOutcome`으로 시작하는 식별자의 최장 길이가 40자 이하인지도 확인한다(SC-002).

**진행 점검**: T040~T056의 변경 파일과 검증 결과를 보고하고 U4로 연속 진행한다.

---

## 실행 단위 U4: 조립과 실행 분리 `[통합: Composition + App + docs]`

**목표**: `AppComposition` 생성자의 부작용을 `start()`로 옮기고, Infrastructure 타입을 공개
API로 승격하던 typealias를 Composition 소유 클래스로 대체한다.

**분리 불가 근거**: 공개 표면 변경과 App 호출부 변경이 같은 변경에서 일어나야 컴파일된다.
형태 폴더 어휘 추가는 FR-012에 따라 같은 변경에 포함해야 어휘 정본과 실제 구조가 갈라지지 않는다.

**소유 경로**: `sources/Projects/Composition/**`, `sources/Projects/App/GitIt/GitItApp.swift`,
`docs/conventions/file-vocabulary.md`

**관련 변경 시나리오**: S3

**독립 검증**: `build`·`test` 통과 + quickstart 시나리오 3의 세 grep이 0줄.

### 구현 — Composition

- [ ] T057 [S3] `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`를
      `sources/Projects/Composition/Adapter/Assemblies/GenerationReminderScheduler.swift`로 옮기고
      타입 이름을 `GenerationReminderScheduler`로 바꾼다. `Factories/`는 "구현 선택과 생성"만
      담으므로 관찰 Task 수명과 등록 집합을 소유하는 이 타입에 맞지 않는다(FR-012).
- [ ] T058 [S3] `sources/Projects/Composition/Adapter/Assemblies/GenerationReminderScheduler.swift`가
      `GenerationReminderRegistry`를 직접 구현하도록 바꾸고, `start(...)`가
      `Task<Void, Never>`를 반환하게 하며 `waitUntilObservationFinished()`를 제거한다(FR-010).
- [ ] T059 [S3] `sources/Projects/Composition/Adapter/Adapters/GenerationReminderRegistryAdapter.swift`를
      삭제한다. 변환 없는 순수 위임이므로 T058이 대체한다(FR-013).
- [ ] T060 [S3] `sources/Projects/Composition/Adapter/AppDelegates/PushNotificationAppDelegate.swift`를
      생성하고, `UIApplicationDelegate` 콜백을 내부 `FirebaseMessagingAppDelegate`에 위임하는
      `public final class`를 작성한다. Infrastructure 구체 타입이 이 파일 밖으로 노출되지
      않아야 한다(FR-011,
      [contracts/composition-public-surface.md](./contracts/composition-public-surface.md) §2).
- [ ] T061 [S3] `sources/Projects/Composition/Adapter/Factories/PushNotificationAppDelegate.swift`
      (typealias)를 삭제한다.
- [ ] T062 [S3] `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`에서
      생성자의 부작용 3건(관찰 시작, `configure(...)` 전역 상태 쓰기, 기기 등록 네트워크 호출)을
      제거하고 `public func start() -> AppCompositionRuntime` 진입점으로 옮긴다.
      반환 핸들로 시작한 작업을 취소할 수 있어야 한다(FR-008, FR-009).
- [ ] T063 [P] [S3] `sources/Projects/Composition/Tests/Adapter/Factories/GenerationCompletionReminderCoordinatorTests.swift`를
      `sources/Projects/Composition/Tests/Adapter/Assemblies/GenerationReminderSchedulerTests.swift`로
      옮기고, `waitUntilObservationFinished()` 대신 `start(...)`가 반환하는 `Task`를 `await`하도록 바꾼다.
- [ ] T064 [S3] `sources/Projects/Composition/Tests/Adapter/Assemblies/AppCompositionPublicSurfaceTests.swift`에
      `live(...)` 호출만으로 부작용이 발생하지 않음을 검증하는 테스트를 추가한다(SC-004).

### 구현 — App

- [ ] T065 [S3] `sources/Projects/App/GitIt/GitItApp.swift`가 조립 후 `composition.start()`를
      호출하고, `@UIApplicationDelegateAdaptor`에 Composition 소유
      `PushNotificationAppDelegate`를 사용하도록 바꾼다.

### 구현 — 공용 문서

- [ ] T066 [S3] `docs/conventions/file-vocabulary.md` §3의 형태 어휘 표에서
      `Composition/Adapter/` 소스 루트에 `AppDelegates/`(담는 선언: 플랫폼 생명주기 delegate
      타입) 행을 추가한다. 책임 패키지는 Composition이다. 이 문서 변경은 FR-012와 어휘 표
      자체의 규정("표에 없는 형태 폴더를 추가하려면 같은 PR에서 표를 갱신한다")이 요구한다.

### 단위 검증

- [ ] T067 [no-write] [S3] `make tuist` 후 `build`·`test`를 실행하고 quickstart 시나리오 3의
      세 grep이 0줄임을 확인한다. `make tuist` 실행 전후 `git status`를 비교한다.

**진행 점검**: T057~T067의 변경 파일과 검증 결과를 보고하고 U5로 연속 진행한다.

---

## 실행 단위 U5: 사용처 없는 UI 컴포넌트 제거 `[단일: UI]`

**목표**: production 참조가 0인 `TextField`와 그 전용 테스트를 제거한다.

**소유 경로**: `sources/Projects/UI/Component/Controls/TextField.swift`,
`sources/Projects/UI/Tests/Component/Unit/Controls/TextFieldTests.swift`

**관련 변경 시나리오**: S4

**독립 검증**: 두 파일 삭제 후 `build`·`test` 통과.

### 구현

- [ ] T068 [S4] `sources/Projects/UI/Component/Controls/TextField.swift`를 삭제한다.
      저장소 전체에서 production 참조가 0이며 남은 참조는 자기 파일의 `#Preview` 3건과
      아래 테스트뿐이다([research.md](./research.md) R-007).
- [ ] T069 [S4] `sources/Projects/UI/Tests/Component/Unit/Controls/TextFieldTests.swift`를 삭제한다.

### 단위 검증

- [ ] T070 [no-write] [S4] `build`·`test`를 실행하고 두 경로가 존재하지 않음을 확인한다.

**진행 점검**: T068~T070의 변경 파일과 검증 결과를 보고하고 U6으로 연속 진행한다.

---

## 실행 단위 U6: Feature·App 죽은 코드 제거 `[통합: Feature + App]`

**목표**: 소비되지 않는 delegate, 미사용 상수, 사용되지 않는 취소 id, 단방향 2케이스 enum,
취소 수단 없는 Effect를 정리한다.

**분리 불가 근거**: `Delegate.notificationOptionSelected`를 제거하면 `AppRootFeature`의 수신
분기도 같은 변경에서 사라져야 `switch` 전수성이 유지되고 컴파일된다.

**소유 경로**: `sources/Projects/Feature/**`, `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`

**관련 변경 시나리오**: S4

**독립 검증**: `build`·`test` 통과 + quickstart 시나리오 4의 grep이 0줄.

### 구현

- [ ] T071 [S4] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`에서
      `Delegate.notificationOptionSelected(accepted:)` 케이스와 이를 발행하는
      `finishWaiting`의 분기를 제거한다. 이 출력은 유일한 소비자가 무시한다(FR-013).
- [ ] T072 [S4] 같은 파일에서 `CancelID.submission`을 제거한다. 저장소에 이 id를 취소하는
      코드가 없고 `cancelInFlight`도 없어 사용되지 않는다. 중복 제출은 기존
      `state.submission != .committing` guard가 계속 막는다.
- [ ] T073 [S4] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`에서
      `.projectRegistration(.presented(.delegate(.notificationOptionSelected(_))))` 빈 분기를 제거한다.
- [ ] T074 [P] [S4] `sources/Projects/Feature/ProjectRegistration/Screens/NotificationOptionSheet.swift`에서
      미사용 상수 `Constant.bellIconSize`를 제거한다.
- [ ] T075 [S4] `sources/Projects/Feature/Home/Reducers/HomeFeature.swift`에서 단방향 2케이스
      enum `GenerationOutcomeObservation`을 `Bool` 상태로 바꾸고, 관찰 Effect에
      `.cancellable(id:cancelInFlight:)`를 추가한다. 이 Effect는 현재 이 Feature에서 유일하게
      취소 수단이 없어 State 폐기 후에도 스트림 소비 Task가 남는다.
- [ ] T076 [S4] `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`에서
      제거된 delegate를 검증하는 `receive` 구문 6곳을 제거한다.
- [ ] T077 [P] [S4] `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureGenerationOutcomeTests.swift`가
      새 `Bool` 상태를 참조하도록 갱신한다.

### 단위 검증

- [ ] T078 [no-write] [S4] `build`·`test`를 실행하고
      `grep -rn "notificationOptionSelected\|bellIconSize\|CancelID.submission\|GenerationReminderRegistryAdapter" sources/Projects --include="*.swift"`가
      0줄임을 확인한다(SC-005).

**진행 점검**: T071~T078의 변경 파일과 검증 결과를 보고하고 U7로 연속 진행한다.

---

## 실행 단위 U7: 중복·항진 테스트 정리 `[단일: Feature 테스트]`

**목표**: 완전히 포함되는 테스트를 삭제하고, 본문이 같고 상수만 다른 3건을 파라미터화
테스트로 합치며, 기본값만 확인하는 항진 테스트를 제거한다.

**소유 경로**: `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`

**관련 변경 시나리오**: S4

**독립 검증**: `test` 통과 + 검증되는 입력 조합 수가 줄지 않음(SC-008).

### 구현

- [ ] T079 [S4] `알림 수락은 notificationOptionSelected accepted true를 출력한 뒤 waitAtHomeTapped
      동작을 이어간다` 테스트를 삭제한다. 뒤따르는 `권한이 허용되면 …` 테스트와 send/receive
      시퀀스가 동일하고 후자가 spy 검증까지 포함해 완전히 포함한다.
- [ ] T080 [S4] `권한이 허용되면 …`, `권한을 방금 거부해도 …`, `권한이 이미 거부된 상태면 …`
      세 테스트를 `@Test(arguments:)` 파라미터화 테스트 하나로 합친다. 세 테스트는 본문 25줄이
      동일하고 스텁 결과(`.authorized`/`.declined`/`.previouslyDenied`)와 기대 호출 횟수
      (`0`/`0`/`1`)만 다르다. 검증 입력 조합 3개를 모두 유지한다.
- [ ] T081 [S4] `알림 옵션 선택은 상태 전이 자체에 영향을 주지 않는다` 테스트를 삭제한다.
      검증 대상 필드(`repositoryURLInput`, `quizLevel`)를 한 번도 설정하지 않아 항상 통과하며
      `exhaustivity = .off`로 실제 상태 변화도 확인하지 않는다(FR-015).

### 단위 검증

- [ ] T082 [no-write] [S4] `test`를 실행하고 통합 전후 검증 입력 조합 수를 비교해 줄지
      않았음을 확인한다.

**진행 점검**: T079~T082의 변경 파일과 검증 결과를 보고하고 U8로 연속 진행한다.

---

## 실행 단위 U8: 테스트 target 신설과 검증 공백 보강 `[통합: Tuist manifest + Infrastructure·Composition·Feature 테스트]`

**목표**: `InfrastructurePushMessagingTests` target을 신설하고 계층 간 값 변환 검증을 추가한다.

**분리 불가 근거**: manifest의 target 정의와 테스트 소스가 함께 있어야 target이 빌드된다.
manifest만 바꾸면 소스 없는 target이, 소스만 추가하면 빌드되지 않는 파일이 남는다.
Tuist manifest는 패키지에 속하지 않는 파일이며 이 단위가 최초로 필요로 하므로 여기에 배정한다.

**소유 경로**: `sources/Tuist/ProjectDescriptionHelpers/**`,
`sources/Projects/Infrastructure/Tests/PushMessaging/**`,
`sources/Projects/Composition/Tests/Adapter/Adapters/**`,
`sources/Projects/Feature/Tests/Home/Reducers/**`

**관련 변경 시나리오**: S5

**독립 검증**: `make tuist` 후 `test` 실행 기록에 새 target이 나타나고 통과한다(SC-006).

### 구현 — Tuist manifest

- [ ] T083 [S5] `sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`에
      `InfrastructurePushMessagingTests` enum case를 추가하고, 다른 Infrastructure 테스트와 같은
      형태의 `.testModule(...)` 정의를 추가하며, `sourceDirectory`의 테스트 분기에 이 case를
      포함한다.
- [ ] T084 [S5] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 Infrastructure
      프로젝트 `testTargets` 배열에 `InfrastructurePushMessagingTests`를 추가한다.

### 구현 — Infrastructure 테스트

- [ ] T085 [P] [S5] `sources/Projects/Infrastructure/Tests/PushMessaging/Remote/Models/RemoteNotificationPayloadTests.swift`를
      생성하고 `[AnyHashable: Any]` → `[String: String]` 변환에서 비문자열 키가 제외되는지
      검증한다.
- [ ] T086 [P] [S5] `sources/Projects/Infrastructure/Tests/PushMessaging/Local/Models/LocalNotificationRequestTests.swift`를
      생성하고 생성한 `identifier`·`title`·`body`가 그대로 읽히는지 검증한다.

### 구현 — Composition 테스트

- [ ] T087 [S5] `sources/Projects/Composition/Tests/Adapter/Adapters/NotificationAuthorizationGatewayAdapterTests.swift`를
      생성하고 Infrastructure `LocalNotificationAuthorizationOutcome`의 세 케이스가 각각 대응하는 Domain
      `NotificationAuthorizationOutcome`으로 변환되는지 검증한다. 현재 이 변환에는 테스트가
      없어 세 분기를 뒤바꿔도 실패하지 않는다(FR-017).

### 구현 — Feature 테스트

- [ ] T088 [S5] `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureGenerationOutcomeTests.swift`에
      등록 완료 트리거(`reloadRequested`)와 생성 완료 트리거(`generationOutcomeReceived`)가
      근접해 발생할 때의 동작을 고정하는 테스트를 추가한다. 두 경로는 유지하기로 결정했으므로
      (R-009) 현재 동작을 회귀 테스트로 잠근다.

### 단위 검증

- [ ] T089 [no-write] [S5] `make tuist` 후 `build`·`compile`·`test`를 실행하고, 실행 기록에
      `InfrastructurePushMessagingTests`가 나타나며 실패가 없음을 확인한다. `make tuist` 실행
      전후 `git status`를 비교해 추적 파일 변경이 생기지 않았는지 확인한다.

**진행 점검**: T083~T089의 변경 파일과 검증 결과를 보고하고 U9로 연속 진행한다.

---

## 실행 단위 U9: 전체 기능 검증 `[no-write]`

**목표**: 전체 읽기 전용 검증으로 명세의 성공 기준을 확인한다.

**관련 변경 시나리오**: S1~S5 전체

- [ ] T090 [no-write] `make tuist` 후 `build`·`compile`·`test`를 순차 실행한다. `make tuist`
      실행 전후 `git status`를 비교해 추적 파일 변경이 생기면 완료로 처리하지 않고 변경 경로와
      영향을 보고한다.
- [ ] T091 [no-write] `/tmp/gitit-baseline-tests.log`(T008)와 현재 테스트 결과를 비교해 변경 전
      통과하던 테스트가 모두 통과하고 새로 실패하는 테스트가 0건임을 확인한다(SC-003).
      이름이 바뀐 테스트는 대응 관계를 보고에 기록한다.
- [ ] T092 [no-write] [quickstart.md](./quickstart.md)의 시나리오별 grep 검증 5개를 모두
      실행해 SC-001·SC-002·SC-004·SC-005·SC-006을 확인한다.
- [ ] T093 [no-write] SC-007을 확인한다.
      `sources/Projects/Composition/Adapter/Adapters/NotificationAuthorizationGatewayAdapter.swift`의
      매핑 한 줄을 임시로 뒤바꿔 T087의 테스트가 실패하는지 확인한 뒤 원상복구한다. 이 임시
      변경은 커밋하지 않으며 복구 후 `git status`가 깨끗한지 확인한다.
- [ ] T094 [no-write] `./tools/script-verification/bin/run.sh`를 실행해 정적 검사와 회귀
      테스트를 확인한다(SC-009).
- [ ] T095 마지막 커밋 단위를 stage하기 전에 포맷 훅을 실행하고, 허용된 포맷 결과를 같은
      단위에 포함한다. 훅을 우회하지 않는다(`--no-verify` 금지).

**완료 보고**: 전체 검증 결과와 [research.md](./research.md) R-006·R-009에 기록한 범위 밖
항목(리마인드 정책의 Composition 유지, Home 갱신 경로 2개 유지, 인증 결과 계열 제외,
target 분리 보류, 저장소 전반 `@unknown default`)을 이유·영향·미검증 범위와 함께 PR에 남긴다
(Constitution 원칙 3).

---

## 의존성 그래프

```text
U0 (기준선, 승인 필요)
  ↓
U1 (S1: Infrastructure 경계)
  ↓
U2 (S2: 모델 어휘)  ──→  U3 (S2: UseCase 어휘)
                            ↓
                          U4 (S3: 조립/실행 분리)
                            ↓
        ┌───────────────────┼───────────────────┐
        ↓                   ↓                   ↓
   U5 (S4: UI)         U6 (S4: Feature/App)     │
                            ↓                   │
                       U7 (S4: 테스트)          │
                            └──────────┬────────┘
                                       ↓
                                  U8 (S5: 검증 공백)
                                       ↓
                                  U9 (전체 검증)
```

**U5의 위치**: U5는 다른 어떤 단위와도 파일을 공유하지 않아 U1 이후 어느 시점에나 실행할 수
있다. U4 뒤에 배치한 것은 각 커밋의 diff를 하나의 관심사로 유지하기 위한 선택이며 기술적
의존성은 아니다.

## 병렬 실행 기회

서로 다른 실행 단위는 Git index를 공유하므로 병렬 실행하지 않는다. 아래는 **각 단위 내부**의
병렬 가능 작업이다.

| 단위 | 병렬 가능 작업 | 근거 |
| --- | --- | --- |
| U0 | T006, T007 | 서로 다른 화면 파일이며 앞선 커밋과 겹치지 않음 |
| U1 | T013, T014, T015, T017 | 서로 다른 파일의 단순 이동 |
| U2 | T025 / T028·T029 / T033·T034 / T037 | Data·Composition·Feature 테스트가 서로 독립 |
| U3 | T042, T047 / T051 / T054 | 모델 이동과 테스트 갱신이 서로 독립 |
| U4 | T063 | 다른 Composition 소스와 파일이 겹치지 않음 |
| U6 | T074, T077 | Sheet 상수와 Home 테스트가 서로 독립 |
| U8 | T085, T086 | 서로 다른 신규 테스트 파일 |

## 승인 조건

Constitution 원칙 7에 따라 아래 경우에만 중단하고 명시적 승인을 요청한다. 그 밖의 후속
단위와 읽기 전용 전체 검증은 반복 승인 없이 연속 진행한다.

| 상황 | 해당 작업 |
| --- | --- |
| 사용자 소유 미커밋 변경의 소비 | T001 |
| 이 계획에 없는 범위 확대가 필요해진 경우 | 발견 시 중단 |
| `make tuist`가 추적 파일 diff를 바꾼 경우 | T008, T067, T089, T090 |
| 기존 staged·unstaged 변경의 소유권을 확인할 수 없는 경우 | 모든 단위 |

## 변경 시나리오 추적

| 시나리오 | 우선순위 | 작업 | 독립 수용 기준 |
| --- | --- | --- | --- |
| S1 Infrastructure 경계 | P1 | T009~T022 | Infrastructure 소스에 서비스 용어·표시 문구 0건, 파일당 최상위 타입 1개 |
| S2 어휘 통일 | P2 | T023~T056 | 옛 어휘 grep 0줄, 최장 이름 40자 이하, 기존 테스트 전부 통과 |
| S3 조립/실행 분리 | P3 | T057~T067 | `live(...)` 부작용 0건, Composition 공개 API에 Infrastructure 타입 0건 |
| S4 죽은 코드·중복 테스트 | P4 | T068~T082 | 죽은 선언 grep 0줄, 검증 입력 조합 수 유지 |
| S5 검증 공백 | P5 | T083~T089 | 새 테스트 target이 실행에 포함되어 통과, 매핑 분기 뒤바꾸면 실패 |

## 최소 가치 범위

**U0 + U1 (T001~T022)** 만으로도 유일하게 문서화된 패키지 규칙 위반이 해소되어 독립적인
가치를 제공한다. 이후 단위는 같은 기능 범위이므로 새 권한이 필요하지 않으면 연속 진행한다.
