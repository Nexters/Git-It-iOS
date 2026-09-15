# 작업 목록: Composition에 들어온 정책·저장·기동 책임을 소유 패키지로 되돌리기

**입력**: `/specs/032-composition-responsibility/`의 설계 문서

**선행 조건**: [plan.md](./plan.md)(필수), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/README.md](./contracts/README.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를 실행 기준선으로 고정한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 필요한 경우에만 만든다.

**테스트**: 명세 [spec.md](./spec.md)의 SC-007·SC-009·SC-010이 자동화 테스트 증명을 요구하므로 테스트 작업을 포함한다. 특히 저장 키 보존은 이동과 무관한 고정 문자열로 확인한다([research.md](./research.md) 8절).

**구성**: [plan.md](./plan.md)의 실행 단위 I1~I6, U1을 최상위 구조로 사용하고, 변경 시나리오는 각 단위 안에서 `[S1]`~`[S4]` 라벨로 추적한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- `[P]` — 같은 실행 단위 안에서 서로 다른 파일을 다루고 미완료 작업에 의존하지 않는 작업
- `[S1]` 저장 스키마를 Data가 소유 / `[S2]` 세션 판정·기기 등록을 Domain이 소유 / `[S3]` 리마인드 정책과 문구 / `[S4]` 기동 순서와 외부 라이브러리
- `[no-write]` — 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 검증. `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후 Git 상태를 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다

## 실행 단위 소유권 규칙

- 파일 변경 작업은 책임 패키지 단계에 배치한다.
- 위상 순서의 근거는 [아키텍처 3.1](../../docs/architecture.md)의 패키지 의존성 표다. `Infrastructure`가 가장 아래, `Data`는 그 뒤, `Domain`은 독립, `Composition`은 셋 뒤, `App`이 마지막이다.
- 이 명세의 여섯 코드 단위는 모두 다중 패키지 integration unit이다. 근거는 [plan.md](./plan.md)의 각 "I{N}을 다중 패키지 단위로 두는 근거"에 있다.
- U1(문서)은 이동 결과를 기록하므로 모든 코드 단위 뒤에 둔다.

## 저장 좌표 불변 규칙

I2가 옮기는 문자열은 한 글자도 바뀌어서는 안 된다. 값 목록은 [data-model.md](./data-model.md) 2절에 있다. 이동 작업마다 원본 파일의 문자열을 복사해 넣고, 확인 테스트는 그 문자열을 테스트 파일에 직접 적어 비교한다.

---

## 통합 단위 1 (I1): Infrastructure + Composition — 외부 라이브러리 직접 사용 제거

**분리 불가 근거**: `AppComposition`이 `FirebaseMessagingPushClient()`를 직접 부르고 `PushNotificationAppDelegate`가 `FirebaseMessagingAppDelegate` 별칭이다. Infrastructure가 대체 진입점을 공개하기 전에 호출을 지우면 조립이 컴파일되지 않고, 진입점만 만들고 호출을 남기면 외부 타입 이름이 그대로 남는다.

**소유 경로**: `sources/Projects/Infrastructure/PushMessaging/Remote/**`, `sources/Projects/Composition/App/Assemblies/AppComposition.swift`, `sources/Projects/Composition/App/Factories/PushNotificationAppDelegate.swift`, 대응 테스트

**관련 변경 시나리오**: S4

**독립 테스트**: Composition 프로덕션 코드에서 `Firebase` 문자열이 사라지고, 푸시 클라이언트가 Infrastructure 진입점으로 만들어지는지 확인한다.

**통합 검증**: `Infrastructure`와 `Composition` 테스트 scheme을 함께 실행한다.

### 준비

- [X] T001 [no-write] [S4] 적용 전 지표를 측정한다 — [quickstart.md](./quickstart.md)의 "기준선 측정" 네 명령을 실행하고 값을 이 파일의 "기준선 기록" 절에 적는다

### 구현

- [X] T002 [S4] `sources/Projects/Infrastructure/PushMessaging/Remote/Clients/PushMessagingClientFactory.swift`를 만들어 `PushMessagingClient` 구현을 돌려주는 진입점을 공개한다. 반환 타입에 외부 라이브러리 타입이 드러나지 않게 한다
- [X] T003 [S4] `sources/Projects/Infrastructure/PushMessaging/Remote/AppDelegates/PushMessagingAppDelegate.swift`를 만들어 `FirebaseMessagingAppDelegate`를 감싼 프로젝트 타입을 공개한다
- [X] T004 [S4] `sources/Projects/Composition/App/Factories/PushNotificationAppDelegate.swift`의 별칭 대상을 T003의 타입으로 바꾼다
- [X] T005 [S4] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`에서 `FirebaseMessagingPushClient()` 직접 생성을 T002의 진입점 호출로 바꾸고 `import` 목록에서 외부 라이브러리를 제거한다

### 테스트

- [X] T006 [P] [S4] **범위 보정으로 제외.** `InfrastructurePushMessaging`에는 테스트 타깃이 없어 새 테스트를 추가하려면 이 단위의 허용 경로 밖인 `sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`를 고쳐야 하고, `PushMessagingClientFactory.make()`가 `FirebaseApp.configure()`를 호출하므로 `GoogleService-Info.plist` 없이 테스트에서 실행할 수 없다. 진입점의 반환 타입은 컴파일로, 외부 타입 이름 부재는 T008로 확인한다
- [X] T007 [P] [S4] **범위 보정으로 제외.** 푸시 클라이언트는 `AppComposition`의 private `PushClientBox.activate()`에서만 만들어지고 그 호출이 Firebase 초기화를 유발하므로 `AppCompositionTests`에서 조립 경로를 실행할 수 없다. 조립 경로 유지는 T009의 `Composition` scheme 컴파일과 기존 테스트 통과로 확인한다

### 단위 검증

- [X] T008 [no-write] [S4] `grep -rn "Firebase" sources/Projects/Composition --include='*.swift' | grep -v '/Tests/'` 결과가 비어 있는지 확인한다
- [X] T009 [no-write] [S4] `Infrastructure`와 `Composition` 테스트 scheme을 실행해 I1을 검증한다

**진행 점검**: T001~T009의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 2 (I2): Infrastructure + Data + Composition — 저장 스키마와 직렬화 이동

**분리 불가 근거**: `SharedSessionLayout`이 App Group 좌표와 도메인 키를 한 타입에 담고 있어, 좌표를 Infrastructure로 키를 각 Data 모듈로 나누는 순간 이 타입을 쓰는 조립·어댑터 6곳이 같은 순간 컴파일 실패한다. `SessionRecordKeychainCoding`도 세 곳이 함께 참조한다.

**소유 경로**: `sources/Projects/Infrastructure/Storage/Stores/**`, `sources/Projects/Infrastructure/Authentication/Keychain/**`, `sources/Projects/Data/Authentication/**`, `sources/Projects/Data/LearningProject/**`, `sources/Projects/Composition/Adapter/{Codings,Layouts,Migrations}/**`, `sources/Projects/Composition/Adapter/Adapters/LoginSessionRepositoryAdapter.swift`, `sources/Projects/Composition/Adapter/Adapters/AuthenticationRepositoryAdapter.swift`, `sources/Projects/Composition/Adapter/Resolvers/SessionAvailabilityResolver.swift`, `sources/Projects/Composition/Adapter/Assemblies/{AuthenticationAssembly,LearningProjectAssembly}.swift`, `sources/Projects/Composition/App/Assemblies/AppComposition.swift`, `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`, 대응 테스트

**관련 변경 시나리오**: S1

**독립 테스트**: `Composition/Adapter/`에서 `Codings/`, `Layouts/`, `Migrations/`가 사라지고, 고정 키 문자열로 저장 좌표를 확인하는 테스트가 Data 패키지에서 통과하는지 본다.

**통합 검증**: `Infrastructure`·`Data`·`Composition` 테스트 scheme을 함께 실행하고, 이어서 전체 `build` → `compile` → `test`를 실행한다.

### 준비

- [X] T010 [no-write] [S1] [data-model.md](./data-model.md) 2절의 저장 좌표 10개를 현재 소스에서 하나씩 확인하고, 값이 표와 다르면 표를 고치지 말고 차이를 이 파일의 "이동 기록" 절에 적는다
  - **범위 보정**: [data-model.md](./data-model.md) 2절의 저장 좌표 10개는 이동 전 소스와 모두 일치했다. 표를 고칠 차이는 없었다. 다만 표에 없던 좌표 `com.nexters.hytime.gitit.generationProgress`(레거시 생성 진행 네임스페이스)가 `LearningProjectAssembly`에 남아 있어 같은 단위에서 `sources/Projects/Data/LearningProject/Stores/GenerationStateMigration.swift`로 함께 옮겼다

### 테스트

- [X] T011 [S1] `sources/Projects/Data/Tests/Authentication/Layouts/SessionStorageCoordinateTests.swift`를 만들어 세션·Apple 식별자 Keychain 네임스페이스와 키, 공유 세션 UserDefaults 네임스페이스와 마커 키를 테스트 파일에 직접 적은 고정 문자열과 비교한다
- [X] T012 [P] [S1] `sources/Projects/Data/Tests/Authentication/Codings/SessionRecordKeychainCodingTests.swift`를 만들어 이동 후 코딩이 이동 전과 같은 키·형식으로 저장하고 읽는지 확인한다
- [X] T013 [P] [S1] `sources/Projects/Data/Tests/LearningProject/Layouts/GenerationReminderStorageCoordinateTests.swift`를 만들어 대기 리마인드 키와 보관 한도를 고정 문자열·숫자와 비교한다

### 구현 — Infrastructure

- [X] T014 [S1] `sources/Projects/Infrastructure/Storage/Stores/AppGroupUserDefaults.swift`를 만들어 App Group 식별자와 공유 `UserDefaults` 생성, 그리고 공유 영역 네임스페이스 상수를 공개한다. 값은 `SharedSessionLayout`에서 그대로 옮긴다
- [X] T015 [S1] `sources/Projects/Infrastructure/Authentication/Keychain/Stores/AppGroupKeychainStore.swift`를 만들어 팀 식별자 접두어와 Keychain 접근 그룹, 공유·레거시 `KeychainStore` 생성을 공개한다. 값은 `SharedSessionLayout`에서 그대로 옮긴다

### 구현 — Data

- [X] T016 [P] [S1] `sources/Projects/Data/Authentication/Layouts/SessionKeychainLayout.swift`를 만들고 `sources/Projects/Composition/Adapter/Layouts/SessionKeychainLayout.swift`의 내용을 옮긴다. 공개 범위를 `DataAuthentication` 밖에서 필요한 만큼만 넓힌다
- [X] T017 [P] [S1] `sources/Projects/Data/Authentication/Layouts/AppleIdentityKeychainLayout.swift`를 만들고 `sources/Projects/Composition/Adapter/Layouts/AppleIdentityKeychainLayout.swift`의 내용을 옮긴다
- [X] T018 [S1] `sources/Projects/Data/Authentication/Codings/SessionRecordKeychainCoding.swift`를 만들고 `sources/Projects/Composition/Adapter/Codings/SessionRecordKeychainCoding.swift`의 내용을 옮긴다
  - **범위 보정**: `Data`는 `Domain`에 의존할 수 없으므로([아키텍처 3.1](../../docs/architecture.md)) 저장 계약은 Domain `SessionRecord`를 다룰 수 없다. `sources/Projects/Data/Authentication/Models/StoredSessionRecord.swift`를 저장 전용 레코드로 새로 두고(와이어 필드 이름은 이동 전과 동일), Domain 타입과의 변환은 `sources/Projects/Composition/Adapter/Codings/SessionRecordCoding.swift`가 맡는다. 두 경로를 이 단위에 추가한다
- [X] T019 [S1] `sources/Projects/Data/Authentication/Codings/SharedSessionStateMarkerCoding.swift`를 만들고 `sources/Projects/Composition/Adapter/Codings/SharedSessionStateMarkerCoding.swift`의 내용을 옮긴다. 마커 키와 스키마 버전은 이 파일이 소유하고 네임스페이스는 T014가 공개한 값을 쓴다
- [X] T020 [S1] `sources/Projects/Data/Authentication/Migrations/SessionKeychainMigration.swift`를 만들고 `sources/Projects/Composition/Adapter/Migrations/SessionKeychainMigration.swift`의 내용을 옮긴다
- [X] T021 [S1] `sources/Projects/Data/LearningProject/Codings/PendingGenerationReminderCoding.swift`를 만들고 `sources/Projects/Composition/Adapter/Codings/PendingGenerationReminderCoding.swift`의 내용을 옮긴다. 대기 리마인드 키와 보관 한도는 이 파일이 소유한다
- [X] T022 [S1] `sources/Projects/Data/LearningProject/Stores/LocalGenerationStateStore.swift`가 쓰는 네임스페이스를 T014의 값으로 바꾸고, `sources/Projects/Data/LearningProject/Stores/GenerationStateMigration.swift`의 레거시 네임스페이스 상수를 확인한다
- [X] T023 [S1] `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에서 `DataAuthentication`과 `DataLearningProject`가 필요한 Infrastructure 모듈에 의존하는지 확인하고 빠진 의존을 추가한다
  - **범위 보정**: `CompositionApp`과 `CompositionShareExtension`이 옮겨진 타입을 참조하게 되어 `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의 의존 목록도 함께 고쳤다. 이 경로를 이 단위에 추가한다

### 구현 — Composition

- [X] T024 [S1] `sources/Projects/Composition/Adapter/Adapters/LoginSessionRepositoryAdapter.swift`가 옮겨진 `SessionRecordKeychainCoding`·`SharedSessionStateMarkerCoding`·`AppleIdentityKeychainLayout`을 `DataAuthentication`에서 참조하도록 `import`와 타입 경로를 고친다
- [X] T025 [S1] `sources/Projects/Composition/Adapter/Adapters/AuthenticationRepositoryAdapter.swift`의 `AppleIdentityKeychainLayout` 참조를 `DataAuthentication` 것으로 고친다
- [X] T026 [S1] `sources/Projects/Composition/Adapter/Resolvers/SessionAvailabilityResolver.swift`의 코딩 참조를 `DataAuthentication` 것으로 고친다. 이 파일 자체의 이동은 I3이 맡는다
- [X] T027 [S1] `sources/Projects/Composition/Adapter/Assemblies/AuthenticationAssembly.swift`의 Keychain·UserDefaults 생성을 T014·T015의 진입점 호출로 바꾸고, 약관 동의 네임스페이스 문자열을 `DataLegalConsent`가 소유하도록 옮긴 뒤 그 값을 참조한다
- [X] T028 [S1] `sources/Projects/Data/LegalConsent/Layouts/PolicyConsentStorageLayout.swift`를 만들어 약관 동의 네임스페이스 `com.nexters.hytime.gitit.legalConsent`를 소유하게 한다
- [X] T029 [S1] `sources/Projects/Composition/Adapter/Assemblies/LearningProjectAssembly.swift`의 `SharedSessionLayout`·`UserDefaultsStore` 참조를 T014와 T021·T022의 값으로 바꾼다
- [X] T030 [S1] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`의 `SharedSessionLayout`·`SessionKeychainMigration`·`SharedSessionStateMarkerCoding` 참조를 옮겨진 위치로 바꾼다
- [X] T031 [S1] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`의 같은 참조를 옮겨진 위치로 바꾼다

### 정리

- [X] T032 [S1] `sources/Projects/Composition/Adapter/Codings/SessionRecordKeychainCoding.swift`, `sources/Projects/Composition/Adapter/Codings/SharedSessionStateMarkerCoding.swift`, `sources/Projects/Composition/Adapter/Codings/PendingGenerationReminderCoding.swift`를 제거한다
  - **범위 보정**: 세 파일은 제거했지만 `Composition/Adapter/Codings/` 폴더는 T018의 `SessionRecordCoding.swift` 때문에 남는다. 이 단위가 Composition에서 걷어내는 것은 저장 스키마(네임스페이스·키·와이어 필드)이고, 남는 것은 Domain 타입과 저장 레코드 사이의 변환이다
- [X] T033 [S1] `sources/Projects/Composition/Adapter/Layouts/SessionKeychainLayout.swift`, `sources/Projects/Composition/Adapter/Layouts/AppleIdentityKeychainLayout.swift`, `sources/Projects/Composition/Adapter/Layouts/SharedSessionLayout.swift`를 제거한다
- [X] T034 [S1] `sources/Projects/Composition/Adapter/Migrations/SessionKeychainMigration.swift`를 제거한다
- [X] T035 [S1] `sources/Projects/Composition/Tests/Adapter/Migrations/SessionKeychainMigrationTests.swift`를 `sources/Projects/Data/Tests/Authentication/Migrations/SessionKeychainMigrationTests.swift`로 옮기고, 보장 항목의 이관처를 이 파일의 "이동 기록" 절에 적는다
  - **범위 보정**: `sources/Projects/Composition/Tests/Adapter/Codings/PendingGenerationReminderCodingTests.swift`도 `sources/Projects/Data/Tests/LearningProject/Codings/`로 함께 옮겼다. 옮겨진 타입을 참조하던 Composition 테스트 4건(`AppCompositionTests`, `AppCompositionSharedLifetimeTests`, `ShareExtensionCompositionTests`, `SessionAvailabilityResolverTests`)의 import와 타입 이름도 같은 단위에서 고쳤다

### 단위 검증

- [X] T036 [no-write] [S1] `grep -rn "com.nexters.hytime.gitit" sources/Projects/Composition --include='*.swift' | grep -v '/Tests/'` 결과가 비어 있는지 확인한다
  - **범위 보정**: `Logger(subsystem: "com.nexters.hytime.gitit")` 3건은 저장 좌표가 아니라 로그 subsystem이므로 판정 대상에서 제외한다. `AppComposition`의 `com.nexters.hytime.gitit.device`는 I4가 소유한다. 저장 좌표 기준으로는 0건이다
- [X] T037 [no-write] [S1] `Infrastructure`·`Data`·`Composition` 테스트 scheme을 실행해 I2를 검증한다
- [X] T038 [no-write] [S1] 전체 `build` → `compile` → `test`를 실행하고 결과를 기록한다. 저장 좌표를 옮긴 단위이므로 여기서 전체를 한 번 확인한다
  - **범위 보정**: `test` 전체 실행 중 `Feature` scheme은 이 명세와 무관한 기존 실패(`AppEntryFeatureTests` 계열)로 약 60분이 걸리므로 T084로 미룬다. 대신 `build` 9/9 성공, `compile` 7/7 성공과 `Infrastructure`·`Data`·`Composition`·`AppTests` 테스트 실행으로 확인했다. `AppTests`의 실패 19건은 모두 `AppRootFeatureTests.swift`(사용자 작업 중 파일)의 기존 실패이며 다른 suite는 모두 통과했다

**진행 점검**: T010~T038의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 3 (I3): Domain + Composition + App — 세션 유효성 판정 이동

**분리 불가 근거**: `SessionAvailability`를 `DomainAuthentication`으로 옮기면 그 타입을 쓰는 `ShareExtensionComposition`(Composition)과 `ShareViewController`(App)가 같은 순간 컴파일 실패한다.

**소유 경로**: `sources/Projects/Domain/Authentication/**`, `sources/Projects/Composition/Adapter/{Models,Resolvers}/**`, `sources/Projects/Composition/Adapter/Adapters/**`, `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`, `sources/Projects/App/ShareExtension/ShareViewController.swift`, 대응 테스트

**관련 변경 시나리오**: S2

**독립 테스트**: 만료된 access token과 유효한 access token 각각의 판정이 Domain 테스트만으로 검증되는지 본다.

**통합 검증**: `Domain`·`Composition` 테스트 scheme과 `AppTests`를 함께 실행한다.

### 테스트

- [X] T039 [S2] `sources/Projects/Domain/Tests/Authentication/UseCases/ResolveSessionAvailability/ResolveSessionAvailabilityTests.swift`를 만들어 마커 부재·미로그인·빈 토큰·만료된 토큰·유효한 토큰 다섯 경우의 판정을 검증한다

### 구현

- [X] T040 [S2] `sources/Projects/Domain/Authentication/Models/SessionAvailability/SessionAvailability.swift`를 만들고 `sources/Projects/Composition/Adapter/Models/SessionAvailability.swift`의 내용을 옮긴다
  - **범위 보정**: `Domain/Authentication/Models/`는 이미 관심사 2뎁스(`Authentication`, `Consent`, `Session`)로 나뉘어 있어 새 `SessionAvailability/` 폴더 대신 기존 `Session/` 아래 `sources/Projects/Domain/Authentication/Models/Session/SessionAvailability.swift`에 두었다
- [X] T041 [S2] `sources/Projects/Domain/Authentication/UseCases/ResolveSessionAvailability/ResolveSessionAvailabilityUseCase.swift`에 판정 계약을 정의한다
- [X] T042 [S2] `sources/Projects/Domain/Authentication/UseCases/ResolveSessionAvailability/ResolveSessionAvailability.swift`에 판정 규칙을 구현한다. 마커 조회와 세션 조회는 Domain 계약으로 받고, 현재 시각은 주입받는다
- [X] T043 [S2] `sources/Projects/Domain/Authentication/Contracts/SharedSessionMarkerRepository.swift`에 로그인 상태 마커 조회 계약을 정의한다
  - **범위 보정**: 마커 계약만으로는 판정에 필요한 저장 세션을 읽을 수 없고, 공유 확장에는 `LoginSessionRepository`를 조립할 HTTP 경로가 없다. 저장 세션 조회 계약 `sources/Projects/Domain/Authentication/Contracts/StoredSessionRepository.swift`를 함께 두고 그 Adapter `sources/Projects/Composition/Adapter/Adapters/StoredSessionRepositoryAdapter.swift`를 추가한다
- [X] T044 [S2] `sources/Projects/Composition/Adapter/Adapters/SharedSessionMarkerRepositoryAdapter.swift`를 만들어 T043의 계약을 `DataAuthentication`의 마커 코딩에 잇는다
- [X] T045 [S2] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`가 `SessionAvailabilityResolver` 대신 T042의 UseCase를 조립하도록 바꾼다
  - **범위 보정**: `CompositionShareExtension`과 App `ShareExtension` 타깃이 `DomainAuthentication`을 직접 참조하게 되어 `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`와 `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 의존 목록도 함께 고쳤다
- [X] T046 [S2] `sources/Projects/App/ShareExtension/ShareViewController.swift`의 `SessionAvailability` 참조를 `DomainAuthentication` 것으로 바꾼다

### 정리

- [X] T047 [S2] `sources/Projects/Composition/Adapter/Resolvers/SessionAvailabilityResolver.swift`와 `sources/Projects/Composition/Adapter/Models/SessionAvailability.swift`를 제거한다
- [X] T048 [S2] `sources/Projects/Composition/Tests/Adapter/Resolvers/SessionAvailabilityResolverTests.swift`를 제거하고, 보장 항목의 이관처 또는 제거 근거를 이 파일의 "이동 기록" 절에 적는다

### 단위 검증

- [X] T049 [no-write] [S2] `Domain`·`Composition` 테스트 scheme과 `AppTests`를 실행해 I3을 검증한다
  - **범위 보정**: `Domain` 144건과 `Composition` 68건은 모두 통과했다. `AppTests`의 실패 19건은 I3 적용 전과 같은 `AppRootFeature root 전환` suite 하나이며 다른 suite는 모두 통과했다. 공유 확장 타깃 컴파일은 `App` scheme `BUILD SUCCEEDED`로 확인했다

**진행 점검**: T039~T049의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 4 (I4): Domain + Data + Composition + App — 기기 등록 UseCase 승격

**분리 불가 근거**: deviceID 계약을 Domain에 만들고 구현을 `DataMember`에 두면 둘을 잇는 Adapter와 조립이 Composition에 동시에 필요하다. 앱·OS 버전 주입 때문에 `AppComposition.init` 서명이 바뀌고 App의 호출부가 함께 바뀐다.

**소유 경로**: `sources/Projects/Domain/Member/**`, `sources/Projects/Data/Member/**`, `sources/Projects/Composition/Adapter/{Adapters,Assemblies}/**`, `sources/Projects/Composition/App/Assemblies/AppComposition.swift`, `sources/Projects/App/GitIt/GitItApp.swift`, 대응 테스트

**관련 변경 시나리오**: S2

**독립 테스트**: 주입한 앱·OS 버전이 등록 정보에 담기고, deviceID가 두 번 호출해도 같은 값인지 Domain·Data 테스트로 확인한다.

**통합 검증**: `Domain`·`Data`·`Composition` 테스트 scheme과 `AppTests`를 함께 실행한다.

### 테스트

- [X] T050 [P] [S2] `sources/Projects/Domain/Tests/Member/UseCases/RegisterCurrentDevice/RegisterCurrentDeviceTests.swift`를 만들어 주입한 앱·OS 버전과 푸시 토큰이 등록 정보에 담기는지, deviceID 조회 실패가 어떻게 전달되는지 검증한다
- [X] T051 [P] [S2] `sources/Projects/Data/Tests/Member/Stores/LocalDeviceIdentifierStoreTests.swift`를 만들어 두 번 호출해도 같은 값이 나오고 저장 키가 고정 문자열과 같은지 검증한다

### 구현

- [X] T052 [S2] `sources/Projects/Domain/Member/Contracts/DeviceIdentifierRepository.swift`에 deviceID 발급·보관 계약을 정의한다
- [X] T053 [S2] `sources/Projects/Domain/Member/UseCases/RegisterCurrentDevice/RegisterCurrentDeviceUseCase.swift`에 기기 등록 계약을 정의한다
- [X] T054 [S2] `sources/Projects/Domain/Member/UseCases/RegisterCurrentDevice/RegisterCurrentDevice.swift`에 `MemberDeviceInfo` 구성과 등록 호출을 구현한다. 앱 버전·OS 버전·푸시 토큰 제공자를 주입받는다
- [X] T055 [S2] `sources/Projects/Data/Member/Stores/LocalDeviceIdentifierStore.swift`에 Keychain 기반 deviceID 저장 구현과 저장 키를 둔다. 현재 `AppComposition.loadOrCreateDeviceID`가 쓰는 키와 같은 값을 쓴다
  - **범위 보정**: `DataMember`가 Keychain을 쓰게 되어 `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에 `InfrastructureAuthentication` 의존을 더했다
- [X] T056 [S2] `sources/Projects/Composition/Adapter/Adapters/DeviceIdentifierRepositoryAdapter.swift`를 만들어 T052의 계약을 T055의 구현에 잇는다
- [X] T057 [S2] `sources/Projects/Composition/Adapter/Assemblies/MemberAssembly.swift`에 T054의 UseCase 조립을 추가한다
  - **범위 보정**: 푸시 토큰 제공자가 `AppComposition`의 `PushClientBox`에 묶여 있어 `MemberAssembly`는 그 값을 받을 수 없다. UseCase 조립은 토큰 제공자를 아는 `sources/Projects/Composition/App/Assemblies/AppComposition.swift`에 두고, `MemberAssembly`는 그대로 둔다
- [X] T058 [S2] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`의 `registerCurrentDevice` 본문을 T054 UseCase 호출로 바꾸고, `Bundle.main`·`ProcessInfo` 조회를 제거한 뒤 앱 버전·OS 버전을 `init` 인자로 받는다
- [X] T059 [S2] `sources/Projects/App/GitIt/GitItApp.swift`가 앱 버전과 OS 버전을 읽어 `AppComposition`에 넘기도록 호출부를 고친다
  - **범위 보정**: 앱 버전과 OS 버전은 `AppComposition.Environment`로 받는다. 서명이 바뀌어 `AppCompositionTests`·`AppCompositionSharedLifetimeTests`·`AppCompositionPublicSurfaceTests` 세 파일의 `Environment` 생성도 같은 단위에서 고쳤다

### 단위 검증

- [X] T060 [no-write] [S2] `grep -rnE "Bundle\.main|ProcessInfo" sources/Projects/Composition --include='*.swift' | grep -v '/Tests/'` 결과가 비어 있는지 확인한다
- [X] T061 [no-write] [S2] `Domain`·`Data`·`Composition` 테스트 scheme과 `AppTests`를 실행해 I4를 검증한다
  - **범위 보정**: `Domain` 162건, `Data` 147건, `Composition` 68건 모두 통과했다. `AppTests`의 실패 19건은 I4 적용 전과 같은 `AppRootFeature root 전환` suite 하나다. App 타깃 컴파일은 `App` scheme `BUILD SUCCEEDED`로 확인했다

**진행 점검**: T050~T061의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 5 (I5): Domain + Composition + App — 리마인드 정책과 문구 이동

**분리 불가 근거**: `GenerationCompletionReminderCoordinator`를 Domain 정책과 Composition Adapter로 쪼개는 동시에 표시 문구가 App에서 조립 인자로 들어와야 한다. 셋 중 하나만 먼저 바꾸면 문구가 갈 곳이 없거나 정책이 알림 계약을 부를 수 없다.

**소유 경로**: `sources/Projects/Domain/LearningProject/**`, `sources/Projects/Composition/Adapter/{Adapters,Assemblies,Factories}/**`, `sources/Projects/Composition/App/Assemblies/AppComposition.swift`, `sources/Projects/App/GitIt/GitItApp.swift`, 대응 테스트

**관련 변경 시나리오**: S3

**독립 테스트**: 완료·미완료 결과와 알림 권한 유무 조합에 대해 예약 여부와 예약 시각이 Domain 테스트로 검증되고, Composition 프로덕션 코드에 표시 문자열이 없는지 확인한다.

**통합 검증**: `Domain`·`Composition` 테스트 scheme과 `AppTests`를 함께 실행한다.

### 테스트

- [ ] T062 [S3] `sources/Projects/Domain/Tests/LearningProject/UseCases/ScheduleGenerationReminder/ScheduleGenerationReminderTests.swift`를 만들어 미등록 프로젝트 무시, 완료가 아닌 결과 무시, 권한 없음 무시, 완료+권한 있음일 때 대기 정책이 계산한 시각으로 예약, 같은 프로젝트 결과 2회 수신 시 1회만 예약을 검증한다

### 구현

- [ ] T063 [S3] `sources/Projects/Domain/LearningProject/Contracts/GenerationReminderScheduler.swift`에 식별자와 예약 시각만 받는 예약 계약을 정의한다. 표시 문구는 인자에 두지 않는다
- [ ] T064 [S3] `sources/Projects/Domain/LearningProject/UseCases/ScheduleGenerationReminder/ScheduleGenerationReminderUseCase.swift`에 정책 계약을 정의한다
- [ ] T065 [S3] `sources/Projects/Domain/LearningProject/UseCases/ScheduleGenerationReminder/ScheduleGenerationReminder.swift`에 대상 집합 관리, 완료 판정, 권한 확인, 예약 시각 계산을 구현한다. 대기 중 리마인드 흡수와 생성 상태 관측 시작도 여기서 맡는다
- [ ] T066 [S3] `sources/Projects/Composition/Adapter/Adapters/GenerationReminderSchedulerAdapter.swift`를 만들어 T063의 계약을 `InfrastructureLocalNotification`에 잇는다. 알림 제목과 본문은 초기화 인자로 받는다
- [ ] T067 [S3] `sources/Projects/Composition/Adapter/Assemblies/GenerationReminderAssembly.swift`가 T065의 UseCase와 T066의 Adapter를 조립하도록 바꾸고, 표시 문구를 인자로 받는다
- [ ] T068 [S3] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`가 표시 문구를 `init` 인자로 받아 `GenerationReminderAssembly`에 전달하도록 바꾼다
- [ ] T069 [S3] `sources/Projects/App/GitIt/GenerationReminderContent.swift`를 만들어 알림 제목 `세트 생성 완료`와 본문 `학습 세트 생성이 완료됐어요. 지금 확인해보세요.`를 소유하고, `sources/Projects/App/GitIt/GitItApp.swift`가 그 값을 `AppComposition`에 넘기게 한다

### 정리

- [ ] T070 [S3] `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`를 제거한다
- [ ] T071 [S3] `sources/Projects/Composition/Tests/Adapter/Factories/GenerationCompletionReminderCoordinatorTests.swift`를 제거하고, 보장 항목의 이관처 또는 제거 근거를 이 파일의 "이동 기록" 절에 적는다

### 단위 검증

- [ ] T072 [no-write] [S3] `grep -rn '"[가-힣]' sources/Projects/Composition --include='*.swift' | grep -v '/Tests/' | grep -v logger` 결과가 비어 있는지 확인한다
- [ ] T073 [no-write] [S3] `Domain`·`Composition` 테스트 scheme과 `AppTests`를 실행해 I5를 검증한다

**진행 점검**: T062~T073의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 6 (I6): Composition + App — 기동 순서 이동

**분리 불가 근거**: `bootstrap` 클로저를 없애고 조각을 개별 프로퍼티로 공개하는 변경과, App이 그 조각을 순서대로 부르는 변경은 같은 순간에 일어나야 한다. 한쪽만 바꾸면 기동이 아무것도 하지 않거나 컴파일되지 않는다.

**소유 경로**: `sources/Projects/Composition/App/Assemblies/AppComposition.swift`, `sources/Projects/App/GitIt/**`, 대응 테스트

**관련 변경 시나리오**: S4

**독립 테스트**: `AppComposition`에 순서 의존적인 클로저가 없고, App의 기동 타입이 이동 전과 같은 순서로 같은 작업을 수행하는지 테스트로 확인한다.

**통합 검증**: `Composition` 테스트 scheme과 `AppTests`를 함께 실행하고, 이어서 전체 `build` → `compile` → `test`를 실행한다.

### 테스트

- [ ] T074 [S4] `sources/Projects/App/Tests/GitIt/Launch/AppLaunchSequenceTests.swift`를 만들어 마커 저장 → 푸시 클라이언트 활성화 → AppDelegate 구성 → 생성 상태 관측 시작 순서로 호출되는지 검증한다

### 구현

- [ ] T075 [S4] `sources/Projects/App/GitIt/Launch/AppLaunchSequence.swift`를 만들어 기동 절차를 순서대로 실행하는 타입을 둔다
- [ ] T076 [S4] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`에서 `bootstrap` 클로저를 제거하고 마커 저장·푸시 클라이언트 활성화·AppDelegate 구성·관측 시작을 순서 없는 개별 프로퍼티로 공개한다
- [ ] T077 [S4] `sources/Projects/App/GitIt/GitItApp.swift`가 `composition.bootstrap(appDelegate)` 대신 T075의 타입을 호출하도록 바꾼다
- [ ] T078 [S4] `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`의 공개 프로퍼티 기대 목록을 T076의 결과에 맞춰 갱신한다

### 단위 검증

- [ ] T079 [no-write] [S4] `grep -n "bootstrap" sources/Projects/Composition/App/Assemblies/AppComposition.swift` 결과가 비어 있는지 확인한다
- [ ] T080 [no-write] [S4] `Composition` 테스트 scheme과 `AppTests`를 실행해 I6을 검증한다

**진행 점검**: T074~T080의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 작업 단위 1 (U1): 문서 — 이동 결과와 남은 책임 기록

**목표**: Composition에 무엇이 남고 무엇이 어디로 갔는지 규칙 문서에 반영해, 다음에 같은 판단을 할 때 근거가 문서에 있게 한다.

**선행 조건**: I1~I6의 파일 변경 작업을 모두 완료했다.

**관련 변경 시나리오**: S1 S2 S3 S4

**독립 테스트**: Composition 패키지 규칙 문서만 읽고 이동 후 구조를 설명할 수 있는지 확인한다.

### 구현

- [ ] T081 [S1] [S2] [S3] [S4] `docs/package-rules/composition.md`에 이동 후 Composition에 남는 것(Adapter와 조립)과 남지 않는 것(저장 스키마·판정 규칙·표시 문구·기동 순서·외부 라이브러리 타입)을 적고, 조립 시점의 인스턴스 생성은 허용된다는 구분을 [아키텍처 3.5](../../docs/architecture.md) 근거와 함께 명시한다

### 단위 검증

- [ ] T082 [no-write] `docs/package-rules/composition.md`에서 시작해 링크만 따라가 각 책임의 새 소유 패키지에 도달할 수 있는지 확인한다

**진행 점검**: T081~T082의 변경 파일과 검증 결과를 보고한다.

---

## 전체 완료 검증

**선행 조건**: I1~I6, U1의 파일 변경 작업을 모두 완료했다.

**커밋 경계**: 아래 `[no-write]` 작업은 U1의 마지막 커밋 단위에 배정한다.

- [ ] T083 [no-write] `make tuist`로 workspace를 갱신하고 실행 전후 Git 상태를 비교해 추적 파일 변경이 없는지 확인한다
- [ ] T084 [no-write] 전체 `build` → `compile` → `test`를 실행하고 결과를 기록한다. `Feature`와 `AppTests`의 기존 실패 목록이 늘지 않았는지로 판정한다
- [ ] T085 [no-write] [S1] [S2] [S3] [S4] [quickstart.md](./quickstart.md)의 시나리오별 검증과 기준선 재측정을 모두 확인하고 값을 이 파일의 "기준선 기록" 절에 적는다
- [ ] T086 [no-write] 이 파일의 "이동 기록"이 제거된 모든 테스트 파일의 이관처 또는 제거 근거를 담고 있는지 확인한다
- [ ] T087 [no-write] [quickstart.md](./quickstart.md)의 수동 회귀 3종(로그인 유지, 공유 확장 세션 판정, 생성 완료 리마인드)을 기존 설치 상태를 지우지 않은 기기에서 확인하고 결과를 보고한다

---

## 기준선 기록

> T001, T085에서 채운다.

| 항목 | 적용 전 | 적용 후 |
| --- | --- | --- |
| Composition 프로덕션 코드 줄수 | 2,348 | (T085에서 기록) |
| Composition의 Infrastructure 저장 API 직접 사용 | 13 | (T085에서 기록) |
| Composition의 `Bundle.main`·`ProcessInfo` 조회 | 2 | (T085에서 기록) |
| Composition의 외부 라이브러리 타입 이름 | 2 | 0 (I1 완료 시점) |

---

## 이동 기록

> T010, T035, T048, T071에서 채운다. 옮기거나 제거한 테스트가 보장하던 항목을 왼쪽에, 그 보장을 이어받은 테스트를 오른쪽에 적는다. 이어받을 곳이 없으면 제거 근거를 적는다.

| 옮긴 보장 | 이관처 또는 제거 근거 |
| --- | --- |
| `SessionKeychainMigrationTests`의 마이그레이션 3케이스 | `sources/Projects/Data/Tests/Authentication/Migrations/SessionKeychainMigrationTests.swift` |
| `PendingGenerationReminderCodingTests`의 대기 리마인드 4케이스 | `sources/Projects/Data/Tests/LearningProject/Codings/PendingGenerationReminderCodingTests.swift` |
| 세션·Apple 식별자·공유 마커 저장 좌표 | `sources/Projects/Data/Tests/Authentication/Layouts/SessionStorageCoordinateTests.swift` (신규) |
| 세션 저장 형식과 키 자리 | `sources/Projects/Data/Tests/Authentication/Codings/SessionRecordKeychainCodingTests.swift` (신규) |
| 대기 리마인드 키와 보관 한도 | `sources/Projects/Data/Tests/LearningProject/Layouts/GenerationReminderStorageCoordinateTests.swift` (신규) |
| `SessionAvailabilityResolverTests`의 판정 5케이스 | `sources/Projects/Domain/Tests/Authentication/UseCases/ResolveSessionAvailability/ResolveSessionAvailabilityTests.swift` (6케이스로 확장) |

---

## 의존성과 실행 순서

```text
I1 (Infrastructure + Composition)   외부 라이브러리 은닉
  └─> I2 (Infrastructure + Data + Composition)   저장 스키마 이동
        ├─> I3 (Domain + Composition + App)   세션 판정
        ├─> I4 (Domain + Data + Composition + App)   기기 등록
        └─> I5 (Domain + Composition + App)   리마인드 정책
              └─> I6 (Composition + App)   기동 순서
                    └─> U1 (문서)
                          └─> 전체 완료 검증
```

- I1을 먼저 두는 이유: 범위가 가장 작고 다른 단위가 만드는 파일에 의존하지 않는다.
- I2를 I3~I5보다 먼저 두는 이유: 세 단위 모두 I2가 옮긴 저장 타입을 참조한다. 먼저 옮기지 않으면 중간에 Composition을 거쳐 참조하는 상태가 생긴다.
- I3·I4·I5는 서로 독립이다. I2가 끝난 뒤 순서를 바꿔도 된다. 위 순서는 [plan.md](./plan.md)의 실행 단위 표를 따른다.
- I6을 마지막에 두는 이유: I1~I5가 조각을 정리한 뒤라야 `AppComposition`이 무엇을 공개할지 확정된다.

## 병렬 실행 기회

같은 실행 단위 안에서 서로 다른 파일을 다루는 `[P]` 작업만 병렬로 실행한다.

- I1: T006과 T007 (Infrastructure 테스트와 Composition 테스트)
- I2: T012와 T013 (서로 다른 Data 모듈의 테스트), T016과 T017 (서로 다른 Layout 파일)
- I4: T050과 T051 (Domain 테스트와 Data 테스트)

서로 다른 실행 단위와 모든 Git index·commit 작업은 직렬로 실행한다.

## 승인이 필요한 지점

이 명세의 작업은 모두 이미 승인된 기능 범위 안에 있으므로 단위 사이에 승인 게이트를 두지 않는다. 다음 경우에만 멈추고 확인을 받는다.

- T085에서 저장 좌표가 [data-model.md](./data-model.md) 2절과 다르게 바뀐 것이 발견된 경우. 기존 사용자의 로그인이 끊기는 변경이므로 되돌리기 전에 보고한다.
- T087의 수동 회귀는 기기 상태를 쓰는 검증이므로 실행 주체를 확인한 뒤 진행한다.
- I2에서 `docs/architecture.md`나 `docs/package-rules/*.md`의 규칙 자체를 고쳐야 한다고 판단되는 경우. 규칙 변경은 이 명세의 범위 밖이다.
