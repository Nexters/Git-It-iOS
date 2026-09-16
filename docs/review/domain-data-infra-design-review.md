# Domain·Data·Infrastructure 설계 점검 결과

**상태**: 초안
**작성일**: 2026-09-17
**근거 시점**: branch `feature/domain-data-infra-design-review`, commit `b424b27`
**명세**: specs/035-domain-data-infra-design-review/spec.md
**판정 기준**: 명세 035의 FR-014(관심사 중복 판정 조건 (1) 책임·연산 1:1, (2) Domain에
비즈니스 로직 없이 Data 래핑, (3) 이름·필드 동일), FR-017(Data 공개 선언은 실행 역할만
표현하고 HTTP·Keychain·UserDefaults·URLSession 같은 기술을 노출하지 않으며, Domain 공개 선언은
Data 형태·특정 API에 의존하지 않는다), FR-020(`Repository` 허용, `Store`·`Registry`·`Gateway`·
`Parser` 접미어와 `load`/`save` 연산 비허용)과 명확화 1~6(외부 서비스명은 그 서비스가 역할
대상일 때만 허용, 외부 고정 명칭 보존은 직렬화 key·서버 필드·플랫폼 API 값에만 적용)을
적용했다. 이 원칙의 정본은 [아키텍처 문서](../architecture.md) 2장과 결정 기록 `D-ARCH-004`에
둔다(U2에서 기록). 항목 구조는
`specs/035-domain-data-infra-design-review/data-model.md`, 절 구성은
`specs/035-domain-data-infra-design-review/contracts/review-record.md`를
따른다.

점검 대상은 Domain 프로덕션 114파일(`Project.swift` 제외)·테스트 52파일, Data 프로덕션
93파일·테스트 57파일, Infrastructure 프로덕션 43파일·테스트 22파일과 README 2개
(`sources/Projects/Domain/Authentication/README.md`,
`sources/Projects/Infrastructure/Authentication/README.md`)다. 기준 문서는 Constitution,
아키텍처 문서, Domain·Data·Infrastructure 패키지 규칙, 네이밍 컨벤션과 하위 문서, 추상화
컨벤션과 구조 기준선, 디렉터리·파일 컨벤션, 파일·형태 어휘, 테스트 컨벤션이다.

ID 대응: research 3.2의 RN-11은 위반이 아니므로 `OK-01`로 옮겼고, RN-19(README 이름 갱신)는
rename 항목이 아니라 DOC-04와 U3 작업 T019의 결과이므로 별도 ID를 두지 않는다. research 3.3의
DS-08은 위반이 아니므로 `OK-06`으로 옮겼다. 비워 둔 번호는 재사용하지 않는다.

## 2.1 문서 교정 (`DOC-NN`)

