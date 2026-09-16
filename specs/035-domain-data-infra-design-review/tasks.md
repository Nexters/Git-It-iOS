# 작업 목록: Domain·Data·Infrastructure 설계 점검과 문서·네이밍 교정

**입력**: `/specs/035-domain-data-infra-design-review/`의 설계 문서

**선행 조건**: plan.md, spec.md, research.md, data-model.md, contracts/review-record.md, quickstart.md

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 명세가 새 테스트를 요청하지 않는다. 기존 테스트는 이름 치환만 한다(SC-004).

**구성**: 실행 단위 5개. U1·U2·U5는 문서 단위, U3·U4는 공개 API rename이라 소유 패키지와
참조 패키지를 묶은 integration unit이다. 위상 순서는 Domain → Data → Composition → Feature이며
Infrastructure는 코드 변경이 없다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: S1 점검 결과, S2 규칙 문서, S3 네이밍
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동
  검증. `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후
  Git 상태를 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다.
- 파일 변경 작업은 정확한 저장소 상대 경로와 책임 패키지 또는 integration unit을 가져야 한다.
- 문서 경로는 `GIT_IT_DOCS_ROOT`(`docs`) 기준이다. 디렉터리와 glob은 구현 권한이 아니다.
- rename 작업은 확정한 새 식별자를 설명에 적는다. 새 이름은 [research.md 3.2](./research.md)의
  방향을 따르며 아래에 확정값을 명시한다. 동작·시그니처·저장 key·의존 방향은 바꾸지 않는다.
- 빌드·테스트 명령(`"$build" build|compile|test`)은 사용자가 직접 실행한다. 작업은 실행
  요청과 결과 기록까지를 뜻한다.

## 실행 단위 소유권 규칙

- U1·U2·U5의 `docs/**` 파일은 파일 단위로 명시했다. 목록에 없는 문서는 수정하지 않는다.
- `specs/**`(이 tasks.md 완료 표시 제외), `docs/spec-kit/**`, `docs/retrospective/**`, 기존
  `docs/review/*-requirements.md`는 당시 기록이므로 수정하지 않는다.
- Composition·Feature 파일은 U3·U4의 참조 갱신만 허용한다. 그 밖의 위반은 U1에서 기록만 한다.
- `docs/spec-kit/<feature>/trouble-shooting.md`와 `tacit-knowledge.md`는 구현 작업이 아니다.

## 확정 rename 표

| ID | 옛 이름 | 새 이름 | 근거 |
| --- | --- | --- | --- |
| RN-01 | `DataAuthenticationError` | `AuthenticationServiceError` | 서버 응답 분류 오류. Domain `AuthenticationError`와 구분 |
| RN-02 | `DataMemberError` | `MemberServiceError` | 위와 같음 |
| RN-03 | `DataLearningProjectError` | `LearningProjectServiceError` | 위와 같음 |
| RN-04 | `DataExternalRepositoryError` | `ExternalRepositoryFetchError` | `offline`/`other` — 조회 실패 분류 |
| RN-05 | `HTTPAuthenticationRemote` | `AuthenticationRemote` | FR-017 기술 용어 제거 |
| RN-06 | `HTTPExternalRepositoryRemote` | `ExternalRepositoryRemote` | 위와 같음 |
| RN-07a | `HTTPAnswerRemote` | `AnswerRemote` | 위와 같음 |
| RN-07b | `HTTPBookmarkRemote` | `BookmarkRemote` | 위와 같음 |
| RN-07c | `HTTPLearningSetRemote` | `LearningSetRemote` | 위와 같음 |
| RN-07d | `HTTPProjectRemote` | `ProjectRemote` | 위와 같음 |
| RN-08 | `HTTPMemberRemote` | `MemberRemote` | 위와 같음 |
| RN-09 | `LearningProjectHTTPExecutor` | `LearningProjectRequestExecutor` | 위와 같음(internal, 파일 이름) |
| RN-10a | `SessionRecordKeychainCoding` | `SessionRecordStorageCoding` | 저장 매체 용어 제거 |
| RN-10b | `SessionKeychainMigration` | `SessionStorageMigration` | 위와 같음 |
| RN-10c | `SessionKeychainLayout` | `SessionStorageLayout` | 위와 같음. `Key` rawValue 불변 |
| RN-10d | `AppleIdentityKeychainLayout` | `AppleIdentityStorageLayout` | 위와 같음. `Key` rawValue 불변 |
| RN-10e | `AppleIdentityKeychainStore` | `AppleIdentityStore` | 위와 같음 |
| RN-12 | `PendingGenerationReminderStore` | `PendingGenerationReminders` | FR-020 `Store` 접미어 |
| RN-13 | `GenerationReminderRegistry` | `GenerationReminderRegistration` | FR-020 `Registry` 접미어 |
| RN-14 | `NotificationAuthorizationGateway` | `NotificationAuthorization` | FR-020 `Gateway` 접미어 |
| RN-15 | `ExternalRepositoryURLParser` | `ExternalRepositoryLocator` | FR-020 `Parser` 접미어 |
| RN-16 | `GenerationStateRepository.load()` / `save(_:)` | `currentState()` / `record(_:)` | FR-020 저장소 연산. 시그니처 불변 |
| RN-17 | `StoredSessionRepository` | `CurrentSessionRepository` | `Stored` 저장 방식 용어 |
| RN-18 | `SharedSessionMarkerRepository` | `SharedSignInStateRepository` | `Marker` 구현 용어 |

`Local…Store` 3개, Domain `…Repository`·`ExternalRepositoryLookup`·`GenerationReminderScheduler`·
`GenerationOutcomeRepository`, Data `GitHub…`·`AppleLoginRequestDTO`, Infrastructure 전체는
rename하지 않고 U1에서 `OK-*`로 기록한다. Composition Adapter 파일 이름은 채택 계약 이름을
따라 함께 바꾼다(`…RepositoryAdapter` → 새 계약 이름 + `Adapter`).

---

## 작업 패키지 1 (U1): 점검 결과 작성 — 문서

**목표**: 세 패키지 전수 점검 결과를 `docs/review/domain-data-infra-design-review.md`에
기록한다.

**소유 경로**: `docs/review/domain-data-infra-design-review.md`, `docs/review/README.md`

**관련 변경 시나리오**: S1

**독립 검증**: quickstart 시나리오 1 명령. 임의 항목의 대상 위치를 열어 불일치를 재현.

### 구현

- [X] T001 [S1] `docs/review/domain-data-infra-design-review.md`를
      [contracts/review-record.md](./contracts/review-record.md) 형식으로 생성한다. 머리부에
      근거 시점 commit을 적고, research 3.1의 DOC-01~08을 2.1 표에, 확정 rename 표의 RN
      항목을 2.2 표에(새 이름·참조 패키지·저장 값 열 포함, 상태 `미해소`), research 3.3의
      DS-01~09를 2.3 표에(DS-01·02·03은 관심사 중복 하위 표 포함) 옮긴다.
- [X] T002 [S1] 같은 파일에 Domain 114·Data 93·Infrastructure 43개 프로덕션 파일과 테스트
      target, README 2개(`sources/Projects/Domain/Authentication/README.md`,
      `sources/Projects/Infrastructure/Authentication/README.md`)를 FR-002 기준 문서와
      FR-014·FR-017·FR-020에 대조해 research에 없는 발견을 추가한다. research 3.1의 DOC-09(구조
      기준선 Domain Authentication 행의 계약 2개 누락)도 2.1 표에 포함한다. Data `Local…Store` 3개, Domain `…Repository` 13개와 허용 계약 3개, Data
      `GitHub…`·`AppleLoginRequestDTO`, `DataLegalConsent` target 축, Infrastructure 공개 이름,
      `InfrastructurePushMessaging/Remote/` 하위 능력을 `OK-*`로 근거와 함께 기록한다. 발견한
      동작 결함은 `DS-*`로 기록만 한다.
- [X] T003 [S1] `docs/review/README.md`의 "그 밖의 점검 문서" 목록에 새 문서를 추가한다.

### 정리와 패키지 검증

- [X] T004 [no-write] [S1] quickstart 시나리오 1 명령으로 배경 예시 5건과
      `ExternalRepositoryLocation` 쌍이 항목으로 존재하는지, 모든 `OK-*`에 근거가 있는지,
      DS 관심사 중복 항목에 판정 조건·양쪽 선언·Adapter·권장 방향·영향 범위가 있는지 확인한다.

**진행 점검**: T001~T004의 변경 파일과 검증 결과를 보고하고 U2로 진행한다.

---

## 작업 패키지 2 (U2): 규칙 문서 교정 — 문서 + Domain README

**목표**: DOC-01~06·08을 해소하고 FR-017 원칙의 정본과 결정 기록을 아키텍처 문서에 둔다.

**소유 경로**: `docs/architecture.md`, `docs/package-rules/domain.md`,
`docs/package-rules/data.md`, `docs/package-rules/infrastructure.md`,
`docs/conventions/naming.md`, `docs/conventions/file-vocabulary/shape-vocabulary.md`,
`sources/Projects/Domain/Authentication/README.md`, `docs/review/domain-data-infra-design-review.md`

**관련 변경 시나리오**: S2

**독립 검증**: quickstart 시나리오 2 명령과 수용 시나리오 2-3·2-4 대조 읽기.

### 구현

- [X] T005 [S2] `docs/architecture.md` 2장 Domain·Data·Infrastructure 설명에 FR-017 원칙을
      정본으로 서술하고, 3.3 "Data ↔ Infrastructure"의 `UserRemote`/`HTTPUserRemote` 예시를
      기술 이름 없는 예시로 바꾼다. 새 예시는 `UserRemote` 구조체가 `private let client: HTTPClient`를
      내부에서만 사용하는 형태로 쓰고 공개 initializer 시그니처는 예시에 넣지 않는다(생성 인자는
      Composition 조립에서 주입한다는 주석 한 줄만 둔다). 9장에
      `D-ARCH-004 — Domain·Data·Infrastructure 관심사 경계`를 추가해 명세 035의 FR-017·FR-020과
      명확화 1~6의 판정 기준(`Repository` 허용, `Store`·`Registry`·`Gateway`·`Parser`·`load`/`save`
      비허용, 외부 서비스명 허용 조건)을 이 문서에만 기록하고, 현행 Data 공개 initializer의
      Infrastructure 인자는 점검 결과 DS-06으로 이관 중임을 한 문장으로 적는다(DOC-02).
- [X] T006 [P] [S2] `docs/package-rules/infrastructure.md` 설명 2문단과 정책 5항의
      "Composition Adapter" 서술을 "Data 내부 구현이 사용"으로 고치고(DOC-01), 정책 2항 뒤에
      능력 묶음 target(`InfrastructureAuthentication`)이 현행이며 분리는 점검 결과 DS-07의
      후속임을 명시한다(DOC-05). 정책 1항이 D-ARCH-004를 참조하게 한다.
- [X] T007 [P] [S2] `docs/package-rules/data.md` 설명 2문단과 정책 5항을 FR-017에 맞게
      재서술한다: Data 공개 선언은 실행 역할만 표현하고 기술은 내부 구현에서만 사용하며 밖으로
      노출하지 않는다. D-ARCH-004를 참조한다(DOC-03).
- [X] T008 [P] [S2] `docs/package-rules/domain.md` 정책 1항에 D-ARCH-004 참조 링크를 추가한다.
      FR-020 접미어·연산 판정 기준은 재서술하지 않고 D-ARCH-004를 가리키는 한 문장으로만
      둔다(FR-018 정본 단일화).
- [X] T009 [P] [S2] `docs/conventions/naming.md` 4장 표의 Data 행 "필요한 기술 계약"을 "실행
      역할, DTO"로, 노출하지 않는 문맥에 "전송·저장 기술 용어"를 추가하고 D-ARCH-004를
      참조한다(DOC-06). 7장 외부 고정 명칭 절 아래에는 서비스명 허용 기준의 정본이 D-ARCH-004임을
      가리키는 한 문장만 두고 기준을 재서술하지 않는다.
- [X] T010 [P] [S2] `docs/conventions/file-vocabulary/shape-vocabulary.md` Data 행에
      `Codings/`(저장 형식 인코딩·디코딩), `Layouts/`(저장소 key 배치), `Migrations/`(저장 형식
      이전)를 추가한다(DOC-08).
- [X] T011 [P] [S2] `sources/Projects/Domain/Authentication/README.md`에서 `AuthenticationOutcome`
      설명을 제거하고 공개 모델·계약 목록을 현재 코드(`AuthenticatedUser`, `AuthorizationStatus`,
      계약 5개)와 일치시킨다(DOC-04). RN-17·18의 새 이름은 U3에서 반영하므로 여기서는 옛 이름을
      유지한다.
- [X] T012 [S2] `docs/review/domain-data-infra-design-review.md` 2.1 표에서 DOC-01~06·08의 상태를
      `해소`로 바꾼다.

### 정리와 패키지 검증

- [X] T013 [no-write] [S2] quickstart 시나리오 2의 `grep` 명령을 실행하고, 아키텍처 2장·3.3·9장,
      패키지 규칙 3개, 네이밍 4장 표가 FR-017과 같은 결론인지 읽어 확인한다. 수정한 문서의
      상대 링크 대상이 존재하는지 `grep -o '](\.\./[^)]*)'`로 확인한다.

**진행 점검**: T005~T013의 변경 파일과 검증 결과를 보고하고 U3으로 진행한다.

---

## 작업 패키지 3 (U3): Domain 계약 rename — integration unit(Domain + Composition + Feature)

**목표**: RN-12~18을 적용하고 Composition Adapter·Assembly와 Feature 참조를 같은 변경에서
갱신한다.

**분리 불가 근거**: Domain 계약 이름을 바꾸면 Composition Adapter의 채택 선언과 Feature의
`ExternalRepositoryURLParser` 주입 타입이 즉시 compile되지 않는다. Domain → Composition →
Feature 순으로 한 단위에서 처리한다.

**소유 경로**: 아래 작업의 파일. 새 파일 이름은 `git mv`로 만든다.

**관련 변경 시나리오**: S3

**독립 검증**: `DomainLearningProjectTests`, `DomainAuthenticationTests`,
`CompositionLearningProjectTests`, `CompositionAuthenticationTests`, `FeatureTests` 통과와
옛 이름 0건.

### 구현 — Domain

- [X] T014 [S3] RN-12·13·14·15: `sources/Projects/Domain/LearningProject/Contracts/PendingGenerationReminderStore.swift`
      → `sources/Projects/Domain/LearningProject/Contracts/PendingGenerationReminders.swift`,
      `sources/Projects/Domain/LearningProject/Contracts/GenerationReminderRegistry.swift` →
      `sources/Projects/Domain/LearningProject/Contracts/GenerationReminderRegistration.swift`,
      `sources/Projects/Domain/LearningProject/Contracts/NotificationAuthorizationGateway.swift` →
      `sources/Projects/Domain/LearningProject/Contracts/NotificationAuthorization.swift`,
      `sources/Projects/Domain/LearningProject/Contracts/ExternalRepositoryURLParser.swift` →
      `sources/Projects/Domain/LearningProject/Contracts/ExternalRepositoryLocator.swift`로 파일과
      프로토콜 이름을 바꾼다. 메서드 시그니처는 그대로 둔다.
- [X] T015 [S3] RN-16: `sources/Projects/Domain/LearningProject/Contracts/GenerationStateRepository.swift`의
      `load()`를 `currentState()`, `save(_:)`를 `record(_:)`로 바꾼다(반환·인자 타입 불변).
- [X] T016 [P] [S3] RN-17·18: `sources/Projects/Domain/Authentication/Contracts/StoredSessionRepository.swift`
      → `sources/Projects/Domain/Authentication/Contracts/CurrentSessionRepository.swift`,
      `sources/Projects/Domain/Authentication/Contracts/SharedSessionMarkerRepository.swift` →
      `sources/Projects/Domain/Authentication/Contracts/SharedSignInStateRepository.swift`로 파일과
      프로토콜 이름을 바꾼다.
- [X] T017 [S3] Domain 참조 갱신: `sources/Projects/Domain/Authentication/UseCases/ResolveSessionAvailability/ResolveSessionAvailability.swift`,
      `sources/Projects/Domain/LearningProject/UseCases/FetchExternalRepository/FetchExternalRepository.swift`,
      `sources/Projects/Domain/LearningProject/UseCases/RequestGenerationReminder/RequestGenerationReminder.swift`,
      `sources/Projects/Domain/LearningProject/UseCases/ScheduleGenerationReminder/ScheduleGenerationReminder.swift`,
      `sources/Projects/Domain/LearningProject/UseCases/ScheduleGenerationReminder/ScheduleGenerationReminderUseCase.swift`,
      `sources/Projects/Domain/LearningProject/UseCases/TrackGeneration/GenerationStateCoordinator.swift`,
      `sources/Projects/Domain/LearningProject/UseCases/TrackGeneration/TrackGeneration.swift`의
      타입·메서드 참조와 프로퍼티 이름을 새 이름으로 바꾼다.
- [X] T018 [S3] Domain 테스트 치환: `sources/Projects/Domain/Tests/Authentication/UseCases/ResolveSessionAvailability/ResolveSessionAvailabilityTests.swift`,
      `sources/Projects/Domain/Tests/LearningProject/LearningProjectLifecycleTests.swift`,
      `sources/Projects/Domain/Tests/LearningProject/TestDoubles/StubExternalRepositoryURLParser.swift`
      → `sources/Projects/Domain/Tests/LearningProject/TestDoubles/StubExternalRepositoryLocator.swift`,
      `sources/Projects/Domain/Tests/LearningProject/TestDoubles/StubGenerationStateRepository.swift`,
      `sources/Projects/Domain/Tests/LearningProject/UseCases/CreateLearningProjectTests.swift`,
      `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchExternalRepositoryTests.swift`,
      `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchLearningProjectsTests.swift`,
      `sources/Projects/Domain/Tests/LearningProject/UseCases/RequestGenerationReminderTests.swift`,
      `sources/Projects/Domain/Tests/LearningProject/UseCases/ScheduleGenerationReminder/ScheduleGenerationReminderTests.swift`,
      `sources/Projects/Domain/Tests/LearningProject/UseCases/TrackGenerationTests.swift`에서
      이름만 치환한다.
- [X] T019 [S3] `sources/Projects/Domain/Authentication/README.md`의 계약 목록에 RN-17·18 새
      이름을 반영한다.

### 구현 — Composition

- [X] T020 [S3] Adapter 파일·타입 rename: `sources/Projects/Composition/Authentication/Adapters/StoredSessionRepositoryAdapter.swift`
      → `sources/Projects/Composition/Authentication/Adapters/CurrentSessionRepositoryAdapter.swift`,
      `sources/Projects/Composition/Authentication/Adapters/SharedSessionMarkerRepositoryAdapter.swift` →
      `sources/Projects/Composition/Authentication/Adapters/SharedSignInStateRepositoryAdapter.swift`,
      `sources/Projects/Composition/LearningProject/Adapters/ExternalRepositoryURLParserAdapter.swift`
      → `sources/Projects/Composition/LearningProject/Adapters/ExternalRepositoryLocatorAdapter.swift`,
      `sources/Projects/Composition/LearningProject/Adapters/NotificationAuthorizationGatewayAdapter.swift` →
      `sources/Projects/Composition/LearningProject/Adapters/NotificationAuthorizationAdapter.swift`,
      `sources/Projects/Composition/LearningProject/Adapters/PendingGenerationReminderStoreAdapter.swift` →
      `sources/Projects/Composition/LearningProject/Adapters/PendingGenerationRemindersAdapter.swift`.
      채택 프로토콜 이름을 새 이름으로 바꾼다.
- [X] T021 [S3] `sources/Projects/Composition/LearningProject/Adapters/GenerationStateRepositoryAdapter.swift`의
      `load()`/`save(_:)` 구현 이름을 `currentState()`/`record(_:)`로 바꾼다(내부 `store.load/save`
      호출은 Data 계약이므로 유지).
- [X] T022 [S3] Assembly 참조 갱신: `sources/Projects/Composition/Authentication/Assemblies/SessionAvailabilityAssembly.swift`,
      `sources/Projects/Composition/LearningProject/Assemblies/ExternalRepositoryAssembly.swift`,
      `sources/Projects/Composition/LearningProject/Assemblies/GenerationReminderAssembly.swift`,
      `sources/Projects/Composition/LearningProject/Assemblies/LearningProjectAssembly.swift`,
      `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`의
      타입·프로퍼티 이름을 새 이름으로 바꾼다.

### 구현 — Feature

- [X] T023 [S3] `sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift`,
      `sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift`,
      `sources/Projects/Feature/Tests/ShareRegistration/TestDoubles/ShareRegistrationTestSupport.swift`의
      `ExternalRepositoryURLParser` 참조를 `ExternalRepositoryLocator`로 바꾼다.

### 정리와 통합 검증

- [X] T024 [S3] `docs/conventions/abstraction/structure-baseline.md` 3.1 표의 Domain
      LearningProject 행에서 RN-12~15 이름을 새 이름으로 바꾸고(DOC-07 일부), 표에 빠져 있는
      Domain Authentication 계약 2개를 새 이름 `CurrentSessionRepository`·`SharedSignInStateRepository`로
      그 행에 추가한다(DOC-09). 표의 프로토콜 수 합계 47과 2절의 세는 명령 결과는 바뀌지 않는다.
- [X] T025 [S3] `docs/review/domain-data-infra-design-review.md` 2.2 표의 RN-12~18 상태와 2.1
      표의 DOC-09 상태를 `해소`로 바꾼다.
- [X] T026 [no-write] [S3] `git grep -nE 'PendingGenerationReminderStore|GenerationReminderRegistry|NotificationAuthorizationGateway|ExternalRepositoryURLParser|StoredSessionRepository|SharedSessionMarkerRepository' -- sources docs ':!docs/spec-kit' ':!docs/retrospective' ':!docs/review/*-requirements.md'`
      가 점검 결과 문서 `docs/review/domain-data-infra-design-review.md`의 옛 이름 열 외 0건인지
      확인하고(quickstart 시나리오 3과 같은 제외 경로), Domain·Composition·Feature 테스트
      scheme의 `compile`·`test` 실행을 사용자에게 요청해 결과를 기록한다.

**진행 점검**: T014~T026의 변경 파일과 검증 결과를 보고하고 U4로 진행한다.

---

## 작업 패키지 4 (U4): Data 공개 타입 rename — integration unit(Data + Composition)

**목표**: RN-01~10을 적용하고 Composition Adapter·Assembly·테스트와 관련 문서를 같은 변경에서
갱신한다.

**분리 불가 근거**: Data 공개 타입 이름을 바꾸면 Composition Assembly의 생성 코드와 Adapter의
오류 변환이 즉시 compile되지 않는다.

**소유 경로**: 아래 작업의 파일. 새 파일 이름은 `git mv`로 만든다.

**관련 변경 시나리오**: S3

**독립 검증**: Data 테스트 target 5개와 Composition 테스트 target 통과, 옛 이름 0건, Keychain
key·저장 key 문자열 diff 0건.

### 구현 — Data

- [X] T027 [P] [S3] RN-01~04: `sources/Projects/Data/Authentication/Errors/DataAuthenticationError.swift`
      → `sources/Projects/Data/Authentication/Errors/AuthenticationServiceError.swift`,
      `sources/Projects/Data/Member/Errors/DataMemberError.swift` →
      `sources/Projects/Data/Member/Errors/MemberServiceError.swift`,
      `sources/Projects/Data/LearningProject/Errors/DataLearningProjectError.swift` →
      `sources/Projects/Data/LearningProject/Errors/LearningProjectServiceError.swift`,
      `sources/Projects/Data/ExternalRepository/Errors/DataExternalRepositoryError.swift` →
      `sources/Projects/Data/ExternalRepository/Errors/ExternalRepositoryFetchError.swift`로 파일과
      타입 이름을 바꾼다. case와 `init(from:)`은
      불변.
- [X] T028 [P] [S3] RN-05·06·08: `sources/Projects/Data/Authentication/Remotes/HTTPAuthenticationRemote.swift`
      → `sources/Projects/Data/Authentication/Remotes/AuthenticationRemote.swift`,
      `sources/Projects/Data/ExternalRepository/Remotes/HTTPExternalRepositoryRemote.swift` →
      `sources/Projects/Data/ExternalRepository/Remotes/ExternalRepositoryRemote.swift`,
      `sources/Projects/Data/Member/Remotes/HTTPMemberRemote.swift` →
      `sources/Projects/Data/Member/Remotes/MemberRemote.swift`로 파일과 타입 이름을 바꾼다. `init(client: HTTPClient, …)` 시그니처
      불변.
- [X] T029 [P] [S3] RN-07·09: `sources/Projects/Data/LearningProject/Remotes/HTTPAnswerRemote.swift`
      → `sources/Projects/Data/LearningProject/Remotes/AnswerRemote.swift`,
      `sources/Projects/Data/LearningProject/Remotes/HTTPBookmarkRemote.swift` →
      `sources/Projects/Data/LearningProject/Remotes/BookmarkRemote.swift`,
      `sources/Projects/Data/LearningProject/Remotes/HTTPLearningSetRemote.swift` →
      `sources/Projects/Data/LearningProject/Remotes/LearningSetRemote.swift`,
      `sources/Projects/Data/LearningProject/Remotes/HTTPProjectRemote.swift` →
      `sources/Projects/Data/LearningProject/Remotes/ProjectRemote.swift`,
      `sources/Projects/Data/LearningProject/Remotes/LearningProjectHTTPExecutor.swift` →
      `sources/Projects/Data/LearningProject/Remotes/LearningProjectRequestExecutor.swift`로 파일과
      타입 이름을 바꾸고 상호 참조를 갱신한다.
- [X] T030 [P] [S3] RN-10: `sources/Projects/Data/Authentication/Codings/SessionRecordKeychainCoding.swift`
      → `sources/Projects/Data/Authentication/Codings/SessionRecordStorageCoding.swift`,
      `sources/Projects/Data/Authentication/Migrations/SessionKeychainMigration.swift` →
      `sources/Projects/Data/Authentication/Migrations/SessionStorageMigration.swift`,
      `sources/Projects/Data/Authentication/Layouts/SessionKeychainLayout.swift` →
      `sources/Projects/Data/Authentication/Layouts/SessionStorageLayout.swift`,
      `sources/Projects/Data/Authentication/Layouts/AppleIdentityKeychainLayout.swift` →
      `sources/Projects/Data/Authentication/Layouts/AppleIdentityStorageLayout.swift`,
      `sources/Projects/Data/Authentication/Stores/AppleIdentityKeychainStore.swift` →
      `sources/Projects/Data/Authentication/Stores/AppleIdentityStore.swift`로 파일과 타입 이름을
      바꾼다. `Key` enum의 rawValue와 namespace
      문자열은 한 글자도 바꾸지 않는다.
- [X] T031 [S3] Data 내부 참조 갱신: T027~T030의 새 이름을 Data 프로덕션 파일 안에서 서로
      참조하는 곳(`Remotes/*.swift`의 오류 변환, `Migrations`·`Codings`·`Stores`의 Layout 참조)에
      반영한다. 대상은 T027~T030에 열거한 파일로 한정한다.
- [X] T032 [S3] Data 테스트 치환: 아래 파일에서 파일 이름과 참조를 치환한다. 기대값 문자열은
      바꾸지 않는다.
      - `sources/Projects/Data/Tests/Authentication/Codings/SessionRecordKeychainCodingTests.swift`
        → `sources/Projects/Data/Tests/Authentication/Codings/SessionRecordStorageCodingTests.swift`
      - `sources/Projects/Data/Tests/Authentication/Errors/DataAuthenticationErrorTests.swift`
        → `sources/Projects/Data/Tests/Authentication/Errors/AuthenticationServiceErrorTests.swift`
      - `sources/Projects/Data/Tests/Authentication/Layouts/SessionStorageCoordinateTests.swift`(이름 유지)
      - `sources/Projects/Data/Tests/Authentication/Migrations/SessionKeychainMigrationTests.swift`
        → `sources/Projects/Data/Tests/Authentication/Migrations/SessionStorageMigrationTests.swift`
      - `sources/Projects/Data/Tests/Authentication/Remotes/HTTPAuthenticationRemoteTests.swift`
        → `sources/Projects/Data/Tests/Authentication/Remotes/AuthenticationRemoteTests.swift`
      - `sources/Projects/Data/Tests/ExternalRepository/Errors/DataExternalRepositoryErrorTests.swift`
        → `sources/Projects/Data/Tests/ExternalRepository/Errors/ExternalRepositoryFetchErrorTests.swift`
      - `sources/Projects/Data/Tests/ExternalRepository/Remotes/HTTPExternalRepositoryRemoteNoAuthorizationTests.swift`
        → `sources/Projects/Data/Tests/ExternalRepository/Remotes/ExternalRepositoryRemoteNoAuthorizationTests.swift`
      - `sources/Projects/Data/Tests/ExternalRepository/Remotes/HTTPExternalRepositoryRemoteTests.swift`
        → `sources/Projects/Data/Tests/ExternalRepository/Remotes/ExternalRepositoryRemoteTests.swift`
      - `sources/Projects/Data/Tests/LearningProject/Errors/DataLearningProjectErrorTests.swift`
        → `sources/Projects/Data/Tests/LearningProject/Errors/LearningProjectServiceErrorTests.swift`
      - `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPAnswerRemoteTests.swift`
        → `sources/Projects/Data/Tests/LearningProject/Remotes/AnswerRemoteTests.swift`
      - `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPBookmarkRemoteTests.swift`
        → `sources/Projects/Data/Tests/LearningProject/Remotes/BookmarkRemoteTests.swift`
      - `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPLearningSetRemoteTests.swift`
        → `sources/Projects/Data/Tests/LearningProject/Remotes/LearningSetRemoteTests.swift`
      - `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPProjectRemoteAuthorizationTests.swift`
        → `sources/Projects/Data/Tests/LearningProject/Remotes/ProjectRemoteAuthorizationTests.swift`
      - `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPProjectRemoteTests.swift`
        → `sources/Projects/Data/Tests/LearningProject/Remotes/ProjectRemoteTests.swift`
      - `sources/Projects/Data/Tests/Member/Errors/DataMemberErrorTests.swift`
        → `sources/Projects/Data/Tests/Member/Errors/MemberServiceErrorTests.swift`
      - `sources/Projects/Data/Tests/Member/Remotes/HTTPMemberRemoteTests.swift`
        → `sources/Projects/Data/Tests/Member/Remotes/MemberRemoteTests.swift`

### 구현 — Composition

- [X] T033 [S3] Composition 참조 갱신: `sources/Projects/Composition/Authentication/Adapters/AuthenticationRepositoryAdapter.swift`,
      `sources/Projects/Composition/Authentication/Adapters/LoginSessionRepositoryAdapter.swift`,
      `sources/Projects/Composition/Authentication/Assemblies/AuthenticationAssembly.swift`,
      `sources/Projects/Composition/Authentication/Codings/SessionRecordCoding.swift`,
      `sources/Projects/Composition/LearningProject/Adapters/AnswerRepositoryAdapter.swift`,
      `sources/Projects/Composition/LearningProject/Adapters/BookmarkRepositoryAdapter.swift`,
      `sources/Projects/Composition/LearningProject/Adapters/ExternalRepositoryLookupAdapter.swift`,
      `sources/Projects/Composition/LearningProject/Adapters/LearningProjectRepositoryAdapter.swift`,
      `sources/Projects/Composition/LearningProject/Adapters/LearningSetRepositoryAdapter.swift`,
      `sources/Projects/Composition/LearningProject/Assemblies/ExternalRepositoryAssembly.swift`,
      `sources/Projects/Composition/LearningProject/Assemblies/LearningProjectAssembly.swift`,
      `sources/Projects/Composition/Member/Adapters/MemberRepositoryAdapter.swift`,
      `sources/Projects/Composition/Member/Assemblies/MemberAssembly.swift`의 Data 타입 참조를
      새 이름으로 바꾼다.
- [X] T034 [S3] Composition 테스트 치환: `sources/Projects/Composition/Tests/App/SharedLifetimeTests.swift`,
      `sources/Projects/Composition/Tests/Authentication/Adapters/AuthenticationRepositoryAdapterTests.swift`,
      `sources/Projects/Composition/Tests/Authentication/Adapters/LoginSessionRepositoryAdapterTests.swift`,
      `sources/Projects/Composition/Tests/LearningProject/Adapters/AnswerRepositoryAdapterTests.swift`,
      `sources/Projects/Composition/Tests/LearningProject/Adapters/BookmarkRepositoryAdapterTests.swift`,
      `sources/Projects/Composition/Tests/LearningProject/Adapters/ExternalRepositoryLookupAdapterTests.swift`,
      `sources/Projects/Composition/Tests/LearningProject/Adapters/LearningProjectRepositoryAdapterTests.swift`,
      `sources/Projects/Composition/Tests/LearningProject/Adapters/LearningSetRepositoryAdapterTests.swift`,
      `sources/Projects/Composition/Tests/Member/Adapters/MemberRepositoryAdapterTests.swift`에서
      이름만 치환한다.

### 정리와 통합 검증

- [X] T035 [P] [S3] `docs/conventions/abstraction/protocol-criteria.md` 46행,
      `docs/conventions/abstraction/test-double-injection.md` 27·32행의 `HTTPProjectRemote`를
      `ProjectRemote`로, `docs/release/guideline-5-1-1-appeal.md` 11행의
      `LearningProjectHTTPExecutor`를 `LearningProjectRequestExecutor`로 바꾼다.
      `test-double-injection.md` 27행은 단순 치환하면 "`ProjectRemote`의 동작을 검증할 때
      `ProjectRemote` 프로토콜과 그 스텁을 만들지"처럼 구조체와 가상 프로토콜 이름이 같아지므로,
      가상 프로토콜을 "별도의 remote 프로토콜"처럼 이름 없이 서술하도록 문장을 다시 쓴다.
- [X] T036 [P] [S3] `docs/review/domain-data-infra-design-review.md` 2.2 표의 RN-01~10 상태를
      `해소`로 바꾼다.
- [X] T037 [no-write] [S3] quickstart 시나리오 3의 옛 이름 `git grep`(Data 그룹)과 저장·전송 값
      `git diff` 명령을 실행해 옛 이름 0건, key 문자열 변경 0건을 확인하고, Data·Composition
      테스트 scheme의 `compile`·`test` 실행을 사용자에게 요청해 결과를 기록한다.

**진행 점검**: T027~T037의 변경 파일과 검증 결과를 보고하고 U5로 진행한다.

---

## 작업 패키지 5 (U5): 마무리 — 문서

**목표**: 점검 결과 문서를 완료 상태로 만들고 전체 검증 결과를 기록한다.

**소유 경로**: `docs/review/domain-data-infra-design-review.md`

**관련 변경 시나리오**: S1, S2, S3

- [X] T038 [S1] `docs/review/domain-data-infra-design-review.md` 머리부 상태를 `완료`로 바꾸고
      2.5 검증 결과 표에 SC-001~SC-010의 확인 방법을 적는다(결과 열은 T039~T041 뒤 기입).

## 전체 완료 검증

**선행 조건**: T038까지 완료하고 U5의 마지막 커밋 단위를 아직 commit하지 않은 상태.

**커밋 경계**: 아래 `[no-write]` 작업과 필수 `after_implement` 포맷 훅을 마친 뒤 U5 단위를
최종 commit한다. 훅 결과(포맷된 Swift 파일)는 같은 commit에 포함한다.

- [ ] T039 [no-write] `"$build" build && "$build" compile && "$build" test` 실행을 사용자에게
      요청하고 결과를 `docs/review/domain-data-infra-design-review.md` 2.5 표 SC-004 행에
      기록한다(기록은 T038 범위의 같은 파일). "변경 전후 동일 통과"는 변경 전 별도 실행 대신
      quickstart 시나리오 3의 테스트 diff 명령으로 `Tests/**` 변경이 파일 이름·식별자 치환뿐임을
      확인해 입증하고, 그 결과를 같은 행에 함께 적는다.
- [ ] T040 [no-write] quickstart 시나리오 1~3 전체 명령, `"$depcheck"`(SC-006), manifest diff
      없음(SC-005), 프로토콜 수 47(FR-012), `./tools/script-tests/bin/run.sh`,
      `./tools/script-verification/bin/run.sh`를 실행해 결과를 2.5 표에 기록한다.
- [ ] T041 [no-write] 수용 시나리오 1-1~1-3, 2-1~2-4, 3-1~3-3을 대조해 SC-001·002·003·007·
      008·009·010을 2.5 표에 기록한다.

## 의존성과 실행 순서

### 실행 단위 순서와 근거

```text
U1 점검(문서) → U2 문서 교정 → U3 Domain rename(Domain+Composition+Feature)
  → U4 Data rename(Data+Composition) → U5 마무리(문서) → 전체 검증
```

- U1이 먼저인 이유: U2~U4가 U1의 항목 ID를 인용한다.
- U2가 U3·U4보다 먼저인 이유: 판정 기준(D-ARCH-004)을 문서로 확정한 뒤 이름을 바꾼다.
- U3이 U4보다 먼저인 이유: 아키텍처 3.1 위상(Data는 Domain에 의존하지 않지만 Composition이
  둘 다 참조)에서 Domain을 먼저 두는 원칙 7. U3·U4는 서로 독립이라 순서를 바꿔도 compile은
  되지만 이 문서가 정한 순서를 유지한다.
- Infrastructure는 코드 변경이 없어 단위를 두지 않는다.

### 위험 기반 승인

- 새 범위: U1 점검에서 research에 없는 rename 항목을 발견하면 확정 rename 표에 추가하고 그
  항목의 파일 경로를 U3/U4 작업에 덧붙여야 하므로 tasks.md 갱신을 위해 중단한다. `OK-*`·
  `DS-*` 추가는 U1 안에서 계속한다.
- target rename이 필요해지면 FR-009a 경로(manifest·`tools/package-dependencies/config/source-roots`·
  `sources/Tuist/ProjectDescriptionHelpers/AllTestsScheme.swift`·
  `tools/script-tests/tests/test-testable-schemes.sh`)가 이 문서에 없으므로 중단하고 갱신한다.
- 빌드·테스트 실행은 사용자가 수행한다. 실행 결과 실패는 원인이 이름 치환 누락이면 같은
  단위에서 고치고, 동작 결함이면 중단한다.

### 변경 시나리오 추적성

| 시나리오 | 작업 | 독립 수용 기준 |
| --- | --- | --- |
| S1 점검 결과 | T001~T004, T038, T041 | 임의 항목 재현 가능, 처리 구분 하나, 배경 예시 5건 포함 |
| S2 규칙 문서 | T005~T013 | 옛 서술 0건, 문서 간 결론 일치, FR-017 원칙 반영 |
| S3 네이밍 | T014~T037 | 옛 이름 0건, 빌드·테스트 동일 통과, 저장 값 불변 |

### 실행 단위 내부 실행

- `[P]`는 같은 단위 안의 서로 다른 파일에만 붙였다. T027~T030은 서로 다른 파일이지만 T031이
  그 결과에 의존하므로 T031 전에 모두 끝낸다.
- `/speckit-implement`는 각 단위의 미완료 작업을 논리적 커밋 단위로 묶는다. U3·U4는 단위
  전체가 하나의 compile 가능한 경계이므로 소유 패키지와 참조 패키지를 한 commit에 담는다.
  단위 안에서 rename 그룹(예: RN-01~04 오류, RN-05~09 Remote, RN-10 저장)별로 나눌 수 있다.
- 마지막 단위(U5)는 전체 검증과 `after_implement` 훅이 끝날 때까지 commit하지 않는다.

## 구현 전략

1. tasks.md의 blob hash와 diff를 기준선으로 고정하고 U1부터 시작한다.
2. U1·U2는 문서만 바꾸므로 각 단위를 commit 하나로 둔다.
3. U3·U4는 rename 그룹별 commit으로 나누되 각 commit이 compile되게 소유·참조를 함께 담는다.
4. U5에서 전체 검증, 훅, 최종 commit을 순서대로 수행한다.

## 참고

- 확정 rename 표의 새 이름이 구현 중 기존 이름과 충돌하면 중단하고 표를 갱신한다.
- `HTTPMethod`(DS-05)·`APIResponseDTO` 계열(DS-04)·`ExternalRepositoryLocation`(DS-01)은 이번에
  건드리지 않는다.

## 단계 6: 수렴

`/speckit-converge`가 2026-09-17에 추가한 단계다. 점검 문서의 DOC-10·DOC-11을 소유하는 작업이
없어 SC-002·SC-003이 부분 충족에 머물렀다. 이 단계는 U5의 T038(점검 문서 머리부·2.5 확인 방법)
뒤에 실행하며, 아래 `전체 수렴 완료 검증`은 기존 T039~T041과 함께 마지막 실행 단위의
`FINALIZATION_TASKS`로 매핑한다. 세 작업 패키지는 서로 다른 파일만 바꾸므로 분리 가능하고,
코드 변경이 없어 통합 검증은 문서 대조와 기존 전체 검증으로 충분하다.

### 작업 패키지: Infrastructure

**소유 경로**: `sources/Projects/Infrastructure/Authentication/README.md`

- [ ] T042 [S2] `sources/Projects/Infrastructure/Authentication/README.md` 교정 per S2/AC2, SC-003
      (partial): 33행의 "`changes()`는 revoked 상태를 전달하는 `AsyncStream`을 제공합니다" 항목을
      코드의 실제 API로 바꾼다(`map(_:)`이 platform 상태를 `AppleCredentialState`로 변환하고
      `state(for:)`가 Apple user ID로 현재 상태를 조회한다). 검증 근거(78~82행)의 경로 5건을
      실제 파일로 고친다: `Tests/Authentication/AppleAuthentication/Providers/AppleAuthorizationProviderTests.swift`,
      `Tests/Authentication/AppleAuthentication/Providers/AppleCredentialStateProviderTests.swift`,
      `Tests/Authentication/Keychain/Stores/KeychainStoreTests.swift`,
      `Tests/Authentication/RandomGenerator/Providers/SecureRandomGeneratorTests.swift`,
      `Tests/Authentication/SensitiveValueExposureTests.swift`. 79행 항목 이름의 "stream"은
      "credential 상태 변환과 조회"로 바꾼다. 그 밖의 문장은 유지한다.

### 작업 패키지: 문서

**소유 경로**: `docs/conventions/abstraction/structure-baseline.md`,
`docs/review/domain-data-infra-design-review.md`

- [ ] T043 [S1] `docs/conventions/abstraction/structure-baseline.md` 3.1 정정 per SC-002, FR-012
      (partial): 제목 "근거 A — 패키지 경계를 넘는 계약 (20개)"를 "(25개)"로 바꾸고, Domain
      LearningProject 행에 `GenerationReminderScheduler`·`PendingGenerationReminders`를, Domain
      Member 행에 `DeviceIdentifierRepository`를 추가한다. `GenerationReminderRegistration`은
      LearningProject 행에서 빼고 별도 행 `| Domain LearningProject | \`GenerationReminderRegistration\` |
      Domain \`ScheduleGenerationReminderUseCase\`가 상속(Composition 채택자 없음, 존치 재검토는
      점검 문서 DS-12) |`로 둔다. 1절 수치(47)와 2절 명령은 바꾸지 않는다.
- [ ] T044 [S1] `docs/conventions/abstraction/structure-baseline.md` 3.3 정정 per SC-002
      (partial): 제목의 "(25개)"를 "(20개)"로 바꾸고 목록을 코드와 같게 쓴다. Domain
      Authentication 7개(`PolicyConsentUseCase`, `RefreshSessionUseCase`,
      `ResolveSessionAvailabilityUseCase`, `RestoreSessionUseCase`, `SignInUseCase`,
      `SignOutUseCase`, `VerifyAuthorizationUseCase`), Domain LearningProject
      10개(`CreateLearningProjectUseCase`, `FetchExternalRepositoryUseCase`,
      `FetchLearningProjectsUseCase`, `LearningLibraryUseCase`, `RequestGenerationReminderUseCase`,
      `ScheduleGenerationReminderUseCase`, `SetQuestionBookmarkUseCase`, `SubmitChoiceAnswerUseCase`,
      `SubmitEssayAnswerUseCase`, `TrackGenerationUseCase`), Domain Member
      3개(`DeleteMemberAccountUseCase`, `MemberAccountUseCase`, `RegisterCurrentDeviceUseCase`).
      아래 설명 문단은 유지한다.
- [ ] T045 [S1] `docs/review/domain-data-infra-design-review.md` 갱신 per SC-002, S1/AC2
      (partial): 2.1 표 DOC-10·DOC-11의 상태를 `해소`로 바꾸고, 불일치 열 끝의 "후속 작업으로
      남긴다" 문장을 T042~T044로 교정했다는 문장으로 바꾼다. 2.5 표 SC-002 결과를 "충족(DOC
      11·RN 23 모두 해소)"로, SC-003 결과를 README 3개 모두 코드와 일치로 갱신한다. ID는
      재번호하지 않는다.

### 전체 수렴 완료 검증

- [ ] T046 [no-write] 생성된 Xcode 프로젝트가 rename 전 경로를 참조하므로 `make tuist`로
      workspace를 재생성한 뒤(실행 전후 `git status --short` 동일 확인) `"$build" build &&
      "$build" compile && "$build" test`를 실행하고 결과를 점검 문서 2.5 표 SC-004 행에
      기록한다 per SC-004 (partial). 기록은 T045 범위의 같은 파일이다.
- [ ] T047 [no-write] 수용 시나리오 2-2(README 3개의 타입·경로를 코드와 대조), 2.1·2.2 표의
      `미해소` 0건, quickstart 시나리오 1~3 명령을 다시 실행해 SC-002·SC-003·SC-010 결과를 2.5
      표에 확정한다 per S2/AC2, SC-002, SC-003 (partial).
