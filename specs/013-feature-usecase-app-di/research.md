# 조사: Feature → Domain UseCase 의존과 App 소유 의존성 주입

**날짜**: 2026-08-21 | **명세**: [spec.md](./spec.md)

이 문서는 계획 수립에 필요한 미결 사항을 저장소의 실제 코드로 확인하고 결정한 기록이다.
모든 근거는 현재 작업 트리에서 재확인할 수 있다.

## R-001. UseCase Protocol과 구현의 네이밍 규약

- **결정**: Protocol은 `<동사><명사>UseCase`, 구현 타입은 `<동사><명사>`로 하고 호출 진입점은
  `callAsFunction`으로 통일한다. 입력 문서의 `DefaultFetchLearningProjectsUseCase` 형태는 쓰지 않는다.
- **근거**: `Domain/LearningProject/UseCases`에 이미 확립된 규약이다.
  `FetchLearningProjectsUseCase` ↔ `FetchLearningProjects`,
  `DeleteLearningProjectUseCase` ↔ `DeleteLearningProject` 쌍이 존재한다. Constitution 원칙 10은
  표면적 통일을 위한 일괄 접두어를 금지하며, `Default` 접두어는 책임을 드러내지 않는다.
- **검토한 대안**: 입력 문서의 `Default` 접두어 규약. 기존 4쌍을 모두 개명해야 하고 원칙 10에
  어긋나므로 기각.

## R-002. Authentication UseCase Protocol 추가 대상

- **결정**: `SignInUseCase`, `SignOutUseCase`, `RestoreSessionUseCase`,
  `ObserveAuthorizationChangesUseCase` 4개를 추가하고 기존 `SignIn`, `SignOut`, `RestoreSession`,
  `ObserveAuthorizationChanges`가 각각 conform하도록 한다. **네 번째 Protocol 이름은 R-018에서
  `ObserveAuthenticationOutcomesUseCase`로, 구현은 `ObserveAuthenticationOutcomes`로 확정됐다.** 시그니처는 현재 구현의
  `callAsFunction`을 그대로 옮긴다.
- **근거**: 네 타입 모두 `Sendable` 준수 struct이며 Repository 두 개를 생성자 주입받는 형태라
  Protocol 추출에 추가 설계가 필요 없다. 반환 타입 `AuthenticationOutcome`,
  `AsyncStream<AuthenticationOutcome>`은 모두 Domain 소유 타입이라 FR-003·FR-004를 이미 만족한다.
- **검토한 대안**: 네 UseCase를 하나의 `AuthenticationUseCase`로 묶기. FR-007(무관한 작업 결합
  금지)에 위배되므로 기각.

## R-003. Data Remote 구현이 사용할 Infrastructure API

- **결정**: `InfrastructureNetworkClient`의 `HTTPClient`를 그대로 사용한다. Data 구현은
  Data 소유 요청 값(`LearningProjectRequest` 등)을 `HTTPRequest`로 변환해 `HTTPClient.send`를
  호출하고, `HTTPResponse.Body`와 `HTTPClientError`를 Data 오류로 변환한다.
- **근거**: `HTTPClient`는 baseURL·공통 헤더·타임아웃·취소·본문 인코딩·상태코드 분기를 이미
  제공하며 `HTTPClientError`가 `connectionFailed`, `timedOut`, `cancelled`,
  `responseDecodingFailed`를 구분한다. Data 오류(`DataLearningProjectError` 등)의
  `.transport`, `.decoding` 케이스와 직접 대응한다.
- **검토한 대안**: Data가 `URLSession`을 직접 사용. Infrastructure 경계를 우회하므로 기각.

## R-004. Data 소유 요청 타입의 존치

- **결정**: `LearningProjectRequest`, Data의 `HTTPMethod`, `AuthorizedRequestHeaders`,
  `*Endpoint` 열거형을 그대로 유지하고, 새 concrete 구현이 이들을 Infrastructure 타입으로
  변환하는 책임을 진다.
- **근거**: 명세는 "서버 endpoint, DTO 스키마 변경 없음"을 가정으로 명시한다. 이 타입들은
  이미 Data 테스트가 검증하고 있으며, 존치하면 endpoint 정의와 전송 수단이 분리된 상태가
  유지돼 Data 테스트를 Infrastructure 없이 실행할 수 있다.
