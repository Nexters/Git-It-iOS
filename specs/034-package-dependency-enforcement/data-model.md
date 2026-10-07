# 데이터 모델: 패키지 의존성 기계 검증과 CompositionAdapter 도메인 축 분할

## 1. 검사 도구의 엔터티

### 1.1 의존성 규칙 설정 (`config/allowed-dependencies`)

| 필드 | 형식 | 규칙 |
| --- | --- | --- |
| 패키지 | `App`·`Composition`·`Feature`·`Domain`·`Data`·`Infrastructure`·`UI` 중 하나 | 7개가 정확히 한 번씩 |
| 허용 패키지 목록 | 공백 구분, 0개 이상 | 알려진 패키지만, 자기 자신 금지, 중복 금지 |

### 1.2 아키텍처 표 행

| 필드 | 원천 | 정규화 |
| --- | --- | --- |
| 패키지 | 3.1 표 첫 열 | 앞뒤 공백 제거 |
| 허용 패키지 목록 | 3.1 표 둘째 열 | 쉼표 분리, `—`는 빈 목록, 이름순 정렬 |

1.1과 1.2는 패키지 이름순으로 정렬한 뒤 행 단위로 같아야 한다.

### 1.3 모듈

| 필드 | 원천 |
| --- | --- |
| 이름 | `enum <패키지>ModuleName`의 `case` |
| 소속 패키지 | 선언한 파일의 `<패키지>` |
| 선언 위치 | 파일 경로와 줄 번호 |

모든 모듈 이름은 저장소 전체에서 유일하다.

### 1.4 Target 블록

| 필드 | 설명 |
| --- | --- |
| target | 블록이 선언하는 모듈 이름 |
| 시작 줄 | `case .<모듈>:` 또는 `name: <패키지>ModuleName.<모듈>.rawValue` 줄 |
| 선언 목록 | 1.5의 목록 |
| production target | test target이면 `productionTarget:`의 모듈, 아니면 없음 |

모듈 하나에 target 블록이 정확히 하나 있다.

### 1.5 모듈 선언

| 필드 | 설명 |
| --- | --- |
| 선언 target | 1.4의 target |
| 형태 | `from`(`.from<패키지>(.<모듈>)`) 또는 `target`(`.target(name: <패키지>ModuleName.<모듈>.rawValue)`) |
| 대상 패키지 | `from`은 `<패키지>`, `target`은 선언 target과 같은 패키지 |
| 대상 모듈 | `<모듈>` |
| 위치 | manifest 경로와 줄 번호 |

검증: 대상 모듈이 대상 패키지가 선언한 모듈이어야 한다. `from`의 대상 패키지가 선언 target
패키지와 다르면 1.1 허용 목록에 있어야 한다.

### 1.6 Source root

| 필드 | 설명 |
| --- | --- |
| target | 1.4의 target |
| 루트 | `GIT_IT_PROJECTS_ROOT` 기준 상대 디렉터리 |

target과 1:1, 루트는 존재하고 target 소속 패키지 디렉터리 아래에 있다. Swift 파일은 접두어가
일치하는 가장 긴 루트에 속한다.

### 1.7 내부 import

| 필드 | 설명 |
| --- | --- |
| 파일 | Swift 파일 경로 |
| 줄 | 줄 번호 |
| 소속 target / 패키지 | 1.6으로 결정 |
| 대상 모듈 / 패키지 | 1.3으로 결정 |

### 1.8 위반

| 규칙 | 조건 | 종료 코드 |
| --- | --- | --- |
| `table-mismatch` | 1.1과 1.2가 다름 | 1 |
| `manifest-package` | 1.5 `from`의 패키지 조합이 허용 목록에 없음 | 1 |
| `import-package` | 1.7의 패키지 조합이 허용 목록에 없음 | 1 |
| `import-undeclared` | 조합은 허용되나 대상 모듈이 target 선언 집합에 없음 | 1 |

