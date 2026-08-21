# 데이터 모델: Feature → Domain UseCase 의존과 App 소유 의존성 주입

**날짜**: 2026-08-21 | **명세**: [spec.md](./spec.md) | **조사**: [research.md](./research.md)

이 기능은 새 비즈니스 엔터티를 만들지 않는다. 아래는 이번 변경이 다루는 **계약과 타입 경계**의
목록이며, 각 항목은 현재 상태와 목표 상태를 함께 기록한다.

## 1. Domain UseCase 계약

### 1.1 LearningProject *(현재 완비)*

| Protocol | 구현 | 시그니처 | 상태 |
|---|---|---|---|
| `FetchLearningProjectsUseCase` | `FetchLearningProjects` | `callAsFunction(page:size:) async throws -> LearningProjectPage` | 존재 |
| `FetchLearningProjectDetailUseCase` | `FetchLearningProjectDetail` | `callAsFunction(projectID:) async throws -> LearningProjectDetail` | 존재 (레이블 rename) |
| `CreateLearningProjectUseCase` | `CreateLearningProject` | `callAsFunction(githubRepoURL:quizLevel:) async throws -> LearningProjectRegistration` | 존재 (레이블 rename) |
| `DeleteLearningProjectUseCase` | `DeleteLearningProject` | `callAsFunction(projectID:) async throws` | 존재 (레이블 rename) |
| `FetchExternalRepositoryUseCase` | `FetchExternalRepository` | `callAsFunction(url:) async throws -> ExternalRepository` | 존재 |

### 1.2 Authentication *(Protocol 신설 대상)*

`ObserveAuthorizationChanges`는 `ObserveAuthenticationOutcomes`로 rename한다(FR-063).

| Protocol | 구현 | 시그니처 | 상태 |
|---|---|---|---|
| `SignInUseCase` | `SignIn` | `callAsFunction(_ method: AuthenticationMethod) async -> AuthenticationOutcome` | **신설** |
| `SignOutUseCase` | `SignOut` | `callAsFunction() async -> AuthenticationOutcome` | **신설** |
| `RestoreSessionUseCase` | `RestoreSession` | `callAsFunction() async -> AuthenticationOutcome` | **신설** |
| `ObserveAuthenticationOutcomesUseCase` | `ObserveAuthenticationOutcomes` | `callAsFunction() async -> AsyncStream<AuthenticationOutcome>` | **신설 + 구현 rename** |

**검증 규칙**: 모든 Protocol은 `Sendable`을 요구한다. 입력·출력·오류 타입은 Domain 소유
타입이거나 언어 표준 타입이어야 한다(FR-003, FR-004).

## 2. Domain Repository 계약 *(변경 없음, Adapter의 구현 대상)*

| Protocol | 소유 모듈 | 연산 |
|---|---|---|
| `LearningProjectRepository` | `DomainLearningProject` | `register`, `fetchProjects`, `fetchProjectDetail`, `deleteProject` *(파라미터 레이블 rename)* |
| `ExternalRepositoryLookup` | `DomainLearningProject` | `repository(owner:name:)` |
| `AuthenticationRepository` | `DomainAuthentication` | `authenticate`, `authorizationStatus`, `authorizationChanges`, `clearAuthentication` |
| `LoginSessionRepository` | `DomainAuthentication` | `start`, `restore`, `signOut` |

## 3. Data 기술 계약과 구현

| Data Protocol | 소유 모듈 | 구현 상태 | 이번 목표 |
|---|---|---|---|
| `ProjectRemote` | `DataLearningProject` | 없음 | `HTTPProjectRemote` 신설 |
| `LearningSetRemote` | `DataLearningProject` | 없음 | **범위 밖** — `LearningProjectRepository`는 `ProjectRemote`만으로 충족 |
| `QuizGenerationRemote` | `DataLearningProject` | 없음 | **범위 밖** — `LearningProjectRepository`는 `ProjectRemote`만으로 충족 |
| `AnswerRemote` | `DataLearningProject` | 없음 | **범위 밖** — `LearningProjectRepository`는 `ProjectRemote`만으로 충족 |
| `BookmarkRemote` | `DataLearningProject` | 없음 | **범위 밖** — `LearningProjectRepository`는 `ProjectRemote`만으로 충족 |
| `AuthenticationRemote` | `DataAuthentication` | 없음 | `HTTPAuthenticationRemote` 신설 |
| `ExternalRepositoryRemote` | `DataExternalRepository` | 없음 | `HTTPExternalRepositoryRemote` 신설 |
| `MemberRemote` | `DataMember` | 없음 | **범위 밖** (대응 Domain 계약 없음) |