- **검토한 대안**: Data 요청 타입을 삭제하고 Infrastructure `HTTPRequest`를 직접 사용.
  Data 계약 테스트를 다시 써야 하고 명세의 무변경 가정을 깨므로 기각.

## R-005. `D-ARCH-003` 결정 기록의 위치

- **결정**: `docs/architecture.md` 끝에 `## 9. 아키텍처 결정 기록` 절을 신설해 기록한다.
- **근거**: 저장소에 `decision-log.md`가 존재하지 않는다. 새 파일과 새 문서 규약을 도입하는
  대신 아키텍처 정본 문서 안에 두면 FR-056(문서 일관성) 검증이 한 파일에서 끝난다.
- **검토한 대안**: `docs/architecture-decisions.md` 신설. 문서 규약과 상호 참조 규칙을 함께
  정해야 하므로 이번 범위에서 기각.

## R-006. 의존 규칙 개정이 필요한 문서 범위 *(명세보다 넓음)*

- **결정**: FR-059·FR-061의 대상은 `docs/architecture.md` 하나가 아니다. 다음 세 파일을 함께
  개정해야 규칙이 일관된다.
  - `docs/architecture.md` — 3.1 의존성 표, 7.1 금지 목록, 3.3 Adapter 경계, 4장 제어 흐름
  - `docs/package-rules/data.md` — "프로젝트 내부의 다른 패키지에 의존해서는 안 됩니다",
    "Infrastructure 타입 또는 외부 라이브러리의 구체 API를 직접 참조해서는 안 됩니다",
    "Data↔Infrastructure Adapter를 Data 내부에 구현해서는 안 됩니다" 3개 제약
  - `docs/package-rules/composition.md` — "Data가 정의한 기술 계약은 Core가 제공하는 내부
    API를 이용한 Adapter로 충족" 정책과 Data↔Infrastructure Adapter 소유 서술
- **근거**: 세 파일 모두 현재 `Data → Infrastructure`를 금지하고 Data↔Infrastructure Adapter를
  Composition 책임으로 규정한다. 아키텍처 문서만 고치면 패키지 규칙 문서가 반대 규칙을
  유지해 FR-056(모순 서술 0건)을 만족할 수 없다.
- **검토한 대안**: 아키텍처 문서만 개정. 남은 두 문서가 구현과 정면으로 모순되므로 기각.

## R-007. 패키지 구현 순서와 그 근거

- **결정**: `Domain → Infrastructure → Data → Composition` 순서로 진행한다.
- **근거**: 개정 후 의존 규칙에서 Domain과 Infrastructure는 서로 의존하지 않는 leaf,
  `Data → Infrastructure`, `Composition → Domain·Data·Infrastructure`이다. 따라서 Data는
  Infrastructure보다 뒤, Composition은 마지막이 강제된다. Domain과 Infrastructure는 상호
  독립이므로 Constitution 원칙 7에 따라 이 계획이 상대 순서를 정한다. Domain을 먼저 두는
  이유는 Domain UseCase Protocol이 Composition이 노출할 타입의 기준이고, Infrastructure
  보완 범위(FR-010)는 Data 구현 설계에서 도출되므로 Domain 확정 뒤에 판단하는 편이
  정확하기 때문이다.
- **검토한 대안**: `Infrastructure → Domain → Data → Composition`. 위상적으로 동등하게
  유효하지만 Infrastructure 보완 범위를 Domain 계약 확정 전에 판단해야 해서 기각.
- **비고**: 이 순서는 개정 전 의존성 표에서도 유효하므로, 문서 개정 전에 순서 불일치로
  구현이 막히는 상황은 발생하지 않는다.

## R-008. 문서 개정 작업의 패키지 배정

- **결정**: FR-055·FR-059·FR-061의 문서 개정 작업을 **Domain 단계의 선행 작업**으로 배정하고,
  Domain 소스 변경보다 앞에 배치한다.
