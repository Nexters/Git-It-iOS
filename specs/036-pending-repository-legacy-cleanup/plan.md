# 구현 계획: 레거시 이관 코드 제거, 생성 대기 Repository 도입, Infrastructure 의존의 Data 한정과 Home 생성 결과 관찰 재개

**Git-flow 유형**: `feature`

**브랜치**: `feature/pending-repository-legacy-cleanup`

**날짜**: 2026-09-17 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/036-pending-repository-legacy-cleanup/spec.md`의 기능 명세

## 요약

이 기능은 네 가지 구조 변경과 하나의 동작 결함 수정을 한 브랜치에서 수행한다.

1. **이관 코드 제거**: 생성 상태 이관과 세션 Keychain 이관 코드, 옛 DTO, 옛 Keychain 생성 진입점을 지운다.
2. **Data 기술 재구현 제거**: Data의 `HTTPMethod`와 Endpoint 중첩 `Method`, 문자열 method, method 변환 함수를
   지우고 Remote 내부에서 Infrastructure 요청을 직접 만든다.
3. **생성 대기 Repository**: Domain `PendingGenerationRepository` 하나가 생성 진행 기록과 완료 알림 대기를
   소유한다. 생성 요청과 목록 조회는 이 계약으로 대기를 확인한다. Data `LocalPendingGenerationStore` actor가
   읽기·변환·기록을 직렬화하고 상태 변화를 구독자에게 보낸다. 저장 좌표는 바꾸지 않는다.
4. **Infrastructure 의존의 Data 한정**: Data에 `DataShared`(키 기반 값 저장, 보안 저장, 요청 전송)와
   `DataNotification`(알림 권한·예약, 푸시 수신, 앱 델리게이트) target을 추가한다. Composition은 Data 계약과
   생성 진입점만 사용한다. 허용 의존성 설정·Tuist manifest·아키텍처 문서를 `Composition: Domain Data`로 맞춘다.
5. **Home 관찰 재개**: 관찰 상태 플래그를 없애고 `.task`마다 취소 가능한 관찰 Effect를 시작한다.

결정 근거는 [research.md](./research.md), 공개 모양은 [contracts/](./contracts/), 저장 좌표는
[data-model.md](./data-model.md), 검증 절차는 [quickstart.md](./quickstart.md)를 따른다.

## 기술 맥락

**언어/버전**: Swift 6 컴파일러(Xcode 26), target 설정 `SWIFT_VERSION` 5.0
(`sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift:29`), POSIX sh(검사 도구)

**주요 의존성**: Tuist, The Composable Architecture(Feature·App), Firebase Messaging(Infrastructure
PushMessaging 내부), Foundation `Synchronization`(`Mutex`)

**저장소**: App Group UserDefaults(`group.com.nexters.hytime.gitit`), 기기 UserDefaults, Keychain(공유 access
group `6924CABL23.com.nexters.hytime.gitit.shared`)

**테스트**: Swift Testing(`@Suite`, `@Test`, `#expect`), TCA `TestStore`, POSIX sh 회귀 테스트
(`tools/script-tests`)

**대상 플랫폼**: iOS 26.0 이상(앱과 Share Extension)

**프로젝트 유형**: 모바일 앱(Tuist 멀티 패키지)

**성능 목표**: 사용자 체감 변화 없음. 생성 대기 조회는 호출마다 App Group 저장소를 읽으며 항목은 수십 개 이하
(알림 대기 상한 32, 생성 기록은 보존 1시간)

**제약 조건**:
- 저장 좌표·값 형식 불변(FR-009·FR-023)
- Data 공개 선언에 기술 이름·Infrastructure 타입 금지(D-ARCH-004, FR-020)
- Infrastructure 의존 target은 Data와 Infrastructure 자신뿐(FR-018)
- 빌드·컴파일·테스트 실행은 사용자가 직접 수행(사용자 운영 방침)

