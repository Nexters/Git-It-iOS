# 0단계 조사: UC01~UC20 전체 UseCase end-to-end 구현

**출처**: `private/CONVENTION-BASELINE.md`(문서 ID `015-CONVENTION-BASELINE`, 기준일 2026-08-22, 저장소 기준 `Nexters/Git-It-iOS develop@bdb095b5416207982c53f2ccb083373d6b42edb7`)를 커밋 대상 경로로 복사한 사본이다. `private/**`는 `.gitignore`로 커밋되지 않으므로([명확화 세션 2026-08-22](./spec.md#명확화) 참고), 이 문서를 `/speckit-plan` 이후 모든 단계(계획·작업·구현)의 컨벤션 정본으로 사용한다. 원본과 내용이 갈리면 이 커밋 사본이 아니라 저장소의 [Constitution](../../.specify/memory/constitution.md)과 [아키텍처 문서](../../docs/architecture.md)를 우선한다(Constitution 적용 절 참고).

## 주요 결정 다이제스트

- 결정: 패키지 의존 방향은 `App→Feature,Composition,Domain`, `Composition→Domain,Data,Infrastructure`, `Feature→Domain,UI`, `Domain/Infrastructure/UI→—`, `Data→Infrastructure`로 고정한다.
  근거: 아키텍처 문서 3.1과 D-ARCH-003 결정을 그대로 반영해 Domain/Data/Infrastructure의 독립성을 보존한다.
  검토한 대안: Composition이 주입까지 겸하는 구조(기각 — App의 조립 root 역할과 충돌), Data가 Protocol만 소유하는 구조(기각 — concrete Remote 부재 시 "구현 완료" 판정이 불가능해짐).

- 결정: Data target이 DTO·Endpoint·Data 오류뿐 아니라 Infrastructure 기반 concrete Remote(`HTTP<Capability>Remote`)까지 소유한다.
  근거: D-ARCH-003이 `Data → Infrastructure` 의존을 허용하며, concrete Remote 부재 상태를 "Data 구현 완료"로 판정하지 않기 위함이다.
  검토한 대안: Composition이 Data↔Infrastructure 변환을 담당(기각 — 3.3 Adapter 경계는 Domain↔Data에만 적용).

- 결정: 보호 API Remote는 매 요청 직전 access token을 읽는 동적 provider(`accessTokenProvider: @Sendable () async -> String?`)를 받는다.
  근거: token snapshot 고정 시 refresh 이후에도 만료 token을 계속 전송하는 결함이 발생한다.
  검토한 대안: Remote 생성 시 token을 고정 주입(기각 — refresh와 정합 불가).

- 결정: refresh는 전역 single-flight actor가 소유하며 동시 401은 하나의 refresh 작업에 합류한다.
  근거: 여러 보호 Remote가 동시에 401을 받으면 병렬 refresh 요청이 race condition과 token 교체 충돌을 유발한다.
  검토한 대안: Remote별 독립 refresh(기각 — session 정본이 여러 개가 되어 C-COMP-002의 공유 수명 요구를 위반).

- 결정: UC12(RefreshSession)·UC14(SignOut revoke)는 서버 endpoint 미확보(`INT-API-001`) 상태에서 구조(Protocol·outcome·single-flight 규칙)만 구현하고 임의 path·DTO를 만들지 않으며, "구조 완료"와 "production capability 완료"를 분리 판정한다.
  근거: 승인되지 않은 계약을 조립하면 이후 실제 서버 계약과 충돌할 때 재작업 비용이 발생하고, 임의 성공 처리는 세션 안전성을 해친다.
  검토한 대안: 서버 계약을 추정해 우선 구현(기각 — 명세 제외 범위 "서버 refresh/revoke endpoint·DTO의 임의 설계"에 위배).

- 결정: optional `nextSetID`/`nextQuestionID`/`preferredQuestionID`는 nil을 그대로 보존하고 빈 문자열이나 임의 UUID로 정규화하지 않는다.
  근거: 빈 문자열 보정은 "다음 세트/질문 없음"과 "알 수 없는 값"을 구분 불가능하게 만들어 U07/U08 fallback 로직이 잘못된 화면을 렌더링할 수 있다.
  검토한 대안: Domain에서 sentinel 값으로 정규화(기각 — 서버 nullability 의미 손실).

- 결정: 프로젝트 등록 결과는 `ProjectRegistrationReceipt.requestStatus: String`(raw 값)로 보존하고 `QuizGenerationStatus` 같은 클라이언트측 상태 머신으로 변환하지 않는다.
  근거: 서버가 정의하지 않은 `analyzed`/`anchored` 같은 단계를 클라이언트가 발명하면 실제 생성 상태와 어긋난 UI가 노출된다.
  검토한 대안: 알려진 값만 enum으로 매핑하고 나머지는 폐기(기각 — 알 수 없는 값 손실).

- 결정: UIComponent 공개 계약은 scalar/value 입력, `Binding`, 콜백 세 종류만 허용하고 `ViewModel`/`State`/`Props` wrapper를 금지한다.
  근거: Feature/Domain 모델이 UIComponent로 새면 UI 패키지가 특정 Feature에 결합돼 재사용성과 계층 경계가 깨진다.
  검토한 대안: 경량 ViewModel 허용(기각 — 아키텍처 문서 7.3 "UI에서 특정 Feature의 업무 상태와 화면 흐름을 소유하지 않는다"에 위배).

- 결정: `UIComponentLayoutHarness`를 `UIComponentPreviewApp`으로 이름만 교정하고, 이 앱을 production App 도달성의 근거로 사용하지 않는다.
  근거: 현재 명칭이 실제 역할(컴포넌트 카탈로그·시각 검토·UI 자동화 host)을 드러내지 못해 "제품 화면 구현 완료"로 오인될 위험이 있다.
  검토한 대안: 이름 유지(기각 — 책임 기반 네이밍 원칙 위반).

## 원문 (private/CONVENTION-BASELINE.md 커밋 사본)

> 아래는 정합 대상 원본 전문이다. 번호와 표 구조를 원문 그대로 유지한다.

### 1. 정합 목적

현재 저장소에는 Domain UseCase Protocol, Data의 일부 HTTP 구현, Composition Assembly가 추가됐지만 Feature와 App은 아직 제품 실행 경로를 구성하지 않는다. 또한 서버 계약과 iOS Domain 모델 사이에 nullability·상태 의미·오류 의미 손실이 남아 있다.

이 문서는 다음 구현 명세가 패키지 경계와 객체 수명을 다시 해석하지 않도록 아래 사항을 먼저 고정한다.

1. 패키지별 책임과 의존 방향
2. Domain UseCase의 선언·구현·네이밍 방식
3. Data concrete 구현과 인증 헤더 처리
4. CompositionAdapter와 App의 의존성 주입 경계
5. Feature와 UI의 상태·입력 계약
6. 세션 수명·401·refresh 단일 비행
7. Tuist target·scheme·test plan 원칙
8. Spec-Kit 패키지별 구현 순서와 승인 게이트

### 2. 입력 정본과 해석 우선순위

| 우선순위 | 근거 | 적용 방식 |
|---:|---|---|
| 1 | `decision-log.md` | 승인된 제품·클라이언트 소비 의미 |
| 2 | `common-spec.md`, `U01`~`U08` | 기능·상태·오류·접근성 요구사항 |
| 3 | 배포 `/v3/api-docs` | 확보 시 실제 네트워크 정본 |
| 4 | `Git-it-Server main@8641bc961cac7dfbf0079cdbec020c65da8ccff1` | 배포 artifact 미확보 상태의 API 기준선 |
| 5 | Figma file `mCRt0ejmzI4EFW3UnC9Bzb`, root `86:761` | 제품-visible 화면·문구·상태 |
| 6 | iOS `develop@bdb095b...` | 현재 구현 사실 |
| 7 | 과거 source index·감사 문서 | 변경 추적과 회귀 참고 |

#### 2.1 현재 브랜치 기준

- 프로젝트 문서가 가리키던 `feature/for-release`는 이미 `develop`에 병합됐으며 현재 ref로 사용하지 않는다.
- 이후 `develop`에는 Server API Data 계약, GitHub Data 계약, Data→Infrastructure concrete 구현, Domain UseCase Protocol, CompositionAdapter 조립이 추가됐다.
- 따라서 새 명세의 코드 기준은 `develop@bdb095b...`로 고정한다.
- 구현 시작 시 `develop` HEAD가 달라졌다면 source audit를 다시 수행하고 `spec.md`의 기준 SHA를 갱신한다.

### 3. 정합된 패키지 책임

#### 3.1 의존 방향

```text
App ───────────────→ Feature
 │                    │
 │                    ├────────→ Domain*
 │                    └────────→ UI
 │
 ├──────────────────→ CompositionAdapter
 │                    ├────────→ Domain*
 │                    ├────────→ Data*
 │                    └────────→ Infrastructure*
 │
 └──────────────────→ Domain*  (Feature initializer의 Protocol 타입 표면에 필요한 경우)

Data* ──────────────→ Infrastructure*

Domain* ────────────→ 없음
Infrastructure* ────→ 없음
UI ─────────────────→ 없음
```

`*`는 bounded context별 target을 뜻한다.

#### 3.2 패키지별 필수 책임

| 패키지 | 소유 | 금지 |
|---|---|---|
| **Domain** | 비즈니스 모델, 오류, Repository 계약, `XxxUseCase` Protocol, concrete `Xxx` | DTO, HTTP, Keychain, Apple SDK, SwiftUI, TCA, Data import |
| **Infrastructure** | 범용 HTTP·transport·Keychain·Apple·OS integration | Git-It endpoint/DTO, Domain·Data 의미, 제품 정책 |
| **Data** | DTO, Endpoint, Data 오류, `Remote` Protocol, Infrastructure 기반 concrete Remote | Domain 모델·Repository·UseCase, Composition·Feature·App·UI import |
| **CompositionAdapter** | Domain↔Data Adapter, 오류·모델 변환, live 객체 생성, 공유 수명 | Feature/Store/View 생성, 새 비즈니스 규칙, Data 정책 소유 |
| **UI** | Design token, 범용 UI 표현 계약, 자산, Preview/Review app | Feature·Domain·Data·Composition 타입, TCA, ViewModel wrapper |
| **Feature** | TCA State·Action·Reducer·View, UseCase 호출, 화면 delegate | Data·Infrastructure·Composition import, concrete UseCase 생성, production `@Dependency` 조회 |
| **App** | Composition root 1회 생성, Feature initializer 주입, root/session/navigation | Domain 규칙, DTO 변환, Remote/Adapter 구현, Feature 내부 상태 |

### 4. Domain UseCase 컨벤션

#### C-DOM-001 — Protocol과 concrete 이름

```swift
public protocol FetchLearningSetUseCase: Sendable {
    func callAsFunction(
        projectID: String,
        setID: String
    ) async throws -> LearningSet
}

public struct FetchLearningSet: FetchLearningSetUseCase {
    // Domain Repository Protocol만 주입
}
```

- Protocol은 `<동사><대상>UseCase`, concrete는 `UseCase` 접미어를 제거한다.
- 모든 경계 타입은 `Sendable`을 기본으로 한다.
- 비동기 작업은 `async`; 실패 의미가 결과 enum으로 모델링되지 않는 한 `throws`를 사용한다.
- Protocol 시그니처에는 Domain 모델·Swift 표준 타입만 사용한다.
- Feature가 호출하는 operation에는 Protocol이 반드시 존재해야 한다.
- 하나의 UseCase가 여러 외부 operation을 숨기지 않는다. 단, 하나의 사용자 의도를 완료하기 위한 원자적 조정은 허용한다.

#### C-DOM-002 — 비번호 지원 UseCase

UC01~UC20 외에도 앱 생명주기를 위해 다음 지원 UseCase를 유지할 수 있다.

- `RestoreSessionUseCase`
- `ObserveAuthenticationOutcomesUseCase`
- `LoadLegalDocumentsUseCase`
- `RecordLegalAcceptanceUseCase`

이들은 UC 번호를 새로 만들지 않으며, 제품 요구사항의 보조 operation임을 문서에 명시한다.

#### C-DOM-003 — 값 의미 보존

- 서버 identifier, 배열 순서, nullability를 보존한다.
- optional ID를 `""`, `0`, 임의 UUID로 정규화하지 않는다.
- raw receipt를 제품에 없는 상태 머신으로 승격하지 않는다.
- 서버 통계·채점·진행률을 Domain에서 재계산하지 않는다.
- 외부 wire enum은 Data에서 raw 값을 보존하고 Domain에서 승인된 의미로만 변환한다.

### 5. Data와 Infrastructure 컨벤션

#### C-DATA-001 — Data가 concrete Remote를 소유한다

Data target은 다음을 함께 소유한다.

```text
Contracts/<Capability>Remote.swift
DTOs/*.swift
Endpoints/*.swift
Errors/*.swift
Remotes/HTTP<Capability>Remote.swift
```

- Data concrete Remote는 `InfrastructureNetworkClient` 등 필요한 Infrastructure target을 Tuist에 명시한다.
- Data는 Domain을 import하지 않는다.
- DTO→Domain 변환은 Data가 아니라 CompositionAdapter가 소유한다.
- concrete Remote가 없는 Protocol은 "Data 구현 완료"로 판정하지 않는다.

#### C-DATA-002 — 인증 헤더

- Git-It 보호 API Remote는 매 요청 직전에 현재 access token을 읽는 동적 token provider를 받는다.
- token snapshot을 Remote 생성 시 고정하지 않는다.
- `Authorization: Bearer <token>`은 실제 `HTTPRequest.headers`에 포함돼야 한다.
- GitHub public API Remote에는 Git-It Bearer token을 전달하지 않는다.
- token 원문은 로그, `description`, analytics, crash metadata에 기록하지 않는다.

권장 생성 계약:

```swift
public init(
    client: HTTPClient,
    accessTokenProvider: @escaping @Sendable () async -> String?
)
```

#### C-DATA-003 — 오류 책임

- Infrastructure 오류 → Data 오류는 concrete Remote가 변환한다.
- HTTP status·server code는 진단 metadata로 보존한다.
- Data 오류 → Domain 오류는 CompositionAdapter가 변환한다.
- 401을 `unexpected`나 일반 transport 오류로 축약하지 않는다.
- project/set/question/member 404를 하나의 `notFound`로 합치지 않는다.
- server message 원문은 UI에 직접 전달하지 않는다.

### 6. CompositionAdapter와 App 주입 컨벤션

#### C-COMP-001 — 역할 분리

- CompositionAdapter는 객체를 **만들고 변환**한다.
- App은 만들어진 UseCase를 **Feature initializer에 연결**한다.
- Feature는 의존성을 **사용**한다.

```text
CompositionAdapter.live(environment)
  → any FetchLearningProjectsUseCase
  → any FetchMemberProfileUseCase
  → ...

App
  → MainShellFeature(
       fetchLearningProjects: composition.fetchLearningProjects,
       fetchMemberProfile: composition.fetchMemberProfile
     )
```

CompositionAdapter 또는 typed assembly를 Feature에 통째로 전달하지 않는다.

#### C-COMP-002 — 공유 수명

하나의 App composition graph에서 다음 수명을 보장한다.

| 객체 | 수명 |
|---|---|
| App composition root | process당 1개 |
| Session credential store / refresh coordinator | process당 1개, actor 격리 |
| Git-It server transport | host·environment당 1개 공유 |
| GitHub transport | GitHub host당 1개 공유 |
| Repository Adapter / concrete Remote | composition당 1개 |
| UseCase concrete | composition당 1개 또는 무상태 value |
| Feature Store | route 또는 인증 session 수명 |

Assembly마다 서로 독립된 session store를 만들거나, 보호 Remote마다 서로 다른 token source를 만들지 않는다.

#### C-COMP-003 — 공개 표면

- Composition public property는 `any XxxUseCase` 또는 이를 묶은 불변 typed bundle만 허용한다.
- `HTTPClient`, `KeychainStore`, DTO, Remote, Adapter concrete 타입은 외부에 공개하지 않는다.
- mutable service locator, 문자열 key container, 런타임 downcast를 금지한다.

### 7. 세션·401·refresh 컨벤션

#### C-SESSION-001 — 로컬 정본

```text
SessionRecord
  tokens
    accessToken
    refreshToken
    accessTokenExpiresAt
    refreshTokenExpiresAt
  onboarding
    needsCuration
    acceptedLegalVersions
    acceptedAt
```

- 로그인 응답의 `needsCuration`을 손실 없이 저장한다.
- idToken을 사용자 ID나 장기 세션 식별자로 저장하지 않는다.
- 사용자 표시 정보는 UC16 member profile에서 가져온다.
- 서버가 token expiry를 직접 제공하지 않으면 임의 시간을 생성하지 않는다. 승인된 JWT `exp` 해석 계약 또는 서버 필드가 확보될 때까지 reactive verify/401 정책을 사용한다.

#### C-SESSION-002 — refresh

- refresh는 전역 single-flight actor가 소유한다.
- 동시 401은 하나의 refresh 작업에 합류한다.
- 새 token pair는 원자적으로 교체한다.
- refresh 거부는 session 종료, transport/5xx는 credential 보존 + 보호 UI 비노출이다.
- 서버 refresh capability가 확정되기 전 path·DTO를 추정하지 않는다.
- capability가 없는 production graph를 조용히 성공시키지 않는다. release validation에서 차단한다.

#### C-SESSION-003 — logout/revoke

- logout은 로컬 session과 보호 child effect를 먼저 정리한다.
- revoke는 refresh token snapshot으로 best-effort 실행한다.
- revoke 실패로 로컬 logout을 되돌리지 않는다.
- revoke endpoint가 확정되기 전 임의 endpoint를 만들지 않는다.

### 8. Feature와 TCA 컨벤션

#### C-FEAT-001 — initializer injection

```swift
@Reducer
public struct SavedQuestionsFeature {
    public init(
        fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase
    ) {
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
    }
}
```

- production 의존성은 reducer initializer로만 받는다.
- production `@Dependency`, 전역 container, singleton lookup을 금지한다.
- FeatureTests의 Test Double은 `Feature/Tests/<Feature>/Mocks`에 로컬 소유한다.
- Feature는 DTO, HTTP status, token 원문을 알지 않는다.
- navigation은 delegate Action으로 App에 전달한다.

#### C-FEAT-002 — 동시성

- 조회는 route identity 또는 request generation을 가진다.
- 늦은 이전 응답은 현재 state를 덮어쓰지 않는다.
- 같은 mutation은 single-flight 또는 직렬화한다.
- mutation dispatch 후 Task 취소를 서버 rollback으로 표시하지 않는다.
- 결과를 잃으면 다음 진입·foreground·명시적 refresh에서 서버 정본을 재조회한다.

### 9. UI 컨벤션 정합

#### C-UI-001 — ViewModel 제거

UIComponent 공개 계약은 다음 세 종류만 사용한다.

1. 읽기 전용 scalar/value 입력
2. 외부 변경 상태의 `Binding`
3. 일회성 사용자 입력 callback

금지:

- `ViewModel`, `State`, `Props` 등 표시 값을 다시 묶는 wrapper
- Feature/Domain 모델
- TCA `Store`, `Reducer`, `Action`
- 네트워크·route·비즈니스 상태 해석

#### C-UI-002 — Preview app 명칭

현재 `UIComponentLayoutHarness`는 제품 기능이 아니라 컴포넌트 카탈로그·시각 검토·UI 자동화 host다. 다음 이름을 정본으로 사용한다.

| 현재 | 정합 이름 |
|---|---|
| `UIComponentLayoutHarness` target | `UIComponentPreviewApp` |
| `ComponentLayoutHarness/` | `ComponentPreviewApp/` |
| `UIComponentUITests` host | `UIComponentPreviewApp` |

- Preview app은 production App 도달성의 근거가 아니다.
- `Components/Review`는 preview/review 전용 표현을 소유한다.
- `#Preview`와 Preview app은 공존할 수 있다. 전자는 파일 단위 빠른 확인, 후자는 카탈로그·UI automation host다.

### 10. 네이밍 컨벤션 정합

- 표준 약어는 식별자 첫 단어가 아니면 전체 대문자를 유지한다.
  - `projectID`, `setID`, `questionID`, `repositoryURL`, `HTTPClient`
- 식별자 첫 단어가 약어면 전체 소문자로 시작한다.
  - `idToken`, `urlString`, `httpMethod`
- `projectId`, `repositoryUrl`, `HttpClient` 표기를 새 공개 API에 추가하지 않는다.
- wire key는 `CodingKeys`로 서버 원문(`projectId`, `repositoryUrl`)을 보존한다.
- `Manager`, `Service`, `Handler`는 실제 책임을 설명하지 못하면 사용하지 않는다.
- 파일당 주된 top-level 공개 타입 하나, 파일명과 타입명을 일치시킨다.

### 11. 모델 정합 선행 규칙

다음 세 항목은 새 UseCase 추가보다 먼저 교정한다.

1. `LearningProjectSummary.nextSetID`, `nextQuestionID`를 optional로 변경하고 빈 문자열 보정을 제거한다.
2. `LearningProjectRegistration.status: QuizGenerationStatus`를 `ProjectRegistrationReceipt.requestStatus: String`으로 교체한다.
3. 서버에 없는 `analyzed`, `anchored`를 U02 Domain 상태에서 제거한다. generation status endpoint DTO는 v1 비소비 Data 계약으로만 격리할 수 있다.

추가 교정:

- 상세 set의 `problemCount`, `completedCount`를 0으로 하드코딩하지 않는다.
- 모든 set 완료 시 `nextSet`은 `sets.first`로 replay fallback한다.
- list `page/size`는 Data compatibility detail이며 Domain UseCase 입력에서 제거한다.
- `hasNext=false`를 pagination state 생성 근거로 사용하지 않는다.

### 12. Tuist target 정합

#### 12.1 유지 target

```text
DomainAuthentication
DomainLearningProject
DataAuthentication
DataExternalRepository
DataLearningProject
DataMember
CompositionAdapter
Feature
DesignSystem
UIComponent
GitIt
```

#### 12.2 추가·변경 target

| 변경 | 이유 |
|---|---|
| `DomainMember`, `DomainMemberTests` 추가 | UC15~UC20의 Domain 정본 부재 |
| `FeatureTests` 추가 | Feature local Test Double·TCA TestStore 실행 경로 부재 |
| `DataMember → InfrastructureNetworkClient` 의존 추가 | `HTTPMemberRemote` 구현 |
| `CompositionAdapter → DomainMember, DataMember` 의존 추가 | Member adapter·assembly 조립 |
| `Feature → DomainAuthentication, DomainMember` 의존 추가 | U01/U06 Feature가 Protocol에 의존 |
| `App → DomainLearningProject, DomainMember` 직접 의존 검토·추가 | Feature initializer public signature를 컴파일하기 위한 명시적 의존 |
| `UIComponentLayoutHarness` → `UIComponentPreviewApp` | 실제 역할과 명칭 정합 |

새 target 추가는 bounded context 경계가 실제로 독립될 때만 수행한다. UC06~UC10은 현재 `LearningProject` 학습 문맥에 포함하고 별도 `DomainQuiz` target을 이번 명세에서 만들지 않는다.

### 13. 테스트·scheme·CI 정합

#### C-TEST-001 — 소유

- Domain: 모델 불변식, UseCase, Repository Test Double
- Infrastructure: 범용 기술 API
- Data: request·headers·DTO·오류 변환·Remote contract
- Composition: DTO→Domain, Data→Domain 오류, 공유 수명, protocol-typed public surface
- Feature: TCA `TestStore`, local Mock, delegate, cancellation
- App: launch root, DI graph, route 도달성
- UI: component contract, accessibility, Preview app UI test

#### C-TEST-002 — scheme

- package별 shared scheme 하나를 유지한다.
- 각 package scheme Test Action에는 그 package의 실제 test target만 연결한다.
- `GitItTests`는 App root를 검증할 수 있는 host/target dependency를 갖는다.
- App scheme에 모든 package test를 혼합하지 않는다.
- unit과 UI 실행을 이름만 바꿔 중복 실행하지 않는다.

#### C-CI-001 — 생략 불가

현재 CI의 global variable이 false이면 lint/build/unit/UI compile이 skip되고 gate가 skip을 성공으로 취급할 수 있다. merge-ready 판정에서는 이를 허용하지 않는다.

필수 결과:

- Swift lint
- production build
- unit test compile + execution
- App root integration test
- 변경 범위 UI test execution
- script quality(관련 변경 시)

문서-only 분류 외에 필수 job 전체가 global flag 때문에 skip되면 gate는 실패해야 한다. pre-push의 고비용 검증 opt-in 여부와 원격 required CI는 별도 정책으로 취급한다.

### 14. Spec-Kit 구현 순서

의존성 위상과 독립 패키지의 상대 순서를 다음 명세에서 고정한다.

1. **Domain** — 모든 UseCase Protocol·모델·오류·Repository 계약
2. **Infrastructure** — Data가 요구하는 범용 인증 header/transport/storage API
3. **Data** — DTO·Endpoint·concrete Remote·Data 오류
4. **Composition** — Adapter·Assembly·shared lifetime
5. **UI** — 누락 component와 Preview app rename
6. **Feature** — U01~U08 reducer/view/delegate
7. **App** — composition root, session root, navigation, lifecycle

근거:

- Data는 Infrastructure에 의존한다.
- Composition은 Domain·Data·Infrastructure에 의존한다.
- Feature는 Domain·UI에 의존한다.
- App은 Feature·Composition·Domain에 의존한다.
- Domain과 Infrastructure는 독립이지만, downstream public contract를 먼저 고정하기 위해 Domain을 선행한다.
- Composition과 UI는 독립이지만, live UseCase graph를 먼저 검증한 뒤 UI/Feature로 이동한다.

각 패키지 단계는 구현·검증·사용자 보고를 완료한 뒤 다음 패키지 진행 승인을 받는다.

### 15. 닫힌 해석 충돌

| 충돌 | 정합 결과 |
|---|---|
| `feature/for-release` vs 최신 코드 | `develop@bdb095b...` 사용 |
| Composition이 주입 vs App이 주입 | Composition은 생성·노출, App은 Feature initializer 연결 |
| Data는 Protocol만 소유 vs concrete 구현 소유 | Data가 Infrastructure 기반 concrete Remote까지 소유 |
| UI ViewModel 사용 여부 | UIComponent ViewModel/State wrapper 금지 |
| Harness 명칭 | `UIComponentPreviewApp`으로 교정 |
| 프로젝트 목록 pagination | Domain/Feature pagination 제거, Data compatibility params만 유지 |
| 프로젝트 등록 status | raw request receipt, generation state machine 아님 |
| optional next ID | optional 보존, 빈 문자열 보정 금지 |
| idToken 사용자 ID 사용 | 금지; member profile이 사용자 표시 정본 |
| 상세 set 진행률 0 하드코딩 | 금지; 검증된 서버 필드를 매핑 |
| 401 처리 | Domain unauthorized → root refresh/session flow |

### 16. 완료 기준

이 기준선은 다음 조건을 모두 만족할 때 구현 정본으로 채택한다.

- `spec.md`의 모든 패키지 요구사항이 이 문서와 모순되지 않는다.
- 새 UseCase Protocol이 Domain 외부 타입을 노출하지 않는다.
- 모든 보호 Remote가 실제 Authorization header를 전송한다.
- Feature가 initializer 외 production 의존성 획득 경로를 갖지 않는다.
- UIComponent에 ViewModel/State wrapper가 없다.
- App root가 Composition graph를 한 번 만들고 U01 또는 U03으로 분기한다.
- CI required validation이 global skip 상태로 merge-ready가 되지 않는다.
