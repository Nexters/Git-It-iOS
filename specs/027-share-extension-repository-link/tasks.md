---

description: "공유 시트에서 GitHub 저장소를 등록하는 Share Extension 작업 목록"
---

# 작업 목록: 공유 시트에서 GitHub 저장소를 등록하는 Share Extension

**입력**: `/specs/027-share-extension-repository-link/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts/)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 명세 9절 검증 항목과 [quickstart.md](./quickstart.md)가 단위 검증 범위를 지정하므로
테스트 작업을 포함한다. 프로젝트 기본인 Swift Testing과 한국어 동작 문장 이름을 사용한다.

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안에서 추적한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: S1(공유 시트에서 저장소 등록 완결), S2(등록할 수 없는 상황 안내),
  S3(실패한 등록의 재시도와 중단)
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동
  검증. `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후
  Git 상태를 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다.

**작업 ID 규칙**: 기존 ID의 참조 안정성을 위해 나중에 삽입한 작업은 선행 ID에 소문자 접미어를
붙인다(예: T045a는 T045 다음, T046 앞에 실행). 실행 순서는 문서에 적힌 순서를 따른다.

## 실행 단위 순서와 근거

적용 대상은 Infrastructure → Composition → Feature → App이다. 순서 근거는
[아키텍처 문서](../../docs/architecture.md) 7.1의 의존 방향이며 Domain·Data·UI는 이 명세의
변경 대상이 아니다. 단위 1·2·3·7은 분리하면 컴파일되지 않는 다중 패키지 integration unit이고,
단위 4·5·6은 단일 패키지 단위다.

**선행 작업 트리 상태**: 이 브랜치에는 선행 방식(본 앱으로 링크를 넘기는 컨테이너)의 삭제와
그에 딸린 수정이 이미 작업 트리에 있다. 단위 7을 시작하기 전에 아래 경로의 기존 변경이 이
기능 범위에 속하는지 확인하고, 확인되지 않으면 변경을 보존한 채 중단한다.
`sources/Projects/App/GitIt/Models/SharedRepositoryLink.swift`,
`sources/Projects/App/ShareExtension.entitlements`,
`sources/Projects/App/ShareExtension/Info.plist`,
`sources/Projects/App/ShareExtension/ShareViewController.swift`,
`sources/Projects/App/ShareExtension/SharedRepositoryLinkContainer.swift`,
`sources/Projects/App/ShareExtension/SharedURLExtractor.swift`,
`sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`,
`sources/Projects/App/GitIt/GitItApp.swift`,
`sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`,
`sources/Projects/Feature/MainShell/Router/MainShellRouter.swift`,
`sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`,
`sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`

---

## 실행 단위 1: 로컬 알림 target 분리 (Infrastructure + Composition 통합)

**목표**: Extension이 Firebase 없이 알림 권한을 조회할 수 있도록 로컬 알림 API를 독립 target으로
분리한다.

**소유 경로**: `sources/Projects/Infrastructure/LocalNotification/**`,
`sources/Projects/Infrastructure/PushMessaging/Local/**`,
`sources/Projects/Composition/Adapter/Adapters/NotificationAuthorizationGatewayAdapter.swift`,
`sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`,
`sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`

**분리 불가 근거**: target 신설, 파일 이동, manifest 의존성, import 갱신이 한 단위에 함께 있어야
컴파일된다. 어느 하나만 적용하면 Composition이 빌드되지 않는다.

**관련 변경 시나리오**: S1

**독립 검증**: `InfrastructureLocalNotification`이 Firebase를 링크하지 않고 Composition이 기존
알림 동작을 유지한 채 빌드된다.

### 구현