선언 집합 = target 자신 ∪ 그 target의 1.5 대상 모듈 ∪ (production target이 있으면 그 target과
그 target의 1.5 대상 모듈).

### 1.9 설정·파싱 오류

모두 종료 코드 2. 위반 판정 전에 멈춘다.

| 종류 | 조건 |
| --- | --- |
| `missing-config` | 설정 파일이 없거나 읽을 수 없음 |
| `invalid-config` | 1.1 규칙 위반 |
| `table-unreadable` | 3.1 제목·머리행·표 행을 찾지 못함 |
| `missing-manifest` | `<패키지>ModuleName.swift` 없음 |
| `module-duplicate` | 같은 모듈 이름을 두 번 선언 |
| `target-missing` / `target-duplicate` | 모듈의 target 블록이 0개 / 2개 이상 |
| `declaration-mismatch` | 1.5 대상 모듈이 대상 패키지 소속이 아님 |
| `source-root-missing` / `source-root-unknown` | target에 1.6 행이 없음 / 1.6 행의 target이 없음 |
| `source-root-absent` / `source-root-package` | 루트 디렉터리 없음 / 소속 패키지 밖 |
| `source-unmapped` | Swift 파일이 어느 루트에도 속하지 않음 |

## 2. Composition target 분할 배치

"의존"은 다른 프로젝트 패키지 모듈에 대한 `.from<패키지>` 선언이다. 같은 패키지 `.target`은
괄호에 따로 적는다.

### 2.1 `CompositionShared` — `sources/Projects/Composition/Shared/`

| 파일 | 원래 위치 |
| --- | --- |
| `Factories/HTTPClientFactory.swift` | `Adapter/Factories/` |

의존(1): `InfrastructureNetworkClient`

### 2.2 `CompositionAuthentication` — `sources/Projects/Composition/Authentication/`

| 파일 | 원래 위치 |
| --- | --- |
| `Adapters/AuthenticationRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/LoginSessionRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/PolicyConsentRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/SharedSessionMarkerRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/StoredSessionRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Assemblies/AuthenticationAssembly.swift` | `Adapter/Assemblies/` |
| `Assemblies/SessionAvailabilityAssembly.swift` | 신설(U6) |
| `Codings/SessionRecordCoding.swift` | `Adapter/Codings/` |

의존(6): `DomainAuthentication`, `DataAuthentication`, `DataLegalConsent`,
`InfrastructureAuthentication`, `InfrastructureNetworkClient`, `InfrastructureStorage`
(+ `CompositionShared`)

### 2.3 `CompositionLearningProject` — `sources/Projects/Composition/LearningProject/`

| 파일 | 원래 위치 |
| --- | --- |
| `Adapters/AnswerRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/BookmarkRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/ExternalRepositoryLookupAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/ExternalRepositoryURLParserAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/GenerationOutcomeRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/GenerationReminderSchedulerAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/GenerationStateRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/LearningProjectRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/LearningSetRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/NotificationAuthorizationGatewayAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/PendingGenerationReminderStoreAdapter.swift` | `Adapter/Adapters/` |
| `Assemblies/ExternalRepositoryAssembly.swift` | `Adapter/Assemblies/` |
| `Assemblies/GenerationReminderAssembly.swift` | `Adapter/Assemblies/` |
| `Assemblies/LearningProjectAssembly.swift` | `Adapter/Assemblies/` |

의존(6): `DomainLearningProject`, `DataLearningProject`, `DataExternalRepository`,
`InfrastructureNetworkClient`, `InfrastructureStorage`, `InfrastructureLocalNotification`
(+ `CompositionShared`)

### 2.4 `CompositionMember` — `sources/Projects/Composition/Member/`

| 파일 | 원래 위치 |
| --- | --- |
| `Adapters/CurationRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/DeviceIdentifierRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Adapters/MemberRepositoryAdapter.swift` | `Adapter/Adapters/` |
| `Assemblies/MemberAssembly.swift` | `Adapter/Assemblies/` |