| ID | 기준 위치 | 대상 위치 | 불일치 | 상태 |
| --- | --- | --- | --- | --- |
| DOC-01 | 아키텍처 문서 9장 D-ARCH-003("Data↔Infrastructure 변환은 Data 내부 구현이 담당") | `docs/package-rules/infrastructure.md` 설명 2문단(11행), 정책 5항(19행) | "Composition의 Adapter가 해당 API를 Data의 기술 계약과 연결", "Composition Adapter가 안정적으로 사용"이라고 설명한다. 코드는 `sources/Projects/Data/*/Remotes/*.swift`·`Stores/*.swift`가 `HTTPClient`·`KeychainStore`·`UserDefaultsStore`를 직접 사용하며 Composition에는 Data↔Infrastructure Adapter가 없다 | 해소 |
| DOC-02 | 명세 035 FR-017, 네이밍 컨벤션 4장 패키지 문맥 표 | `docs/architecture.md` 3.3 "Data ↔ Infrastructure"(151~182행) | `HTTPUserRemote`를 Data 공개 타입의 규범 예시로 제시해 기술 이름을 가진 Data 공개 구현을 권장한다. FR-017과 모순이며 SC-010 위반 예시다 | 해소 |
| DOC-03 | 명세 035 FR-017, 아키텍처 2장 Data 책임 | `docs/package-rules/data.md` 설명 2문단(11행), 정책 5항(19행) | "네트워크, 저장소, Keychain, 파일 시스템과 같은 외부 기술 기능을 사용할 때 필요한 계약을 정의"처럼 기술 능력을 Data 계약의 어휘로 서술한다. Data 공개 선언이 실행 역할만 표현하고 기술을 노출하지 않는다는 원칙이 없다 | 해소 |
| DOC-04 | 아키텍처 3장·5장(문서는 코드와 일치), Domain 패키지 규칙 | `sources/Projects/Domain/Authentication/README.md` 공개 모델(13행), Repository 계약(19~34행), 유스케이스 `ObserveAuthenticationOutcomes` 절(56~61행), 검증 근거(91~93행) | 코드에 없는 `AuthenticationOutcome`을 공개 모델로 설명하고, 존재하지 않는 `ObserveAuthenticationOutcomes` 유스케이스 절을 둔다. `AuthenticationRepository`가 "authorization 상태 변경을 `AsyncStream`으로 제공"한다고 적었지만 계약은 `authenticate`·`authorizationStatus`·`clearAuthentication`뿐이다. `LoginSessionRepository.restore()`가 "내부 refresh 결과를 함께 반환"한다고 적었지만 반환 타입은 `AuthenticatedUser?`다. 계약이 5개(`PolicyConsentRepository`, `StoredSessionRepository`, `SharedSessionMarkerRepository` 포함)인데 2개만 설명한다. 검증 근거의 `DomainAuthenticationTests/Security/`는 없고 `Tests/Authentication/SensitiveValueExposureTests.swift`가 루트에 있다 | 해소 |
| DOC-05 | Infrastructure 패키지 규칙 정책 2항("모든 내부 target은 하나의 범용 기술 기능") | `docs/package-rules/infrastructure.md` 정책 2항(16행) | `InfrastructureAuthentication` target이 Apple 인증(`AppleAuthentication/`), Keychain(`Keychain/`), 난수(`RandomGenerator/`) 세 능력을 담는 현행과 불일치한다. 능력 묶음 target의 허용 조건과 분리(DS-07)가 후속임을 문서가 설명하지 않는다 | 해소 |
| DOC-06 | 명세 035 FR-017·FR-018 | `docs/conventions/naming.md` 4장 패키지 문맥 표 Data 행(83행) | 이름이 사용하는 주된 문맥에 "필요한 기술 계약"을 적어 Data 공개 이름이 기술을 문맥으로 삼는 것을 허용한다. 노출하지 않는 문맥에 전송·저장 기술 용어가 없다 | 해소 |
| DOC-07 | 명세 035 FR-012(rename만 발생하면 기준선의 이름만 갱신) | `docs/conventions/abstraction/structure-baseline.md` 3.1 Domain LearningProject 행(52행) | RN-12·13·14·15 대상 이름(`PendingGenerationReminderStore`는 표에 없음, `GenerationReminderRegistry`, `NotificationAuthorizationGateway`, `ExternalRepositoryURLParser`)을 옛 이름으로 적고 있다. U3 rename 뒤 새 이름으로 갱신한다 | 미해소 |
| DOC-08 | 파일·형태 어휘 컨벤션 §3 표(표에 없는 형태는 같은 PR에서 표 갱신) | `docs/conventions/file-vocabulary/shape-vocabulary.md` Data 행(17~26행) | 코드는 `Data/Authentication/Codings/`, `Data/Authentication/Layouts/`, `Data/Authentication/Migrations/`, `Data/LearningProject/Codings/`, `Data/LegalConsent/Layouts/` 다섯 폴더를 쓰지만 표의 Data 행에 `Codings/`·`Layouts/`·`Migrations/`가 없다(Composition 행에만 `Codings/`·`Layouts/`) | 해소 |
| DOC-09 | 추상화 컨벤션 §3(남은 프로토콜과 존치 근거 목록) | `docs/conventions/abstraction/structure-baseline.md` 3.1 Domain Authentication 행(51행) | 계약 3개만 적혀 있고 코드의 `StoredSessionRepository`·`SharedSessionMarkerRepository`(Composition `StoredSessionRepositoryAdapter`·`SharedSessionMarkerRepositoryAdapter`가 채택)가 빠져 있다. 합계 47은 2절 명령으로 재확인해 코드와 같다. U3 rename 뒤 새 이름 `CurrentSessionRepository`·`SharedSignInStateRepository`로 추가한다 | 해소 |
| DOC-10 | 아키텍처 3장·5장(문서는 코드와 일치), Infrastructure 패키지 규칙 | `sources/Projects/Infrastructure/Authentication/README.md` Apple credential 상태(33행), 검증 근거(78~82행) | `AppleCredentialStateProvider.changes()`가 revoked 상태 `AsyncStream`을 제공한다고 적었지만 코드에는 `map(_:)`과 `state(for:)`만 있다. 검증 근거 경로 4건이 실제 경로와 다르다: `Tests/Authentication/AppleAuthentication/AppleAuthorizationProviderTests.swift`(실제 `…/AppleAuthentication/Providers/…`), `…/AppleCredentialStateProviderTests.swift`(실제 `…/Providers/…`), `Tests/Authentication/Keychain/KeychainStoreTests.swift`(실제 `…/Keychain/Stores/…`), `Tests/Authentication/RandomGenerator/SecureRandomGeneratorTests.swift`(실제 `…/RandomGenerator/Providers/…`), `Tests/Authentication/Security/SensitiveValueExposureTests.swift`(실제 `Tests/Authentication/SensitiveValueExposureTests.swift`). 이 파일을 소유한 작업이 tasks.md에 없어 `/speckit-tasks` 갱신이 필요하다 | 미해소 |
| DOC-11 | 추상화 컨벤션 §3, Domain 패키지 규칙 "통합 후 남은 UseCase"(명세 033 결과) | `docs/conventions/abstraction/structure-baseline.md` 3.1 헤더·LearningProject·Member 행(45~53행), 3.3(66~79행) | 3.1이 "20개"라고 적지만 코드의 경계 계약은 Domain 19·Data 2·Infrastructure 4로 25개다. LearningProject 행에 `GenerationReminderScheduler`(Composition `GenerationReminderSchedulerAdapter` 채택)·`PendingGenerationReminderStore`(`PendingGenerationReminderStoreAdapter` 채택), Member 행에 `DeviceIdentifierRepository`(`DeviceIdentifierRepositoryAdapter` 채택)가 빠져 있다. `GenerationReminderRegistry`의 채택 위치를 "Composition Adapter"로 적었지만 Composition에 채택자가 없고 Domain의 `ScheduleGenerationReminderUseCase`가 상속한다(DS-12). 3.3은 UseCase 프로토콜을 25개로 적고 명세 033이 제거한 `VerifyAccessTokenUseCase`·`DeleteLearningProjectUseCase` 등을 나열하지만 코드는 20개다. 이 편집을 소유한 작업이 tasks.md에 없어 `/speckit-tasks` 갱신이 필요하다 | 미해소 |

## 2.2 rename (`RN-NN`)

`대상 위치`는 선언 파일이다. `참조 패키지`는 옛 이름을 참조하는 파일이 있는 패키지와 그 수를
`git grep -l`로 센 값이며 `docs`는 `docs/spec-kit`·`docs/retrospective`·`docs/review`를 제외한
공용 문서다. `저장·전송 값`은 FR-010 판정이다.

