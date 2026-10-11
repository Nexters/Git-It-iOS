# 계약: 네이밍과 시그니처

**관련 요구사항**: FR-005, FR-006, FR-045 / Constitution 원칙 10 / `docs/conventions/naming.md`

**조사 근거**: [research.md](../research.md) R-001, R-011 ~ R-016

## 1. 이름 규약

| 대상 | 규약 | 예 |
|---|---|---|
| Domain UseCase Protocol | `<동사><명사>UseCase` | `FetchLearningProjectsUseCase` |
| Domain UseCase 구현 | `<동사><명사>` | `FetchLearningProjects` |
| UseCase 호출 진입점 | `callAsFunction` | — |
| Data Remote 계약 | `<대상>Remote` *(기존 유지)* | `ProjectRemote` |
| Data Remote 구현 | `HTTP<계약이름>` | `HTTPProjectRemote` |
| Domain↔Data Adapter | `<Domain 계약 이름>Adapter` | `LearningProjectRepositoryAdapter` |
| Composition 조립 진입점 | `<기능>Assembly` | `LearningProjectAssembly` |
| Composition target | `CompositionAdapter` *(rename 후)* | — |

**금지**: `Default` 접두어, 패키지 이름 접두어(`Domain...`, `Data...`), 소속 표시용 공통 축약
접두어, 책임을 설명하지 않는 `Manager`·`Service`·`Handler`.

**표준 약어**: `HTTP`, `URL`, `ID`는 식별자 첫 단어가 아니면 전부 대문자, 첫 단어이면 전부
소문자로 쓴다. `Http`, `Url`, `Id` 형태를 쓰지 않는다.

## 2. 신설 Protocol 확정 시그니처 (DomainAuthentication)

```swift
public protocol SignInUseCase: Sendable {
    func callAsFunction(_ method: AuthenticationMethod) async -> AuthenticationOutcome
}

public protocol SignOutUseCase: Sendable {
    func callAsFunction() async -> AuthenticationOutcome
}

public protocol RestoreSessionUseCase: Sendable {
    func callAsFunction() async -> AuthenticationOutcome
}

public protocol ObserveAuthenticationOutcomesUseCase: Sendable {
    func callAsFunction() async -> AsyncStream<AuthenticationOutcome>
}
```

**제약**: 구현의 현재 시그니처를 문자 그대로 옮긴다. 파라미터 레이블, 생략 레이블(`_`),
`async`·`throws` 유무를 바꾸지 않는다. 시그니처 변경은 Protocol 추출이 아니라 동작 계약
변경이다.

## 3. 기존 Protocol 시그니처 (rename 후, DomainLearningProject)

연산 집합과 동작은 그대로이며 §4.1의 표기 rename만 반영한다.

```swift
FetchLearningProjectsUseCase.callAsFunction(page: Int, size: Int) async throws -> LearningProjectPage
FetchLearningProjectDetailUseCase.callAsFunction(projectID: String) async throws -> LearningProjectDetail
CreateLearningProjectUseCase.callAsFunction(githubRepoURL: String, quizLevel: QuizLevel) async throws -> LearningProjectRegistration
DeleteLearningProjectUseCase.callAsFunction(projectID: String) async throws
FetchExternalRepositoryUseCase.callAsFunction(url: String) async throws -> ExternalRepository
```

**호출 규칙**: `page`와 `size`는 항상 명시한다. Protocol 요구사항에는 기본 인자를 둘 수 없고,
Protocol extension으로 기본값을 흉내 내지 않는다(R-014).

## 4. rename 대상 *(이번 범위에 포함)*

`docs/conventions/naming.md` §8은 rename을 설계·동작 변경과 분리하도록 요구하지만, 이 기능이
Domain UseCase 계약을 정본으로 확정하는 시점이라 사용자 결정으로 예외를 적용한다. 예외 근거는
Constitution 원칙 3에 따라 PR에 기록한다(FR-068, R-018).

### 4.1 표준 약어 표기 — `DomainLearningProject`

