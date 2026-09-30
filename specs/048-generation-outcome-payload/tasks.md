---

description: "생성 결과 원격 알림을 서버의 실제 payload 형식으로 인식하고 로컬 결과 알림 제거 — 작업 목록"
---

# 작업 목록: 생성 결과 원격 알림을 서버의 실제 payload 형식으로 인식하고 로컬 결과 알림 제거

**입력**: `specs/048-generation-outcome-payload/`의 설계 문서

**선행 조건**: plan.md, spec.md, research.md, data-model.md, contracts/generation-outcome-payload.md,
contracts/notification-permission.md, quickstart.md

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를 snapshot한다. 별도
기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만 선택한다.

**테스트**: 명세의 독립 테스트와 성공 기준(SC-001, SC-003, SC-004, SC-008, SC-009)이 자동 검증을 요구하므로
테스트 작업을 포함한다. Swift Testing(`@Suite`, `@Test`)과 한국어 동작 문장 테스트 이름을 쓰고, Test Double은
initializer로 주입한다([테스트 컨벤션](../../docs/conventions/test.md)). 제거한 동작만 검증하던 테스트는 삭제한다.

**구성**: plan.md "실행 단위"의 순서(U1 Domain+Composition+App → U2 Data → U3 Infrastructure+Data 테스트 →
U4 Feature+App → U5 Data → U6 Composition 테스트 → U7 Data+Composition rename → U8 문서)를 따른다. 제거를
사용처(상위)부터 진행해야 단위마다 compile되고, payload 인식은 제거 뒤에 둬야 중간 커밋에서 중복 알림이 생기지
않는다([research R10](./research.md#r10-실행-단위와-위상-순서)).

**경로 기준**: 모든 소스 경로는 저장소 루트 기준이며 `sources/Projects/` 아래에 있다.

**검증 명령**: 저장소 루트에서 다음으로 실행기를 판독한 뒤 사용한다. `build`·`compile`·`test`는
`sources/DerivedData/PreCommit`을 공유하므로 순차 실행한다.

```sh
project_build_runner=$(./.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[S1]**: 시나리오 1 — 생성 불가 알림으로 진행 중 상태 해제(P1)
- **[S2]**: 시나리오 2 — 생성 완료 알림으로 결과 반영(P1)
- **[S3]**: 시나리오 3 — 모든 수신 경로에서 같은 해석(P2)
- **[S4]**: 시나리오 4 — 서버 알림 계약 기록 정정(P3)
- **[S5]**: 시나리오 5 — 같은 결과에 알림은 한 번만(P2)
- **[S6]**: 시나리오 6 — "홈에서 기다리기"는 서버 알림 권한을 요청(P2)
- **[S7]**: 시나리오 7 — 로컬 결과 알림 코드와 알림 권한 계약 정리(P3)
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동 검증.
  `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용한다. 대신 실행 전후
  `git status --porcelain`을 비교하고, 추적 파일 변경이 생기면 완료로 처리하지 않는다.

## 실행 단위 소유권 규칙

- 패키지 소스·테스트는 그 패키지를 포함한 실행 단위가 소유한다. 새 target·manifest 변경은 없다.
- 제거 대상과 유지 대상은 [research R5](./research.md#r5-로컬-결과-알림-제거-범위fr-010-fr-011)를 따른다.
  유지 대상(원격 수신, 결과 반영, 보존 결과, 도착 알림, 만료 타이머, 권한 조회·요청)의 동작은 바꾸지 않는다.
- 공개 이름 변경은 U7에서만 한다. U1~U6에서 남는 선언의 이름은 바꾸지 않는다([네이밍 컨벤션 §8](../../docs/conventions/naming.md)).
- Feature 시트 타입 `GenerationReminderSheet`와 문구 키 `ProjectRegistration.GenerationReminderSheet.*`는 유지한다
  ([research R7](./research.md#r7-홈에서-기다리기-흐름fr-012-fr-013)).
- 각 단위 시작 시 해당 단위의 식별자를 `sources/Projects`에서 다시 검색한다. 이 문서 작성 시점(2026-09-30)의
  목록과 다른 파일이 나오면 누락 파일을 단위에 추가하기 전에 중단하고 보고한다.
- `docs/spec-kit/048-generation-outcome-payload/trouble-shooting.md`와 `tacit-knowledge.md`는 작업으로 만들지 않는다.

---

## 실행 단위 U1: 생성 결과 로컬 알림 예약 제거 (integration: Domain + Composition + App)

**목표**: 생성 요청 시 결과 대기 등록, 결과 반영 시 로컬 알림 예약·취소, 알림 유효 시간, 결과 알림 문구 조립을
제거한다(FR-010).

**분리 불가 근거**:
- Domain의 `GenerationReminderScheduler` 계약, `ProjectGeneration.init(reminderScheduler:)`,
  `PendingGenerationRepository.enqueueReminder`·`drainReminderProjectIDs`를 지우면 Composition의 Adapter와
  Assembly가 compile되지 않는다.
- `AppComposition.Environment`의 문구 인자를 지우면 App의 `GitItApp`이 compile되지 않는다.

**관련 변경 시나리오**: [S5], [S7]

**독립 검증**: `make tuist` 후 `"$project_build_runner" compile`. 결과 반영·보존·중복·만료·도착 알림·현재
상태 조회 테스트는 이름과 기대값을 유지한 채 통과해야 한다(SC-004).

### Domain

- [X] T001 [S5] `sources/Projects/Domain/ProjectGeneration/Contracts/GenerationReminderScheduler.swift`와 `sources/Projects/Domain/ProjectGeneration/Models/Records/GenerationReminder.swift`를 삭제한다
- [X] T002 [S5] `sources/Projects/Domain/ProjectGeneration/Contracts/PendingGenerationRepository.swift`에서 `enqueueReminder(projectID:)`와 `drainReminderProjectIDs()` 요구사항을 제거한다
- [X] T003 [S5] `sources/Projects/Domain/ProjectGeneration/Models/GenerationWaitPolicy.swift`에서 `reminderValidity` 초기화 인자·프로퍼티, `isReminderValid(_:now:)`를 제거하고 `standard`를 `retentionLimit: 3600`만으로 만든다. `expiryDate(for:)`와 `isExpired(_:now:)`는 유지한다
- [X] T004 [S5] `sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`에서 다음을 제거한다. 결과 반영(`finish`), 보존 결과(`preservedOutcomes`), 도착 알림, 만료 타이머, `synchronize`·`release`의 기록 처리는 유지한다
  - `reminderScheduler` 초기화 인자와 프로퍼티
  - `request`의 `enqueueReminder` 호출
  - `reminderProjectIDs`
  - `absorbPendingReminders`와 그 호출
  - `scheduleReminderIfRegistered`
  - `apply`의 사라진 기록 예약 취소 반복과 종료 기록 예약 반복
  - `release`의 `startTask`가 없을 때 `reminderScheduler.cancel` 분기(기록 해제 뒤 반환)
  - `releaseAll`의 `reminderProjectIDs.removeAll()`
- [X] T005 [S5] `sources/Projects/Domain/Tests/ProjectGeneration/TestDoubles/SpyGenerationReminderScheduler.swift`를 삭제한다. `sources/Projects/Domain/Tests/ProjectGeneration/TestDoubles/InMemoryPendingGenerationRepository.swift`에서는 `enqueueReminder`·`drainReminderProjectIDs` 구현과 대기열 저장 프로퍼티를 제거한다
- [X] T006 [S5] `sources/Projects/Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift`를 정리한다
  - 삭제할 테스트(예약·취소 전용): `생성이 완료되면 즉시 완료 알림을 예약한다`, `알림 권한이 없으면 생성 결과 알림을 예약하지 않는다`, `결과 도착 후 5분 안이고 권한이 있으면 알림을 한 번 예약한다`, `결과 도착 후 5분이 지나면 권한이 있어도 알림을 예약하지 않는다`, `권한이 없어 버린 리마인드 대상은 나중에 권한이 생겨도 예약하지 않는다`, `로그아웃하면 모든 기록의 프로젝트 알림 예약을 취소한다`, `보관 기한이 지나 상태에서 사라진 기록의 프로젝트 알림 예약을 취소한다`, `앱 밖에서 저장소 기록이 사라지면 다음 상태 적용 때 그 프로젝트 알림 예약을 취소한다`, `이미 반영된 알림 센터 결과로는 로컬 알림을 다시 예약하지 않는다`
  - 이름과 본문을 고칠 테스트(기록 동작만 남긴다):
    - `요청만 호출하면 결과 관찰을 시작하지 않고 알림 대상을 대기열에 남긴다` → `요청만 호출하면 결과 관찰을 시작하지 않는다`
    - `생성이 실패하면 즉시 failed를 방출하고 실패 알림을 보낸다` → `생성이 실패하면 즉시 failed를 방출한다`
    - `같은 결과가 두 번 도착해도 기록 전이와 알림 예약은 한 번이다` → `같은 결과가 두 번 도착해도 기록 전이는 한 번이다`
    - `동기화하면 보관 기한이 지난 기록을 정리하고 알림 예약을 취소한다` → `동기화하면 보관 기한이 지난 기록을 정리한다`
    - `프로젝트를 해제하면 기록과 리마인드 대상을 지우고 알림 예약을 취소한다` → `프로젝트를 해제하면 기록을 지운다`
  - `Fixture`의 `scheduler` 프로퍼티와 `ProjectGeneration` 생성 시 `reminderScheduler:` 인자를 제거한다
- [X] T007 [S5] `sources/Projects/Domain/Tests/ProjectGeneration/Models/GenerationWaitPolicyTests.swift`에서 다음 세 테스트를 삭제하고, 남은 두 보관 기한 테스트는 유지한다
  - `결과 도착 후 300초까지는 알림이 유효하다`
  - `결과 도착 후 300초가 지나면 알림이 유효하지 않다`
  - `결과가 도착하지 않은 기록의 알림은 유효하지 않다`

### Composition

- [X] T008 [S5] `sources/Projects/Composition/LearningProject/Adapters/GenerationReminderSchedulerAdapter.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/GenerationReminderSchedulerAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/TestDoubles/SpyLocalReminderNotifier.swift`를 삭제한다
- [X] T009 [S5] `sources/Projects/Composition/LearningProject/Adapters/PendingGenerationRepositoryAdapter.swift`에서 `enqueueReminder(projectID:)`와 `drainReminderProjectIDs()` 구현을 제거한다
- [X] T010 [S5] `sources/Projects/Composition/LearningProject/Assemblies/LearningProjectAssembly.swift`를 정리한다
  - 제거: `reminderContent` 인자, `reminderNotifier` 인자와 `notifier` 지역 값, `ProjectGeneration`의 `reminderScheduler:` 인자, 중첩 타입 `GenerationReminderContent`
  - 유지: `DeliveredRemoteMessageReader` 사용과 `import DataNotification`
- [X] T011 [S5] `sources/Projects/Composition/App/Assemblies/ConcernUseCaseAssembly.swift`를 정리한다
  - 제거: `generationReminder` 인자, `LearningProjectAssembly`에 넘기던 결과 알림 인자, 중첩 타입 `GenerationReminderContent`
  - 유지: `reminderNotifier` 인자와 `NotificationAuthorizationAdapter(reminderNotifier:)` 연결(`AppSetting` 권한용)
- [X] T012 [S5] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`에서 `Environment`의 `generationReminderTitle`, `generationReminderBody`, `generationFailureReminderTitle`, `generationFailureReminderBody`와 그 전달을 제거한다
- [X] T013 [S5] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`의 `live(...)`에서 `reminderNotifier` 인자와 그 전달을 제거한다. 다른 사용처가 없으면 `import DataNotification`도 제거한다
- [X] T014 [P] [S5] `sources/Projects/Composition/Tests/LearningProject/Adapters/PendingGenerationRepositoryAdapterTests.swift`를 정리한다
  - 삭제: `같은 저장소를 공유하면 한쪽이 남긴 알림 대기를 다른 쪽이 흡수한다`
  - 수정: 헬퍼의 `GenerationWaitPolicy` 생성에서 `reminderValidity:` 인자를 제거한다
- [X] T015 [P] [S5] `sources/Projects/Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift`를 정리하고 `sources/Projects/Composition/Tests/ShareExtension/TestDoubles/SpyLocalReminderNotifier.swift`를 삭제한다
  - `reminderNotifier` 인자와 fixture 프로퍼티를 제거한다
  - `생성 요청이 실패하면 진행 중 기록과 알림 대기열을 남기지 않는다`는 `생성 요청이 실패하면 진행 중 기록을 남기지 않는다`로 바꾸고 대기열 검증 줄을 뺀다
- [X] T016 [P] [S5] 다음 세 파일의 `AppComposition.Environment` 생성에서 결과 알림 문구 인자 4개를 제거한다
  - `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionTests.swift`
  - `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`
  - `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionSharedLifetimeTests.swift`

### App

- [X] T017 [S5] `sources/Projects/App/GitIt/GitItApp.swift`에서 `LocalizedText.GenerationReminder.*`를 넘기던 `Environment` 인자 4개를 제거한다
- [X] T018 [S5] `sources/Projects/App/GitIt/Localization/LocalizedText.swift`, `sources/Projects/App/GitIt/Localization/Localizable.xcstrings`, `sources/Projects/App/Tests/GitIt/Localization/LocalizedTextTests.swift`를 삭제한다. 이 카탈로그의 키 4개(`GenerationReminder.Completed.*`, `GenerationReminder.Failed.*`)가 모두 제거 대상이다

### 정리와 단위 검증

- [X] T019 [no-write] `make tuist`를 실행한 뒤 `"$project_build_runner" compile`로 모든 테스트 scheme의 build-for-testing이 통과하는지 확인한다. 실행 전후 `git status --porcelain`을 비교한다
- [X] T020 [no-write] [S7] 다음 검색이 `sources/Projects/Domain`, `sources/Projects/Composition`, `sources/Projects/App`에서 0건인지 확인한다: `GenerationReminderScheduler|GenerationReminderContent|enqueueReminder|reminderValidity|isReminderValid|reminderScheduler|LocalizedText\.GenerationReminder`. Data의 `drainReminderProjectIDs`·`appendReminder`는 U2 대상이라 이 검색에서 제외한다

---

## 실행 단위 U2: 결과 대기 대기열 저장과 로컬 알림 예약 능력 제거 (단일 패키지: Data)

**목표**: 공유 저장소의 결과 대기 대기열과 Data 계약의 예약·취소·허용 여부 조회를 제거한다(FR-010, FR-014).

**관련 변경 시나리오**: [S5], [S7]

**독립 검증**: `"$project_build_runner" compile`. 권한 요청 결과·현재 설정 변환 테스트(SC-009)는 그대로 통과해야 한다.

### 구현

- [X] T021 [S5] `sources/Projects/Data/LearningProject/Stores/LocalPendingGenerationStore.swift`에서 다음을 제거한다. `namespace`, `stateKey`, 상태 조회·확인 조회·구독·`modifyState`는 유지한다(R6)
  - `pendingGenerationRemindersKey`, `pendingReminderLimit`
  - `appendReminder(projectID:requestedAt:)`, `drainReminderProjectIDs()`
  - 비공개 `ReminderEntry`, `loadReminderEntries()`
- [X] T022 [S5] `sources/Projects/Data/Notification/Contracts/LocalReminderNotifier.swift`에서 `isAuthorized()`, `schedule(_:at:)`, `cancel(identifier:)` 요구사항을 제거한다. `requestAuthorization()`과 `authorizationSetting()`만 남긴다
- [X] T023 [S5] `sources/Projects/Data/Notification/Clients/ReminderNotificationClient.swift`에서 T022로 사라진 세 메서드의 구현을 제거한다
- [X] T024 [S5] `sources/Projects/Data/Notification/Models/ReminderNotification.swift`를 삭제한다

### 테스트

- [X] T025 [P] [S5] `sources/Projects/Data/Tests/LearningProject/Stores/LocalPendingGenerationStoreTests.swift`를 정리한다
  - 삭제: `같은 프로젝트의 알림 대기는 한 번만 기록하고 흡수하면 비워진다`, `알림 대기가 상한을 넘으면 오래된 항목부터 버린다`, `알림 대기 저장값이 손상되면 빈 목록으로 취급하고 기록을 이어간다`
  - 수정: `저장소를 사용할 수 없으면 기록해도 빈 상태와 빈 알림 대기를 돌려준다`를 `저장소를 사용할 수 없으면 기록해도 빈 상태를 돌려준다`로 바꾸고 대기열 검증을 뺀다
- [X] T026 [P] [S5] `sources/Projects/Data/Tests/LearningProject/Layouts/GenerationReminderStorageCoordinateTests.swift`를 정리한다
  - 삭제: `대기 리마인드 보관 한도는 32개로 유지된다`
  - 수정: 첫 테스트를 `생성 대기 상태는 기존 App Group 네임스페이스와 키를 그대로 쓴다`로 바꾸고 `namespace`·`stateKey`만 검증한다
- [X] T027 [P] [S5] `sources/Projects/Data/Tests/Notification/Clients/ReminderNotificationClientTests.swift`에서 다음 세 테스트를 삭제한다. `권한 요청 결과를 알림 권한 상태로 변환한다`와 `권한을 요청하지 않고 현재 알림 권한 설정을 변환한다`는 유지한다
  - `권한 허용 여부를 그대로 전달한다`
  - `예약 요청의 식별자와 제목, 본문, 시각을 전달한다`
  - `취소 요청을 식별자와 함께 위임한다`

### 정리와 단위 검증

- [X] T028 [no-write] `make tuist`를 실행한 뒤 `"$project_build_runner" compile`이 통과하는지 확인한다. 실행 전후 `git status --porcelain`을 비교한다
- [X] T029 [no-write] [S7] `sources/Projects`에서 `pendingGenerationReminders|pendingReminderLimit|appendReminder|drainReminderProjectIDs|ReminderEntry|ReminderNotification\b` 검색이 0건인지 확인한다

---

## 실행 단위 U3: 로컬 알림 예약·표시·취소 기술 API 제거 (integration: Infrastructure + Data 테스트 더블)

**목표**: Infrastructure 로컬 알림 클라이언트에서 쓰이지 않게 된 기술 API를 제거하고 권한 두 기능만 남긴다(FR-010, FR-011).

**분리 불가 근거**: Data 테스트 더블 `SpyNotificationAuthorizationClient`는 Infrastructure `NotificationAuthorizationClient`
프로토콜을 준수하고 `LocalNotificationRequest`를 참조한다. 프로토콜 요구사항과 모델을 지우면 같은 커밋에서 따라가야
compile된다.

**관련 변경 시나리오**: [S7]

**독립 검증**: `make tuist` 후 `"$project_build_runner" compile`

- [X] T030 [S7] `sources/Projects/Infrastructure/LocalNotification/Clients/NotificationAuthorizationClient.swift`에서 `isAuthorized()`, `present(_:)`, `schedule(_:at:)`, `cancel(identifier:)` 요구사항을 제거한다. `requestAuthorization()`과 `authorizationSetting()`은 유지한다
- [X] T031 [S7] `sources/Projects/Infrastructure/LocalNotification/Clients/LocalNotificationAuthorizationClient.swift`에서 T030으로 사라진 메서드 구현과 비공개 `add(_:trigger:)`를 제거한다
- [X] T032 [S7] `sources/Projects/Infrastructure/LocalNotification/Models/LocalNotificationRequest.swift`를 삭제한다
- [X] T033 [S7] `sources/Projects/Data/Tests/Notification/TestDoubles/SpyNotificationAuthorizationClient.swift`에서 예약·표시·취소 기록 프로퍼티와 `isAuthorized` 구현을 제거한다
- [X] T034 [no-write] `make tuist`를 실행한 뒤 `"$project_build_runner" compile`이 통과하는지 확인한다. 실행 전후 `git status --porcelain`을 비교한다. 이어서 `sources/Projects`에서 `LocalNotificationRequest|isAuthorized\(\)` 검색이 0건인지 확인한다

---

## 실행 단위 U4: 홈에서 기다리기 선택값 전달 제거 (integration: Feature + App)

**목표**: "홈에서 기다리기"의 권한 확인·시트·권한 요청·설정 열기 흐름은 그대로 두고, 앱 루트에서 버려지던 선택값
delegate만 제거한다(FR-012, FR-013).

**분리 불가 근거**: `ProjectRegistrationRouterFeature.Action.Delegate.generationReminderPreferenceSelected`를 지우면
`AppRootFeature`의 delegate `switch`가 compile되지 않는다.

**관련 변경 시나리오**: [S6]

**독립 검증**: `"$project_build_runner" compile`. 권한 4상태 테스트가 SC-008을 검증한다.

### 테스트

- [ ] T035 [S6] `sources/Projects/Feature/Tests/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeatureTests.swift`를 고친다
  - 이름을 바꾸고 `generationReminderPreferenceSelected` 수신 단언을 뺀다. 권한 요청 횟수·설정 열기 횟수·`projectRegistered` 수신은 그대로 검증한다
    - `알림 수락은 권한을 요청하고 리마인드 사용을 알린 뒤 등록을 알린다` → `알림 수락은 권한을 요청한 뒤 등록을 알린다`
    - `알림 거절은 리마인드 미사용을 알리고 등록을 알린다` → `알림 거절은 권한 요청 없이 등록을 알린다`
    - `ready 단계를 받으면 리마인드 선택 없이 등록을 알린다` → `ready 단계를 받으면 등록을 알린다`
  - `알림 권한이 이미 허용되어 있으면 시트 없이 바로 등록을 알린다`, `알림 권한이 없으면 리마인드 시트를 연다`, `권한 요청이 거부되면 설정 화면을 정확히 한 번 안내한다`는 이름을 유지하고 선택값 단언만 뺀다
- [ ] T036 [S6] `sources/Projects/Feature/Tests/ProjectRegistration/Router/ProjectRegistrationRouterFeatureTests.swift`에서 `generationReminderPreferenceSelected` delegate 수신 단언을 제거한다

### 구현

- [ ] T037 [S6] `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeature.swift`를 정리한다
  - 제거: `Action.Delegate.generationReminderPreferenceSelected(isEnabled:)`, `finishWaiting(receipt:isReminderEnabled:)`의 `isReminderEnabled` 인자와 그 전달
  - 유지: `waitAtHomeTapped`, `waitAtHomeAuthorizationChecked`, `generationReminderAccepted`·`generationReminderDeclined`, 시트 상태, `acceptGenerationReminder`의 권한 요청과 설정 열기
- [ ] T038 [S6] `sources/Projects/Feature/ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift`에서 `Action.Delegate.generationReminderPreferenceSelected`와 하위 delegate를 상위로 전달하던 분기를 제거한다
- [ ] T039 [S6] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`에서 `case .generationReminderPreferenceSelected: return .none` 분기를 제거한다

### 정리와 단위 검증

- [ ] T040 [no-write] `"$project_build_runner" compile`이 통과하는지 확인하고, `sources/Projects`에서 `generationReminderPreferenceSelected|isReminderEnabled` 검색이 0건인지 확인한다

---

## 실행 단위 U5: 생성 결과 원격 알림을 서버 type 값으로 인식 (단일 패키지: Data)

**목표**: 서버의 `type: QUIZ_READY`·`QUIZ_REJECTED`를 완료·실패 결과로 인식하고, 기존 `status` 형식을 호환한다(FR-001~FR-005).

**관련 변경 시나리오**: [S1], [S2], [S3]

**독립 검증**: `"$project_build_runner" compile`. [판정표](./contracts/generation-outcome-payload.md#판정표) 12건을 테스트로 검증한다.

### 테스트

- [ ] T041 [S1] [S2] `sources/Projects/Data/Tests/LearningProject/DTOs/QuizGenerationOutcomeDTOTests.swift`에 판정표 1~3번 테스트를 추가한다. 관찰 원문 payload는 `aps`, `gcm.message_id`, `google.c.sender.id`, `google.c.fid`, `google.c.a.e` 키를 포함한 사전으로 쓴다
  - `서버 QUIZ_READY 알림 원문을 완료 결과로 인식한다`
  - `서버 QUIZ_REJECTED 알림 원문을 실패 결과로 인식한다`(원문 2건을 인자로 받는 parameterized 테스트)
- [ ] T042 [S3] 같은 파일에 판정표 6~9·11번 테스트를 추가한다. 기존 `status` 테스트(4·5·10·12번에 해당)는 유지한다
  - `type과 status가 함께 있으면 type을 따른다`
  - `알 수 없는 type이면 status로 판정한다`
  - `type 값은 대소문자와 표기가 정확히 같아야 인식한다`(`quiz_ready`, `QUIZ_FAILED` 인자)
  - `projectId가 빈 문자열이면 인식하지 않는다`
- [ ] T043 [S3] `sources/Projects/Data/Tests/LearningProject/Sources/PushQuizGenerationOutcomeSourceTests.swift`에 `서버 type 형식 payload를 수신하면 결과로 전달한다`를 추가한다. 관찰 원문 `QUIZ_REJECTED` payload를 `ingest`하고 구독 스트림이 실패 결과를 받는지 확인한다

### 구현

- [ ] T044 [S1] [S2] [S3] `sources/Projects/Data/LearningProject/DTOs/QuizGenerationOutcomeDTO.swift`의 `init?(rawPayload:deliveredAt:)`를 [계약의 판정 순서](./contracts/generation-outcome-payload.md#판정-순서)대로 바꾼다
  - `type` 값과 `RawStatus`의 대응은 파일 안의 비공개 선언으로 둔다
  - `RawStatus` 이름·케이스와 공개 초기화 형태는 유지한다(R4)

### 정리와 단위 검증

- [ ] T045 [no-write] `"$project_build_runner" compile`이 통과하는지 확인한다

---

## 실행 단위 U6: 알림 센터 경로의 서버 type payload 반영 검증 (단일 패키지: Composition, 테스트만)

**목표**: 알림 센터 읽기 경로도 같은 판정으로 결과를 만든다는 것을 검증한다(FR-003).

**관련 변경 시나리오**: [S3]

**독립 검증**: `"$project_build_runner" compile`

- [ ] T046 [S3] `sources/Projects/Composition/Tests/LearningProject/Adapters/GenerationOutcomeRepositoryAdapterTests.swift`에 `알림 센터 메시지의 서버 type 결과를 전달 시각과 함께 반환한다`를 추가한다. 관찰 원문 `QUIZ_READY`·`QUIZ_REJECTED` payload와 결과가 아닌 메시지를 섞고, 완료·실패 결과 두 건만 전달 시각과 함께 반환되는지 확인한다
- [ ] T047 [no-write] `"$project_build_runner" compile`이 통과하는지 확인한다

---

## 실행 단위 U7: 알림 권한 계약 이름을 권한 책임으로 변경 (integration: Data + Composition, rename 전용)

**목표**: 권한 조회·요청만 남은 Data 계약과 참조를 권한 책임 이름으로 바꾼다. 동작은 바꾸지 않는다(FR-015).

**분리 불가 근거**: Data 공개 계약·모델·생성 진입점 이름을 바꾸면 Composition의 `NotificationAuthorizationAdapter`와
`ConcernUseCaseAssembly`가 같은 커밋에서 따라가야 compile된다.

**관련 변경 시나리오**: [S7]

**독립 검증**: `make tuist` 후 `"$project_build_runner" compile`. `git diff -M --stat`에서 파일 이동이 rename으로 인식되고,
본문 변경이 식별자 치환뿐이어야 한다.

- [ ] T048 [S7] Data 소스 파일을 `git mv`로 옮기고 타입 이름을 바꾼다([research R8](./research.md#r8-알림-권한-계약-이름fr-015))
  - `sources/Projects/Data/Notification/Contracts/LocalReminderNotifier.swift` → `sources/Projects/Data/Notification/Contracts/NotificationPermissionRequester.swift` (`LocalReminderNotifier` → `NotificationPermissionRequester`)
  - `sources/Projects/Data/Notification/Clients/ReminderNotificationClient.swift` → `sources/Projects/Data/Notification/Clients/NotificationPermissionClient.swift` (`ReminderNotificationClient` → `NotificationPermissionClient`)
  - `sources/Projects/Data/Notification/Models/ReminderAuthorizationSetting.swift` → `sources/Projects/Data/Notification/Models/NotificationPermissionSetting.swift` (`ReminderAuthorizationSetting` → `NotificationPermissionSetting`)
  - `sources/Projects/Data/Notification/Models/ReminderAuthorizationStatus.swift` → `sources/Projects/Data/Notification/Models/NotificationPermissionRequestResult.swift` (`ReminderAuthorizationStatus` → `NotificationPermissionRequestResult`)
- [ ] T049 [S7] `sources/Projects/Data/Notification/Factories/NotificationFactory.swift`의 `localReminderNotifier()`를 `notificationPermissionRequester()`로 바꾸고, 반환 타입을 `any NotificationPermissionRequester`로 한다
- [ ] T050 [S7] Data 테스트 파일을 `git mv`로 옮기고 suite·타입 참조를 바꾼다
  - `sources/Projects/Data/Tests/Notification/Clients/ReminderNotificationClientTests.swift` → `sources/Projects/Data/Tests/Notification/Clients/NotificationPermissionClientTests.swift`
  - `sources/Projects/Data/Tests/LearningProject/Layouts/GenerationReminderStorageCoordinateTests.swift` → `sources/Projects/Data/Tests/LearningProject/Layouts/PendingGenerationStorageCoordinateTests.swift`
- [ ] T051 [S7] `sources/Projects/Composition/LearningProject/Adapters/NotificationAuthorizationAdapter.swift`의 초기화 인자·저장 프로퍼티를 `permissionRequester: any NotificationPermissionRequester`로 바꾸고, 새 Data 모델 이름을 반영한다
- [ ] T052 [S7] `sources/Projects/Composition/App/Assemblies/ConcernUseCaseAssembly.swift`의 `reminderNotifier` 인자를 `notificationPermissionRequester`로 바꾸고, `NotificationFactory.notificationPermissionRequester()`와 `NotificationAuthorizationAdapter(permissionRequester:)`로 연결한다
- [ ] T053 [no-write] `make tuist`를 실행한 뒤 `"$project_build_runner" compile`이 통과하는지 확인한다. 실행 전후 `git status --porcelain`을 비교한다. 이어서 `sources/Projects`에서 `LocalReminderNotifier|ReminderNotificationClient|ReminderAuthorization(Setting|Status)|localReminderNotifier|reminderNotifier` 검색이 0건인지 확인한다

---

## 실행 단위 U8: 046 서버 payload 가정 정정 (문서, 책임: 048 기능)

**목표**: 046 명세의 서버 payload 가정과 실기기 검증 기록을 2026-09-29 관찰로 정정한다(FR-008).

**관련 변경 시나리오**: [S4]

**독립 검증**: 문서 검토. SC-006을 확인한다.

- [ ] T054 [S4] `specs/046-project-list-refresh/spec.md`를 고친다. 서버 payload를 `status: completed/failed`로 단정한 가정 문장(가정 섹션의 "서버의 생성 결과 원격 알림은 … `status`(`completed`/`failed`)를 payload에 담는다")에 "2026-09-29 실기기 관찰로 정정: 서버는 `type`(`QUIZ_READY`·`QUIZ_REJECTED`)을 보낸다. [048 명세](../048-generation-outcome-payload/spec.md) 참조" 표시를 붙인다. 다른 문장은 바꾸지 않는다
- [ ] T055 [S4] `specs/046-project-list-refresh/device-verification.md`의 "서버 payload" 표를 채운다
  - `projectId`·`status` 키와 값 형식 행: "`status` 없음. `type: QUIZ_READY`(완료)·`QUIZ_REJECTED`(생성 불가)와 최상위 `projectId`, 2026-09-29 iPhone 12 mini 관찰 3건"
  - `content-available` 포함 여부 행: "(이번 관찰에서 확인 못 함)"
  - 등록 응답 `projectId` 일치 행: 관찰 대기로 둔다

---

## 전체 완료 검증 (마지막 적용 단위 뒤, `[no-write]`)

- [ ] T056 [no-write] `"$project_build_runner" build`, `"$project_build_runner" compile`, `"$project_build_runner" test`를 순서대로 실행하고 결과를 기록한다(SC-001, SC-003, SC-004, SC-008, SC-009)
- [ ] T057 [no-write] [S7] [quickstart.md](./quickstart.md) "2. 잔여 참조 검색"을 실행해 0건인지 확인한다(SC-010, SC-007)
- [ ] T058 [no-write] [S1] [S2] [S5] [S6] 실기기에서 [quickstart.md](./quickstart.md) "3. 실기기 검증" 1~6을 확인한다(SC-002, SC-005). 실기기를 쓸 수 없으면 미검증으로 기록하고 PR 미검증 범위에 적는다
- [ ] T059 [no-write] 실행 전후 `git status --porcelain`을 비교해 검증 작업이 추적 파일을 바꾸지 않았는지 확인한다

---

## 의존성과 실행 순서

```text
U1 (Domain+Composition+App) ─▶ U2 (Data) ─▶ U3 (Infrastructure+Data 테스트)
                                                     │
U4 (Feature+App) ◀──────────────────────────────────┘ (U1 이후 독립이지만 순서 고정)
      │
      ▼
U5 (Data payload) ─▶ U6 (Composition 테스트) ─▶ U7 (rename) ─▶ U8 (문서) ─▶ 전체 완료 검증
```

- U2는 U1이 Composition의 대기열·예약 사용처를 걷어낸 뒤에만 compile된다.
- U3은 U2가 Data의 `schedule`·`cancel`·`isAuthorized` 사용을 걷어낸 뒤에만 compile된다.
- U5는 U1~U3 뒤에 둬 중간 커밋에서 로컬 결과 알림이 예약되지 않게 한다.
- U7은 U2·U3에서 권한 계약이 축소된 뒤 rename만 수행한다.

### 시나리오 완료 순서

- **S5, S7(제거)**: U1~U3
- **S6**: U4
- **S1, S2, S3**: U5, U6
- **S7(rename)**: U7
- **S4**: U8

S1·S2(P1)의 사용자 효과는 U5에서 나타난다. U5 이전 단위는 P1 효과가 중복 알림 없이 나타나기 위한 선행 조건이다.

## 단위 내부 병렬 실행 예시

- **U1**: T014·T015·T016은 서로 다른 Composition 테스트 파일이다. T009~T013으로 운영 코드를 정리한 뒤 병렬로 진행할 수 있다.
- **U2**: T025·T026·T027은 서로 다른 Data 테스트 파일이다. T021~T024 뒤에 병렬로 진행할 수 있다.
- 단위 사이는 병렬로 실행하지 않는다.

## 위험 기반 승인 조건

- 같은 기능 범위의 다음 단위와 읽기 전용 검증은 반복 승인 없이 진행한다.
- 다음 경우에는 멈추고 사용자에게 확인한다.
  - 단위 시작 시 검색 결과가 이 문서 목록과 다르다.
  - 제거 대상이 설정 화면 권한이나 원격 수신 동작에 쓰이는 것이 발견된다.
  - `make tuist` 뒤 추적 파일 변경이 생긴다.
  - 실기기 검증에서 서버 payload가 관찰 원문과 다르다.

## 변경 시나리오 추적 전략

| 시나리오 | 요구사항 | 작업 |
|---|---|---|
| S1 | FR-002, FR-005, FR-006 | T041, T044, T058 |
| S2 | FR-001, FR-006 | T041, T044, T058 |
| S3 | FR-003, FR-004, FR-005 | T042, T043, T044, T046 |
| S4 | FR-008 | T054, T055 |
| S5 | FR-010, FR-014 | T001~T018, T021~T027 |
| S6 | FR-012, FR-013 | T035~T039 |
| S7 | FR-010, FR-011, FR-015, FR-016 | T020, T029~T034, T048~T053, T057 |

FR-009(서버 계약·폴링 변경 없음)는 어느 작업도 서버 호출이나 타이머를 추가하지 않는다는 것으로 충족한다.
FR-007(인식 실패 진단 로그)은 `PushQuizGenerationOutcomeSource.ingest`의 기존 로그를 유지하는 것으로 충족하며
([research R3](./research.md#r3-인식-실패-진단-로그fr-007)), T058 실기기 검증에서 서버 payload에 "파싱 실패"가
남지 않는 것으로 확인한다(SC-005).
FR-016(이전 명세 대체 기록)은 048 spec·research에 이미 기록했으므로 구현 작업이 없다.