- **근거**: FR-060은 문서 개정이 어떤 패키지 구현 작업보다 먼저 끝나야 한다고 요구한다.
  Constitution 원칙 7은 파일 변경 작업을 반드시 하나의 책임 패키지 단계 안에 배치하도록
  요구하며, 원칙 4는 `docs/**`를 정확한 파일 경로로 명시한 작업만 허용한다. 첫 적용 대상
  패키지인 Domain 단계의 선두에 두면 두 요구를 동시에 만족한다.
- **검토한 대안**: Data 단계에 배정(의존성 선언을 최초로 필요로 하는 패키지). FR-060의
  "어떤 패키지 구현 작업보다 먼저"를 위반하므로 기각.

## R-009. Composition 공개 API의 형태

- **결정**: 기능별로 분리한 조립 진입점을 제공하고, 하나의 거대한 컨테이너 타입을 만들지
  않는다. 각 진입점은 Domain UseCase Protocol 타입만 노출한다.
- **근거**: FR-028(내부 타입 비노출)과 FR-051(Feature에 컨테이너 전체 전달 금지)을 구조로
  강제한다. 공유가 필요한 객체(HTTPClient, Keychain, 세션 Repository)는 조립 시점에 한 번
  만들어 주입하는 방식으로 FR-027·SC-010(중복 생성 0건)을 만족시킨다.
- **검토한 대안**: 단일 `AppComposition` 값 타입. 입력 문서의 예시지만, App이 그 값을
  통째로 Feature에 넘기기 쉬워 FR-051 위반을 구조적으로 유도하므로 기각.
- **비고**: 최종 타입 이름과 분할 단위는 Composition 단계 착수 시 확정한다. 이번 계획은
  "노출 타입은 Domain Protocol", "공유 객체는 1회 생성"이라는 제약만 고정한다.

## R-010. 기존 Composition target 이름

- **결정**: ~~기존 `CompositionAdepter` target 이름을 그대로 사용하고 이번 범위에서 개명하지
  않는다.~~ → **R-018로 번복**. 사용자 결정에 따라 이번 범위에서 `CompositionAdapter`로 rename한다.
- **근거**: 철자 오류(`Adepter`)가 있으나 target 이름 변경은 Tuist manifest, 디렉터리,
  테스트 target, App 의존성 선언을 동시에 바꾸는 별개의 변경이다. 명세의 범위 밖이며
  Constitution 원칙 10은 네이밍 변경과 동작 변경의 범위를 분리하도록 요구한다.
- **검토한 대안**: 이번에 `CompositionAdapter`로 개명. 범위를 넓히고 검증을 섞으므로 기각.
- **비고**: 아래 기각 근거는 당시 판단이며, 사용자 결정으로 무효화됐다. R-018 참조.

---

# 추가 조사: 시그니처와 네이밍 점검 (2026-08-21)

`docs/conventions/naming.md`(최종 수정 2026-08-21, "표준 약어 대소문자 규칙 추가")를 기준으로
이번 계획이 만들거나 경유하는 시그니처를 점검했다.

## R-011. `projectId` 표기 위반과 이번 범위에서의 처리

- **사실**: Domain은 `projectId`(소문자 `d`), Data는 `projectID`를 사용한다.
  `LearningProjectRepository.fetchProjectDetail(projectId:)`,
  `DeleteLearningProjectUseCase.callAsFunction(projectId:)`,
  `LearningProjectSummary.projectId`, `LearningProjectDetail.projectId`,
  `LearningProjectRegistration.projectId`가 해당한다. Data의 `ProjectEndpoint.detail(projectID:)`
  등은 규칙을 지키고 있다.
- **판정**: `docs/conventions/naming.md` §9는 `projectID`를 허용 예, `projectId`를 비허용 예로
  명시한다. 현재 Domain 표기는 이 규칙 위반이다.
- **결정**: ~~이번 기능에서 고치지 않는다.~~ → **R-018로 번복**. 사용자 결정에 따라 이번
  범위에서 rename한다.
- **근거**: `naming.md` §8은 rename을 설계·동작 변경과 분리하도록 요구한다. 이 rename은 Domain
  모델 3개, Repository 계약, UseCase Protocol 2개, 구현 2개와 Domain 테스트를 동시에 바꾸며,
  이번 기능의 Data 구현·Composition 조립 변경과 섞이면 검증 범위를 구분할 수 없다.