**규모/범위**:
- Composition Infrastructure import 제거: 프로덕션 16개 파일, 테스트 16개 파일(조사 결과)
- Data 공개 initializer 전환 16곳
- Domain 계약 2개 → 1개, Data 계약 1개 제거, Data 역할 계약 5개와 target 2개 추가
- 문서 약 15개 파일

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 점검 | 0단계 전 | 1단계 후 |
|------|------|----------|----------|
| 1. 명시적인 경계 | 새 target 의존을 Tuist에 명시하고 순환이 없다(`DataShared` ← 기능 Data target, `DataNotification`은 독립). Composition → Infrastructure 제거로 의존 표가 좁아진다 | 통과 | 통과 |
| 2. 상태와 데이터 안전성 | 생성 대기 상태의 소유자는 프로세스당 `LocalPendingGenerationStore` 1개(actor). 스트림 구독 등록·해제 경합 제거. 저장 좌표 불변. 취소 경로: Home 관찰은 `.task` 취소, 결과 관찰은 프로세스 수명 | 통과 | 통과 |
| 3. 검증 가능한 변경 | 단위마다 테스트·grep 검증을 두고 전체 검증 명령을 [quickstart.md](./quickstart.md)에 기록. 문서는 구조 결정이 바뀌는 곳만 갱신(아키텍처 3.1·3.3·7.1). 예외(UIKit import, 추상화 근거 추가)는 복잡성 추적과 PR에 기록 | 통과 | 통과 |
| 4. 스킬별 수정 경로 | 이 명령은 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 수정 | 통과 | 통과 |
| 5·6. Spec-Kit 범위·한국어 산출물 | 내부 변경과 사용자 결함 수정의 실제 이해관계자를 명세에 기록. 산출물은 한국어, 식별자는 원문 | 통과 | 통과 |
| 7. 위험 기반 실행 단위 | 아키텍처 3.1 위상 순서를 따르고 공개 API 이전은 integration unit으로 묶음(아래 "실행 단위") | 통과 | 통과 |
| 8. Git-flow 브랜치 | 기존 브랜치 `feature/pending-repository-legacy-cleanup` 재사용 | 통과 | 통과 |
| 9. 세션 지식 기록 | 기록 조건 충족 시 전용 스킬로 별도 수행. 계획 작업에 포함하지 않음 | 해당 없음 | 해당 없음 |
| 10. 책임과 문맥에 따른 네이밍 | Domain `PendingGenerationRepository`(Repository 접미어 허용, load/save 없음). Data 계약 이름에 HTTP·Keychain·UserDefaults·URLSession·Firebase 없음. rename과 설계 변경을 같은 단위에 섞지 않음(기존 이름 유지 가능한 곳은 유지) | 통과 | 통과 |