| 현재 | 변경 후 | 선언 위치 |
|---|---|---|
| `projectId` | `projectID` | `LearningProjectRepository`(2개 연산), `FetchLearningProjectDetailUseCase`, `DeleteLearningProjectUseCase`, `FetchLearningProjectDetail`, `DeleteLearningProject`, `LearningProjectSummary`, `LearningProjectDetail`, `LearningProjectRegistration` |
| `githubRepoUrl` | `githubRepoURL` | `LearningProjectRepository.register`, `CreateLearningProjectUseCase`, `CreateLearningProject` |
| `nextSetId` | `nextSetID` | `LearningProjectSummary` |
| `nextQuestionId` | `nextQuestionID` | `LearningProjectSummary`, `LearningProjectDetail` |
| `setId` | `setID` | `LearningProjectSetProgress` |

Domain 테스트(`Domain/Tests/LearningProject/**`)의 호출부와 Test Double 레이블도 함께 바꾼다.

**배정**: Domain 단계.

### 4.2 UseCase 이름 — `DomainAuthentication`

| 현재 | 변경 후 |
|---|---|
| `ObserveAuthorizationChanges` | `ObserveAuthenticationOutcomes` |
| *(신설)* | `ObserveAuthenticationOutcomesUseCase` |

이름만 바꾸고 구현 본문과 동작은 그대로 둔다. **관찰과 세션 복원의 책임 분리는 범위 밖이다.**

**배정**: Domain 단계. Protocol 신설(FR-008)과 함께 수행한다.

### 4.3 Tuist target 철자

| 현재 | 변경 후 |
|---|---|
| `CompositionAdepter` | `CompositionAdapter` |
| `CompositionAdepterTests` | `CompositionAdapterTests` |
| `Composition/Adepter/` | `Composition/Adapter/` |
| `Composition/Tests/Adepter/` | `Composition/Tests/Adapter/` |

영향 파일: `CompositionModuleName.swift`, `ProjectName.swift`, `AppModuleName.swift`(참조
1건, FR-064a), placeholder 소스와 컴파일 테스트(파일명·타입명·`@testable import`·`@Suite`
문자열).

**배정**: Composition 단계.

### 4.4 rename 대상이 아닌 것

- Data DTO의 `CodingKeys`가 보존하는 서버 원문 키 — `"githubRepoUrl"`, `"repositoryUrl"`,
  `"repositoryImageUrl"`, `"nextSetId"`, `"nextQuestionId"`, `"setId"` (FR-066)
- 테스트의 JSON fixture 문자열과 서버 오류 `field` 값
- 이미 규칙을 지키는 경계 — `DomainAuthentication`, Domain의 `ExternalRepository`, Data,
  Infrastructure, UI
- `docs/spec-kit/006-final-uxui-screens/trouble-shooting.md`의 `Adepter` 언급 — Constitution
  원칙 9에 따라 append-only 기록은 수정하지 않는다 (R-019)

### 4.5 순수 rename 보장

다음을 함께 바꾸면 순수 rename이 아니다 (FR-065).

- 연산 집합 또는 타입의 상태
- 저장 위치, 값의 수명과 소유자
- 비동기·오류·취소 동작
- 패키지 책임 또는 의존 방향
- 외부 API·schema와의 mapping 또는 호환성

**검증**: rename 전후로 동일한 테스트 집합이 통과해야 한다 (FR-067, SC-020).

### 4.6 표기 반전이 발생하지 않는다

Domain 단계에서 표기 rename을 끝내므로, Data 단계의 구현과 Composition 단계의 Adapter는
처음부터 `projectID`·`githubRepoURL` 표기로 작성된다. Adapter에서 식별자·URL 필드의 표기를
뒤집는 변환은 **0건이어야 한다** (SC-022).

## 5. 검토 체크리스트 (구현 시 적용)

- [ ] 새 공개 이름의 각 단어가 실제 책임·경계·수명을 설명하는가?
- [ ] 표준 약어가 `Http`·`Url`·`Id` 절충 표기 없이 위치에 맞게 표기됐는가?
- [ ] Protocol 시그니처가 구현과 문자 그대로 일치하는가?
- [ ] Data 구현 이름의 기술 용어가 그 구현이 실제로 소유하는 기술인가?
- [ ] Composition 이름이 Adapter·조립·수명 문맥을 벗어나 새 비즈니스 책임을 암시하지 않는가?
- [ ] rename이 이 기능의 동작 변경과 섞이지 않았는가?
- [ ] Adapter에 표기를 뒤집는 변환이 남아 있지 않은가? (§4.6)
- [ ] rename이 §4.5의 항목을 함께 바꾸지 않았는가?