의존(5): `DomainAuthentication`, `DomainMember`, `DataMember`, `InfrastructureAuthentication`,
`InfrastructureNetworkClient` (+ `CompositionShared`)

### 2.5 조립 루트

| target | 의존(분할 전 → 후) | 같은 패키지 |
| --- | --- | --- |
| `CompositionApp` | 9 → 6: `DomainAuthentication`, `DomainLearningProject`, `DomainMember`, `InfrastructureAuthentication`, `InfrastructureNetworkClient`, `InfrastructurePushMessaging` | `CompositionAuthentication`, `CompositionLearningProject`, `CompositionMember` |
| `CompositionShareExtension` | 8 → 6: `DomainAuthentication`, `DomainLearningProject`, `InfrastructureAuthentication`, `InfrastructureLocalNotification`, `InfrastructureNetworkClient`, `InfrastructureStorage` | `CompositionAuthentication`, `CompositionLearningProject` |

App 패키지 `ShareExtension` target은 쓰지 않는 `.fromComposition(.CompositionAdapter)`와
`ShareViewController.swift`의 `import CompositionAdapter`를 지운다.

### 2.6 테스트 target

| target | 루트 | production | 추가 선언 |
| --- | --- | --- | --- |
| `CompositionAuthenticationTests` | `Composition/Tests/Authentication` | `CompositionAuthentication` | 없음 |
| `CompositionLearningProjectTests` | `Composition/Tests/LearningProject` | `CompositionLearningProject` | 없음 |
| `CompositionMemberTests` | `Composition/Tests/Member` | `CompositionMember` | 없음 |
| `CompositionAppTests` | `Composition/Tests/App` | `CompositionApp` | `DataAuthentication` |
| `CompositionShareExtensionTests` | `Composition/Tests/ShareExtension` | `CompositionShareExtension` | `DataAuthentication`, `DataLearningProject` |

테스트 파일 배정은 [research.md](./research.md) 9절에 있다. `Composition/Tests/Adapter/`는
사라진다.

## 3. 조립 API 변화(U6)

공개 타입의 추가만 있고 기존 공개 멤버 제거는 `MemberAssembly.repository` 하나다. 이
멤버의 소비자는 `AppComposition`뿐이다.

| 타입 | 변화 | 대체하는 루트 코드 |
| --- | --- | --- |
| `AuthenticationAssembly` | `static func migrateSessionKeychain(sharedKeychainStore: KeychainStore)` 추가 | `SessionKeychainMigration(sharedKeychainStore:legacyKeychainStore:)()` |
| `AuthenticationAssembly` | `init`에 `sharedDefaults: UserDefaults? = AppGroupUserDefaults.makeShared()` 추가, `recordSharedSessionState: @Sendable () async -> Void` 공개 | `markerCoding?.save(isSignedIn:)` |
| `SessionAvailabilityAssembly` | 신설. `init(keychainStore:sharedDefaults:)`, `resolveSessionAvailability`, `accessTokenProvider` | ShareExtension 루트의 세션 판정 closure 두 개 |
| `MemberAssembly` | `makeRegisterCurrentDevice(keychainStore:appVersion:osVersion:deviceTokenProvider:) -> @Sendable () async throws -> Void` 추가, `repository` 제거 | `RegisterCurrentDevice(repository:deviceIdentifierRepository:…)` |
| `GenerationReminderAssembly` | `static func makePendingReminderEnqueue(sharedDefaults: UserDefaults?) -> @Sendable (String) async -> Void` 추가 | `PendingGenerationReminderCoding.append(projectID:)` |
| `makeHTTPClient` | `internal` → `public` (I5) | — |

상태 전이·저장 키·호출 순서는 바뀌지 않는다. 키체인 마이그레이션은 `AppComposition.live`
첫 줄에서 계속 먼저 실행된다.