| ID | 옛 이름 | 새 이름 | 종류 | 대상 위치 | 위반 근거 | 참조 패키지 | 저장·전송 값 | 상태 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| RN-01 | `DataAuthenticationError` | `AuthenticationServiceError` | 타입·파일 | `sources/Projects/Data/Authentication/Errors/DataAuthenticationError.swift` | 네이밍 접두어·접미어 규칙(패키지 이름 반복 `Data...` 접두어 금지). Domain `AuthenticationError`와 공존하므로 구분 문맥은 필요하지만 패키지 이름이 아니라 오류가 분류하는 대상(서버 응답 실패)으로 표현한다 | Data 4, Composition 1 | 영향 없음(case·`init(from:)` 불변) | 미해소 |
| RN-02 | `DataMemberError` | `MemberServiceError` | 타입·파일 | `sources/Projects/Data/Member/Errors/DataMemberError.swift` | RN-01과 같음(Domain `MemberError` 공존) | Data 4, Composition 1 | 영향 없음 | 미해소 |
| RN-03 | `DataLearningProjectError` | `LearningProjectServiceError` | 타입·파일 | `sources/Projects/Data/LearningProject/Errors/DataLearningProjectError.swift` | RN-01과 같음(Domain `LearningProjectError` 공존) | Data 5, Composition 4 | 영향 없음 | 미해소 |
| RN-04 | `DataExternalRepositoryError` | `ExternalRepositoryFetchError` | 타입·파일 | `sources/Projects/Data/ExternalRepository/Errors/DataExternalRepositoryError.swift` | RN-01과 같음(Domain `ExternalRepositoryError` 공존). `offline`·`other` 두 case뿐이라 조회 실패 분류 이름으로 | Data 4, Composition 1 | 영향 없음 | 미해소 |
| RN-05 | `HTTPAuthenticationRemote` | `AuthenticationRemote` | 타입·파일 | `sources/Projects/Data/Authentication/Remotes/HTTPAuthenticationRemote.swift` | FR-017 Data 공개 타입 이름의 전송 기술 용어(HTTP). `Remotes/` 폴더와 `Remote` 역할어는 어휘표·프로토콜 규칙에 있어 유지 | Data 2, Composition 5 | 영향 없음(`init(client: HTTPClient, …)` 시그니처 불변, 노출 자체는 DS-06) | 미해소 |
| RN-06 | `HTTPExternalRepositoryRemote` | `ExternalRepositoryRemote` | 타입·파일 | `sources/Projects/Data/ExternalRepository/Remotes/HTTPExternalRepositoryRemote.swift` | RN-05와 같음 | Data 3, Composition 3 | 영향 없음 | 미해소 |
| RN-07a | `HTTPAnswerRemote` | `AnswerRemote` | 타입·파일 | `sources/Projects/Data/LearningProject/Remotes/HTTPAnswerRemote.swift` | RN-05와 같음 | Data 2, Composition 3 | 영향 없음 | 미해소 |
| RN-07b | `HTTPBookmarkRemote` | `BookmarkRemote` | 타입·파일 | `sources/Projects/Data/LearningProject/Remotes/HTTPBookmarkRemote.swift` | RN-05와 같음 | Data 2, Composition 3 | 영향 없음 | 미해소 |
| RN-07c | `HTTPLearningSetRemote` | `LearningSetRemote` | 타입·파일 | `sources/Projects/Data/LearningProject/Remotes/HTTPLearningSetRemote.swift` | RN-05와 같음 | Data 2, Composition 3 | 영향 없음 | 미해소 |
| RN-07d | `HTTPProjectRemote` | `ProjectRemote` | 타입·파일 | `sources/Projects/Data/LearningProject/Remotes/HTTPProjectRemote.swift` | RN-05와 같음 | Data 3, Composition 3, docs 2(`abstraction/protocol-criteria.md`, `abstraction/test-double-injection.md`) | 영향 없음 | 미해소 |
| RN-08 | `HTTPMemberRemote` | `MemberRemote` | 타입·파일 | `sources/Projects/Data/Member/Remotes/HTTPMemberRemote.swift` | RN-05와 같음 | Data 2, Composition 3 | 영향 없음 | 미해소 |
| RN-09 | `LearningProjectHTTPExecutor` | `LearningProjectRequestExecutor` | 타입·파일 | `sources/Projects/Data/LearningProject/Remotes/LearningProjectHTTPExecutor.swift` | FR-017 취지. `internal`이지만 파일 이름이 기술을 드러내고 Data 안의 역할은 요청 실행이다 | Data 5, docs 1(`release/guideline-5-1-1-appeal.md`) | 영향 없음 | 미해소 |
| RN-10a | `SessionRecordKeychainCoding` | `SessionRecordStorageCoding` | 타입·파일 | `sources/Projects/Data/Authentication/Codings/SessionRecordKeychainCoding.swift` | FR-017 Data 공개 타입 이름의 저장 기술 용어(Keychain) | Data 4, Composition 1 | 영향 없음(`SessionKeychainLayout.Key` rawValue 참조만) | 미해소 |
| RN-10b | `SessionKeychainMigration` | `SessionStorageMigration` | 타입·파일 | `sources/Projects/Data/Authentication/Migrations/SessionKeychainMigration.swift` | RN-10a와 같음 | Data 2, Composition 1 | 영향 없음 | 미해소 |
| RN-10c | `SessionKeychainLayout` | `SessionStorageLayout` | 타입·파일 | `sources/Projects/Data/Authentication/Layouts/SessionKeychainLayout.swift` | RN-10a와 같음 | Data 3 | `namespace` `"com.nexters.hytime.gitit.session"`과 `Key` rawValue 불변 | 미해소 |
| RN-10d | `AppleIdentityKeychainLayout` | `AppleIdentityStorageLayout` | 타입·파일 | `sources/Projects/Data/Authentication/Layouts/AppleIdentityKeychainLayout.swift` | RN-10a와 같음. `Apple`은 저장 값(Apple user ID)의 역할 대상이라 유지(명확화 5) | Data 3, Composition 2 | `namespace` `"com.nexters.hytime.gitit.authentication"`과 `Key` rawValue 불변 | 미해소 |
| RN-10e | `AppleIdentityKeychainStore` | `AppleIdentityStore` | 타입·파일 | `sources/Projects/Data/Authentication/Stores/AppleIdentityKeychainStore.swift` | RN-10a와 같음 | Data 1, Composition 2 | 영향 없음 | 미해소 |
| RN-12 | `PendingGenerationReminderStore` | `PendingGenerationReminders` | 프로토콜·파일 | `sources/Projects/Domain/LearningProject/Contracts/PendingGenerationReminderStore.swift` | FR-020 `Store` 접미어(저장 매체·접근 방식 노출). 연산 `drainProjectIDs()`는 유지. Composition `PendingGenerationReminderStoreAdapter` 파일·타입 이름을 함께 바꾼다 | Domain 3, Composition 2 | 영향 없음(Data `PendingGenerationReminderCoding`의 key 불변) | 해소 |
| RN-13 | `GenerationReminderRegistry` | `GenerationReminderRegistration` | 프로토콜·파일 | `sources/Projects/Domain/LearningProject/Contracts/GenerationReminderRegistry.swift` | FR-020 `Registry` 접미어. 채택자는 Domain `ScheduleGenerationReminderUseCase`(상속)뿐이며 Composition Adapter는 없다(DS-12) | Domain 4, docs 1(`abstraction/structure-baseline.md`) | 영향 없음 | 해소 |
| RN-14 | `NotificationAuthorizationGateway` | `NotificationAuthorization` | 프로토콜·파일 | `sources/Projects/Domain/LearningProject/Contracts/NotificationAuthorizationGateway.swift` | FR-020 `Gateway` 접미어. Composition `NotificationAuthorizationGatewayAdapter` 이름을 함께 바꾼다 | Domain 3, Composition 2, docs 1 | 영향 없음 | 해소 |
| RN-15 | `ExternalRepositoryURLParser` | `ExternalRepositoryLocator` | 프로토콜·파일 | `sources/Projects/Domain/LearningProject/Contracts/ExternalRepositoryURLParser.swift` | FR-020 `Parser` 접미어(형식·접근 방식 노출). Feature `ShareRegistrationFeature`가 직접 주입받으므로 Feature 참조 3파일을 함께 갱신한다. Data `GitHubRepositoryURLParser`는 OK-09 | Domain 5, Composition 3, Feature 3, docs 1 | 영향 없음 | 해소 |
| RN-16 | `GenerationStateRepository.load()` / `save(_:)` | `currentState()` / `record(_:)` | 연산 | `sources/Projects/Domain/LearningProject/Contracts/GenerationStateRepository.swift` | FR-020 저장소 연산 이름 그대로 노출. 반환·인자 타입(`GenerationState`) 불변. 호출부는 Domain `GenerationStateCoordinator`(92·118행)와 Composition `GenerationStateRepositoryAdapter`(구현), Domain 테스트 `StubGenerationStateRepository`. Adapter 내부의 Data `GenerationStateStore.load/save` 호출은 OK-10 | Domain 3, Composition 1 | 영향 없음(Data DTO·UserDefaults key 불변) | 해소 |
| RN-17 | `StoredSessionRepository` | `CurrentSessionRepository` | 프로토콜·파일 | `sources/Projects/Domain/Authentication/Contracts/StoredSessionRepository.swift` | FR-020 취지. `Stored`가 저장 방식을 드러내며 연산은 `currentSession()` 하나다. Composition `StoredSessionRepositoryAdapter` 이름을 함께 바꾼다 | Domain 3, Composition 2 | 영향 없음(Composition `SessionRecordCoding`의 Keychain key 불변) | 해소 |
| RN-18 | `SharedSessionMarkerRepository` | `SharedSignInStateRepository` | 프로토콜·파일 | `sources/Projects/Domain/Authentication/Contracts/SharedSessionMarkerRepository.swift` | `Marker`는 App Group 저장 구현 용어이며 Domain 연산은 `signedInState()`다. Composition `SharedSessionMarkerRepositoryAdapter` 이름을 함께 바꾼다. Data `SharedSessionStateMarkerCoding`은 OK-09 | Domain 3, Composition 2 | 영향 없음(`stateMarkerKey` `"stateMarker"` 불변) | 해소 |