**브랜치 네임스페이스**: `feature/` 네임스페이스의 기존 브랜치를 `/speckit-specify`가 재사용 상태로 확인했다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`,
`contracts/**`만 수정했다. 구현 파일 경로는 아래 실행 단위에 기록하고 `tasks.md`가 작업으로 옮긴다.

**세션 지식 기록**: Constitution 원칙 9를 따른다.

**Git 실행 직렬화**: 같은 checkout에서 commit·pre-commit·staged formatter 체인은 하나만 실행한다.

**커밋 단위 구현**: 아래 실행 단위 하나가 하나 이상의 커밋 단위가 된다. 각 단위는 작업 ID, 정확한 파일,
검증, 커밋 메시지를 `/speckit-implement` 시점에 확정한다.

**책임 기반 네이밍**: [docs/conventions/naming.md](../../docs/conventions/naming.md)와 D-ARCH-004를 적용했다.

**실행 단위 진행**: 아래 "실행 단위"를 따른다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/036-pending-repository-legacy-cleanup/
├── spec.md
├── plan.md                                   # 이 파일
├── research.md                               # 결정 R1~R13
├── data-model.md                             # 모델·상태 전이·저장 좌표
├── quickstart.md                             # 검증 절차
├── contracts/
│   ├── pending-generation-repository.md      # Domain 계약·Data 저장·Composition 연결
│   ├── data-capability-contracts.md          # DataShared·DataNotification 계약과 공개 API 전환
│   ├── dependency-rules.md                   # 허용 의존성·검사 기대값·문서 갱신 위치
│   └── home-generation-observation.md        # Home 관찰 lifecycle
├── checklists/requirements.md
└── tasks.md                                  # /speckit-tasks 산출물(아직 없음)
```

### 소스 코드(저장소 루트)

```text
sources/
├── Tuist/ProjectDescriptionHelpers/
│   ├── Projects/DataModuleName.swift              # DataShared·DataNotification target 추가
│   ├── Projects/CompositionModuleName.swift       # .fromInfrastructure 제거, Data 신규 target 의존
│   └── AllTestsScheme.swift                       # 새 테스트 target 추가
└── Projects/
    ├── Infrastructure/Authentication/Keychain/Stores/AppGroupKeychainStore.swift   # makeLegacy 제거
    ├── Domain/LearningProject/
    │   ├── Contracts/PendingGenerationRepository.swift      # 신규
    │   ├── Contracts/GenerationStateRepository.swift        # 제거
    │   ├── Contracts/PendingGenerationReminders.swift       # 제거
    │   └── UseCases/{CreateLearningProject,FetchLearningProjects,TrackGeneration,ScheduleGenerationReminder}/
    ├── Data/
    │   ├── Shared/{Contracts,Stores,Remotes,Factories,Errors,Models}/        # 신규 target(형태 폴더는 구현 시 확정)
    │   ├── Notification/{Contracts,Clients,AppDelegates,Factories,Models}/   # 신규 target
    │   ├── Authentication/{Codings,Stores,Remotes,Endpoints,Layouts}/        # 계약 주입 전환, Migrations/ 제거
    │   ├── ExternalRepository/{Remotes,Requests}/
    │   ├── LearningProject/{Stores,Codings,Contracts,DTOs,Endpoints,Models,Remotes}/
    │   ├── LegalConsent/Stores/
    │   ├── Member/{Endpoints,Remotes,Stores}/
    │   └── Tests/{Shared,Notification,Authentication,ExternalRepository,LearningProject,LegalConsent,Member}/
    ├── Composition/{Shared,Authentication,LearningProject,Member,App,ShareExtension}/ 와 Tests/
    ├── Feature/Home/HomeFeature.swift, Feature/Tests/Home/Home/
    └── App/                                        # 코드 변경 없음 예상(typealias 이름 유지)
tools/package-dependencies/{config/allowed-dependencies,config/source-roots,tests/test-package-dependencies.sh}
docs/{architecture.md,assets/package-dependency-graph.*,package-rules/*.md,conventions/**,review/domain-data-infra-design-review.md}
```

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 유지하고 Data 패키지 안에 target 2개를 추가한다. Feature 폴더
구성은 바꾸지 않는다.

## 패키지 위상 순서

[아키텍처 문서](../../docs/architecture.md) 3.1 의존 표 기준 위상 순서:
Infrastructure → Domain → Data → Composition → Feature → App.

| 패키지 | 이 기능의 변경 | 순서 근거 |
|--------|----------------|-----------|
| Infrastructure | `makeLegacy()` 제거만 | Composition·Data가 참조를 먼저 끊어야 하므로 U1 integration unit에 포함 |
| Domain | 생성 대기 계약·UseCase | Data·Composition보다 먼저. 계약 제거가 Composition compile을 깨므로 U4 integration unit |
| Data | 이관 제거, 기술 재구현 제거, 계약·target 추가 | Composition보다 먼저. 공개 initializer 변경은 Composition과 integration unit |
| Composition | 조립·Adapter·테스트 전환 | Data 뒤 |
| Feature | Home 관찰 | Domain 뒤. Composition과 서로 의존하지 않으며 `TrackGenerationUseCase` API가 바뀌지 않아 U9로 분리 |
| App | 변경 없음 예상 | Composition 공개 표면 변경 시 compile 확인만 |
| tools·docs | 검사 설정·fixture·규칙 문서 | 코드 의존 제거 뒤(U8·U10) |

## 실행 단위

각 단위는 끝날 때 단위 검증을 통과해야 하며, 같은 기능 범위의 다음 단위는 반복 승인 없이 진행한다.
빌드·테스트 명령은 사용자가 실행한다는 운영 방침에 따라, 구현 단계는 정적 검증(grep, 검사 도구)을 수행하고
빌드·테스트 결과는 사용자 실행 결과로 기록한다.

### U1. 이관 코드 제거 — integration unit (Infrastructure·Data·Composition)

- 분리 불가 근거: Data 공개 타입(`GenerationStateMigration`, `SessionStorageMigration`)과 Infrastructure 공개
  함수(`makeLegacy()`)를 지우면 Composition 조립 코드가 같은 커밋에서 바뀌어야 compile된다.
- 파일:
  - `sources/Projects/Data/LearningProject/Stores/GenerationStateMigration.swift`(삭제)
  - `sources/Projects/Data/LearningProject/DTOs/GenerationState/LegacyGenerationProgressDTO.swift`(삭제)
  - `sources/Projects/Data/LearningProject/DTOs/GenerationState/LegacyRepositoryCreationStateDTO.swift`(삭제)
  - `sources/Projects/Data/LearningProject/Stores/LocalGenerationStateStore.swift`(migration 인자·상태 제거)
  - `sources/Projects/Data/Authentication/Migrations/SessionStorageMigration.swift`(삭제, 폴더 제거)
  - `sources/Projects/Data/Tests/LearningProject/Stores/GenerationStateMigrationTests.swift`(삭제)
  - `sources/Projects/Data/Tests/LearningProject/Stores/LocalGenerationStateStoreTests.swift`(이관 사례 제거)
  - `sources/Projects/Data/Tests/Authentication/Migrations/SessionStorageMigrationTests.swift`(삭제, 폴더 제거)
  - `sources/Projects/Infrastructure/Authentication/Keychain/Stores/AppGroupKeychainStore.swift`
  - `sources/Projects/Composition/Authentication/Assemblies/AuthenticationAssembly.swift`
  - `sources/Projects/Composition/App/Assemblies/AppComposition.swift`
  - `sources/Projects/Composition/LearningProject/Assemblies/LearningProjectAssembly.swift`
  - Infrastructure·Composition 테스트 중 `makeLegacy`·`migrateSessionKeychain` 참조(구현 시 grep으로 확정)
  - `docs/conventions/file-vocabulary/shape-vocabulary.md`(Data 행 `Migrations/` 제거)
- 검증: quickstart 시나리오 2 grep 0건. 사용자 빌드·테스트.
- 커밋 태그: `[Remove]`

### U2. Data 기술 재구현 제거 — Data 단일 패키지

- 파일:
  - `sources/Projects/Data/LearningProject/Models/HTTPMethod.swift`(삭제)
  - `sources/Projects/Data/LearningProject/Endpoints/{LearningProjectRequest,ProjectEndpoint,LearningSetEndpoint,AnswerEndpoint,BookmarkEndpoint,QuizGenerationEndpoint,AuthorizedRequestHeaders}.swift`
  - `sources/Projects/Data/LearningProject/Remotes/{LearningProjectRequestExecutor,ProjectRemote}.swift`
  - `sources/Projects/Data/Authentication/Endpoints/AuthenticationEndpoint.swift`, `Authentication/Remotes/AuthenticationRemote.swift`
  - `sources/Projects/Data/Member/Endpoints/MemberEndpoint.swift`, `Member/Remotes/MemberRemote.swift`
  - `sources/Projects/Data/ExternalRepository/Requests/GitHubRepositoryRequest.swift`, `ExternalRepository/Remotes/ExternalRepositoryRemote.swift`
  - Data 테스트: `Tests/*/Endpoints/*Tests.swift`, `Tests/ExternalRepository/Requests/GitHubRepositoryRequestTests.swift`,
    `Tests/*/Remotes/*Tests.swift`(method 단언 이동 시)
- Composition은 `GitHubRepositoryRequest(owner:repository:)`만 사용하므로 영향 없음
  (`Composition/LearningProject/Adapters/ExternalRepositoryLookupAdapter.swift:21`).
- 검증: quickstart 시나리오 3. 사용자 빌드·테스트.
- 커밋 태그: `[Refactor]`

### U3. `DataShared` target과 키 기반 값 저장 전환 — integration unit (Data·Composition·Tuist·tools)

- 분리 불가 근거: Data 저장 타입 공개 initializer가 `UserDefaults`/`UserDefaultsStore`에서 `KeyValueStorage`로
  바뀌면 Composition 조립·테스트가 함께 바뀌어야 compile되고, 새 target은 manifest·`source-roots`와 함께 추가해야
  검사기가 통과한다.
- 파일:
  - `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`, `AllTestsScheme.swift`
  - `tools/package-dependencies/config/source-roots`
  - `sources/Projects/Data/Shared/**`(신규: `KeyValueStorage`, 실제 구현, `StorageLocation`, `StorageFactory`)
  - `sources/Projects/Data/Tests/Shared/**`(신규: 실제 구현의 키·형식 테스트)
  - `sources/Projects/Data/Authentication/Codings/SharedSessionStateMarkerCoding.swift`
  - `sources/Projects/Data/LegalConsent/Stores/LocalPolicyConsentStore.swift`
  - 해당 Data 테스트와 `TestDoubles/InMemoryKeyValueStorage.swift`
  - `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`(`DataShared` 의존 추가)
  - `sources/Projects/Composition/Authentication/Assemblies/{AuthenticationAssembly,SessionAvailabilityAssembly}.swift`,
    `Composition/Authentication/Adapters/LoginSessionRepositoryAdapter.swift`,
    `Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift` 및 관련 테스트
    (`Tests/Authentication/Adapters/PolicyConsentRepositoryAdapterTests.swift` 등, 구현 시 grep으로 확정)
- 제외: `LocalGenerationStateStore`와 `PendingGenerationReminderCoding`은 U4에서 `LocalPendingGenerationStore`로
  대체되므로 이 단위에서 전환하지 않는다. U4의 새 저장 actor가 처음부터 `KeyValueStorage`를 받는다.
- 검증: Data 저장 타입 공개 선언에서 `UserDefaults`·`UserDefaultsStore` 0건, 좌표 테스트 기대값 불변.
  `tools/package-dependencies/bin/run.sh` 통과. 사용자 `make tuist`·빌드·테스트.
- 커밋 태그: `[Refactor]`

### U4. 생성 대기 Repository — integration unit (Domain·Data·Composition)

- 분리 불가 근거: Domain 계약 `GenerationStateRepository`·`PendingGenerationReminders` 제거와 UseCase 생성 인자
  변경은 Composition Adapter·Assembly와 함께 바뀌어야 compile된다. Data 계약 `GenerationStateStore` 제거도 같다.
- 파일:
  - Domain: `LearningProject/Contracts/{PendingGenerationRepository(신규),GenerationStateRepository(삭제),PendingGenerationReminders(삭제)}.swift`,
    `UseCases/CreateLearningProject/CreateLearningProject.swift`, `UseCases/FetchLearningProjects/FetchLearningProjects.swift`,
    `UseCases/TrackGeneration/{TrackGeneration,GenerationStateCoordinator}.swift`,
    `UseCases/ScheduleGenerationReminder/ScheduleGenerationReminder.swift`
  - Domain 테스트: `Tests/LearningProject/TestDoubles/{StubGenerationStateRepository → StubPendingGenerationRepository}.swift`,
    `Tests/LearningProject/UseCases/{TrackGenerationTests,CreateLearningProjectTests,FetchLearningProjectsTests}.swift`,
    `Tests/LearningProject/UseCases/ScheduleGenerationReminder/ScheduleGenerationReminderTests.swift`,
    `Tests/LearningProject/LearningProjectLifecycleTests.swift`
  - Data: `LearningProject/Stores/LocalPendingGenerationStore.swift`(신규), `LocalGenerationStateStore.swift`(삭제),
    `Codings/PendingGenerationReminderCoding.swift`(삭제), `Contracts/GenerationStateStore.swift`(삭제)와 테스트
    (`Tests/LearningProject/Stores/LocalPendingGenerationStoreTests.swift` 신규, 기존 두 테스트 삭제·이동,
    `Tests/LearningProject/Layouts/GenerationReminderStorageCoordinateTests.swift` 대상 변경)
  - Composition: `LearningProject/Adapters/{PendingGenerationRepositoryAdapter(신규),GenerationStateRepositoryAdapter(삭제),PendingGenerationRemindersAdapter(삭제)}.swift`,
    `LearningProject/Assemblies/{LearningProjectAssembly,GenerationReminderAssembly}.swift`,
    `App/Assemblies/AppComposition.swift`, `ShareExtension/Assemblies/ShareExtensionComposition.swift`와 관련 테스트
    (`Tests/LearningProject/Adapters/PendingGenerationRepositoryAdapterTests.swift` 신규,
    `Tests/LearningProject/Assemblies/LearningProjectAssemblyTests.swift`, `Tests/ShareExtension/ShareExtensionCompositionTests.swift`)
- 검증: quickstart 시나리오 1. 사용자 빌드·테스트.
- 커밋 태그: `[Refactor]`
- 위험: 생성 결과 관찰 시작을 한 번만 보장하지 못하면 결과가 중복 반영될 수 있음 → `TrackGenerationTests`에
  다중 호출 사례 유지.

### U5. 보안 저장 전환 — integration unit (Data·Composition)

- 분리 불가 근거: `KeychainStore` 인자를 받는 Data·Composition 공개 initializer가 함께 바뀐다.
- 파일:
  - `sources/Projects/Data/Shared/**`(`SecureValueStorage`, 오류, 실제 구현, `StorageFactory` 확장)와 테스트
  - `sources/Projects/Data/Authentication/{Codings/SessionRecordStorageCoding,Stores/AppleIdentityStore,Layouts/AppleIdentityStorageLayout,Layouts/SessionStorageLayout}.swift`
  - `sources/Projects/Data/Member/Stores/LocalDeviceIdentifierStore.swift`
  - Data 테스트: `Tests/Authentication/Codings/SessionRecordStorageCodingTests.swift`, `Tests/Authentication/Layouts/SessionStorageCoordinateTests.swift`,
    `Tests/Member/Stores/LocalDeviceIdentifierStoreTests.swift`
  - Composition: `Authentication/Assemblies/{AuthenticationAssembly,SessionAvailabilityAssembly}.swift`,
    `Authentication/Adapters/{CurrentSessionRepositoryAdapter,LoginSessionRepositoryAdapter,AuthenticationRepositoryAdapter}.swift`,
    `Authentication/Codings/SessionRecordCoding.swift`, `Member/Assemblies/MemberAssembly.swift`,
    `Member/Adapters/DeviceIdentifierRepositoryAdapter.swift`, `App/Assemblies/AppComposition.swift`,
    `ShareExtension/Assemblies/ShareExtensionComposition.swift`
  - Composition 테스트: `Tests/App/**`, `Tests/Authentication/**`, `Tests/ShareExtension/**`(in-memory 보안 저장 더블)
- 검증: Composition의 `KeychainStore` 참조 0건, Domain 오류 결과 테스트 기대값 불변. 사용자 빌드·테스트.
- 커밋 태그: `[Refactor]`

### U6. 요청 전송 전환 — integration unit (Data·Composition)

- 분리 불가 근거: Remote 7개 공개 initializer의 `HTTPClient` 인자 제거와 Composition `makeHTTPClient` 제거가 함께
  바뀐다. 소스가 없어지는 `CompositionShared` target 제거와, Data target 간 `package` 접근 수준을 위한
  `Target+Module.swift`의 `-package-name` 설정도 같은 단위에서 해야 빌드된다([research.md](./research.md) R9 추가 결정).
- 파일:
  - `sources/Projects/Data/Shared/**`(`RequestTransport`, 요청·응답·오류 값, 실제 구현, `RequestClientFactory`)와 테스트
  - `sources/Projects/Data/{Authentication,ExternalRepository,LearningProject,Member}/Remotes/*.swift`
  - Data Remote 테스트(`Tests/*/Remotes/*Tests.swift`, 생성 인자만 변경)
  - `sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift`(`packageName` 인자), `Projects/DataModuleName.swift`
  - `sources/Projects/Composition/Shared/Factories/HTTPClientFactory.swift`(삭제), `CompositionModuleName.swift`의
    `CompositionShared` target, `tools/package-dependencies/config/source-roots`의 해당 행,
    `docs/package-rules/composition.md`의 `CompositionShared` 행
  - Composition Assembly: `Authentication/Assemblies/AuthenticationAssembly.swift`, `LearningProject/Assemblies/{ExternalRepositoryAssembly,LearningProjectAssembly}.swift`,
    `Member/Assemblies/MemberAssembly.swift`, `App/Assemblies/AppComposition.swift`, `ShareExtension/Assemblies/ShareExtensionComposition.swift`
  - Composition 테스트: `Tests/{App,Authentication,LearningProject,Member}/TestDoubles/RecordingHTTPTransport.swift`(→ `RecordingRequestTransport`),
    Adapter·Assembly 테스트 12개(조사 목록)
- 검증: Composition의 `HTTPClient`·`HTTPTransport`·`StandardJSONBodyCoding` 참조 0건, Data Remote 테스트 기대값 불변.
- 커밋 태그: `[Refactor]`

### U7. `DataNotification` target과 알림·푸시·Apple 로그인 전환 — integration unit (Data·Composition·Tuist·tools)

- 분리 불가 근거: 새 target 추가(manifest·`source-roots`)와 Composition 알림·푸시·앱 델리게이트 전환, Apple 로그인
  제공자 이동이 함께 바뀌어야 Composition의 마지막 Infrastructure import가 사라진다.
- 파일:
  - `sources/Tuist/ProjectDescriptionHelpers/Projects/{DataModuleName,CompositionModuleName}.swift`, `AllTestsScheme.swift`
  - `tools/package-dependencies/config/source-roots`
  - `sources/Projects/Data/Notification/**`, `sources/Projects/Data/Tests/Notification/**`(신규)
  - `sources/Projects/Data/Authentication/{Sources/AppleSignInSource,Models/AppleSignInCredential,Models/AppleSignInState,Errors/AppleSignInError}.swift`(신규)와
    `sources/Projects/Data/Tests/Authentication/Sources/AppleSignInSourceTests.swift`
  - Composition: `LearningProject/Adapters/{GenerationReminderSchedulerAdapter,NotificationAuthorizationAdapter}.swift`,
    `LearningProject/Assemblies/GenerationReminderAssembly.swift`, `App/Factories/PushNotificationAppDelegate.swift`,
    `App/Assemblies/AppComposition.swift`, `ShareExtension/Assemblies/ShareExtensionComposition.swift`,
    `Authentication/Adapters/AuthenticationRepositoryAdapter.swift`, `Authentication/Assemblies/AuthenticationAssembly.swift`
  - Composition 테스트: `Tests/ShareExtension/TestDoubles/SpyNotificationAuthorizationClient.swift`(→ `SpyLocalReminderNotifier`),
    `Tests/ShareExtension/ShareExtensionCompositionTests.swift`, `Tests/App/SharedLifetimeTests.swift`,
    `Tests/Authentication/Adapters/AuthenticationRepositoryAdapterTests.swift`, `Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`
  - App: `sources/Projects/App/GitIt/GitItApp.swift`(typealias 이름을 유지하면 변경 없음, compile 확인)
- 검증: quickstart 시나리오 4-1의 import grep 0건(manifest grep은 U8에서 0건).
- 커밋 태그: `[Refactor]`

### U8. 의존성 규칙 강제 — integration unit (Tuist·tools·docs)

- 분리 불가 근거: 검사기는 `allowed-dependencies`와 `docs/architecture.md` 3.1 표의 일치, manifest `.from<패키지>`를
  함께 판정한다. 셋 중 하나만 바꾸면 검사가 실패한다.
- 파일:
  - `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`(`.fromInfrastructure` 전부 제거)
  - `tools/package-dependencies/config/allowed-dependencies`
  - `tools/package-dependencies/tests/test-package-dependencies.sh`(fixture 규칙·위반 사례)
  - `docs/architecture.md`(3.1 표, 7.1 금지 목록)
  - `docs/assets/package-dependency-graph.dot`, `docs/assets/package-dependency-graph.svg`
- 검증: quickstart 시나리오 4-1·4-2. `./tools/script-verification/bin/run.sh`.
- 커밋 태그: `[Build]`

### U9. Home 생성 결과 관찰 재개 — Feature 단일 패키지

- 파일: `sources/Projects/Feature/Home/HomeFeature.swift`,
  `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift`,
  필요 시 `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubTrackGenerationUseCase.swift`
- 순서 근거: Feature는 Domain에만 의존하고 `TrackGenerationUseCase` API가 바뀌지 않아 U1~U8과 독립이다. 위상 순서상
  Composition 뒤에 둔다.
- 검증: quickstart 시나리오 5. 사용자 Feature 테스트.
- 커밋 태그: `[Fix]`

### U10. 규칙 문서 정합과 전체 검증 — docs

- 파일: [contracts/dependency-rules.md](./contracts/dependency-rules.md) 3장의 나머지 문서
  (`docs/architecture.md` L11·L22·L35·3.3·6장·9장, `docs/package-rules/{composition,data,infrastructure,app}.md`,
  `docs/conventions/abstraction/{protocol-criteria,test-double-injection,structure-baseline}.md`,
  `docs/conventions/file-vocabulary/shape-vocabulary.md`(`Factories/`),
  `docs/review/domain-data-infra-design-review.md`), `sources/Projects/Infrastructure/*/README.md`와
  `sources/Projects/Domain/*/README.md` 중 바뀐 계약을 설명하는 파일(구현 시 grep으로 확정)
- 검증: quickstart 전체. 마지막 커밋 전 Swift 포맷 훅 실행(Constitution 원칙 7).
- 커밋 태그: `[Docs]`

## 복잡성 추적

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
|------|-------------|-------------------------------|
| 추상화 컨벤션 "테스트 더블은 Protocol 근거가 아니다"(`docs/conventions/abstraction/test-double-injection.md` L5-6)와 다른 Data 역할 Protocol 5개 | 명확화 Q1·Q2 답변: Composition이 Infrastructure를 볼 수 없게 되므로 앱·Share Extension·Composition 테스트의 대체 주입 지점을 Data 소유 계약으로 유지해야 한다. U10에서 컨벤션에 근거를 추가한다 | Composition 테스트를 Data 상위 타입 대체로만 바꾸는 안(Q2 선택지 B)은 사용자가 선택하지 않음 |
| `DataNotification`의 `UIKit` import | App의 `@UIApplicationDelegateAdaptor`가 쓰는 앱 델리게이트 클래스를 Infrastructure 타입 노출 없이 제공해야 한다 | Infrastructure 클래스를 typealias로 재공개하면 Data 공개 선언에 Infrastructure 타입이 드러나 FR-020 위반 |
| Data 패키지가 데이터 획득·저장 밖의 기술(알림 예약·푸시 수신)을 감쌈 | FR-018: Infrastructure 의존 가능 target이 Data뿐이다 | 새 패키지 신설은 아키텍처 의존 표와 검사기 규칙을 크게 바꿔 명세 범위를 넘음 |