- [ ] T001 `sources/Projects/Infrastructure/PushMessaging/Local/Clients/LocalNotificationClient.swift`를 `sources/Projects/Infrastructure/LocalNotification/Clients/LocalNotificationClient.swift`로 옮긴다
- [ ] T002 `sources/Projects/Infrastructure/PushMessaging/Local/Clients/UserNotificationCenterLocalClient.swift`를 `sources/Projects/Infrastructure/LocalNotification/Clients/UserNotificationCenterLocalClient.swift`로 옮긴다
- [ ] T003 [P] `sources/Projects/Infrastructure/PushMessaging/Local/Models/LocalNotificationAuthorizationOutcome.swift`를 `sources/Projects/Infrastructure/LocalNotification/Models/LocalNotificationAuthorizationOutcome.swift`로 옮긴다
- [ ] T004 [P] `sources/Projects/Infrastructure/PushMessaging/Local/Models/LocalNotificationRequest.swift`를 `sources/Projects/Infrastructure/LocalNotification/Models/LocalNotificationRequest.swift`로 옮긴다
- [ ] T005 `sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`에 `InfrastructureLocalNotification` target을 추가하고 기존 `InfrastructurePushMessaging`은 원격 푸시 소스만 소유하도록 조정한다
- [ ] T006 `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의 `CompositionAdapter` 의존성에 `InfrastructureLocalNotification`을 추가한다
- [ ] T007 `sources/Projects/Composition/Adapter/Adapters/NotificationAuthorizationGatewayAdapter.swift`, `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`, `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`의 import를 새 target 이름으로 갱신한다

### 단위 검증

- [ ] T008 [no-write] `make tuist` 실행 전후 Git 상태를 비교해 추적 파일 변경이 생기지 않음을 확인하고, 프로젝트 build runner의 `build`로 Infrastructure와 Composition이 빌드되는지 확인한다

**진행 점검**: T001~T008의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행 단위로
진행한다.

---

## 실행 단위 2: 공유 Keychain 접근 (Infrastructure + App 공용 파일 통합)

**목표**: 본 앱과 Extension이 같은 Keychain 항목을 읽을 수 있는 저장 조건을 만든다.

**소유 경로**: `sources/Projects/Infrastructure/Authentication/Keychain/**`,
`sources/Projects/Infrastructure/Tests/Authentication/Keychain/**`,
`sources/Projects/App/GitIt.entitlements`,
`sources/Projects/App/ShareExtension.entitlements`

**분리 불가 근거**: access group 속성과 entitlements 선언이 함께 적용되지 않으면 실행 시 항목을
읽지 못하고 기존 세션 접근이 깨진다.

**관련 변경 시나리오**: S1, S2

**독립 검증**: 저장·조회·삭제가 지정한 access group과 접근성으로 수행되고, 기존 항목 접근이
회귀하지 않는다.

### 테스트

- [ ] T009 [S2] `sources/Projects/Infrastructure/Tests/Authentication/Keychain/Stores/KeychainStoreTests.swift`에 access group과 `afterFirstUnlockThisDeviceOnly` 접근성이 저장 속성에 반영되는지 검증하는 테스트를 추가한다

### 구현

- [ ] T010 [P] [S2] `sources/Projects/Infrastructure/Authentication/Keychain/Models/KeychainAccessibility.swift`에 `afterFirstUnlockThisDeviceOnly` 값을 추가한다
- [ ] T011 [P] [S2] `sources/Projects/Infrastructure/Authentication/Keychain/Models/KeychainAccessGroup.swift`를 만들어 access group 식별자를 표현하는 값 타입을 정의한다
- [ ] T012 [S2] `sources/Projects/Infrastructure/Authentication/Keychain/Stores/KeychainStore.swift`가 access group을 주입받아 질의 속성에 반영하고 저장 시 `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`를 사용하도록 바꾼다. 이미 존재하는 항목은 갱신 경로에서 접근성 속성이 바뀌지 않으므로, 접근성 전환은 이전 절차(T032)의 재저장으로만 이루어진다는 규칙을 코드 주석과 테스트로 고정한다. access group을 주지 않은 기존 호출은 동작을 유지한다
- [ ] T013 [P] [S1] `sources/Projects/App/GitIt.entitlements`에 keychain access group과 App Group 선언을 추가한다
- [ ] T014 [P] [S1] `sources/Projects/App/ShareExtension.entitlements`를 만들어 본 앱과 같은 keychain access group과 App Group을 선언한다. 이 파일을 소비하는 Extension target은 T058에서 생기므로 이 단위 종료 시점에는 참조되지 않은 상태로 남는 것이 정상이다

### 단위 검증

- [ ] T015 [no-write] 프로젝트 build runner의 `compile`과 `test`로 Infrastructure 테스트가 통과하는지 확인한다

**진행 점검**: T009~T015의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 3: 조립 루트 분리 (Composition + App 통합)

**목표**: `CompositionAdapter`에서 원격 푸시 의존을 제거해 Extension이 공유 조립 요소를 링크할
수 있게 한다.

**소유 경로**: `sources/Projects/Composition/App/**`,
`sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`,
`sources/Projects/Composition/Adapter/Factories/PushNotificationAppDelegate.swift`,
`sources/Projects/Composition/Tests/App/**`,
`sources/Projects/Composition/Tests/Adapter/Assemblies/AppCompositionTests.swift`,
`sources/Projects/Composition/Tests/Adapter/Assemblies/AppCompositionSharedLifetimeTests.swift`,
`sources/Projects/Composition/Tests/Adapter/SharedLifetimeTests.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`,
`sources/Projects/App/GitIt/GitItApp.swift`

**분리 불가 근거**: 공개 타입의 target 이전이므로 파일 이동, manifest, scheme, import 갱신이
같은 단위에 있어야 본 앱이 컴파일된다.

**관련 변경 시나리오**: S1

**독립 검증**: `CompositionAdapter`가 `InfrastructurePushMessaging`을 의존하지 않고, 본 앱의
푸시·리마인더 동작이 회귀 없이 유지된다.

### 구현

- [ ] T016 `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`를 `sources/Projects/Composition/App/Assemblies/AppComposition.swift`로 옮긴다
- [ ] T017 `sources/Projects/Composition/Adapter/Factories/PushNotificationAppDelegate.swift`를 `sources/Projects/Composition/App/Factories/PushNotificationAppDelegate.swift`로 옮긴다
- [ ] T018 `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`에 `CompositionApp`과 `CompositionAppTests` target을 추가하고, `CompositionAdapter`에서 `InfrastructurePushMessaging` 의존성을 제거한다
- [ ] T019 `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 Composition scheme에 새 build·test target을 추가한다
- [ ] T020 `sources/Projects/Composition/Tests/Adapter/Assemblies/AppCompositionTests.swift`, `sources/Projects/Composition/Tests/Adapter/Assemblies/AppCompositionSharedLifetimeTests.swift`, `sources/Projects/Composition/Tests/Adapter/SharedLifetimeTests.swift`를 `sources/Projects/Composition/Tests/App/` 아래로 옮기고 import를 갱신한다
- [ ] T021 `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 `GitIt` target 의존성에 `CompositionApp`을 추가한다
- [ ] T022 `sources/Projects/App/GitIt/GitItApp.swift`의 import를 `CompositionApp`으로 갱신한다

### 단위 검증

- [ ] T023 [no-write] `make tuist` 실행 전후 Git 상태를 비교하고, build runner의 `build`와 `test`로 Composition·App이 회귀 없이 통과하는지 확인한다

**진행 점검**: T016~T023의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 4: 공유 저장소와 세션 판정 (Composition)

**목표**: 본 앱과 Extension이 공유하는 세션 상태 마커, 세션 이전, 리마인더 대기 목록과 세션
판정 규칙을 구현한다.

**소유 경로**: `sources/Projects/Composition/Adapter/**`,
`sources/Projects/Composition/App/Assemblies/AppComposition.swift`,
`sources/Projects/Composition/Tests/Adapter/**`

**관련 변경 시나리오**: S1, S2

**독립 검증**: 마커 유무·로그인 여부·토큰 만료 조합에서 `SessionAvailability` 판정이
[data-model.md](./data-model.md) 표와 일치하고, 이전 실패 시 기존 항목이 보존된다.

### 테스트

- [ ] T024 [P] [S2] `sources/Projects/Composition/Tests/Adapter/Resolvers/SessionAvailabilityResolverTests.swift`에 마커 없음·로그아웃·토큰 없음·토큰 만료·정상 다섯 경우의 판정 테스트를 작성한다
- [ ] T025 [P] [S1] `sources/Projects/Composition/Tests/Adapter/Migrations/SessionKeychainMigrationTests.swift`에 기존 항목 이전 후 삭제, 공유 항목이 이미 있을 때 무동작, 실패 시 기존 항목 보존을 검증하는 테스트를 작성한다
- [ ] T026 [P] [S1] `sources/Projects/Composition/Tests/Adapter/Codings/PendingGenerationReminderCodingTests.swift`에 대기 항목 추가·중복 방지·상한 초과 처리·디코딩 실패 처리 테스트를 작성한다

### 구현

- [ ] T027 [P] [S2] `sources/Projects/Composition/Adapter/Layouts/SharedSessionLayout.swift`를 만들어 App Group 식별자와 저장 키를 한곳에 정의한다
- [ ] T028 [P] [S2] `sources/Projects/Composition/Adapter/Models/SessionAvailability.swift`를 만들어 사용 가능·로그인 필요·앱 실행 필요 판정 값을 정의한다
- [ ] T029 [S2] `sources/Projects/Composition/Adapter/Codings/SharedSessionStateMarkerCoding.swift`를 만들어 App Group UserDefaults에 세션 상태 마커를 읽고 쓴다
- [ ] T030 [S1] `sources/Projects/Composition/Adapter/Codings/PendingGenerationReminderCoding.swift`를 만들어 리마인더 대기 목록을 읽고 추가하고 흡수 후 제거한다
- [ ] T031 [S2] `sources/Projects/Composition/Adapter/Resolvers/SessionAvailabilityResolver.swift`를 만들어 마커와 공유 Keychain 세션으로 판정 결과를 계산한다. 갱신 경로를 호출하지 않는다
- [ ] T032 [S1] `sources/Projects/Composition/Adapter/Migrations/SessionKeychainMigration.swift`를 만들어 access group 없는 기존 항목을 공유 항목으로 이전하고 성공 시에만 기존 항목을 삭제한다
- [ ] T033 [S1] `sources/Projects/Composition/Adapter/Codings/SessionRecordKeychainCoding.swift`가 공유 access group을 사용하도록 갱신한다
- [ ] T034 [S1] `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`가 시작 시 대기 목록을 흡수해 등록 대상에 반영하고 흡수한 항목을 제거하도록 확장한다
- [ ] T035 [S1] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`가 부팅 시 세션 이전을 수행하고 세션 상태 마커를 기록하며 조정자에 대기 목록 흡수 경로를 주입하도록 연결한다

### 단위 검증

- [ ] T036 [no-write] build runner의 `compile`과 `test`로 Composition 테스트가 통과하는지 확인한다

**진행 점검**: T024~T036의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 5: Extension 조립 루트 (Composition)

**목표**: Extension이 사용할 최소 조립 표면을 제공한다.

**소유 경로**: `sources/Projects/Composition/ShareExtension/**`,
`sources/Projects/Composition/Tests/ShareExtension/**`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: 조립 루트가 [contracts/share-extension-composition.md](./contracts/share-extension-composition.md)의
공개 표면만 노출하고 원격 푸시 target에 의존하지 않는다.

### 테스트

- [ ] T037 [S2] `sources/Projects/Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift`에 조립 루트가 세션 갱신 경로 없이 조립되고 권한 조회·리마인더 기록 경로가 계약대로 동작하는지 검증하는 테스트를 작성한다

### 구현

- [ ] T038 [S1] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`를 만들어 로컬 판정, 저장소 조회, 프로젝트 등록, 세션 판정, 알림 권한 조회, 리마인더 기록을 조립한다. 정적 접근 토큰 제공자만 주입하고 세션 갱신 사용 사례는 조립하지 않는다
- [ ] T039 `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`에 `CompositionShareExtension`과 `CompositionShareExtensionTests` target을 추가한다
- [ ] T040 `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 Composition scheme에 새 build·test target을 추가한다

### 단위 검증

- [ ] T041 [no-write] `make tuist` 실행 전후 Git 상태를 비교하고 build runner의 `compile`과 `test`로 새 target이 통과하는지 확인한다

**진행 점검**: T037~T041의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 6: Extension 화면 (Feature)

**목표**: 단일 화면 상태 전환으로 등록을 완결하는 화면과 상태 관리를 구현한다.

**소유 경로**: `sources/Projects/Feature/ShareRegistration/**`,
`sources/Projects/Feature/Tests/ShareRegistration/**`

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: [data-model.md](./data-model.md)의 상태 전이표 전체가 TestStore로 검증되고,
Domain 계약과 디자인 시스템만 참조하며, 실패 경로마다 구분되는 진단 이벤트가 발신된다.

### 테스트

- [ ] T042 [P] [S2] `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureValidationTests.swift`에 로컬 판정 실패, 마커 없음, 로그인 필요, 조회 인증 오류, 조회 성공 전이를 검증하는 테스트를 작성한다
- [ ] T043 [P] [S1] `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureSubmissionTests.swift`에 난이도 선택, 등록 성공, 요청 중 중복 실행 차단, 권한 허용 시 리마인더 기록과 미허용 시 미기록, 등록 응답이 인증 오류일 때 갱신 없이 로그인 필요로 전환, 리마인더 기록이 실패해도 성공 상태 표시가 유지되는 경우를 검증하는 테스트를 작성한다
- [ ] T044 [P] [S3] `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureFailureTests.swift`에 등록 실패 사유 표시, 재시도 대상 단계, 화면 종료 시 요청 취소를 검증하는 테스트를 작성한다
- [ ] T045 [P] [S1] `sources/Projects/Feature/Tests/ShareRegistration/TestDoubles/ShareRegistrationTestSupport.swift`에 위 테스트가 공유할 테스트 더블을 작성한다
- [ ] T045a [P] [S2] [S3] `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationDiagnosticsTests.swift`에 URL 판정 실패, 세션 판정 결과, 앱 실행 필요, 저장소 조회 실패, 등록 실패가 서로 구분되는 진단 이벤트로 발신되고 이벤트 값에 접근 토큰·원본 URL 전체·사용자 식별자가 포함되지 않는지 검증하는 테스트를 작성한다

### 구현

- [ ] T045b [P] [S2] [S3] `sources/Projects/Feature/ShareRegistration/ShareRegistrationDiagnosticEvent.swift`에 실패 경로별 진단 이벤트를 정의한다. 이벤트는 토큰·원본 URL 전체·개인정보를 값으로 갖지 않는다
- [ ] T046 [S1] `sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift`에 상태·액션·리듀서를 구현한다. 상태 집합과 전이는 data-model.md 표를 따르고, 요청 중을 제외한 모든 상태에서 닫기 동작을 허용하며, 기본 난이도는 `QuizLevel.l1`로 둔다. 상태 전이와 실패 사유를 주입받은 진단 이벤트 발신 경로로 내보낸다
- [ ] T047 [S1] `sources/Projects/Feature/ShareRegistration/ShareRegistrationScreen.swift`에 카드 형태의 단일 화면을 구현한다. 색상·타이포·컴포넌트는 `DesignSystem`과 `UIComponent`만 사용한다
- [ ] T048 [P] [S1] `sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+RepositorySection.swift`에 조회 결과와 난이도 선택 영역을 구현한다
- [ ] T049 [P] [S2] `sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+GuidanceSection.swift`에 URL 오류·로그인 필요·앱 실행 필요·실패 안내 영역을 구현한다
- [ ] T050 [P] [S1] `sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationScreenPreviews.swift`에 주요 상태의 Preview를 추가한다

### 단위 검증

- [ ] T051 [no-write] build runner의 `compile`과 `test`로 Feature 테스트가 통과하는지 확인한다

**진행 점검**: T042~T051의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 7: Extension 번들과 본 앱 반영 (App + Feature 통합)

**목표**: Share Extension 번들을 추가해 공유 시트 진입을 연결하고, 본 앱의 복귀 갱신과 선행
방식 잔여를 정리한다.

**소유 경로**: `sources/Projects/App/ShareExtension/**`,
`sources/Projects/App/GitIt/GitItApp.swift`,
`sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`,
`sources/Projects/App/Tests/GitIt/**`,
`sources/Projects/Feature/MainShell/Router/MainShellRouter.swift`,
`sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`,
`sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`

**분리 불가 근거**: Extension target 추가는 manifest, Info.plist, entitlements, 본 앱 embed 설정이
동시에 필요하고, 선행 방식 제거를 함께 반영하지 않으면 본 앱과 Feature가 컴파일되지 않는다.

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: 공유 시트에 Extension이 노출되고, 본 앱이 포그라운드 복귀 시 목록을 갱신하며,
선행 방식의 링크 전달 경로가 남아 있지 않다.

### 테스트

- [ ] T052 [P] [S2] `sources/Projects/App/Tests/GitIt/ShareExtension/SharedItemURLResolverTests.swift`에 URL 항목 우선, 텍스트 항목 보조 변환, 항목이 여러 개일 때 첫 유효 항목 선택, 변환 실패 처리를 검증하는 테스트를 작성한다
- [ ] T053 [P] [S1] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에 포그라운드 복귀 시 프로젝트 목록을 다시 조회하고 갱신 실패 시 기존 목록을 유지하는 테스트를 추가한다

### 구현

- [ ] T054 [S2] `sources/Projects/App/ShareExtension/SharedItemURLResolver.swift`에 공유 항목에서 URL을 얻는 규칙을 구현한다
- [ ] T054a [P] [S2] [S3] `sources/Projects/App/ShareExtension/ShareRegistrationDiagnosticLog.swift`에 진단 이벤트를 `os.Logger`로 기록하는 구현을 작성한다. subsystem과 category는 [contracts/share-extension-ui.md](./contracts/share-extension-ui.md)의 값을 사용하고 원격 전송 경로를 두지 않는다
- [ ] T055 [S1] `sources/Projects/App/ShareExtension/ShareViewController.swift`에 Extension 진입점을 구현한다. 조립 루트와 진단 기록 구현을 주입해 화면을 표시하고, 호스트 앱이 배경으로 비치도록 투명 배경과 카드 표시를 구성하며, 종료 시 Extension 컨텍스트를 완료한다
- [ ] T056 [P] [S1] `sources/Projects/App/ShareExtension/ShareExtensionEndpointHost.swift`에 자기 번들 Info.plist에서 API·외부 저장소 호스트를 읽는 해석기를 구현한다
- [ ] T057 [P] [S1] `sources/Projects/App/ShareExtension/Info.plist`에 web URL 1건으로 한정한 활성화 규칙과 호스트 구성 키를 정의한다
- [ ] T058 [S1] `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`에 `ShareExtension` target을 추가하고 `GitIt`이 이를 embed하도록 의존성과 entitlements를 연결한다
- [ ] T059 [S1] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 App scheme build target에 `ShareExtension`을 추가한다
- [ ] T060 [S1] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`에 포그라운드 복귀 시 프로젝트 목록을 갱신하는 처리를 추가하고 선행 방식의 공유 링크 수신 경로 잔여를 제거한다
- [ ] T061 [S1] `sources/Projects/App/GitIt/GitItApp.swift`에서 장면 활성 전환을 루트로 전달하고 선행 방식의 진입 처리를 제거한다
- [ ] T062 [P] [S1] `sources/Projects/Feature/MainShell/Router/MainShellRouter.swift`와 `sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`에서 선행 방식의 공유 링크 라우팅 잔여를 정리한다
- [ ] T063 [P] [S1] `sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`를 정리된 라우팅에 맞게 갱신한다

### 단위 검증

- [ ] T064 [no-write] `make tuist` 실행 전후 Git 상태를 비교하고 build runner의 `build`로 Extension을 포함한 모든 공유 scheme이 빌드되는지 확인한다

**진행 점검**: T052~T064의 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 이어간다.

---

## 전체 완료 검증

**선행 조건**: 실행 단위 7의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할 마지막
커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 실행 단위 7의 마지막 커밋 단위에 배정한다. 모든 검증과
필수 `after_implement` hook을 마친 뒤 그 단위를 최종 commit한다.

- [ ] T065 [no-write] build runner의 `build`, `compile`, `test`를 순서대로 실행하고 결과를 기록한다
- [ ] T066 [no-write] [S1] [S2] [S3] [quickstart.md](./quickstart.md)의 단위 검증 표가 요구하는 항목이 모두 통과했는지 확인하고, Console에서 실패 경로별 진단 로그가 구분되며 토큰·개인정보가 없는지 확인한 뒤, 실기기 수동 검증 중 수행하지 못한 항목을 미검증 범위로 기록한다
- [ ] T067 [no-write] Extension target이 `FirebaseCore`·`FirebaseMessaging`을 링크하지 않고, 세션 갱신 경로를 조립하지 않으며, 앱 실행·배지 설정 등 애플리케이션 단위 API를 호출하지 않는지 의존성과 조립 루트, Extension 소스로 확인한다

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- 단위 1 → 2 → 3 → 4 → 5 → 6 → 7 순서로 실행한다. 1·2는 Infrastructure 경계를 바꾸므로 이를
  참조하는 Composition 작업(3·4·5)보다 먼저 오고, Feature(6)는 Composition 계약이 확정된 뒤,
  App(7)은 Feature 화면이 있어야 연결할 수 있다.
- 단위 2와 단위 3은 서로 의존하지 않지만 이 문서가 2 → 3 순서를 고정한다. 근거는 단위 3이
  옮기는 `AppComposition`이 단위 4에서 공유 저장소 연결을 받기 때문에, 자격 증명 조건을 먼저
  확정하는 편이 재작업이 적다는 것이다.
- 각 단위를 완료·검증한 뒤 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 단위로
  반복 승인 없이 진행한다.
- 다음 경우에만 중단하고 명시적 승인을 요청한다: 선행 작업 트리 변경의 소유권을 확인할 수 없을
  때, App Group·access group 식별자처럼 배포 구성이 바뀌는 결정이 필요할 때, 이 문서에 없는
  범위가 필요할 때.

### 변경 시나리오 추적성

| 변경 시나리오 | 관련 작업 | 독립 수용 기준 |
|---|---|---|
| S1 등록 완결 | T013, T014, T025, T026, T030, T032~T035, T038, T043, T045~T048, T050, T053~T063 | 로그인 상태에서 공유해 등록을 완료하고 본 앱 복귀 시 목록에 반영된다 |
| S2 등록 불가 안내 | T009~T012, T024, T027~T029, T031, T037, T042, T045a, T045b, T049, T052, T054, T054a | 비저장소 URL·로그아웃·미이전 상태에서 각각 구분된 안내가 뜨고 등록이 차단되며, 각 실패 경로가 진단 로그로 구분된다 |
| S3 실패 재시도 | T037, T044, T045a, T045b, T052~T064 | 네트워크 오류 후 재시도가 가능하고, 요청 중 종료 시 자동 재실행이 없으며, 실패 사유가 진단 로그에 남는다 |

### 실행 단위 내부 실행

- 테스트는 같은 단위의 구현 전에 작성하고 예상한 이유로 실패하는지 확인한다.
- `[P]`는 현재 단위 안의 서로 다른 파일에만 사용한다. 단위 6의 T042~T045a, 단위 4의 T024~T026,
  단위 7의 T052~T053이 대표적인 병렬 구간이다.
- 파일 이동 작업(T001~T004, T016~T017, T020)은 같은 manifest 작업과 순차 실행한다.
- 서로 다른 실행 단위는 Git index를 공유하므로 병렬 실행하지 않는다.

## 구현 전략

1. tasks.md의 blob hash와 전체 diff를 기준선으로 고정하고 첫 미완료 실행 단위를 선택한다.
2. 그 단위의 미완료 작업을 논리적 커밋 단위로 설계한다.
3. 각 커밋 단위의 구현·검증·완료 표시·staging·commit을 순서대로 마치고 커밋을 확인한다.
4. 단위가 커밋되면 변경 파일과 검증 결과를 보고하고 다음 단위로 이어간다.
5. 새 권한이 필요한 경계가 나타나면 변경을 시작하기 전에 중단하고 승인을 요청한다.
6. 실행 단위 7의 마지막 단위는 전체 완료 검증과 필수 `after_implement` hook까지 마친 뒤 최종
   commit한다.

## 참고

- 최소 가치 범위는 S1이며, 그 완결에는 단위 1~7이 모두 필요하다. Extension 진입 자체가 S1의
  전제이므로 중간 단위만으로는 사용자에게 검증 가능한 가치를 만들지 못한다.
- 실기기 검증이 필요한 항목(공유 시트 노출, access group 접근, 메모리 측정)은
  [quickstart.md](./quickstart.md)의 수동 검증 절차를 따르고 수행 여부를 PR에 정확히 남긴다.