## 2.3 후속 설계 변경 (`DS-NN`)

| ID | 대상 | 기준 위치 | 불일치 | 권장 방향 | 영향 범위 |
| --- | --- | --- | --- | --- | --- |
| DS-01 | Domain `ExternalRepositoryLocation` ↔ Data `ExternalRepositoryLocation` | 명세 035 FR-014 조건 (3) | 두 구조체의 이름과 필드(`owner: String`, `name: String`)가 완전히 같고, Adapter는 필드 복사만 한다 | Domain 모델을 남기고 Data 쪽을 제거한다. Data `GitHubRepositoryURLParser.location(from:)`이 `(owner, name)` 튜플 또는 `GitHubRepositoryRequest` 인자를 직접 돌려주게 하거나, 위치 값의 소유자를 Domain 하나로 둔다 | Composition `ExternalRepositoryURLParserAdapter`, `ExternalRepositoryLookupAdapter`, `ExternalRepositoryAssembly`; Data `GitHubRepositoryURLParser`, `GitHubRepositoryRequest`와 테스트 `GitHubRepositoryURLParserTests`; Composition 테스트 `ExternalRepositoryLookupAdapterTests` |
| DS-02 | Domain `GenerationStateRepository` ↔ Data `GenerationStateStore` | 명세 035 FR-014 조건 (1) | `load() -> GenerationState`/`save(_:)`와 `load() -> GenerationStateDTO`/`save(_:)`가 연산 단위로 1:1이다. Adapter는 DTO↔모델 변환과 `status` 문자열↔enum 변환을 수행하므로 조건 (2)에는 해당하지 않는다 | Data 계약 `GenerationStateStore`를 제거하고 `LocalGenerationStateStore`를 Composition이 직접 받게 하거나(추상화 컨벤션 근거 A 재검토), 상태 변환을 Data DTO 없이 Domain 모델 저장으로 단순화한다 | Composition `GenerationStateRepositoryAdapter`, `LearningProjectAssembly`, `GenerationReminderAssembly`; Data `LocalGenerationStateStore`, `GenerationStateMigration`과 테스트; Composition 테스트 |
| DS-03 | Domain `PendingGenerationReminderStore` ↔ Data `PendingGenerationReminderCoding` | 명세 035 FR-014 조건 (1)·(2) | 두 선언의 공유 연산이 `drainProjectIDs() async -> [String]` 하나뿐이고, Adapter가 인자·결과 변환 없이 위임한다. Domain 쪽에 비즈니스 로직이 없다 | Domain 계약 하나만 남기고 Data 타입이 직접 채택하게 하거나 Composition이 클로저로 연결한다. RN-12 rename은 이 결정 전에 수행한다(rename과 설계 변경 분리) | Composition `PendingGenerationReminderStoreAdapter`, `GenerationReminderAssembly`; Domain `ScheduleGenerationReminder`; Data `PendingGenerationReminderCoding`과 테스트 |
| DS-04 | Data `APIResponseDTO`, `FieldErrorDTO`, `EmptyResponseData`, `ServerAPIError` 3중 반복 | 명세 035 명확화 4, 파일 하나에 타입 하나(파일 이름=타입 이름) | `Data/Authentication`, `Data/LearningProject`, `Data/Member`에 같은 이름·같은 필드의 선언이 각각 있다(12파일). `ServerAPIError.httpStatus`는 Data 공개 프로퍼티 이름에 기술 용어를 포함한다(FR-017). 테스트 더블 `JSONBodyCoding`·`StubHTTPTransport`도 4개 테스트 target에 반복된다 | 서버 응답 봉투를 공유 Data target으로 모으거나 Infrastructure `HTTPClient` 응답 처리로 흡수한다. 통합 시 `httpStatus`를 `statusCode`로 바꾼다 | Data 3 target의 `Remotes/*.swift`·`Errors/*.swift`, Composition Adapter의 오류 변환, Data 테스트 `APIResponseDTOTests`·`ServerAPIErrorTests` 3벌 |
| DS-05 | Data `HTTPMethod` ↔ Infrastructure `HTTPMethod` | 명세 035 FR-017·명확화 4, Data 패키지 규칙 제약 | `Data/LearningProject/Models/HTTPMethod.swift`가 Infrastructure `HTTPMethod`와 같은 이름의 기술 타입을 재정의하고, `LearningProjectRequest.method: HTTPMethod`가 그 타입을 공개 프로퍼티로 노출한다 | Data 선언을 제거하고 `LearningProjectRequest.method`가 Infrastructure 타입을 쓰거나, 요청 값 타입이 method를 내부에서만 다루게 한다 | Data `LearningProjectRequest`, `LearningProjectHTTPExecutor`(RN-09), Endpoint 5개와 테스트 `AnswerEndpointTests` 등 |
| DS-06 | Data 공개 initializer의 Infrastructure·플랫폼 타입 인자 | 명세 035 FR-017 "기술을 Data 밖으로 노출하지 않는다" | `HTTPClient` 7곳(`HTTPAuthenticationRemote`, `HTTPExternalRepositoryRemote`, `HTTPAnswerRemote`, `HTTPBookmarkRemote`, `HTTPLearningSetRemote`, `HTTPProjectRemote`, `HTTPMemberRemote`), `KeychainStore` 4곳(`SessionRecordKeychainCoding`, `SessionKeychainMigration`, `AppleIdentityKeychainStore`, `LocalDeviceIdentifierStore`), `UserDefaultsStore<…>` 3곳(`GenerationStateMigration`, `LocalGenerationStateStore`, `LocalPolicyConsentStore`), Foundation `UserDefaults` 2곳(`SharedSessionStateMarkerCoding`, `PendingGenerationReminderCoding`). `PendingGenerationReminderCoding`은 Infrastructure `AppGroupUserDefaults.sharedSessionNamespace`도 참조한다. 이름 변경으로 해소되지 않는다 | Data가 소유하는 역할 계약(전송·저장 능력) 뒤로 숨기거나 생성 인자를 Composition 조립에서만 보이게 한다. 아키텍처 3.3 새 예시는 이 결정을 전제로 공개 initializer를 싣지 않는다 | Data 프로덕션 16개 initializer와 각 테스트, Composition Assembly 6개(`AuthenticationAssembly`, `SessionAvailabilityAssembly`, `ExternalRepositoryAssembly`, `GenerationReminderAssembly`, `LearningProjectAssembly`, `MemberAssembly`), `ShareExtensionComposition` |
| DS-07 | `InfrastructureAuthentication` target의 Keychain·RandomGenerator 하위 능력 | Infrastructure 패키지 규칙 정책 2항, 명세 035 FR-009b | target 하나가 Apple 인증, Keychain, 보안 난수 세 범용 기술을 담는다. Data `Member`·`Authentication`이 Keychain만 쓰려고 `InfrastructureAuthentication` 전체에 의존한다 | `InfrastructureKeychain`·`InfrastructureSecureRandom`으로 분리한다. target 분리는 FR-009b에 따라 별도 명세 | Tuist `InfrastructureModuleName`, Data `DataAuthentication`·`DataMember` 의존성, Composition import, `tools/package-dependencies` 설정, 테스트 target |
| DS-09 | Data 형태 폴더 `Codings/`, `Layouts/`, `Migrations/` | 디렉터리·파일 컨벤션 §4, 파일·형태 어휘 §3 | 어휘표에 없는 형태 폴더 다섯 개를 Data가 쓴다(DOC-08과 짝). 이 기능은 어휘표에 추가하는 문서 교정으로 해소한다 | 표 추가 뒤에도 `Layouts/`(상수 enum)·`Migrations/`(1회성 변환)을 `Stores/`·`Models/`로 합칠지 후속에서 판단한다 | Data `Authentication`·`LearningProject`·`LegalConsent` 폴더와 테스트 미러 폴더 |
| DS-10 | Infrastructure의 앱 고유 식별자 상수 | Infrastructure 패키지 규칙(범용 기술 기능, 서비스 고유 값 미소유), 네이밍 4장 Infrastructure 행 | `Infrastructure/Authentication/Keychain/Stores/AppGroupKeychainStore.swift`가 팀 식별자 접두어 `6924CABL23.`과 access group `com.nexters.hytime.gitit.shared`를, `Infrastructure/Storage/Stores/AppGroupUserDefaults.swift`가 `group.com.nexters.hytime.gitit`과 `com.nexters.hytime.gitit.sharedSession`을 하드코딩한다. 범용 기술 패키지가 이 앱의 배포 구성을 소유한다 | 식별자를 Composition 또는 App 구성으로 옮기고 Infrastructure는 값을 인자로 받는다. Data `PendingGenerationReminderCoding`이 참조하는 `sharedSessionNamespace`는 Data 소유 Layout으로 옮긴다 | Infrastructure 2파일, Composition `SessionAvailabilityAssembly`·`ShareExtensionComposition` 등 조립 코드, Data `PendingGenerationReminderCoding`, App Group 설정 |
| DS-11 | Data 폴더 배치 불일치 | 디렉터리·파일 컨벤션 §4·§8(1뎁스는 형태), 테스트 컨벤션 §7·어휘표 `Tests/<역할>/`(production과 같은 형태 폴더) | `Data/LearningProject/Stores/GenerationStateMigration.swift`는 `Authentication`이 쓰는 `Migrations/` 대신 `Stores/`에 있다. `Data/Tests/LearningProject/Layouts/GenerationReminderStorageCoordinateTests.swift`는 production `LearningProject`에 `Layouts/`가 없는데 테스트만 그 형태 폴더를 쓴다(검증 대상은 `Codings/PendingGenerationReminderCoding`의 key 상수) | DS-09 판단과 함께 `Migrations/` 통일 여부와 테스트 폴더 미러링을 정리한다 | Data 2파일 이동과 테스트 미러 폴더 |
| DS-12 | Domain `GenerationReminderRegistry` 프로토콜의 존치 근거 | 추상화 컨벤션 근거 A·B, 구조 기준선 3.1 | Composition에 채택자가 없고 Domain `ScheduleGenerationReminderUseCase`가 상속하며 `RequestGenerationReminder`가 주입받는다. 요구·제공이 모두 Domain 안이라 의존 방향을 뒤집지 않는다(근거 A 미충족, 프로덕션 교체 지점도 없음). 기준선은 "Composition Adapter" 채택으로 잘못 적고 있다(DOC-11) | UseCase 프로토콜과 같은 3.3 분류로 옮기거나 `ScheduleGenerationReminderUseCase`에 `register(projectID:)`를 직접 두고 제거한다. RN-13 rename은 이 결정 전에 수행한다 | Domain `RequestGenerationReminder`, `ScheduleGenerationReminderUseCase`, 테스트 `RequestGenerationReminderTests`; 구조 기준선 |

