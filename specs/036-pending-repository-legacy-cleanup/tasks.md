---

description: "레거시 이관 코드 제거, 생성 대기 Repository, Infrastructure 의존의 Data 한정, Home 관찰 재개 작업 목록"
---

# 작업 목록: 레거시 이관 코드 제거, 생성 대기 Repository 도입, Infrastructure 의존의 Data 한정과 Home 생성 결과 관찰 재개

**입력**: `specs/036-pending-repository-legacy-cleanup/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 명세 성공 기준(SC-001, SC-003, SC-010~SC-012)이 자동 테스트 존재를 요구하므로 테스트 작업을
포함한다. 동작이 바뀌는 단위(U4, U9)는 테스트를 구현보다 먼저 둔다.

**빌드·테스트 실행**: 사용자 운영 방침에 따라 `build`·`compile`·`test` 명령은 사용자가 실행한다. 각 단위의
`[no-write]` 검증 작업은 정적 검증을 수행하고, 사용자 실행 결과를 받아 기록한다. 결과를 받지 못하면 미검증으로
보고한다.

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안에서 추적한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[S1]~[S5]**: [spec.md](./spec.md)의 변경 시나리오 1~5
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동 검증. `make tuist`의
  파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후 `git status --short`를 비교하고 추적 파일
  변경이 생기면 완료로 처리하지 않는다.
- 파일 변경 작업은 정확한 저장소 상대 경로와 책임 실행 단위를 가진다. 문서 루트는 `GIT_IT_DOCS_ROOT` = `docs`다.
- 서로 다른 실행 단위는 Git index나 같은 파일을 공유하므로 병렬 실행하지 않는다.
- 공개 API 신설·제거 작업은 확정한 식별자를 설명에 적는다. 이름은
  [contracts/](./contracts/)가 정본이며, 구현 중 이름을 바꿔야 하면 계약 문서와 이 목록을 먼저 갱신한다.

## 실행 단위 소유권 규칙

- 패키지 소스·테스트와 패키지 전용 설정은 해당 실행 단위가 소유한다.
- 공용 구성 파일(`sources/Tuist/ProjectDescriptionHelpers/**`, `tools/package-dependencies/config/*`)은 그 변경을
  처음 필요로 하는 integration unit에 배정한다.
- 전체 기능 검증은 마지막 실행 단위 뒤에 `[no-write]`로만 둔다.
- `docs/spec-kit/036-pending-repository-legacy-cleanup/trouble-shooting.md`와 `tacit-knowledge.md`는 작업으로
  만들지 않는다(Constitution 원칙 9).

---

## 실행 단위 U1: 이관 코드 제거 — integration unit (Infrastructure·Data·Composition)

**목표**: 생성 상태 이관과 세션 Keychain 이관 코드를 제거한다([research.md](./research.md) R7).

**분리 불가 근거**: Data 공개 타입 `GenerationStateMigration`·`SessionStorageMigration`과 Infrastructure 공개 함수
`AppGroupKeychainStore.makeLegacy()`를 지우면 이를 호출하는 Composition 조립 코드가 같은 단위에서 바뀌어야
compile된다.

**소유 경로**: 아래 작업의 파일

**관련 변경 시나리오**: S2

**독립 검증**: quickstart 시나리오 2 grep 0건, 사용자 빌드·테스트

### 구현

- [X] T001 [S2] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`에서 `AuthenticationAssembly.migrateSessionKeychain(sharedKeychainStore:)` 호출(현재 162행)을 제거한다
- [X] T002 [S2] `sources/Projects/Composition/Authentication/Assemblies/AuthenticationAssembly.swift`에서 `public static func migrateSessionKeychain(sharedKeychainStore:)`와 `SessionStorageMigration`·`AppGroupKeychainStore.makeLegacy()` 사용을 제거한다
- [X] T003 [S2] `sources/Projects/Composition/LearningProject/Assemblies/LearningProjectAssembly.swift`에서 `GenerationStateMigration(...)` 조립과 `LocalGenerationStateStore(store:migration:)`의 `migration:` 인자를 제거한다
- [X] T004 [S2] `sources/Projects/Data/LearningProject/Stores/LocalGenerationStateStore.swift`에서 `migration` 생성 인자·저장 프로퍼티와 `hasAttemptedMigration` 상태를 제거하고 `load()`가 저장값 또는 빈 `GenerationStateDTO`만 돌려주게 한다
- [X] T005 [S2] `sources/Projects/Data/Tests/LearningProject/Stores/LocalGenerationStateStoreTests.swift`에서 이관 인자를 쓰는 준비 코드와 이관 동작 테스트를 제거한다(현재 형식 저장·조회 테스트의 기대값은 유지)
- [X] T006 [P] [S2] `sources/Projects/Data/LearningProject/Stores/GenerationStateMigration.swift`를 삭제한다
- [X] T007 [P] [S2] `sources/Projects/Data/LearningProject/DTOs/GenerationState/LegacyGenerationProgressDTO.swift`를 삭제한다
- [X] T008 [P] [S2] `sources/Projects/Data/LearningProject/DTOs/GenerationState/LegacyRepositoryCreationStateDTO.swift`를 삭제한다
- [X] T009 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Stores/GenerationStateMigrationTests.swift`를 삭제한다
- [X] T010 [P] [S2] `sources/Projects/Data/Authentication/Migrations/SessionStorageMigration.swift`를 삭제하고 비게 된 `sources/Projects/Data/Authentication/Migrations/` 폴더를 제거한다
- [X] T011 [P] [S2] `sources/Projects/Data/Tests/Authentication/Migrations/SessionStorageMigrationTests.swift`를 삭제하고 비게 된 `sources/Projects/Data/Tests/Authentication/Migrations/` 폴더를 제거한다
- [X] T012 [S2] `sources/Projects/Infrastructure/Authentication/Keychain/Stores/AppGroupKeychainStore.swift`에서 `public static func makeLegacy() -> KeychainStore`와 그 전용 상수를 제거한다
- [X] T013 [S2] `docs/conventions/file-vocabulary/shape-vocabulary.md` Data 행에서 `Migrations/` 형태를 제거한다

### 정리와 단위 검증

- [X] T014 [no-write] [S2] `git grep -nE 'GenerationStateMigration|SessionStorageMigration|LegacyGenerationProgressDTO|LegacyRepositoryCreationStateDTO|makeLegacy|migrateSessionKeychain' -- sources`가 0건인지 확인하고, `make tuist` 후 사용자 `build`·`test` 결과를 기록한다

**진행 점검**: 변경 파일과 검증 결과를 보고하고 U2로 진행한다.

---

## 실행 단위 U2: Data 기술 재구현 제거 — Data 단일 패키지

**목표**: Data의 HTTP method 재선언과 변환 분기를 제거하고 요청 기술 표현을 Data 내부에서만 Infrastructure 타입으로
구성한다([research.md](./research.md) R8).

**소유 경로**: `sources/Projects/Data/{Authentication,ExternalRepository,LearningProject,Member}/**`와 해당 테스트

**관련 변경 시나리오**: S3

**독립 검증**: quickstart 시나리오 3. Composition은 `GitHubRepositoryRequest(owner:repository:)`만 사용하므로
영향이 없다.

### 구현

- [X] T015 [S3] `sources/Projects/Data/LearningProject/Endpoints/LearningProjectRequest.swift`에서 `method` 공개 프로퍼티와 `init(method:path:queryItems:)`의 Data `HTTPMethod` 인자를 제거하고, `internal let transportMethod: InfrastructureNetworkClient.HTTPMethod`와 이를 받는 `internal init`으로 바꾼다(`path`, `queryItems` 공개 유지)
- [X] T016 [S3] `sources/Projects/Data/LearningProject/Endpoints/ProjectEndpoint.swift`가 `LearningProjectRequest`의 internal init으로 같은 method·경로·query를 만들게 수정한다
- [X] T017 [P] [S3] `sources/Projects/Data/LearningProject/Endpoints/LearningSetEndpoint.swift`를 T015 init으로 수정한다
- [X] T018 [P] [S3] `sources/Projects/Data/LearningProject/Endpoints/AnswerEndpoint.swift`를 T015 init으로 수정한다
- [X] T019 [P] [S3] `sources/Projects/Data/LearningProject/Endpoints/BookmarkEndpoint.swift`를 T015 init으로 수정한다
- [X] T020 [P] [S3] `sources/Projects/Data/LearningProject/Endpoints/QuizGenerationEndpoint.swift`를 T015 init으로 수정한다
- [X] T021 [S3] `sources/Projects/Data/LearningProject/Endpoints/AuthorizedRequestHeaders.swift`를 `internal`로 내리고 `fieldValues` 대신 `internal var headers: HTTPHeaders`를 제공한다(헤더 이름·값 불변)
- [X] T022 [S3] `sources/Projects/Data/LearningProject/Remotes/LearningProjectRequestExecutor.swift`에서 `httpMethod(for:)` 변환 함수를 제거하고 `request.transportMethod`와 `AuthorizedRequestHeaders.headers`를 그대로 사용한다
- [X] T023 [S3] `sources/Projects/Data/LearningProject/Remotes/ProjectRemote.swift`의 인라인 `LearningProjectRequest(...)` 생성을 T015 init으로 수정한다
- [X] T024 [S3] `sources/Projects/Data/LearningProject/Models/HTTPMethod.swift`를 삭제한다
- [X] T025 [S3] `sources/Projects/Data/Authentication/Endpoints/AuthenticationEndpoint.swift`에서 중첩 `public enum Method`, `public let method`, `public func headers(accessToken:)`를 제거하고 `internal let transportMethod: InfrastructureNetworkClient.HTTPMethod`와 `internal func headers(accessToken:) -> HTTPHeaders`로 바꾼다(`appleLogin`·`verifyAccessToken` 경로와 헤더 값 불변)
- [X] T026 [S3] `sources/Projects/Data/Authentication/Remotes/AuthenticationRemote.swift`에서 method 삼항 변환과 헤더 dictionary 복사를 제거하고 T025 internal 멤버를 사용한다
- [X] T027 [S3] `sources/Projects/Data/Member/Endpoints/MemberEndpoint.swift`에서 중첩 `public enum Method`, `public let method`, `public func headers(accessToken:)`를 T025와 같은 internal 멤버로 바꾼다(6개 endpoint 경로·method 불변)
- [X] T028 [S3] `sources/Projects/Data/Member/Remotes/MemberRemote.swift`에서 `httpMethod(for:)`를 제거하고 T027 internal 멤버를 사용한다
- [X] T029 [S3] `sources/Projects/Data/ExternalRepository/Requests/GitHubRepositoryRequest.swift`에서 `public let method: String`을 제거한다(`scheme`, `host`, `path`, `headers` 유지)
- [X] T030 [S3] `sources/Projects/Data/ExternalRepository/Remotes/ExternalRepositoryRemote.swift`가 T029 변경 뒤에도 `.get`과 같은 헤더로 요청을 만드는지 맞춘다

### 테스트 정리

- [X] T031 [P] [S3] `sources/Projects/Data/Tests/Authentication/Endpoints/AuthenticationEndpointTests.swift`의 method·헤더 단언을 `@testable` internal 멤버(`transportMethod`, `headers(accessToken:)`) 단언으로 바꾸고 기대값은 유지한다
- [X] T032 [P] [S3] `sources/Projects/Data/Tests/Member/Endpoints/MemberEndpointTests.swift`를 T031과 같은 방식으로 바꾼다
- [X] T033 [P] [S3] `sources/Projects/Data/Tests/LearningProject/Endpoints/ProjectEndpointTests.swift`의 `request.method` 단언을 `request.transportMethod` 단언으로 바꾼다
- [X] T034 [P] [S3] `sources/Projects/Data/Tests/LearningProject/Endpoints/LearningSetEndpointTests.swift`를 T033과 같은 방식으로 바꾼다
- [X] T035 [P] [S3] `sources/Projects/Data/Tests/LearningProject/Endpoints/AnswerEndpointTests.swift`를 T033과 같은 방식으로 바꾼다
- [X] T036 [P] [S3] `sources/Projects/Data/Tests/LearningProject/Endpoints/BookmarkEndpointTests.swift`를 T033과 같은 방식으로 바꾼다
- [X] T037 [P] [S3] `sources/Projects/Data/Tests/LearningProject/Endpoints/QuizGenerationEndpointTests.swift`를 T033과 같은 방식으로 바꾼다
- [X] T038 [P] [S3] `sources/Projects/Data/Tests/LearningProject/Endpoints/AuthorizedRequestHeadersTests.swift`를 `headers` 단언으로 바꾸고 이름·값 기대값을 유지한다
- [X] T039 [P] [S3] `sources/Projects/Data/Tests/ExternalRepository/Requests/GitHubRepositoryRequestTests.swift`에서 `method` 단언을 제거한다(GET 전송은 `ExternalRepositoryRemoteTests.swift`의 기록 요청 단언으로 유지되는지 확인)

### 정리와 단위 검증

- [X] T040 [no-write] [S3] quickstart 시나리오 3의 grep 0건과 `git diff`에서 Remote 테스트의 경로·method·query·헤더 기대값 변경 0건을 확인하고 사용자 Data `test` 결과를 기록한다

**진행 점검**: 변경 파일과 검증 결과를 보고하고 U3으로 진행한다.

---

## 실행 단위 U3: `DataShared` target과 키 기반 값 저장 전환 — integration unit (Tuist·tools·Data·Composition·docs)

**목표**: Data가 기술 이름 없는 `KeyValueStorage`를 정의하고 공유 로그인 상태·약관 동의 저장이 이를 주입받게 한다
([contracts/data-capability-contracts.md](./contracts/data-capability-contracts.md) 1·2.1·2.4장).

**분리 불가 근거**: 새 target은 manifest·`source-roots`·전체 테스트 scheme과 함께 추가해야 검사기와 빌드가 통과하고,
`SharedSessionStateMarkerCoding`·`LocalPolicyConsentStore` 공개 initializer 변경은 Composition 조립·테스트와 함께
바뀌어야 compile된다.

**관련 변경 시나리오**: S4

**독립 검증**: 두 저장 타입 공개 선언의 `UserDefaults`·`UserDefaultsStore` 0건, 저장 좌표 테스트 기대값 불변,
`tools/package-dependencies/bin/run.sh` 통과

### 준비와 기반

- [X] T041 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에 `DataShared`(소스 `Shared`, 의존 `InfrastructureStorage`)와 `DataSharedTests`(소스 `Tests/Shared`, 의존 `DataShared`, `InfrastructureStorage`) target을 추가하고 `DataAuthentication`, `DataExternalRepository`, `DataLearningProject`, `DataLegalConsent`, `DataMember`에 `DataShared` 의존을 추가한다
- [X] T042 [S4] `sources/Tuist/ProjectDescriptionHelpers/AllTestsScheme.swift`에 `DataSharedTests`를 추가한다
- [X] T043 [S4] `tools/package-dependencies/config/source-roots`에 `DataShared Data/Shared`, `DataSharedTests Data/Tests/Shared` 행을 추가한다
- [X] T044 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의 `CompositionAuthentication`, `CompositionLearningProject`, `CompositionMember`, `CompositionApp`, `CompositionShareExtension`에 `DataShared` 의존을 추가한다
- [X] T045 [S4] `docs/conventions/file-vocabulary/shape-vocabulary.md` Data 행에 `Factories/`(기술 능력 구현 선택과 생성 진입점) 형태를 추가한다

### 테스트

- [X] T046 [P] [S4] `sources/Projects/Data/Tests/Shared/Stores/LocalKeyValueStorageTests.swift`에 실제 구현이 `"<namespace>.<key>"` 키에 JSON으로 저장·조회·삭제하고 `removeAllValues()`가 같은 namespace 값만 지우는지 격리된 `UserDefaults(suiteName:)`로 검증하는 테스트를 작성한다
- [X] T047 [P] [S4] `sources/Projects/Data/Tests/Shared/Factories/StorageFactoryTests.swift`에 App Group 저장소를 만들 수 없을 때 `.appGroup` 저장소가 기록을 무시하고 조회에 `nil`을 돌려주는지 검증하는 테스트를 작성한다

### 구현

- [X] T048 [P] [S4] `sources/Projects/Data/Shared/Contracts/KeyValueStorage.swift`에 `public protocol KeyValueStorage`(`value(_:forKey:)`, `setValue(_:forKey:)`, `removeValue(forKey:)`, `removeAllValues()`)를 정의한다
- [X] T049 [P] [S4] `sources/Projects/Data/Shared/Models/StorageLocation.swift`에 `public enum StorageLocation { case appGroup, device }`를 정의한다
- [X] T050 [S4] `sources/Projects/Data/Shared/Stores/LocalKeyValueStorage.swift`에 Infrastructure `UserDefaultsStore`를 감싸는 `internal` 실제 구현을 추가한다
- [X] T051 [S4] `sources/Projects/Data/Shared/Stores/UnavailableKeyValueStorage.swift`에 기록을 무시하고 조회에 `nil`을 돌려주는 `internal` 구현을 추가한다
- [X] T052 [S4] `sources/Projects/Data/Shared/Factories/StorageFactory.swift`에 `public enum StorageFactory`와 `keyValueStorage(namespace:location:) -> any KeyValueStorage`를 추가한다(`.appGroup`은 `AppGroupUserDefaults.makeShared()`, 실패 시 T051)
- [X] T053 [S4] `sources/Projects/Data/Authentication/Codings/SharedSessionStateMarkerCoding.swift`의 `init(userDefaults: UserDefaults)`를 `init(storage: any KeyValueStorage)`로 바꾸고 key `stateMarker`·schemaVersion 1 형식을 유지한다
- [X] T054 [S4] `sources/Projects/Data/LegalConsent/Stores/LocalPolicyConsentStore.swift`의 `init(store: UserDefaultsStore<[PolicyConsentRecordDTO]>)`를 `init(storage: any KeyValueStorage)`로 바꾸고 key `records` 형식을 유지한다
- [X] T055 [S4] `sources/Projects/Data/Tests/LegalConsent/TestDoubles/InMemoryKeyValueStorage.swift`에 JSON 왕복을 수행하는 in-memory 테스트 더블을 추가한다
- [X] T056 [S4] `sources/Projects/Data/Tests/LegalConsent/Stores/LocalPolicyConsentStoreTests.swift`가 T055 더블을 주입하도록 바꾸고 기대값을 유지한다
- [X] T057 [S4] `sources/Projects/Data/Tests/Authentication/TestDoubles/InMemoryKeyValueStorage.swift`에 JSON 왕복을 수행하는 in-memory 테스트 더블을 추가한다
- [X] T058 [S4] `sources/Projects/Data/Tests/Authentication/Codings/SharedSessionStateMarkerCodingTests.swift`에 T057 더블을 주입해 로그인 상태 저장 후 조회, 저장값이 없을 때 `nil`, schemaVersion이 1이 아닌 값은 `nil`, 저장 key가 `stateMarker`인지 검증하는 테스트를 작성한다
- [X] T059 [S4] `sources/Projects/Data/Authentication/Layouts/SessionStorageLayout.swift`에 공유 세션 namespace 문자열 상수 `sharedSessionNamespace = "com.nexters.hytime.gitit.sharedSession"`을 추가하고 `SharedSessionStateMarkerCoding.swift`가 이를 쓰도록 한다(T060의 Composition 참조 대상)
- [X] T060 [S4] `sources/Projects/Composition/Authentication/Assemblies/SessionAvailabilityAssembly.swift`에서 `SharedSessionStateMarkerCoding`을 `StorageFactory.keyValueStorage(namespace: SessionStorageLayout.sharedSessionNamespace, location: .appGroup)` 또는 주입된 `any KeyValueStorage`로 만들도록 바꾼다(`sharedDefaults: UserDefaults?` 인자를 `sharedStorage: (any KeyValueStorage)?`로 교체, namespace는 T059 Data 상수를 참조)
- [X] T061 [S4] `sources/Projects/Composition/Authentication/Assemblies/AuthenticationAssembly.swift`의 `policyConsentStore` 기본값과 `sharedDefaults` 인자를 `StorageFactory`·`any KeyValueStorage` 기반으로 바꾼다
- [X] T062 [S4] `sources/Projects/Composition/Authentication/Adapters/LoginSessionRepositoryAdapter.swift`의 `AppGroupUserDefaults.makeShared()` 기본값을 `any KeyValueStorage` 주입으로 바꾼다
- [X] T063 [S4] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`가 `SessionAvailabilityAssembly`에 `sharedStorage`를 전달하도록 바꾼다(`sharedDefaults` 인자는 U4 T105에서 제거될 때까지 완료 알림 대기 기록에만 사용)
- [X] T064 [P] [S4] `sources/Projects/Composition/Tests/Authentication/TestDoubles/InMemoryKeyValueStorage.swift`에 in-memory 테스트 더블을 추가한다
- [X] T065 [S4] `sources/Projects/Composition/Tests/Authentication/Adapters/PolicyConsentRepositoryAdapterTests.swift`가 `UserDefaultsStore` 대신 T064 더블로 `LocalPolicyConsentStore`를 만들도록 바꾼다
- [X] T066 [S4] `sources/Projects/Composition/Tests/Authentication/Assemblies/AuthenticationAssemblyTests.swift`의 조립 인자를 T061 시그니처에 맞춘다
- [X] T067 [P] [S4] `sources/Projects/Composition/Tests/ShareExtension/TestDoubles/InMemoryKeyValueStorage.swift`에 in-memory 테스트 더블을 추가한다
- [X] T068 [S4] `sources/Projects/Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift`의 `sharedDefaults` 준비를 공유 로그인 상태에 한해 T067 더블로 바꾼다

### 정리와 단위 검증

- [X] T069 [no-write] [S4] `git grep -nE '^\s*public\b.*\b(UserDefaults|UserDefaultsStore)\b' -- sources/Projects/Data/Authentication/Codings/SharedSessionStateMarkerCoding.swift sources/Projects/Data/LegalConsent/Stores/LocalPolicyConsentStore.swift`가 0건, `sources/Projects/Data/Tests/Authentication/Layouts/SessionStorageCoordinateTests.swift` 기대값 diff 0건, `tools/package-dependencies/bin/run.sh` 종료 코드 0을 확인하고 `make tuist` 전후 Git 상태 비교와 사용자 `build`·`test` 결과를 기록한다

**진행 점검**: 변경 파일과 검증 결과를 보고하고 U4로 진행한다.

---

## 실행 단위 U4: 생성 대기 Repository — integration unit (Domain·Data·Composition)

**목표**: Domain `PendingGenerationRepository` 하나가 생성 진행 기록과 완료 알림 대기를 소유하고, 생성 요청과 목록 조회의
대기 확인 경계가 된다([contracts/pending-generation-repository.md](./contracts/pending-generation-repository.md)).

**분리 불가 근거**: Domain 계약 `GenerationStateRepository`·`PendingGenerationReminders`와 Data 계약
`GenerationStateStore` 제거, UseCase 생성 인자 변경은 Composition Adapter·Assembly와 함께 바뀌어야 compile된다.

**관련 변경 시나리오**: S1

**독립 검증**: quickstart 시나리오 1

### Domain 테스트

- [ ] T070 [S1] `sources/Projects/Domain/Tests/LearningProject/TestDoubles/StubPendingGenerationRepository.swift`에 `PendingGenerationRepository`를 `GenerationState` 모델 전이로 구현하는 actor 테스트 더블(초기 상태 주입, 기록 스냅샷, 상태 변화 스트림, 알림 대기 목록)을 추가한다
- [ ] T071 [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/CreateLearningProjectTests.swift`를 `pendingGenerations:` 주입으로 바꾸고, 대기 중 URL 요청 시 서버 등록 미호출·중복 오류, 서버 등록 실패 시 대기 해제, 다른 URL 동시 요청 허용 사례를 유지·보강한다
- [ ] T072 [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchLearningProjectsTests.swift`를 `pendingGenerations:` 주입으로 바꾸고 생성 중 프로젝트 제외, `hasNext` 유지, 끝난 생성은 제외하지 않음 사례를 검증한다
- [ ] T073 [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/TrackGenerationTests.swift`를 T070 더블 기반으로 바꾸고 연산 위임, 생성 결과 반영(`finishGeneration`), 결과 관찰을 여러 번 호출해도 한 번만 시작, 관찰자 전달 사례를 검증한다
- [ ] T074 [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/ScheduleGenerationReminder/ScheduleGenerationReminderTests.swift`의 private `StubPendingGenerationReminders`를 T070 더블로 바꾸고 알림 대기 흡수 사례를 유지한다
- [ ] T075 [S1] `sources/Projects/Domain/Tests/LearningProject/LearningProjectLifecycleTests.swift`의 `TrackGeneration` 조립을 T070 더블로 바꾼다
- [ ] T076 [S1] `sources/Projects/Domain/Tests/LearningProject/TestDoubles/StubGenerationStateRepository.swift`를 삭제한다

### Domain 구현

- [ ] T077 [S1] `sources/Projects/Domain/LearningProject/Contracts/PendingGenerationRepository.swift`에 계약 문서 1장의 `public protocol PendingGenerationRepository`(9개 연산)를 정의한다
- [ ] T078 [S1] `sources/Projects/Domain/LearningProject/UseCases/CreateLearningProject/CreateLearningProject.swift`를 `init(repository:pendingGenerations:now:)`로 바꾸고 `beginGeneration`·`attachProjectID`·`releaseGeneration(githubRepoURL:)`를 사용한다
- [ ] T079 [S1] `sources/Projects/Domain/LearningProject/UseCases/FetchLearningProjects/FetchLearningProjects.swift`를 `init(repository:pendingGenerations:)`로 바꾸고 `pendingState().activeProjectIDs`로 제외한다
- [ ] T080 [S1] `sources/Projects/Domain/LearningProject/UseCases/TrackGeneration/GenerationStateCoordinator.swift`를 상태 보관·관찰자 관리 없이 생성 결과 관찰을 한 번만 시작해 `finishGeneration`으로 반영하는 actor로 축소한다
- [ ] T081 [S1] `sources/Projects/Domain/LearningProject/UseCases/TrackGeneration/TrackGeneration.swift`를 `init(pendingGenerations:outcomeRepository:now:)`로 바꾸고 `TrackGenerationUseCase` 6개 연산을 계약 문서 2장 대응표대로 위임한다
- [ ] T082 [S1] `sources/Projects/Domain/LearningProject/UseCases/ScheduleGenerationReminder/ScheduleGenerationReminder.swift`의 `pendingReminders: (any PendingGenerationReminders)?`를 `pendingGenerations: (any PendingGenerationRepository)?`로 바꾸고 `drainReminderProjectIDs()`를 사용한다
- [ ] T083 [P] [S1] `sources/Projects/Domain/LearningProject/Contracts/GenerationStateRepository.swift`를 삭제한다
- [ ] T084 [P] [S1] `sources/Projects/Domain/LearningProject/Contracts/PendingGenerationReminders.swift`를 삭제한다

### Data 테스트

- [ ] T085 [S1] `sources/Projects/Data/Tests/LearningProject/TestDoubles/InMemoryKeyValueStorage.swift`에 JSON 왕복 in-memory 테스트 더블을 추가한다
- [ ] T086 [S1] `sources/Projects/Data/Tests/LearningProject/Stores/LocalPendingGenerationStoreTests.swift`에 상태 조회·`modifyState` 기록과 `nil` 무기록, 구독 직후 현재 상태 전달과 기록마다 전달, 구독 종료 후 미전달, 알림 대기 중복 무시·상한 32·흡수 후 비움·손상된 값 빈 목록, 저장소 사용 불가 시 빈 상태 사례를 작성한다
- [ ] T087 [S1] `sources/Projects/Data/Tests/LearningProject/Layouts/GenerationReminderStorageCoordinateTests.swift`의 대상 상수를 `LocalPendingGenerationStore`의 namespace·key(`generationState`, `pendingGenerationReminders`)·상한 32로 바꾸고 문자열 기대값을 유지한다
- [ ] T088 [P] [S1] `sources/Projects/Data/Tests/LearningProject/Codings/PendingGenerationReminderCodingTests.swift`를 삭제한다(사례는 T086로 이동)
- [ ] T089 [P] [S1] `sources/Projects/Data/Tests/LearningProject/Stores/LocalGenerationStateStoreTests.swift`를 삭제한다(사례는 T086로 이동)

### Data 구현

- [ ] T090 [S1] `sources/Projects/Data/LearningProject/Stores/LocalPendingGenerationStore.swift`에 계약 문서 3장의 `public actor LocalPendingGenerationStore`를 구현한다(구독자 등록·해제는 `Mutex`로 스트림 생성 시점에 동기 처리, 알림 대기 항목 JSON 필드 `projectID`·`requestedAt` 유지)
- [ ] T091 [P] [S1] `sources/Projects/Data/LearningProject/Stores/LocalGenerationStateStore.swift`를 삭제한다
- [ ] T092 [P] [S1] `sources/Projects/Data/LearningProject/Codings/PendingGenerationReminderCoding.swift`를 삭제한다
- [ ] T093 [P] [S1] `sources/Projects/Data/LearningProject/Contracts/GenerationStateStore.swift`를 삭제한다
- [ ] T094 [S1] `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에서 `DataLearningProject`·`DataLearningProjectTests`의 `InfrastructureStorage` 의존을 `git grep -n 'import InfrastructureStorage' -- sources/Projects/Data/LearningProject sources/Projects/Data/Tests/LearningProject` 결과가 0건일 때 제거한다. 0건이 아니면 의존을 유지하고 남은 import 경로를 진행 보고에 기록한다

### Composition 테스트

- [ ] T095 [S1] `sources/Projects/Composition/Tests/LearningProject/TestDoubles/InMemoryKeyValueStorage.swift`에 in-memory 테스트 더블을 추가한다
- [ ] T096 [S1] `sources/Projects/Composition/Tests/LearningProject/Adapters/PendingGenerationRepositoryAdapterTests.swift`에 같은 저장소를 공유하는 두 Adapter 사이의 기록·조회·알림 대기 흡수, 같은 URL 동시 `beginGeneration` 중 하나만 `true`, 만료 기록 정리 뒤 재시작 허용, 상태 변화 스트림의 모델 변환 사례를 작성한다
- [ ] T097 [S1] `sources/Projects/Composition/Tests/LearningProject/Assemblies/LearningProjectAssemblyTests.swift`를 새 조립에 맞추고 생성 결과 push 수신 후 `trackGeneration.states()`에 완료 상태가 전달되는 사례를 유지한다
- [ ] T098 [S1] `sources/Projects/Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift`의 "등록한 프로젝트를 본 앱이 흡수할 대기 목록에 남긴다" 사례를 `enqueueGenerationReminder` 후 같은 저장소의 `PendingGenerationRepository.drainReminderProjectIDs()` 확인으로 바꾼다

### Composition 구현

- [ ] T099 [S1] `sources/Projects/Composition/LearningProject/Adapters/PendingGenerationRepositoryAdapter.swift`에 `PendingGenerationRepository`를 채택하는 Adapter(`init(store:waitPolicy:now:)`, DTO↔모델 변환·만료 정리·Domain 모델 전이 호출만 수행)를 추가한다
- [ ] T100 [P] [S1] `sources/Projects/Composition/LearningProject/Adapters/GenerationStateRepositoryAdapter.swift`를 삭제한다
- [ ] T101 [P] [S1] `sources/Projects/Composition/LearningProject/Adapters/PendingGenerationRemindersAdapter.swift`를 삭제한다
- [ ] T102 [S1] `sources/Projects/Composition/LearningProject/Assemblies/LearningProjectAssembly.swift`에서 `sharedDefaults` 인자를 `sharedStorage: (any KeyValueStorage)?`로 바꾸고, 프로세스당 `LocalPendingGenerationStore`·`PendingGenerationRepositoryAdapter` 1개를 만들어 `TrackGeneration`·`CreateLearningProject`·`FetchLearningProjects`에 공유하며 `public let pendingGenerations: any PendingGenerationRepository`로 노출한다(`.standard` 대체 저장 제거)
- [ ] T103 [S1] `sources/Projects/Composition/LearningProject/Assemblies/GenerationReminderAssembly.swift`에서 `pendingReminderCoding` 인자와 `makePendingReminderEnqueue(sharedDefaults:)`를 제거하고 `pendingGenerations: (any PendingGenerationRepository)?`를 받아 `ScheduleGenerationReminder`에 전달한다
- [ ] T104 [S1] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`가 `learningProject.pendingGenerations`를 `GenerationReminderAssembly`에 전달하도록 바꾼다
- [ ] T105 [S1] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`의 `enqueueGenerationReminder`를 Share Extension용 `learningProject.pendingGenerations.enqueueReminder(projectID:)`에 연결하고 `sharedDefaults` 인자를 제거한다(공개 프로퍼티 이름·타입 유지)
- [ ] T106 [S1] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`에서 `CompositionLearningProject`·`CompositionShareExtension`의 `InfrastructureStorage` 의존을 해당 소스의 `import InfrastructureStorage`가 0건일 때 제거한다. 0건이 아니면 의존을 유지하고 남은 import 경로를 진행 보고에 기록한다

### 정리와 단위 검증

- [ ] T107 [no-write] [S1] quickstart 시나리오 1의 grep 3개가 0건인지 확인하고 `make tuist` 전후 Git 상태 비교와 사용자 `build`·`test` 결과(Domain·Data·Composition·App 테스트)를 기록한다

**진행 점검**: 변경 파일과 검증 결과를 보고하고 U5로 진행한다.

---

## 실행 단위 U5: 보안 저장 전환 — integration unit (Tuist·Data·Composition)

**목표**: Data·Composition 공개 initializer의 `KeychainStore`를 Data `SecureValueStorage`로 바꾼다
([contracts/data-capability-contracts.md](./contracts/data-capability-contracts.md) 2.2·4·5장).

**분리 불가 근거**: `SessionRecordStorageCoding`·`AppleIdentityStore`·`LocalDeviceIdentifierStore` 공개 initializer와
이를 받는 Composition 공개 API(`AppComposition.live`, `ShareExtensionComposition.live`, `SessionAvailabilityAssembly`,
`MemberAssembly.makeRegisterCurrentDevice` 등)가 함께 바뀌어야 compile된다.

**관련 변경 시나리오**: S4

**독립 검증**: Composition 소스의 `KeychainStore` 참조 0건, Domain 인증 오류 결과 테스트 기대값 불변

### 준비와 기반

- [ ] T108 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에서 `DataShared`·`DataSharedTests`에 `InfrastructureAuthentication` 의존을 추가한다

### 테스트

- [ ] T109 [P] [S4] `sources/Projects/Data/Tests/Shared/Stores/LocalSecureValueStorageTests.swift`에 `@testable import InfrastructureAuthentication`의 `KeychainStore.InMemoryBackend`로 namespace·key 저장·조회·삭제와 `KeychainStoreError` → `SecureValueStorageError` 변환을 검증하는 테스트를 작성한다
- [ ] T110 [P] [S4] `sources/Projects/Data/Tests/Authentication/TestDoubles/InMemorySecureValueStorage.swift`에 in-memory 테스트 더블(오류 주입 가능)을 추가한다
- [ ] T111 [P] [S4] `sources/Projects/Data/Tests/Member/TestDoubles/InMemorySecureValueStorage.swift`에 in-memory 테스트 더블을 추가한다

### 구현

- [ ] T112 [S4] `sources/Projects/Data/Shared/Errors/SecureValueStorageError.swift`에 `public enum SecureValueStorageError`를 정의한다. case는 Infrastructure `KeychainStoreError` case와 `sources/Projects/Composition/Authentication/Adapters/AuthenticationRepositoryAdapter.swift`·`LoginSessionRepositoryAdapter.swift`의 현재 오류 변환을 대조해 Domain 오류 결과가 같아지도록 확정한다
- [ ] T113 [S4] `sources/Projects/Data/Shared/Contracts/SecureValueStorage.swift`에 `public protocol SecureValueStorage`(`data(forKey:)`, `setData(_:forKey:)`, `removeData(forKey:)`)를 정의한다
- [ ] T114 [S4] `sources/Projects/Data/Shared/Stores/LocalSecureValueStorage.swift`에 Infrastructure `KeychainStore`와 `KeychainNamespace`를 감싸는 `internal` 실제 구현을 추가한다
- [ ] T115 [S4] `sources/Projects/Data/Shared/Factories/StorageFactory.swift`에 `secureValueStorage(namespace:location:)`를 추가한다(`.appGroup`은 `AppGroupKeychainStore.makeShared()`, `.device`는 `KeychainStore()`)
- [ ] T116 [S4] `sources/Projects/Data/Authentication/Layouts/SessionStorageLayout.swift`와 `sources/Projects/Data/Authentication/Layouts/AppleIdentityStorageLayout.swift`의 `namespace`를 `KeychainNamespace`에서 같은 값의 `String`으로 바꾼다
- [ ] T117 [S4] `sources/Projects/Data/Authentication/Codings/SessionRecordStorageCoding.swift`를 `init(storage: any SecureValueStorage)`로 바꾸고 key `sessionRecord`·JSON 형식을 유지한다
- [ ] T118 [S4] `sources/Projects/Data/Authentication/Stores/AppleIdentityStore.swift`를 `init(storage: any SecureValueStorage)`로 바꾸고 key `appleUserID`·UTF-8 형식을 유지한다
- [ ] T119 [S4] `sources/Projects/Data/Member/Stores/LocalDeviceIdentifierStore.swift`를 `init(storage: any SecureValueStorage)`로 바꾸고 `namespace`를 `String`으로, key `deviceID`·UTF-8 형식을 유지한다
- [ ] T120 [S4] `sources/Projects/Data/Tests/Authentication/Codings/SessionRecordStorageCodingTests.swift`를 T110 더블 주입으로 바꾸고 기대값을 유지한다
- [ ] T121 [S4] `sources/Projects/Data/Tests/Authentication/Stores/AppleIdentityStoreTests.swift`에 T110 더블을 주입해 사용자 식별자 저장·조회·삭제, key `appleUserID`에 UTF-8 바이트로 저장, 저장소 오류가 호출자에게 전파되는지 검증하는 테스트를 작성한다
- [ ] T122 [S4] `sources/Projects/Data/Tests/Member/Stores/LocalDeviceIdentifierStoreTests.swift`를 T111 더블 주입으로 바꾸고 기대값을 유지한다
- [ ] T123 [S4] `sources/Projects/Data/Tests/Authentication/Layouts/SessionStorageCoordinateTests.swift`의 namespace 단언을 `String` 비교로 바꾸고 문자열 기대값을 유지한다
- [ ] T124 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에서 `DataMember`·`DataMemberTests`의 `InfrastructureAuthentication` 의존을 해당 소스의 import가 0건일 때 제거한다. 0건이 아니면 의존을 유지하고 남은 import 경로를 진행 보고에 기록한다
- [ ] T125 [S4] `sources/Projects/Composition/Authentication/Codings/SessionRecordCoding.swift`를 `any SecureValueStorage` 주입으로 바꾼다
- [ ] T126 [S4] `sources/Projects/Composition/Authentication/Adapters/CurrentSessionRepositoryAdapter.swift`를 `init(secureStorage: any SecureValueStorage)`로 바꾼다
- [ ] T127 [S4] `sources/Projects/Composition/Authentication/Adapters/LoginSessionRepositoryAdapter.swift`의 `KeychainStore`·`KeychainStoreError`를 `any SecureValueStorage`·`SecureValueStorageError`로 바꾸고 Domain 오류 변환 결과를 유지한다
- [ ] T128 [S4] `sources/Projects/Composition/Authentication/Adapters/AuthenticationRepositoryAdapter.swift`의 `keychainStore` 인자와 `KeychainStoreError` 처리를 `any SecureValueStorage`·`SecureValueStorageError`로 바꾼다(Apple 제공자는 U7에서 전환)
- [ ] T129 [S4] `sources/Projects/Composition/Authentication/Assemblies/SessionAvailabilityAssembly.swift`를 `init(secureStorage:sharedStorage:)`로 바꾼다
- [ ] T130 [S4] `sources/Projects/Composition/Authentication/Assemblies/AuthenticationAssembly.swift`의 `keychainStore: KeychainStore = KeychainStore()`를 `secureStorage: (any SecureValueStorage)?`(nil이면 `StorageFactory`)로 바꾼다
- [ ] T131 [S4] `sources/Projects/Composition/Member/Adapters/DeviceIdentifierRepositoryAdapter.swift`를 `init(secureStorage: any SecureValueStorage)`로 바꾼다
- [ ] T132 [S4] `sources/Projects/Composition/Member/Assemblies/MemberAssembly.swift`의 `makeRegisterCurrentDevice(keychainStore:...)`를 `secureStorage:`로 바꾼다
- [ ] T133 [S4] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`의 `live(_:keychainStore:transport:)`와 내부 `keychainStore` 전달을 `secureStorage: (any SecureValueStorage)?`로 바꾼다
- [ ] T134 [S4] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`의 `keychainStore` 인자를 `secureStorage: (any SecureValueStorage)?`로 바꾼다
- [ ] T135 [P] [S4] `sources/Projects/Composition/Tests/App/TestDoubles/InMemorySecureValueStorage.swift`에 in-memory 테스트 더블을 추가한다
- [ ] T136 [P] [S4] `sources/Projects/Composition/Tests/Authentication/TestDoubles/InMemorySecureValueStorage.swift`에 in-memory 테스트 더블(오류 주입 가능)을 추가한다
- [ ] T137 [P] [S4] `sources/Projects/Composition/Tests/ShareExtension/TestDoubles/InMemorySecureValueStorage.swift`에 in-memory 테스트 더블을 추가한다
- [ ] T138 [S4] `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionTests.swift`의 `KeychainStore(backend:)` 준비를 T135 더블로 바꾼다
- [ ] T139 [S4] `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionSharedLifetimeTests.swift`의 `KeychainStore(backend:)` 준비를 T135 더블로 바꾼다
- [ ] T140 [S4] `sources/Projects/Composition/Tests/App/SharedLifetimeTests.swift`의 `KeychainStore` 준비를 T135 더블로 바꾼다
- [ ] T141 [S4] `sources/Projects/Composition/Tests/Authentication/Adapters/AuthenticationRepositoryAdapterTests.swift`의 `KeychainStore` 준비를 T136 더블로 바꾸고 Domain 오류 기대값을 유지한다
- [ ] T142 [S4] `sources/Projects/Composition/Tests/Authentication/Adapters/LoginSessionRepositoryAdapterTests.swift`의 `KeychainStore` 준비를 T136 더블로 바꾸고 Domain 오류 기대값을 유지한다
- [ ] T143 [S4] `sources/Projects/Composition/Tests/Authentication/Assemblies/AuthenticationAssemblyTests.swift`의 `KeychainStore` 준비를 T136 더블로 바꾼다
- [ ] T144 [S4] `sources/Projects/Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift`의 `KeychainStore` 준비를 T137 더블로 바꾼다

### 정리와 단위 검증

- [ ] T145 [no-write] [S4] `git grep -nE 'KeychainStore|KeychainNamespace|AppGroupKeychainStore' -- sources/Projects/Composition`이 0건인지 확인하고 `make tuist` 전후 Git 상태 비교와 사용자 `build`·`test` 결과를 기록한다

**진행 점검**: 변경 파일과 검증 결과를 보고하고 U6으로 진행한다.

---

## 실행 단위 U6: 요청 전송 전환 — integration unit (Tuist·tools·Data·Composition·docs)

**목표**: Remote 공개 initializer의 `HTTPClient`와 Composition의 `HTTPTransport`·`makeHTTPClient`를 Data
`RequestTransport`와 생성 인자로 바꾼다([contracts/data-capability-contracts.md](./contracts/data-capability-contracts.md)
2.3·2.4·4·5장, [research.md](./research.md) R10).

**분리 불가 근거**: Remote 7개 공개 initializer 변경, Composition `makeHTTPClient` 제거, 비게 되는 `CompositionShared`
target 제거가 함께 바뀌어야 compile·검사가 통과한다.

**관련 변경 시나리오**: S4

**독립 검증**: Composition의 `HTTPClient`·`HTTPTransport`·`StandardJSONBodyCoding` 참조 0건, Data Remote 테스트 기대값 불변

### 준비와 기반

- [ ] T146 [S4] `sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift`의 `module`에 선택 인자 `packageName: String?`을 추가하고 값이 있으면 `OTHER_SWIFT_FLAGS`에 `-package-name <값>`을 설정한다(Data target 간 Infrastructure 타입을 주고받는 `package` 접근 수준용)
- [ ] T147 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`의 모든 Data 프로덕션·테스트 target에 `packageName: "GitItData"`를 지정하고 `DataShared`·`DataSharedTests`에 `InfrastructureNetworkClient` 의존을 추가한다

### 테스트

- [ ] T148 [S4] `sources/Projects/Data/Tests/Shared/Remotes/RequestTransportBridgeTests.swift`에 주입된 `RequestTransport` 더블이 받은 `TransportRequest`의 URL·헤더·본문, 응답 상태 코드·본문 전달, `RequestTransportError` → `HTTPClientError` 변환(`cancelled`, `timedOut`, `connectionFailed`)을 검증하는 테스트를 작성한다

### 구현

- [ ] T149 [P] [S4] `sources/Projects/Data/Shared/Contracts/RequestTransport.swift`에 `public protocol RequestTransport`를 정의한다
- [ ] T150 [P] [S4] `sources/Projects/Data/Shared/Models/TransportRequest.swift`에 `public struct TransportRequest`(`url`, `headerFields`, `body`, method 없음)를 정의한다
- [ ] T151 [P] [S4] `sources/Projects/Data/Shared/Models/TransportResponse.swift`에 `public struct TransportResponse`(`init(statusCode:headerFields:body:)`)를 정의한다
- [ ] T152 [P] [S4] `sources/Projects/Data/Shared/Errors/RequestTransportError.swift`에 `public enum RequestTransportError`를 정의한다
- [ ] T153 [S4] `sources/Projects/Data/Shared/Remotes/RequestTransportBridge.swift`에 `RequestTransport`를 Infrastructure `HTTPTransport`로 연결하는 `package` 구현을 추가한다
- [ ] T154 [S4] `sources/Projects/Data/Shared/Factories/RequestClientFactory.swift`에 `public static let defaultResponseTimeout: Duration`과 `package static func makeClient(baseURL:transport:responseTimeout:) -> HTTPClient`(transport가 nil이면 `URLSessionTransport`, 있으면 T153)를 추가한다
- [ ] T155 [S4] `sources/Projects/Data/Authentication/Remotes/AuthenticationRemote.swift`의 공개 init을 `init(baseURL:transport:responseTimeout:accessTokenProvider:)`로 바꾸고 기존 `init(client:accessTokenProvider:)`는 `internal`로 유지한다
- [ ] T156 [P] [S4] `sources/Projects/Data/ExternalRepository/Remotes/ExternalRepositoryRemote.swift`를 T155와 같은 방식(`init(baseURL:transport:responseTimeout:)`, internal `init(client:)`)으로 바꾼다
- [ ] T157 [P] [S4] `sources/Projects/Data/LearningProject/Remotes/ProjectRemote.swift`를 T155와 같은 방식으로 바꾼다
- [ ] T158 [P] [S4] `sources/Projects/Data/LearningProject/Remotes/LearningSetRemote.swift`를 T155와 같은 방식으로 바꾼다
- [ ] T159 [P] [S4] `sources/Projects/Data/LearningProject/Remotes/AnswerRemote.swift`를 T155와 같은 방식으로 바꾼다
- [ ] T160 [P] [S4] `sources/Projects/Data/LearningProject/Remotes/BookmarkRemote.swift`를 T155와 같은 방식으로 바꾼다
- [ ] T161 [P] [S4] `sources/Projects/Data/Member/Remotes/MemberRemote.swift`를 T155와 같은 방식으로 바꾼다
- [ ] T162 [S4] `sources/Projects/Composition/Authentication/Assemblies/AuthenticationAssembly.swift`의 `transport: (any HTTPTransport)?`, `responseTimeout = HTTPClient.defaultResponseTimeout`, `makeHTTPClient` 사용을 `(any RequestTransport)?`, `RequestClientFactory.defaultResponseTimeout`, Remote 새 init으로 바꾸고 `import CompositionShared`를 제거한다
- [ ] T163 [S4] `sources/Projects/Composition/LearningProject/Assemblies/ExternalRepositoryAssembly.swift`를 T162와 같은 방식으로 바꾸고 `import CompositionShared`를 제거한다
- [ ] T164 [S4] `sources/Projects/Composition/LearningProject/Assemblies/LearningProjectAssembly.swift`를 T162와 같은 방식으로 바꾸고 `import CompositionShared`를 제거한다
- [ ] T165 [S4] `sources/Projects/Composition/Member/Assemblies/MemberAssembly.swift`를 T162와 같은 방식으로 바꾸고 `import CompositionShared`를 제거한다
- [ ] T166 [S4] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`의 `transport: (any HTTPTransport)?`를 `(any RequestTransport)?`로 바꾼다
- [ ] T167 [S4] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`의 `transport: (any HTTPTransport)?`를 `(any RequestTransport)?`로 바꾼다
- [ ] T168 [S4] `sources/Projects/Composition/Shared/Factories/HTTPClientFactory.swift`를 삭제한다
- [ ] T169 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`에서 소스가 없어진 `CompositionShared` target과 모든 target의 `CompositionShared` 의존을 제거한다
- [ ] T170 [S4] `tools/package-dependencies/config/source-roots`에서 `CompositionShared Composition/Shared` 행을 제거한다
- [ ] T171 [no-write] [S4] `git grep -l 'import CompositionShared' -- sources/Projects`가 0건인지 확인한다(현재 사용처 `AuthenticationAssembly.swift`, `ExternalRepositoryAssembly.swift`, `LearningProjectAssembly.swift`, `MemberAssembly.swift`의 import는 T162~T165에서 함께 제거)
- [ ] T172 [S4] `docs/package-rules/composition.md`의 `CompositionShared` 행(현재 31행)을 제거한다
- [ ] T173 [P] [S4] `sources/Projects/Composition/Tests/App/TestDoubles/RecordingRequestTransport.swift`에 경로별 응답 스크립트와 요청 기록(`url`, `body`)을 가진 `actor RecordingRequestTransport: RequestTransport`를 추가하고 같은 폴더의 `RecordingHTTPTransport.swift`를 삭제한다
- [ ] T174 [P] [S4] `sources/Projects/Composition/Tests/Authentication/TestDoubles/RecordingRequestTransport.swift`를 T173과 같게 추가하고 `RecordingHTTPTransport.swift`를 삭제한다
- [ ] T175 [P] [S4] `sources/Projects/Composition/Tests/LearningProject/TestDoubles/RecordingRequestTransport.swift`를 T173과 같게 추가하고 `RecordingHTTPTransport.swift`를 삭제한다
- [ ] T176 [P] [S4] `sources/Projects/Composition/Tests/Member/TestDoubles/RecordingRequestTransport.swift`를 T173과 같게 추가하고 `RecordingHTTPTransport.swift`를 삭제한다
- [ ] T177 [S4] `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionTests.swift`의 `HTTPTransportResponse`·transport 준비를 T173 더블과 `TransportResponse`로 바꾼다
- [ ] T178 [S4] `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionSharedLifetimeTests.swift`를 T177와 같은 방식으로 바꾼다
- [ ] T179 [S4] `sources/Projects/Composition/Tests/App/SharedLifetimeTests.swift`의 `HTTPClient`·`StandardJSONBodyCoding` 조립을 Remote 새 init과 T173 더블로 바꾼다
- [ ] T180 [S4] `sources/Projects/Composition/Tests/Authentication/Adapters/AuthenticationRepositoryAdapterTests.swift`의 `HTTPClient`·`HTTPTransportResponse` 준비를 T174 더블로 바꾼다
- [ ] T181 [S4] `sources/Projects/Composition/Tests/Authentication/Adapters/LoginSessionRepositoryAdapterTests.swift`를 T180과 같은 방식으로 바꾼다
- [ ] T182 [S4] `sources/Projects/Composition/Tests/LearningProject/Adapters/AnswerRepositoryAdapterTests.swift`를 T175 더블로 바꾼다(method 단언이 있으면 같은 기대값을 `sources/Projects/Data/Tests/LearningProject/Remotes/AnswerRemoteTests.swift`에서 이미 검증하는지 확인하고 없으면 그 파일에 추가)
- [ ] T183 [S4] `sources/Projects/Composition/Tests/LearningProject/Adapters/BookmarkRepositoryAdapterTests.swift`를 T182와 같은 방식으로 바꾼다(대응 Data 테스트 `BookmarkRemoteTests.swift`)
- [ ] T184 [S4] `sources/Projects/Composition/Tests/LearningProject/Adapters/ExternalRepositoryLookupAdapterTests.swift`를 T182와 같은 방식으로 바꾼다(대응 Data 테스트 `sources/Projects/Data/Tests/ExternalRepository/Remotes/ExternalRepositoryRemoteTests.swift`)
- [ ] T185 [S4] `sources/Projects/Composition/Tests/LearningProject/Adapters/LearningProjectRepositoryAdapterTests.swift`를 T182와 같은 방식으로 바꾼다(대응 Data 테스트 `ProjectRemoteTests.swift`)
- [ ] T186 [S4] `sources/Projects/Composition/Tests/LearningProject/Adapters/LearningSetRepositoryAdapterTests.swift`를 T182와 같은 방식으로 바꾼다(대응 Data 테스트 `LearningSetRemoteTests.swift`)
- [ ] T187 [S4] `sources/Projects/Composition/Tests/Member/Adapters/MemberRepositoryAdapterTests.swift`를 T176 더블로 바꾼다(대응 Data 테스트 `sources/Projects/Data/Tests/Member/Remotes/MemberRemoteTests.swift`)

### 정리와 단위 검증

- [ ] T188 [no-write] [S4] `git grep -nE 'HTTPClient|HTTPTransport|StandardJSONBodyCoding|makeHTTPClient|CompositionShared' -- sources/Projects/Composition sources/Tuist tools/package-dependencies/config`가 0건, Data Remote 테스트 기대값 diff 0건, `tools/package-dependencies/bin/run.sh` 종료 코드 0을 확인하고 `make tuist` 전후 Git 상태 비교와 사용자 `build`·`test` 결과를 기록한다

**진행 점검**: 변경 파일과 검증 결과를 보고하고 U7로 진행한다.

---

## 실행 단위 U7: `DataNotification` target과 알림·푸시·Apple 로그인 전환 — integration unit (Tuist·tools·Data·Composition·docs)

**목표**: Composition의 마지막 Infrastructure 사용(로컬 알림, 푸시, 앱 델리게이트, Apple 로그인 제공자)을 Data로 옮긴다
([contracts/data-capability-contracts.md](./contracts/data-capability-contracts.md) 3·4·5장).

**분리 불가 근거**: 새 target은 manifest·`source-roots`·테스트 scheme과 함께 추가되어야 하고, Composition Adapter·
Assembly·typealias가 같은 단위에서 Data 타입으로 바뀌어야 compile된다.

**관련 변경 시나리오**: S4

**독립 검증**: quickstart 시나리오 4-1 import grep 0건

### 준비와 기반

- [ ] T189 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에 `DataNotification`(소스 `Notification`, 의존 `InfrastructureLocalNotification`, `InfrastructurePushMessaging`, `packageName: "GitItData"`)과 `DataNotificationTests`(소스 `Tests/Notification`)를 추가한다
- [ ] T190 [S4] `sources/Tuist/ProjectDescriptionHelpers/AllTestsScheme.swift`에 `DataNotificationTests`를 추가한다
- [ ] T191 [S4] `tools/package-dependencies/config/source-roots`에 `DataNotification Data/Notification`, `DataNotificationTests Data/Tests/Notification` 행을 추가한다
- [ ] T192 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의 `CompositionLearningProject`, `CompositionApp`, `CompositionShareExtension`에 `DataNotification` 의존을 추가한다
- [ ] T193 [S4] `docs/conventions/file-vocabulary/shape-vocabulary.md` Data 행에 `Clients/`(Data 내부 기술 능력 실제 구현)와 `AppDelegates/`(앱 델리게이트 위임 타입) 형태를 추가한다

### 테스트

- [ ] T194 [P] [S4] `sources/Projects/Data/Tests/Notification/TestDoubles/SpyNotificationAuthorizationClient.swift`에 Infrastructure `NotificationAuthorizationClient` 스파이 더블을 추가한다(현재 `sources/Projects/Composition/Tests/ShareExtension/TestDoubles/SpyNotificationAuthorizationClient.swift` 동작 이관)
- [ ] T195 [S4] `sources/Projects/Data/Tests/Notification/Clients/ReminderNotificationClientTests.swift`에 권한 상태 3종 변환, `isAuthorized`, 예약 요청의 식별자·제목·본문·시각 전달, 취소 위임을 T194 더블로 검증하는 테스트를 작성한다

### Data 구현

- [ ] T196 [P] [S4] `sources/Projects/Data/Notification/Contracts/LocalReminderNotifier.swift`에 `public protocol LocalReminderNotifier`를 정의한다(연산은 `sources/Projects/Composition/LearningProject/Adapters/GenerationReminderSchedulerAdapter.swift`·`NotificationAuthorizationAdapter.swift`와 `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`가 쓰는 것만)
- [ ] T197 [P] [S4] `sources/Projects/Data/Notification/Models/ReminderAuthorizationStatus.swift`에 `public enum ReminderAuthorizationStatus { authorized, declined, previouslyDenied }`를 정의한다
- [ ] T198 [P] [S4] `sources/Projects/Data/Notification/Models/ReminderNotification.swift`에 `public struct ReminderNotification(identifier:title:body:)`를 정의한다
- [ ] T199 [S4] `sources/Projects/Data/Notification/Clients/ReminderNotificationClient.swift`에 Infrastructure `NotificationAuthorizationClient`를 감싸는 `internal` 구현을 추가한다
- [ ] T200 [P] [S4] `sources/Projects/Data/Notification/Contracts/RemoteMessageReceiver.swift`에 `public protocol RemoteMessageReceiver`(`registrationToken()`, `registrationTokenRefreshes()`, `setDeviceToken(_:)`)를 정의한다(연산은 `sources/Projects/Composition/App/Assemblies/AppComposition.swift`의 `PushClientBox` 사용처와 대조해 확정)
- [ ] T201 [S4] `sources/Projects/Data/Notification/Clients/RemoteMessageClient.swift`에 Infrastructure `PushMessagingClientFactory.make()`와 `PushMessagingClient`를 감싸는 `internal` 구현을 추가한다
- [ ] T202 [P] [S4] `sources/Projects/Data/Notification/Models/NotificationAppCallbacks.swift`에 `public struct NotificationAppCallbacks(forwardDeviceToken:ingestRemoteMessagePayload:)`를 정의한다
- [ ] T203 [S4] `sources/Projects/Data/Notification/AppDelegates/NotificationAppDelegate.swift`에 Infrastructure `PushMessagingAppDelegate`를 내부에 두고 `UIApplicationDelegate` 콜백 3개와 `configure(_: NotificationAppCallbacks)`를 위임하는 `public final class NotificationAppDelegate`를 추가한다(`import UIKit`)
- [ ] T204 [S4] `sources/Projects/Data/Notification/Factories/NotificationFactory.swift`에 `public enum NotificationFactory`(`localReminderNotifier()`, `remoteMessageReceiver()`)를 추가한다
- [ ] T205 [S4] `sources/Projects/Data/Authentication/Sources/AppleSignInSource.swift`에 Infrastructure `AppleAuthorizationProvider`·`AppleCredentialStateProvider`를 내부에서 만들고 Data 모델로 결과를 돌려주는 `public actor AppleSignInSource`(연산은 `sources/Projects/Composition/Authentication/Adapters/AuthenticationRepositoryAdapter.swift`의 `authorize()`·자격 상태 조회 사용처와 대조해 확정)를 추가한다
- [ ] T206 [P] [S4] `sources/Projects/Data/Authentication/Models/AppleSignInCredential.swift`에 사용자 식별자와 identity token을 가진 `public struct AppleSignInCredential`을 정의한다
- [ ] T207 [P] [S4] `sources/Projects/Data/Authentication/Models/AppleSignInState.swift`에 Composition이 쓰는 자격 상태 case만 가진 `public enum AppleSignInState`를 정의한다
- [ ] T208 [P] [S4] `sources/Projects/Data/Authentication/Errors/AppleSignInError.swift`에 Composition의 현재 `AppleAuthorizationError` 변환 분기와 같은 결과를 낼 수 있는 case를 가진 `public enum AppleSignInError`를 정의한다
- [ ] T209 [S4] `sources/Projects/Data/Tests/Authentication/Sources/AppleSignInSourceTests.swift`에 Infrastructure 오류·상태가 T207·T208로 변환되는지 검증하는 테스트를 작성한다(실제 Apple 인증 호출이 필요한 사례는 제외)

### Composition 구현

- [ ] T210 [S4] `sources/Projects/Composition/LearningProject/Adapters/GenerationReminderSchedulerAdapter.swift`를 `any LocalReminderNotifier`와 `ReminderNotification`으로 바꾼다
- [ ] T211 [S4] `sources/Projects/Composition/LearningProject/Adapters/NotificationAuthorizationAdapter.swift`를 `any LocalReminderNotifier`와 `ReminderAuthorizationStatus`로 바꾸고 Domain `NotificationAuthorizationOutcome` 변환 결과를 유지한다
- [ ] T212 [S4] `sources/Projects/Composition/LearningProject/Assemblies/GenerationReminderAssembly.swift`의 `localNotificationClient` 인자를 `reminderNotifier: (any LocalReminderNotifier)?`(nil이면 `NotificationFactory.localReminderNotifier()`)로 바꾼다
- [ ] T213 [S4] `sources/Projects/Composition/App/Factories/PushNotificationAppDelegate.swift`의 typealias 대상을 `DataNotification.NotificationAppDelegate`로 바꾼다
- [ ] T214 [S4] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`의 `PushNotificationCallbacks`·`PushMessagingClient`·`PushMessagingClientFactory` 사용을 `NotificationAppCallbacks`·`any RemoteMessageReceiver`·`NotificationFactory`로 바꾸고 `configureAppDelegate`·`deviceTokenRefreshes`·`registerCurrentDevice` 동작을 유지한다
- [ ] T215 [S4] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`의 `localNotificationClient` 인자를 `reminderNotifier: (any LocalReminderNotifier)?`로 바꾼다
- [ ] T216 [S4] `sources/Projects/Composition/Authentication/Adapters/AuthenticationRepositoryAdapter.swift`의 Apple 제공자·`AppleAuthorizationError`·`AppleCredentialState` 사용을 `AppleSignInSource`·`AppleSignInError`·`AppleSignInState`로 바꾸고 Domain 오류 결과를 유지한다
- [ ] T217 [S4] `sources/Projects/Composition/Authentication/Assemblies/AuthenticationAssembly.swift`에서 `AppleAuthorizationProvider()`·`AppleCredentialStateProvider()` 생성을 `AppleSignInSource()`로 바꾼다
- [ ] T218 [S4] `sources/Projects/Composition/Tests/ShareExtension/TestDoubles/SpyLocalReminderNotifier.swift`에 `LocalReminderNotifier` 스파이 더블을 추가하고 `sources/Projects/Composition/Tests/ShareExtension/TestDoubles/SpyNotificationAuthorizationClient.swift`를 삭제한다
- [ ] T219 [S4] `sources/Projects/Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift`의 `localNotificationClient:` 준비를 T218 더블과 `reminderNotifier:`로 바꾼다
- [ ] T220 [S4] `sources/Projects/Composition/Tests/App/SharedLifetimeTests.swift`의 Apple 제공자 생성을 `AppleSignInSource()`로 바꾼다
- [ ] T221 [S4] `sources/Projects/Composition/Tests/Authentication/Adapters/AuthenticationRepositoryAdapterTests.swift`의 Apple 제공자 생성을 `AppleSignInSource()`로 바꾸고 기대값을 유지한다
- [ ] T222 [S4] `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`의 공개 표면 기대값을 T214 변경과 대조해 이름이 바뀐 공개 멤버가 있으면 갱신한다
- [ ] T223 [S4] `sources/Projects/Data/Tests/Authentication/SensitiveValueExposureTests.swift`가 새 Data 공개 타입(`AppleSignInCredential`)의 민감값 노출 규칙을 포함하는지 확인하고 필요하면 사례를 추가한다

### 정리와 단위 검증

- [ ] T224 [no-write] [S4] `git grep -lE '^\s*(@testable\s+)?import\s+Infrastructure' -- sources/Projects ':!sources/Projects/Data' ':!sources/Projects/Infrastructure'`가 0건이고 `sources/Projects/App/GitIt/GitItApp.swift` diff가 없는지 확인하며 `make tuist` 전후 Git 상태 비교와 사용자 `build`·`test` 결과를 기록한다

**진행 점검**: 변경 파일과 검증 결과를 보고하고 U8로 진행한다.

---

## 실행 단위 U8: 의존성 규칙 강제 — integration unit (Tuist·tools·docs)

**목표**: Infrastructure에 의존할 수 있는 패키지를 Data로 한정하고 자동 검사가 강제한다
([contracts/dependency-rules.md](./contracts/dependency-rules.md) 1·2장).

**분리 불가 근거**: 검사기는 `allowed-dependencies`와 `docs/architecture.md` 3.1 표의 일치(`table-mismatch`)와 manifest
`.from<패키지>` 선언(`manifest-package`)을 함께 판정하므로 세 파일을 같은 단위에서 바꿔야 통과한다.

**관련 변경 시나리오**: S4

**독립 검증**: quickstart 시나리오 4-1·4-2

### 테스트

- [ ] T225 [S4] `tools/package-dependencies/tests/test-package-dependencies.sh`의 fixture 규칙 복사(현재 31행·42행)를 `Composition: Domain Data`로 바꾸고, 정상 fixture의 Composition Infrastructure import(현재 238~240행)와 `.fromInfrastructure` 선언(현재 105행)을 제거하며, Composition Swift 파일의 Infrastructure import가 `import-package` 위반·manifest `.fromInfrastructure`가 `manifest-package` 위반으로 보고되는 회귀 사례를 추가한다

### 구현

- [ ] T226 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`에서 남은 모든 `.fromInfrastructure(...)` 의존을 제거한다
- [ ] T227 [S4] `tools/package-dependencies/config/allowed-dependencies`의 `Composition: Domain Data Infrastructure`를 `Composition: Domain Data`로 바꾼다
- [ ] T228 [S4] `docs/architecture.md` 3.1 의존 표의 Composition 행을 `Domain, Data`로 바꾸고 7.1 금지 의존성 목록에 `Composition → Infrastructure`와 `App → Infrastructure`를 추가한다
- [ ] T229 [S4] `docs/assets/package-dependency-graph.dot`에서 `Composition -> Infrastructure` 간선을 제거한다
- [ ] T230 [S4] `docs/assets/package-dependency-graph.svg`를 T229 `.dot`에서 다시 생성한다(`dot` 명령이 없으면 파일을 바꾸지 않고 미갱신 사실을 진행 보고와 PR 기록 대상으로 남긴다)

### 정리와 단위 검증

- [ ] T231 [no-write] [S4] quickstart 시나리오 4-1의 manifest grep 0건, `tools/package-dependencies/bin/run.sh` 종료 코드 0, `./tools/script-tests/bin/run.sh`와 `./tools/script-verification/bin/run.sh` 통과를 확인하고 `make tuist` 전후 Git 상태 비교와 사용자 `build` 결과를 기록한다

**진행 점검**: 변경 파일과 검증 결과를 보고하고 U9로 진행한다.

---

## 실행 단위 U9: Home 생성 결과 관찰 재개 — Feature 단일 패키지

**목표**: Home 재진입 시 생성 결과 관찰을 다시 시작하고 보이는 동안 관찰을 하나로 유지한다
([contracts/home-generation-observation.md](./contracts/home-generation-observation.md)).

**순서 근거**: Feature는 Domain에만 의존하고 U4에서 `TrackGenerationUseCase` API가 바뀌지 않아 U1~U8과 독립이다.
아키텍처 위상 순서(Composition 뒤 Feature)에 맞춰 이 위치에 둔다.

**소유 경로**: `sources/Projects/Feature/Home/HomeFeature.swift`, `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift`,
`sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubTrackGenerationUseCase.swift`

**관련 변경 시나리오**: S5

**독립 검증**: quickstart 시나리오 5

### 테스트

- [ ] T232 [S5] `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubTrackGenerationUseCase.swift`가 구독 종료를 반영한 현재 구독 수와 구독 직후 저장된 상태 전달을 제공하는지 확인하고, 없으면 `activeSubscriptionCount()`와 `store(_: GenerationState)` 보조 연산을 추가한다(기존 연산 동작 유지)
- [ ] T233 [S5] `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift`의 12행 테스트를 `task가 다시 전달되면 이전 생성 결과 관찰을 대체해 하나만 유지한다`로 바꾸고, `화면을 벗어났다 돌아오면 생성 결과 관찰을 다시 시작해 결과를 반영한다`, `화면을 벗어난 동안 끝난 생성 결과를 돌아왔을 때 반영한다` 테스트를 추가해 현재 구현에서 실패하는지 확인한다

### 구현

- [ ] T234 [S5] `sources/Projects/Feature/Home/HomeFeature.swift`에서 `State.GenerationOutcomeObservation`과 `generationOutcomeObservation` 프로퍼티·조건 분기를 제거하고, `CancelID.generationOutcomes`를 추가해 `.view(.task)`마다 `startGenerationOutcomeObservation()`을 `.cancellable(id: CancelID.generationOutcomes, cancelInFlight: true)`로 시작한다

### 정리와 단위 검증

- [ ] T235 [no-write] [S5] `git grep -n 'generationOutcomeObservation' -- sources/Projects/Feature`가 0건이고 `HomeFeatureLoadTests.swift`의 "복귀 task는 재조회하지 않는다" 기대값이 바뀌지 않았는지 확인하며 사용자 Feature `test` 결과를 기록한다

**진행 점검**: 변경 파일과 검증 결과를 보고하고 U10으로 진행한다.

---

## 실행 단위 U10: 규칙 문서 정합 — docs

**목표**: 아키텍처·패키지 규칙·추상화 컨벤션·점검 결과 문서를 이 기능의 코드와 일치시킨다
([contracts/dependency-rules.md](./contracts/dependency-rules.md) 3장).

**관련 변경 시나리오**: S1, S2, S3, S4

**독립 검증**: 아래 문서의 옛 이름·옛 의존 설명 grep 0건

### 구현

- [ ] T236 [S4] `docs/architecture.md`의 패키지 책임 설명(현재 11행·22행·35행), 3.3 Data↔Infrastructure 예시(현재 149~172행), 6장 외부 기술 사용 표(현재 265행), 9장 D-ARCH-004 후속 작업 설명(현재 364~369행)을 Data 역할 계약·생성 진입점 구조로 교정한다
- [ ] T237 [P] [S4] `docs/package-rules/composition.md`의 Infrastructure 객체 조립·진입점 호출·구현 선택 설명(현재 9·19·21·57·63·66~69·79~80행)을 Data 생성 진입점과 Data 계약 주입으로 교정한다
- [ ] T238 [P] [S4] `docs/package-rules/data.md`에 Data가 기술 능력 역할 계약과 생성 진입점을 소유하고 target 간 Infrastructure 타입은 `package` 접근 수준으로만 주고받는다는 규칙을 추가한다(현재 11·19·21행 주변)
- [ ] T239 [P] [S4] `docs/package-rules/infrastructure.md`에 Infrastructure 공개 API의 프로젝트 내 소비자가 Data뿐임을 명시한다(현재 11·20행)
- [ ] T240 [P] [S4] `docs/package-rules/app.md`의 허용 의존성 설명(현재 22행)에 Infrastructure 직접 의존 금지를 명시한다
- [ ] T241 [P] [S4] `docs/conventions/abstraction/protocol-criteria.md`에 "Composition이 Infrastructure에 의존할 수 없어 Data가 기술 능력 계약을 소유하고 Composition·테스트가 대체 구현을 주입한다"는 근거와 예시(`KeyValueStorage`, `SecureValueStorage`, `RequestTransport`, `LocalReminderNotifier`, `RemoteMessageReceiver`)를 추가한다
- [ ] T242 [P] [S4] `docs/conventions/abstraction/test-double-injection.md`의 원칙(현재 5~6행), 주입 대상 표(현재 18~23행), 예시(현재 31~40행)를 Data 계약 주입 기준으로 교정한다
- [ ] T243 [P] [S1] `docs/conventions/abstraction/structure-baseline.md`의 지표 표와 3.1 목록(현재 45~59행)에서 `GenerationStateRepository`·`PendingGenerationReminders`·`GenerationStateStore`를 제거하고 `PendingGenerationRepository`와 Data 역할 계약 5개를 추가해 개수를 다시 센다
- [ ] T244 [P] [S1] `docs/review/domain-data-infra-design-review.md`의 DS-02·DS-03·DS-05·DS-06·DS-09·DS-11 처리 결과와 이관 코드·`HTTPMethod` 관련 설명을 이 기능 결과로 갱신한다
- [ ] T245 [P] [S4] `sources/Projects/Infrastructure/Authentication/README.md`에서 Composition을 소비자로 설명하는 문장이 있으면 Data 내부 구현 소비로 교정한다

### 정리와 단위 검증

- [ ] T246 [no-write] `git grep -nE 'Composition[^\n]*Infrastructure 객체|GenerationStateRepository|PendingGenerationReminders\b|GenerationStateStore\b|HTTPUserRemote|makeHTTPClient' -- docs/architecture.md docs/package-rules docs/conventions`가 이 기능이 교정한 설명 기준 0건인지 확인한다

**진행 점검**: 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 진행한다.

---

## 전체 완료 검증

**선행 조건**: U10의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할 마지막 커밋 단위를 아직 commit하지 않은
상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 U10의 마지막 커밋 단위에 배정한다. 모든 검증과 필수 `after_implement` hook을
마친 뒤 그 단위를 최종 commit한다. 이미 파일 변경 단위가 모두 commit된 단순 재개에서는 `tasks.md` 완료 표시를 위한 별도
최종 검증 단위를 둔다. 읽기 전용 전체 검증은 반복 승인 없이 같은 실행에서 이어서 수행한다.

- [ ] T247 [no-write] [S1] quickstart 시나리오 1 전체를 실행하고 계약 문서 5장의 테스트 파일이 모두 존재하는지 확인한다
- [ ] T248 [no-write] [S2] quickstart 시나리오 2를 실행한다
- [ ] T249 [no-write] [S3] quickstart 시나리오 3을 실행한다
- [ ] T250 [no-write] [S4] quickstart 시나리오 4의 1~4를 실행한다
- [ ] T251 [no-write] [S5] quickstart 시나리오 5를 실행한다
- [ ] T252 [no-write] `make tuist` 전후 Git 상태를 비교하고, 사용자가 실행한 `build`·`compile`·`test`와 `./tools/script-verification/bin/run.sh` 결과를 기록한다(결과가 없으면 미검증으로 보고)

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- 채택 순서: U1 → U2 → U3 → U4 → U5 → U6 → U7 → U8 → U9 → U10 → 전체 완료 검증.
- 근거: 아키텍처 3.1 의존 표의 위상 순서 Infrastructure → Domain → Data → Composition → Feature → App.
  - U1: Infrastructure 공개 함수 제거와 이를 부르는 Data·Composition 코드를 함께 바꾼다.
  - U2: Data만 바꾸고 Composition 공개 사용처가 없어 먼저 둔다.
  - U3: U4·U5·U6·U7이 쓰는 `DataShared` target을 만든다.
  - U4: U3의 `KeyValueStorage`를 사용한다. U4를 U5보다 앞에 두어 생성 대기 저장이 처음부터 새 계약을 쓰게 한다.
  - U5·U6·U7: Composition의 Infrastructure 사용을 기술 능력별로 제거하며 서로 같은 Composition 파일
    (`AppComposition.swift`, `ShareExtensionComposition.swift`, `AuthenticationAssembly.swift`)을 바꾸므로 순차 실행한다.
  - U8: Composition의 Infrastructure import와 사용이 모두 사라진 뒤에만 manifest 의존과 허용 설정을 제거할 수 있다.
  - U9: Domain 뒤 Feature. U1~U8과 코드 의존이 없다.
  - U10: 코드 결과를 문서에 반영한다.
- 각 단위 끝에서 변경 파일과 검증 결과를 보고하고 반복 승인 없이 다음 단위로 진행한다.
- 명시적 승인이 필요한 경우:
  - T112·T196·T200·T205·T208에서 계약 문서와 다른 공개 이름이나 오류 case가 필요해질 때(계약 변경 = 새 설계 결정)
  - T230에서 SVG 생성 도구 설치가 필요할 때
  - 저장 좌표(namespace·key·값 형식)를 바꿔야 하는 상황이 발견될 때(FR-009·FR-023 위반)
  - 사용자 소유 기존 변경(현재 `docs/conventions/abstraction/structure-baseline.md`, `docs/review/domain-data-infra-design-review.md`의
    미커밋 수정, `specs/035-domain-data-infra-design-review/`의 미추적 파일)을 커밋에 포함해야 할 때

### 변경 시나리오 추적성

| 시나리오 | 작업 | 독립 수용 기준 |
|----------|------|----------------|
| S1 생성 대기 Repository | T070~T107, T243, T244, T247 | 같은 저장소 공유 기록·흡수, 동시 시작 중복 차단, 생성 중 목록 제외, 등록 실패 해제 테스트 통과와 옛 계약 grep 0건 |
| S2 이관 코드 제거 | T001~T014, T248 | 이관 식별자 grep 0건, 현재 형식 저장 테스트 기대값 불변 |
| S3 Data 기술 재구현 제거 | T015~T040, T249 | method 재선언·변환 grep 0건, Endpoint·Remote 테스트 기대값 불변 |
| S4 Infrastructure 의존의 Data 한정 | T041~T069, T108~T231, T236~T242, T245, T250 | Data 밖 Infrastructure import·manifest 0건, 검사기 통과와 위반 회귀 사례, Data 공개 선언 기술 타입 0건 |
| S5 Home 관찰 재개 | T232~T235, T251 | 재진입 반영·이탈 중 결과 반영·단일 관찰 테스트 통과 |

### 실행 단위 내부 실행

- U4·U9는 테스트 작업을 구현보다 먼저 수행하고 예상한 이유로 실패하는지 확인한다.
- `[P]`는 현재 실행 단위 안의 서로 다른 파일에만 사용했다. 같은 파일을 바꾸는 작업(예: `AuthenticationAssembly.swift`를
  바꾸는 T130·T162·T217)은 서로 다른 단위이므로 순차 실행한다.
- 병렬 실행 예시(U2): T017, T018, T019, T020은 T015 완료 뒤 동시에 진행할 수 있다. T031~T039도 구현 작업 완료 뒤
  동시에 진행할 수 있다.
- 병렬 실행 예시(U6): T149~T152는 동시에 진행하고, T156~T161은 T154 완료 뒤 동시에 진행할 수 있다. T173~T176은 서로
  다른 테스트 target 파일이라 동시에 진행할 수 있다.
- `/speckit-implement`는 파일을 수정하기 전에 현재 실행 단위의 미완료 작업을 하나의 목적과 독립적인 rollback 경계를 갖는
  커밋 단위로 묶는다. 구현과 직접 관련된 테스트는 같은 단위에 둘 수 있지만 target 추가, 계약 전환, 문서 교정처럼 목적이
  다르면 분리할 수 있다. 단, 분리한 커밋이 compile되지 않으면 같은 커밋으로 묶는다.
- 각 커밋 단위는 포함 작업 ID, 정확한 파일 경로, 검증과 커밋 메시지를 먼저 제시한다. 단위의 검증과 `[X]` 표시를 완료한 뒤
  해당 파일과 이 `tasks.md`만 stage·commit하고, 커밋 성공을 확인하기 전에는 다음 단위를 시작하지 않는다.
- 단위를 시작할 때 작업 ID와 파일 경로를 snapshot하며 checkbox가 `[X]`가 된 뒤에도 해당 단위가 commit되거나 중단될 때까지
  같은 범위를 유지한다.
- 마지막 단위(U10)는 전체 완료 검증과 필수 `after_implement` hook이 끝날 때까지 commit하지 않는다.

## 구현 전략

1. 먼저 중단 단위와 tasks.md 전체 diff를 분류하고 blob hash와 diff를 기준선으로 고정한다. 재개 단위가 없으면 U1부터 시작한다.
2. 그 실행 단위의 미완료 작업을 논리적 커밋 단위로 설계한다.
3. 각 단위의 구현·검증·완료 표시·커밋을 순서대로 완료하고 생성된 커밋을 확인한다.
4. 실행 단위가 커밋되면 변경 파일, 검증 결과와 커밋을 진행 상황으로 보고하고 다음 단위로 이어간다.
5. 위 "명시적 승인이 필요한 경우"가 나타나면 변경을 시작하기 전에 중단하고 승인을 요청한다.
6. U10 뒤 전체 읽기 전용 검증과 시나리오 수용 검증, 필수 `after_implement` hook을 실행하고 결과를 재검증한 뒤 마지막
   단위를 최종 commit한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 최소 가치 범위는 U1~U4(S2·S3·S1)다. S4·S5는 이어서 같은 범위로 진행한다.
- 문제 해결과 암묵지 기록을 구현 작업 ID로 생성하지 않는다.