- **검토한 대안**: 이번 기능에 포함해 한 번에 정리. 명세의 범위 밖이고 §8 위반이므로 기각.
- **영향**: Composition의 Domain↔Data Adapter가 `projectId`(Domain)와 `projectID`(Data) 사이를
  잇는 이음매가 된다. 동작에는 영향이 없으나 Adapter 구현에서 표기가 엇갈리므로, 해당 지점에
  이 결정을 참조하는 주석을 남기지 않고 별도 명세로 정리한다.
- **후속**: 순수 rename을 별도 명세 후보로 남긴다. 실제 범위는 `projectId` 하나가 아니라
  R-017의 전수 조사 결과 전체다.

## R-012. 신설 Protocol의 확정 시그니처

- **결정**: 구현의 현재 시그니처를 문자 그대로 옮긴다. 파라미터 레이블, 생략 레이블(`_`),
  `async`/`throws` 유무를 바꾸지 않는다.

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

public protocol ObserveAuthorizationChangesUseCase: Sendable {
    func callAsFunction() async -> AsyncStream<AuthenticationOutcome>
}
```

**R-018 반영**: 네 번째 Protocol의 확정 이름은 `ObserveAuthenticationOutcomesUseCase`이며
구현은 `ObserveAuthenticationOutcomes`로 rename한다. 시그니처는 위와 동일하다.

- **근거**: 네 구현 모두 `async`이며 오류를 던지지 않고 `AuthenticationOutcome`으로 결과를
  표현한다. 시그니처를 바꾸면 Protocol 추출이 아니라 동작 계약 변경이 되어 §8에 걸린다.
- **검토한 대안**: `throws`를 도입해 실패를 오류로 표현. 기존 `AuthenticationOutcome`의
  `.recoverableFailure`/`.unauthenticated` 구분과 중복되고 동작 변경이므로 기각.

## R-013. `ObserveAuthorizationChanges`의 이름과 반환 타입 불일치

- **사실**: 이름은 authorization 변화 관찰을 뜻하지만 반환은
  `AsyncStream<AuthenticationOutcome>`이다. 구현은 `AuthorizationStatus`를 받아 세션 복원까지
  수행한 뒤 outcome을 방출한다.
- **판정**: `naming.md` §2.1 기준으로 이름이 실제 책임(관찰 + 세션 해석)의 일부만 설명한다.
- **결정**: ~~이번 기능에서 이름을 바꾸지 않는다.~~ → **R-018로 번복**.
  `ObserveAuthenticationOutcomes` / `ObserveAuthenticationOutcomesUseCase`로 rename한다.
- **근거**: 이름을 바꾸려면 책임 자체를 재검토해야 하고(관찰과 세션 복원을 분리할지 여부),
  이는 §8이 말하는 설계 변경이다. Protocol 신설만으로 동작을 고정하는 이번 목적과 분리한다.
- **검토한 대안**: Protocol만 다른 이름으로 신설(예: `ObserveSessionOutcomesUseCase`).
  Protocol과 구현의 이름 쌍이 어긋나 R-001 규약이 깨지므로 기각.
- **후속**: 이름은 이번에 교정한다. 관찰과 세션 복원의 **책임 분리**는 설계 변경이므로 여전히 범위 밖이며 후속 재검토 대상이다.

## R-014. Protocol 경유 호출 시 기본값 소실

- **사실**: `FetchLearningProjects.callAsFunction(page: Int = 0, size: Int = 10)`은 기본값을
  갖지만, Protocol 요구사항 `FetchLearningProjectsUseCase.callAsFunction(page:size:)`에는
  기본값이 없다. Swift는 protocol requirement에 기본 인자를 허용하지 않는다.
- **결정**: 기본값을 Protocol로 끌어올리지 않는다. 호출자가 `page`와 `size`를 항상 명시한다.
- **근거**: 페이지 크기는 호출 화면의 정책이지 Domain 계약의 기본값이 아니다. Protocol
  extension으로 기본값을 흉내 내면 구현이 가진 기본값과 두 벌이 되어 어느 쪽이 적용됐는지
  호출부에서 판단할 수 없다.
- **검토한 대안**: Protocol extension에 `callAsFunction()` 편의 오버로드 추가. 위 이유로 기각.
- **영향**: Composition과 후속 Feature는 페이지 파라미터를 명시적으로 전달한다.

## R-015. Data concrete Remote 구현의 이름

- **결정**: `HTTP<계약이름>` 형태를 사용한다. `HTTPProjectRemote`,
  `HTTPAuthenticationRemote`, `HTTPExternalRepositoryRemote` 등.
- **근거**: `naming.md` §7은 기술 용어를 "그 대상을 직접 감싸는 경계"에 두도록 허용한다. 이
  구현의 책임 자체가 "HTTP로 서버 API를 호출해 DTO를 얻는 것"이므로 기술이 계약의 일부다.
  저장소에 이미 같은 패턴의 선례가 있다. 중립 계약 `HTTPTransport`의 구현이
  `URLSessionTransport`로, 구현 기술을 이름에 드러낸다.
- **검토한 대안**:
  - `ServerProjectRemote` — "Server"가 전송 기술을 특정하지 못해 캐시 기반 구현과 구분되지 않음
  - `DefaultProjectRemote` — §5가 금지하는, 책임을 설명하지 않는 접두어
  - `ProjectRemoteClient` — `Remote`와 `Client` 역할어가 중복
- **비고**: `HTTP`는 §6의 표준 약어이며 식별자 첫 단어가 아니므로 전부 대문자로 유지한다.

## R-016. Composition Adapter와 조립 진입점의 이름

- **결정**:
  - Domain↔Data Adapter: `<Domain 계약 이름>Adapter` — `LearningProjectRepositoryAdapter`,
    `ExternalRepositoryLookupAdapter`, `AuthenticationRepositoryAdapter`,
    `LoginSessionRepositoryAdapter`
  - 조립 진입점: `<기능>Assembly` — `LearningProjectAssembly`, `AuthenticationAssembly`,
    `ExternalRepositoryAssembly`
- **근거**: Adapter 이름은 무엇을 구현하는지(어떤 Domain 계약을 충족하는지)를 드러내야
  사용처에서 독립적으로 읽힌다(§2.2). `naming.md` §4는 Composition의 이름 문맥을 "Adapter,
  조립, 구현 선택, 객체 수명"으로 정하므로 `Assembly`(조립)는 역할어로 성립한다.
  `architecture.md` §3.3의 `DomainDataAdapter`, `DataInfrastructureAdapter`는 다이어그램의
  일반 명칭이지 실제 타입 이름 규약이 아니다.
- **검토한 대안**:
  - `AppComposition` 단일 타입 — R-009에서 기각(FR-051 위반 유도)
  - `LearningProjectUseCases` — 복수형 값 묶음이라 조립·수명 책임을 설명하지 못함
  - `LearningProjectComposition` — 패키지 이름 반복이라 §5가 금지하는 형태에 가까움
  - `LearningProjectFactory` — 객체 수명과 공유 결정 책임을 설명하지 못함
- **비고**: `Assembly`는 진입점당 `HTTPClient`를 1회 생성해 하위 Adapter에 주입하는 책임을
  함께 가진다(FR-027, SC-010).


## R-017. 표준 약어 표기 전수 조사 (`URL`, `ID`, `HTTP`)

`docs/conventions/naming.md` §6과 §9의 대소문자 규칙으로 Domain·Data·Infrastructure·UI의
Swift 식별자를 전수 조사했다.

### 결과 요약

| 경계 | 판정 | 근거 |
|---|---|---|
| Data DTO·Endpoint | **준수** | Swift 프로퍼티는 `URL`·`ID`, `CodingKeys`는 서버 원문 `Url`·`Id` 보존 |
| Infrastructure | **준수** | `HTTPClient`, `HTTPRequest`, `URLSessionTransport`, `HTTPClientError` 등 위반 0건 |
| `DomainAuthentication` | **준수** | `AuthenticationGrant.ID`, `id`, `idToken` — 첫 단어 소문자 규칙까지 정확 |
| `Domain/LearningProject/Models/ExternalRepository.swift` | **준수** | `canonicalURL`, `imageURL` |
| `DomainLearningProject`의 나머지 모델·계약·UseCase | **위반** | 아래 목록 |

### 위반 목록 (`DomainLearningProject` 한정)

| 식별자 | 규칙에 맞는 표기 | 선언 위치 |
|---|---|---|
| `projectId` | `projectID` | `LearningProjectRepository`(2개 연산), `FetchLearningProjectDetailUseCase`, `DeleteLearningProjectUseCase`, `FetchLearningProjectDetail`, `DeleteLearningProject`, `LearningProjectSummary`, `LearningProjectDetail`, `LearningProjectRegistration` |
| `githubRepoUrl` | `githubRepoURL` | `LearningProjectRepository.register`, `CreateLearningProjectUseCase`, `CreateLearningProject` |
| `nextSetId` | `nextSetID` | `LearningProjectSummary` |
| `nextQuestionId` | `nextQuestionID` | `LearningProjectSummary`, `LearningProjectDetail` |
| `setId` | `setID` | `LearningProjectSetProgress` |

Domain 테스트(`Domain/Tests/LearningProject/**`)의 호출부와 Test Double도 같은 레이블을
사용하므로 함께 바뀐다.

- **결정**: ~~이번 기능에서 고치지 않는다.~~ → **R-018로 번복**. 전수 조사 결과 전체를 이번
  범위에서 rename한다.
- **근거**: `naming.md` §8. 이 rename은 Domain 모델 4개, 계약 1개, UseCase Protocol 3개,
  구현 3개와 Domain 테스트 전반의 레이블을 동시에 바꾼다. 같은 커밋에서 Data 구현 신설과
  Composition 조립을 함께 수행하면 어떤 변경이 어떤 검증을 통과시켰는지 구분할 수 없다.
- **검토한 대안**:
  - 이번 기능에 포함 — 명세 범위 밖이고 §8 위반이므로 기각
  - 새로 만드는 Adapter 쪽만 규칙에 맞춰 표기 — Domain 계약이 요구하는 레이블을 바꿀 수
    없으므로 애초에 불가능
- **관찰**: 위반이 `DomainLearningProject`의 초기 모델군에 몰려 있고, 나중에 추가된
  `ExternalRepository`(기능 012)는 규칙을 지킨다. 규약이 신규 코드에는 적용됐지만 기존
  코드에 소급되지 않은 상태로 보인다.

### 이번 계획에 미치는 영향

`LearningProjectRepositoryAdapter`가 Domain과 Data 사이에서 **식별자·URL 필드 전부**의 표기를
뒤집는 변환 지점이 된다.

```text
Data (준수)          →  Domain (위반)
projectID            →  projectId
githubRepoURL        →  githubRepoUrl
nextSetID            →  nextSetId
nextQuestionID       →  nextQuestionId
setID                →  setId
```

동작에는 영향이 없다. Adapter 구현 시 이 표기 반전을 오타로 오인하지 않도록 계획 문서에
근거를 남긴다.


---

# 추가 조사: rename 범위 확정 (2026-08-21)

## R-018. 네이밍 rename 3건을 이번 범위에 포함 *(R-010, R-011, R-013, R-017 번복)*

- **결정**: 사용자 결정에 따라 다음 rename을 이번 기능에서 모두 수행한다.
  1. `DomainLearningProject`의 표준 약어 표기 — `projectId`→`projectID`,
     `githubRepoUrl`→`githubRepoURL`, `nextSetId`→`nextSetID`,
     `nextQuestionId`→`nextQuestionID`, `setId`→`setID`
  2. `ObserveAuthorizationChanges` → `ObserveAuthenticationOutcomes`,
     신설 Protocol은 `ObserveAuthenticationOutcomesUseCase`
  3. Tuist target `CompositionAdepter`/`CompositionAdepterTests` →
     `CompositionAdapter`/`CompositionAdapterTests`
- **근거**: 이 기능이 Domain UseCase 계약을 정본으로 확정하고 Composition Adapter를 신설하는
  시점이다. 지금 바로잡지 않으면 규칙 위반 이름이 새 계약에 고정되고, Data(준수)와
  Domain(위반) 사이에 표기를 뒤집는 변환 지점이 영구화된다. rename을 Domain 단계에서 먼저
  끝내면 Adapter는 처음부터 일치된 표기로 작성된다.
- **검토한 대안**: 별도 선행 명세(014)로 분리. `naming.md` §8을 그대로 지키는 방식이지만,
  사용자가 013 포함을 선택했다.
- **예외 기록 의무**: `naming.md` §8(rename과 설계·동작 변경 분리)의 예외를 적용하므로
  Constitution 원칙 3에 따라 이유·영향·미검증 범위를 PR에 기록한다(FR-068).
- **순수 rename 보장**: 이름과 참조, 테스트 이름, 관련 문서만 바꾼다. 연산 집합, 상태, 저장
  위치, 값의 수명과 소유자, 비동기·오류·취소 동작, 패키지 책임, 의존 방향, 외부 API·schema
  mapping은 바꾸지 않는다(FR-065). rename 전후 동일 테스트 통과로 확인한다(FR-067).

## R-019. `CompositionAdapter` rename의 영향 파일 전수 조사

`Adepter` 표기를 전수 조사한 결과는 다음과 같다.

| 파일 | 변경 내용 | 배정 단계 |
|---|---|---|
| `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift` | enum case 2개와 참조 | Composition |
| `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift` | buildTargets·testTargets 참조 2건 | Composition |
| `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift` | `.fromComposition(.CompositionAdepter)` 1건 | Composition (FR-064a) |
| `sources/Projects/Composition/Adepter/` | 폴더명 → `Adapter/` | Composition |
| `sources/Projects/Composition/Tests/Adepter/` | 폴더명 → `Tests/Adapter/` | Composition |
| `sources/Projects/Composition/Adepter/CompositionAdepterPlaceholder.swift` | 파일명·타입명 | Composition |
| `sources/Projects/Composition/Tests/Adepter/CompositionAdepterCompilationTests.swift` | 파일명·타입명·`@testable import`·`@Suite` 문자열 | Composition |

- **결정**: `docs/spec-kit/006-final-uxui-screens/trouble-shooting.md`의 `Adepter` 언급은
  **바꾸지 않는다**.
- **근거**: Constitution 원칙 9는 세션 지식 기록을 append-only로 규정하고 기존 항목의
  수정·삭제를 금지한다. 이 기록은 당시 상태에 대한 사실 기록이므로 rename 대상이 아니다.
- **부수 효과**: `Target.module`이 `bundleId`를 `name.lowercased()`로 만들므로 framework의
  bundleId가 `...compositionadepter` → `...compositionadapter`로 바뀐다. 내부 framework이며
  App bundleId와 서명 구성에는 영향이 없다.
- **비고**: 폴더 이름 `Adapter`는 `naming.md`의 "source 폴더는 target 이름의 패키지 접두어를
  빼고 역할만 사용" 규칙과 `CompositionModuleName.sourceDirectory`의 `droppingPrefix` 계산에
  그대로 부합한다.

## R-020. rename의 패키지 단계 배정

| rename | 배정 단계 | 근거 |
|---|---|---|
| 표준 약어 표기 (`DomainLearningProject`) | **Domain** | 대상 선언이 모두 Domain 소유. Data 구현과 Adapter 작성 전에 끝나야 표기 반전이 생기지 않는다 |
| `ObserveAuthenticationOutcomes` | **Domain** | `DomainAuthentication` 소유. Protocol 신설(FR-008)과 같은 단계에서 함께 수행하면 한 번만 손댄다 |
| `CompositionAdapter` target | **Composition** | manifest·폴더·테스트가 모두 Composition 소유. App manifest 참조 1건도 이 rename이 최초로 필요하게 만드는 변경이므로 같은 단계에 배정 (Constitution 원칙 7) |

- **순서 효과**: Domain 단계에서 표기 rename을 끝내므로, Data 단계의 구현과 Composition
  단계의 Adapter는 처음부터 `projectID`·`githubRepoURL` 표기로 작성된다. 이전 계획이 예고했던
  Adapter의 표기 반전은 발생하지 않는다(SC-022).