**범위 근거**: `LearningSetRemote`·`QuizGenerationRemote`·`AnswerRemote`·`BookmarkRemote`는
[contracts/composition-graph.md](./contracts/composition-graph.md)의 조립 대상 표가 요구하지
않는다. `LearningProjectRepository`의 연산(`register`, `fetchProjects`, `fetchProjectDetail`,
`deleteProject`)은 `ProjectRemote`의 연산과 1:1로 대응하므로 이번 조립에는 `HTTPProjectRemote`
하나만 필요하다(tasks.md 참고 절, plan.md 위험과 대응 표).

**요청·응답 값 경계** (R-004에 따라 존치):

- Data 소유 요청 타입: `LearningProjectRequest`, Data의 `HTTPMethod`, `AuthorizedRequestHeaders`,
  `GitHubRepositoryRequest`, `*Endpoint` 열거형
- Infrastructure 타입: `HTTPRequest`, `HTTPResponse<Body>`, `HTTPHeaders`, `HTTPClientError`
- **변환 책임**: Data의 concrete Remote 구현이 소유한다.

## 4. 오류 변환 경로

```text
HTTPClientError            (Infrastructure)
  ↓ Data Remote 구현
DataLearningProjectError / DataAuthenticationError / DataExternalRepositoryError
  ↓ Composition Domain↔Data Adapter
LearningProjectError / AuthenticationError / LoginSessionError / ExternalRepositoryError
  ↓
Domain UseCase → (후속) Feature
```

| Infrastructure 오류 | Data 오류 |
|---|---|
| `.connectionFailed`, `.timedOut`, `.cancelled` | `.transport` |
| `.responseDecodingFailed`, `.requestEncodingFailed` | `.decoding` |
| 비 2xx 응답 본문 | `ServerAPIError` 파싱 후 `init(from:)` 매핑 |

**검증 규칙**: Domain UseCase 호출자에게 도달하는 오류에 `HTTPClientError`나 Data 오류 타입이
노출되면 FR-004 위반이다.

## 5. Composition 조립 단위

| 조립 진입점 | Adapter | 충족하는 Domain 계약 | 사용하는 구현 | 공유 수명 |
|---|---|---|---|---|
| `LearningProjectAssembly` | `LearningProjectRepositoryAdapter` | `LearningProjectRepository` | `HTTPProjectRemote` | 세션 단위 공유 |
| `ExternalRepositoryAssembly` | `ExternalRepositoryLookupAdapter` | `ExternalRepositoryLookup` | `HTTPExternalRepositoryRemote` | 세션 단위 공유 |
| `AuthenticationAssembly` | `AuthenticationRepositoryAdapter` | `AuthenticationRepository` | Infrastructure Apple 인증·Keychain | 앱 단위 단일 |
| `AuthenticationAssembly` | `LoginSessionRepositoryAdapter` | `LoginSessionRepository` | `HTTPAuthenticationRemote` + Keychain | 앱 단위 단일 |

**검증 규칙**: `HTTPClient`와 Keychain 저장소는 조립 진입점당 1회만 생성해 모든 Adapter가
공유한다(FR-027, SC-010). 노출되는 property는 §1의 UseCase Protocol 타입뿐이다(FR-022).
타입 이름 규약과 근거는 [contracts/naming-and-signatures.md](./contracts/naming-and-signatures.md)를 따른다.

**표기 일치**: Domain 단계에서 표준 약어 표기 rename을 끝내므로 Domain과 Data의 표기가
일치한다. Adapter에서 식별자·URL 필드의 표기를 뒤집는 변환은 0건이어야 한다(SC-022, R-020).

## 6. 목표 패키지 의존성

| 패키지 | 현재 선언 | 목표 선언 |
|---|---|---|
| `DomainAuthentication`, `DomainLearningProject` | 없음 | 없음 (변경 없음) |
| `InfrastructureNetworkClient`, `InfrastructureAuthentication`, `InfrastructureCache` | 없음 | 없음 (변경 없음) |
| `DataAuthentication` | 없음 | `InfrastructureNetworkClient`, `InfrastructureAuthentication` |
| `DataLearningProject` | 없음 | `InfrastructureNetworkClient` |
| `DataExternalRepository` | 없음 | `InfrastructureNetworkClient` |
| `DataMember` | 없음 | 없음 (범위 밖) |
| `CompositionAdapter` *(rename 후)* | 없음 | Domain·Data·Infrastructure의 필요한 target |
| `Feature` | `DomainLearningProject`, UI, TCA | 변경 없음 |
| `GitIt` (App) | Composition, Feature, `DomainAuthentication` | 동일. target 이름 참조만 `CompositionAdapter`로 갱신 (FR-064a) |