### 관심사 중복 쌍 하위 표

DS-01:

| 판정 조건 | Domain 선언 | Data 선언 | 연결 Adapter |
| --- | --- | --- | --- |
| (3) | `sources/Projects/Domain/LearningProject/Models/LearningProject/ExternalRepositoryLocation.swift` `ExternalRepositoryLocation` | `sources/Projects/Data/ExternalRepository/Models/ExternalRepositoryLocation.swift` `ExternalRepositoryLocation` | `sources/Projects/Composition/LearningProject/Adapters/ExternalRepositoryURLParserAdapter.swift` |

DS-02:

| 판정 조건 | Domain 선언 | Data 선언 | 연결 Adapter |
| --- | --- | --- | --- |
| (1) | `sources/Projects/Domain/LearningProject/Contracts/GenerationStateRepository.swift` `GenerationStateRepository` | `sources/Projects/Data/LearningProject/Contracts/GenerationStateStore.swift` `GenerationStateStore` | `sources/Projects/Composition/LearningProject/Adapters/GenerationStateRepositoryAdapter.swift` |

DS-03:

| 판정 조건 | Domain 선언 | Data 선언 | 연결 Adapter |
| --- | --- | --- | --- |
| (1), (2) | `sources/Projects/Domain/LearningProject/Contracts/PendingGenerationReminderStore.swift` `PendingGenerationReminderStore` | `sources/Projects/Data/LearningProject/Codings/PendingGenerationReminderCoding.swift` `PendingGenerationReminderCoding` | `sources/Projects/Composition/LearningProject/Adapters/PendingGenerationReminderStoreAdapter.swift` |

## 2.4 위반 아님 (`OK-NN`)

| ID | 기준 위치 | 대상 위치 | 판정 근거 |
| --- | --- | --- | --- |
| OK-01 | 명세 035 FR-017, 네이밍 4장 Data 행 | `sources/Projects/Data/Member/Stores/LocalDeviceIdentifierStore.swift`, `sources/Projects/Data/LearningProject/Stores/LocalGenerationStateStore.swift`, `sources/Projects/Data/LegalConsent/Stores/LocalPolicyConsentStore.swift` | `Local`은 전송·저장 기술이 아니라 값이 이 기기에 머문다는 위치·수명 문맥이며 `Store`는 Data 어휘표 `Stores/`의 역할어다. 연산(`loadOrCreate`, `load/save`, `records/saveRecord/removeAll`)은 Data 소유 저장 계약이라 FR-020(Domain 대상) 밖이다(research RN-11) |
| OK-02 | 명세 035 FR-020, 명확화 6 | Domain `AuthenticationRepository`, `LoginSessionRepository`, `PolicyConsentRepository`, `AnswerRepository`, `BookmarkRepository`, `GenerationOutcomeRepository`, `GenerationStateRepository`, `LearningProjectRepository`, `LearningSetRepository`, `DeviceIdentifierRepository`, `MemberRepository`와 RN-17·18의 새 이름 `CurrentSessionRepository`·`SharedSignInStateRepository`; `ExternalRepositoryLookup`, `GenerationReminderScheduler` | `Repository`는 명확화 6이 외부 기능 계약의 역할 어휘로 허용한 접미어다. `Lookup`·`Scheduler`는 저장 매체나 형식이 아니라 제공하는 능력(조회·예약)을 표현한다 |
| OK-03 | 명세 035 명확화 5(외부 서비스명은 역할 대상일 때 허용) | `sources/Projects/Data/ExternalRepository/DTOs/GitHubRepositoryResponseDTO.swift`, `Requests/GitHubRepositoryRequest.swift`, `sources/Projects/Data/Authentication/DTOs/AppleLoginRequestDTO.swift`, `Layouts/AppleIdentityKeychainLayout.swift`(RN-10d의 `Apple`), `Stores/AppleIdentityKeychainStore.swift`(RN-10e의 `Apple`) | GitHub API 응답·요청과 Apple 로그인 요청·Apple user ID 저장은 그 서비스 자체가 선언의 역할 대상이다. 직렬화 key(`html_url` 등)는 외부 고정 명칭으로 보존한다 |
| OK-04 | 네이밍 target·소스 폴더 규칙, 디렉터리 §3 | `DataLegalConsent` target(`sources/Projects/Data/LegalConsent/`) ↔ Domain `Authentication/Models/Consent/` | Data target의 관심사 축이 Domain의 모델 폴더와 다르지만, 관심사 분할은 이름 규칙이 아니라 설계 결정이며 target 이름·소스 루트(`LegalConsent/`) 자체는 `<패키지><역할>` 형식과 접두어 제거 규칙을 지킨다 |
| OK-05 | Infrastructure 패키지 규칙 정책 1항(외부 고정 명칭 보존), 네이밍 7장 | Infrastructure 공개 이름 전체: `HTTPClient`, `HTTPTransport`, `HTTPRequest`, `HTTPResponse`, `HTTPMethod`, `HTTPHeaders`, `HTTPBodyCoding`, `URLSessionTransport`, `KeychainStore`, `KeychainNamespace`, `KeychainAccessGroup`, `KeychainAccessibility`, `UserDefaultsStore`, `AppGroupUserDefaults`, `AppGroupKeychainStore`, `AppleAuthorizationProvider`, `AppleCredentialStateProvider`, `AppleCredential`, `FirebaseMessagingPushClient`, `FirebaseMessagingAppDelegate`, `LocalNotificationAuthorizationClient`, `SecureRandomGenerator`, `InMemoryCache` | Infrastructure는 기술을 직접 감싸는 경계라 기술·플랫폼·공급자 명칭을 보존한다(명세 035 가정). FR-017의 기술 비노출 원칙은 Data 공개 선언에만 적용한다 |
| OK-06 | 파일·형태 어휘 §3 `Infrastructure/<능력>/[<하위 능력>/]` | `sources/Projects/Infrastructure/PushMessaging/Remote/` | 하위 능력 폴더는 어휘표에서 선택 항목이며 하나만 있어도 형태 폴더(`AppDelegates/`, `Clients/`, `Models/`)가 그 아래에 있어 1뎁스 형태 규칙을 지킨다(research DS-08) |
| OK-07 | 네이밍 target·소스 폴더 규칙, 디렉터리 §3·§7 | `sources/Tuist/ProjectDescriptionHelpers/Projects/{Domain,Data,Infrastructure}ModuleName.swift`의 프로덕션 target 14개와 테스트 target 12개 | 모든 target이 `<패키지><역할>` 형식이고 `sourceDirectory`가 접두어를 제거한 역할 폴더(`Authentication/`, `Tests/Authentication/` 등)와 일치한다. `InfrastructureAuthentication`은 이름이 아니라 구성(DS-07)의 문제다. FR-009a의 target rename 대상은 없다(research 3.4) |
| OK-08 | 네이밍 4장 Domain 행(공급자 미노출), Constitution 원칙 10 | `sources/Projects/Domain/LearningProject/Models/LearningProject/GenerationRecord.swift` `githubRepoURL`, `GenerationState.swift`의 `githubRepoURL:` 인자 3곳, `UseCases/TrackGeneration/TrackGeneration.swift` `end(githubRepoURL:)`; `sources/Projects/Domain/Authentication/Models/Authentication/AuthenticationMethod.swift` `case apple` | 학습 프로젝트 생성은 GitHub 저장소 URL을 입력으로 받는 제품 기능이고 Apple 로그인은 사용자가 고르는 인증 방식이라, 두 이름은 공급자 구현 용어가 아니라 비즈니스 입력값의 식별자다(서버 필드 `githubRepoUrl`과도 대응). 다만 같은 target의 `ExternalRepository.canonicalURL`·`LearningProjectDetail.repositoryURL`은 중립 이름이라 어휘가 갈린다. 제품이 GitHub 외 저장소를 받게 되면 rename 항목으로 승격한다 |
| OK-09 | 네이밍 접두어·접미어 규칙(`Stored...` 허용), 모델·DTO 규칙, 파일·형태 어휘 `Parsers/` | Domain `LocalOnboardingState`; Data `StoredSessionRecord`, `SharedSessionStateMarkerCoding`, `GitHubRepositoryURLParser`(`Data/ExternalRepository/Parsers/`) | `Local`·`Stored`는 수명·위치를 실제로 구분하는 수식어다. `SharedSessionStateMarkerCoding`은 Data가 소유한 저장 값(App Group 상태 marker)의 인코딩 역할을 그대로 말하며 기술 이름이 없다. `Parser`는 Data 어휘표 폴더 `Parsers/`와 일치하고 FR-020은 Domain 계약에만 적용된다 |
| OK-10 | 명세 035 FR-020(Domain 계약·연산 대상) | Data `GenerationStateStore.load()/save(_:)`, `SessionRecordKeychainCoding.load()/save(_:)/delete()`, `AppleIdentityKeychainStore.load()/save(_:)/delete()`, `SharedSessionStateMarkerCoding.loadSignedInState()/save(…)` | 저장소 연산 이름 금지는 Domain 공개 계약에 적용하는 기준이다. Data는 저장 실행 역할을 소유하므로 `load`/`save`가 역할 그대로다(기술 이름은 없음). RN-16 뒤 Composition `GenerationStateRepositoryAdapter` 내부의 `store.load/save` 호출은 유지한다 |
| OK-11 | 테스트 컨벤션 §2·§3·§7, 파일·형태 어휘 §2.6 | Domain 52·Data 57·Infrastructure 22 테스트 파일 | `import XCTest` 0건, 영어 `func test…` 0건, `@Test` 함수 이름은 모두 한국어 동작 문장이다. 파일 이름은 `<대상>Tests.swift` 또는 동작 범위(`SensitiveValueExposureTests`, `ConcurrentAccessTests`)이며 공유 더블은 `TestDoubles/`에 있다. 테스트 폴더 미러링 예외 1건은 DS-11 |
| OK-12 | 명세 035 FR-017 | `sources/Projects/Data/Authentication/Endpoints/AuthenticationEndpoint.swift` `Method`, `sources/Projects/Data/Member/Endpoints/MemberEndpoint.swift` `Method`, `Data/*/Errors/ServerAPIError.swift` 타입 이름 | 중첩 enum `Method`(`get`·`post`·`delete`)는 요청 값 타입이 소유한 실행 정보이고 이름에 기술 용어가 없다. `ServerAPIError`는 서버 API 실패라는 역할을 말한다. 프로퍼티 `httpStatus`만 DS-04에 기록했다 |
| OK-13 | 파일 하나에 타입 하나(`private`·`fileprivate` 보조 선언 제외) | `sources/Projects/Infrastructure/NetworkClient/Transports/URLSessionTransport.swift` 70행 `extension Duration` | `fileprivate` 계산 프로퍼티 하나를 더하는 파일 내부 보조 확장이라 개수에 포함하지 않는다 |
| OK-14 | 파일·형태 어휘 §3 Infrastructure 행(`Clients/`는 공개 진입 타입) | `sources/Projects/Infrastructure/PushMessaging/Remote/Clients/PushMessagingClientFactory.swift` | Infrastructure 어휘표에 `Factories/`가 없고, 이 enum은 `PushMessagingClient`의 공개 진입점(`make()`)이라 `Clients/`가 맞다 |
| OK-15 | 아키텍처 3.1·7.1, Data 패키지 규칙 제약 | Domain·Data·Infrastructure 프로덕션 `import` 전수(Domain: `Foundation`·`Synchronization`만, Data: `Foundation`·`InfrastructureNetworkClient`·`InfrastructureAuthentication`·`InfrastructureStorage`·`Synchronization`·`os`, Infrastructure: 플랫폼·Firebase SDK) | 세 패키지 모두 허용 의존성 표를 지키고 Domain/Data가 서로나 App·Feature·UI를 import하지 않는다. Data가 Foundation `UserDefaults`를 공개 initializer에서 받는 것은 의존 방향이 아니라 기술 노출 문제라 DS-06에 기록했다 |

## 2.5 검증 결과

U5에서 확인 방법과 실제 실행 결과를 적는다.

| 성공 기준 | 확인 방법 | 결과 |
| --- | --- | --- |
| SC-001 | — | — |
| SC-002 | — | — |
| SC-003 | — | — |
| SC-004 | — | — |
| SC-005 | — | — |
| SC-006 | — | — |
| SC-007 | — | — |
| SC-008 | — | — |
| SC-009 | — | — |
| SC-010 | — | — |
