# 구현 계획: Feature → Domain UseCase 의존과 App 소유 의존성 주입

**Git-flow 유형**: `feature`

**브랜치**: `미생성 (예정: feature/feature-usecase-app-di)`

**날짜**: 2026-08-21 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/013-feature-usecase-app-di/spec.md`의 기능 명세

## 요약

Feature가 Domain UseCase Protocol에만 의존하고 App이 주입을 수행하는 `D-ARCH-003` 경계를
확립한다. 다만 Feature와 App 구현은 명세 범위 밖이므로, 이번 구현의 실제 산출물은 **그 경계가
성립하기 위한 하위 계층 전체**다.

- **Domain**: Authentication UseCase 4개의 Protocol 신설로 UseCase 계약 완비
- **Infrastructure**: Data 구현이 요구하는 기술 API 대조와 최소 보완
- **Data**: Infrastructure 기반 concrete Remote 구현 신설과 target 의존성 선언
- **Composition**: Domain↔Data Adapter와 Domain UseCase 구현을 조립한 live 실행 그래프
- **문서**: `D-ARCH-003` 결정 기록과 `Data → Infrastructure` 의존 허용 개정
- **네이밍**: 규약 위반 rename 3건 — 표준 약어 표기, `ObserveAuthenticationOutcomes`,
  `CompositionAdapter` target 철자

기술 접근의 핵심은 조사에서 확정한 두 가지다. 첫째, `InfrastructureNetworkClient`의
`HTTPClient`가 이미 충분한 기능을 제공하므로 Data 구현은 Data 소유 요청 값을 `HTTPRequest`로
변환하는 얇은 계층이 된다(R-003, R-004). 둘째, Composition은 단일 컨테이너 대신 기능별 조립
진입점을 제공해 "컨테이너 전체 전달 금지"를 구조로 강제한다(R-009). 셋째, 신설 Protocol의
시그니처는 기존 구현을 문자 그대로 옮겨 Protocol 추출이 동작 계약 변경으로 번지지 않게
한다(R-012). 넷째, 네이밍 rename을 Domain 단계에서 먼저 끝내 Data 구현과 Adapter가 처음부터
일치된 표기로 작성되게 한다(R-018, R-020).

## 기술 맥락

**언어/버전**: Swift 5.0 모드, `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`, Approachable Concurrency 활성

**주요 의존성**: The Composable Architecture(Feature 한정, 이번 범위 밖), Firebase(App 한정, 이번 범위 밖). 이번 변경 대상 패키지는 외부 의존성을 추가하지 않는다.

**저장소**: 원격 HTTP API(`/api/v1/...`), Keychain(인증 토큰), 인메모리 캐시

**테스트**: Swift Testing (`@Suite`, `@Test`), 한국어 백틱 함수명. XCTest는 UI 자동화로 한정

**대상 플랫폼**: iOS 26.0+

**프로젝트 유형**: Tuist 멀티 패키지 iOS 앱

**성능 목표**: 이번 변경은 런타임 동작을 바꾸지 않으므로 새 성능 목표를 두지 않는다. 기존 `HTTPClient` 기본 응답 타임아웃 15초를 유지한다.

**제약 조건**: 사용자 관찰 동작 변경 0건, 서버 endpoint·DTO 스키마 변경 0건, `Feature`·`App` 소스 무변경

**규모/범위**: 변경 대상 패키지 4개, Domain Protocol 4개 신설, Data 모듈 3개에 Remote 구현 신설, Composition 조립 진입점 3개, 문서 3개 개정, 네이밍 rename 3건

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 판정 | 근거 |
|---|---|---|
| 1. 명시적인 경계 | 통과 | 모든 target 의존성을 Tuist에 명시하고 순환 0건을 검증한다. 개정 후 의존 규칙은 [contracts/package-dependency-rules.md](./contracts/package-dependency-rules.md)에 고정했다. |
| 2. 상태와 데이터 안전성 | 통과 | 공유 객체 수명을 Composition이 명시적으로 소유한다(R-009). 모든 UseCase Protocol이 `Sendable`을 요구하고, `HTTPClient`가 취소를 `.cancelled`로 전달한다. |
| 3. 검증 가능한 변경 | 통과 | 각 패키지 단계마다 빌드·테스트 결과를 남긴다. 검증 절차는 [quickstart.md](./quickstart.md)에 정의했다. rename은 전후 동일 테스트 통과로 동작 보존을 확인하고(FR-067), `naming.md` §8 예외 근거를 PR에 기록한다(FR-068). |
| 4. 스킬별 수정 경로 | 통과 | 이 계획은 계획 산출물만 작성했다. `docs/**` 변경은 `tasks.md`가 정확한 파일 경로로 명시하고 책임 패키지에 배정한다(R-008). |
| 5. Spec-Kit 범위 | 통과 | 허용 경로 안에서만 작성했다. |
| 6. 한국어 산출물 | 통과 | 모든 산출물을 한국어로 작성하고 코드 식별자와 경로는 원문을 유지했다. |
| 7. 패키지 단위 구현 진행 | 통과 | 위상 순서와 상대 순서 근거를 R-007에 기록했다. 아래 "패키지 진행"을 따른다. |
| 8. Git-flow 브랜치 | 통과 | 브랜치는 미생성이며 예정 이름만 기록했다. 생성된 것처럼 기록하지 않았다. |
| 9. 세션 지식 기록 | 통과 | 실제 오류·실패가 발생하지 않아 기록 파일을 만들지 않았다. `docs/spec-kit/006-final-uxui-screens/trouble-shooting.md`의 `Adepter` 언급은 append-only 기록이므로 rename 대상에서 제외했다(R-019). |
| 10. 책임과 문맥에 따른 네이밍 | 통과 (예외 기록) | 기존 `<동사><명사>UseCase` 규약을 따르고 `Default` 접두어를 배제했다(R-001). 신설·신규 타입의 이름과 시그니처는 [contracts/naming-and-signatures.md](./contracts/naming-and-signatures.md)에 고정했다(R-012, R-015, R-016). 발견한 규약 위반 3건을 모두 이번 범위에서 rename한다(R-018). **`naming.md` §8(rename과 설계·동작 변경 분리)의 예외를 적용하므로 원칙 3에 따라 PR에 이유·영향·미검증 범위를 기록한다**(FR-068). 아래 [복잡성 추적](#복잡성-추적) 참조. |

**1단계 설계 후 재점검**: 위반 없음. [복잡성 추적](#복잡성-추적) 표는 비어 있다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정했다. 구현 파일은 경로만 기록했다.

**세션 지식 기록**: 조건 미충족으로 기록하지 않았다.

**Git 실행 직렬화**: 검증 명령은 `sources/DerivedData/PreCommit`을 공유하므로 순차 실행을
[quickstart.md](./quickstart.md)에 명시했다.

## 패키지 진행

**구현 순서**: `Domain → Infrastructure → Data → Composition`

**위상 근거** (개정 후 의존성 표):

```text
Domain          → 없음          (leaf)
Infrastructure  → 없음          (leaf)
Data            → Infrastructure
Composition     → Domain, Data, Infrastructure
```

`Data`는 `Infrastructure`보다 뒤, `Composition`은 마지막이 강제된다.

**독립 패키지의 상대 순서 결정** (Constitution 원칙 7이 이 계획에 위임):
`Domain`과 `Infrastructure`는 서로 의존하지 않는다. **Domain을 먼저** 둔다. Domain UseCase
Protocol이 Composition이 노출할 타입의 기준이고, Infrastructure 보완 범위(FR-010)는 Data 구현
설계에서 도출되므로 Domain 계약이 확정된 뒤에 판단하는 편이 정확하다(R-007).

**적용하지 않는 패키지**: `UI`, `Feature`, `App` — 명세 범위 밖이다. 이 패키지들의 소스와
Tuist 선언을 변경하지 않는다.

**승인 게이트**: 각 적용 대상 패키지는 구현 → 검증 → 변경 파일과 검증 결과 보고 → 명시적
사용자 승인을 거친 뒤에만 다음 패키지 파일을 변경한다. 다음 패키지의 영향 분석은 승인 전에
보고할 수 있으나 파일은 변경하지 않는다.

**패키지에 속하지 않는 파일 배정**: `docs/**` 개정 작업은 **Domain 단계의 선행 작업**으로
배정하고 Domain 소스 변경보다 앞에 배치한다. FR-060이 "어떤 패키지 구현 작업보다 먼저"를
요구하고, Domain이 첫 적용 대상 패키지이기 때문이다(R-008). `tasks.md`는 각 문서 작업에 정확한
저장소 상대경로를 명시해야 한다.

**공용 구성 파일 분리**: `sources/Tuist/ProjectDescriptionHelpers/Projects/*.swift`는 여러
패키지의 선언을 담는다. `DataModuleName.swift` 변경은 Data 단계에,
`CompositionModuleName.swift`·`ProjectName.swift`·`AppModuleName.swift` 변경은 Composition
단계에 각각 배치한다. 한 작업이 두 패키지 선언을 동시에 바꾸지 않는다.

**rename 배정** (R-020):

| rename | 단계 | 근거 |
|---|---|---|
| 표준 약어 표기 (`DomainLearningProject`) | Domain | 대상 선언이 모두 Domain 소유. Data 구현·Adapter 작성 전에 끝나야 표기 반전이 생기지 않는다 |
| `ObserveAuthenticationOutcomes` | Domain | `DomainAuthentication` 소유. Protocol 신설(FR-008)과 같은 단계에서 함께 수행 |
| `CompositionAdapter` target | Composition | manifest·폴더·테스트가 Composition 소유. App manifest 참조 1건(FR-064a)도 이 rename이 최초로 필요하게 만드는 변경이므로 같은 단계 |

**App manifest 예외**: `AppModuleName.swift`의 `.fromComposition(.CompositionAdepter)` 참조
1건은 App 패키지가 아니라 Composition 단계에 배정한다. App 소스 파일과 실행 동작은 변경하지
않으며, 빌드 그래프의 target 이름 참조만 갱신한다(FR-064a, SC-021).

## 프로젝트 구조

### 문서(이 기능)

```text
specs/013-feature-usecase-app-di/
├── plan.md              # 이 파일
├── research.md          # 0단계 산출물 (R-001 ~ R-010)
├── data-model.md        # 1단계 산출물
├── quickstart.md        # 1단계 산출물
├── contracts/           # 1단계 산출물
│   ├── domain-usecase-protocols.md
│   ├── composition-graph.md
│   ├── package-dependency-rules.md
│   └── naming-and-signatures.md
├── checklists/
│   └── requirements.md
└── tasks.md             # 2단계 산출물 (/speckit-tasks)
```

### 소스 코드(저장소 루트)

```text
docs/                                        # 단계 0 (Domain 단계 선행 작업)
├── architecture.md                          # 3.1, 3.3, 4장, 7.1 개정 + D-ARCH-003 결정 기록
└── package-rules/
    ├── data.md                              # Infrastructure 의존 금지 제약 개정
    └── composition.md                       # Data↔Infrastructure Adapter 소유 서술 개정

sources/Projects/Domain/                     # 단계 1
├── Authentication/UseCases/                 # Protocol 4개 신설 + ObserveAuthenticationOutcomes rename
├── LearningProject/                         # 표준 약어 표기 rename (계약·Protocol·구현·모델)
├── Tests/Authentication/                    # 기존 테스트 유지
└── Tests/LearningProject/                   # rename에 따른 레이블 갱신

sources/Projects/Infrastructure/             # 단계 2
├── NetworkClient/                           # 대조 결과에 따른 최소 보완
├── Authentication/                          # 대조 결과에 따른 최소 보완
└── Tests/                                   # 보완 API 테스트

sources/Projects/Data/                       # 단계 3
├── LearningProject/                         # ProjectRemote 등 concrete 구현 신설
├── Authentication/                          # AuthenticationRemote 구현 신설
├── ExternalRepository/                      # ExternalRepositoryRemote 구현 신설
├── Member/                                  # 변경 없음 (범위 밖)
└── Tests/                                   # 요청·응답·오류 변환 테스트

sources/Projects/Composition/                # 단계 4
├── Adepter/ → Adapter/                      # 폴더 rename + Adapter·조립 진입점 구현
└── Tests/Adepter/ → Tests/Adapter/          # 폴더 rename + 그래프 생성·변환 테스트

sources/Tuist/ProjectDescriptionHelpers/
├── ProjectName.swift                        # 단계 4: target 이름 참조 2건
└── Projects/
    ├── DataModuleName.swift                 # 단계 3: Infrastructure 의존성 선언
    ├── CompositionModuleName.swift          # 단계 4: target rename + 의존성 선언
    └── AppModuleName.swift                  # 단계 4: target 이름 참조 1건 (FR-064a)
```

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 그대로 사용한다. 새 패키지나 새 target을 만들지
않고, `CompositionAdapter`(rename 후) target 안에서 조립을 구현한다. 각 패키지의 source 폴더는
역할 이름만 사용하는 기존 규칙을 따르며, `Adapter/` 폴더 이름은
`CompositionModuleName.sourceDirectory`의 `droppingPrefix` 계산과 그대로 부합한다(R-019).

## 위험과 대응

| 위험 | 영향 | 대응 |
|---|---|---|
| 문서 개정 범위가 명세보다 넓다 (R-006) | FR-059·FR-061이 `docs/architecture.md`만 지목하나 실제로는 `package-rules/data.md`, `composition.md`도 모순 상태 | 세 파일 모두 단계 0에 포함한다. 계획 보고에서 명시적으로 알린다. |
| Data 구현 범위가 조립 필요 범위를 넘어 확대 | Data 모듈에 Remote Protocol이 8개 있어 전부 구현하면 범위 초과 | 조립 대상 3기능(`Authentication`, `LearningProject`, `ExternalRepository`)이 요구하는 Protocol로 한정한다. `MemberRemote`는 제외한다. |
| Infrastructure 보완이 불필요할 수 있음 | 단계 2가 빈 단계가 될 가능성 | 대조 결과 보완이 없으면 근거를 보고하고 변경 없이 승인 게이트를 통과한다. 빈 단계도 근거 기록의 가치가 있다. |
| 조립 그래프에 소비처가 없음 | Composition 산출물을 사용하는 Feature·App이 범위 밖이라 dead code로 보일 수 있음 | Composition 테스트가 유일한 소비처가 된다. 후속 Feature·App 명세에서 연결한다는 점을 결정 기록에 남긴다. |
| rename이 동작 변경과 섞임 | `naming.md` §8 예외를 적용했으므로 순수 rename 보장이 무너지면 검증 범위를 구분할 수 없음 | rename을 해당 패키지 단계의 **선행 작업**으로 분리하고, rename 직후 동일 테스트 통과를 먼저 확인한 뒤 신규 구현을 시작한다(FR-067). |
| target rename의 파급 | `CompositionAdapter` rename이 manifest 3개, 폴더 2개, 소스 2개와 App 참조 1건에 걸침 | 영향 파일을 R-019에 전수 기록했다. `tuist generate`와 전체 빌드로 검증한다(SC-021). |
| framework bundleId 변경 | `Target.module`이 `bundleId`를 `name.lowercased()`로 만들어 `...compositionadepter` → `...compositionadapter`로 바뀜 | 내부 framework이며 App bundleId와 서명 구성에는 영향이 없다. 전체 빌드로 확인한다. |

## 시그니처와 네이밍 점검

`docs/conventions/naming.md`(최종 수정 2026-08-21) 기준 점검 결과다. 확정한 이름과 시그니처는
[contracts/naming-and-signatures.md](./contracts/naming-and-signatures.md)에 있다.

### 신규 이름

| 대상 | 이름 | 근거 |
|---|---|---|
| Authentication UseCase Protocol | `SignInUseCase`, `SignOutUseCase`, `RestoreSessionUseCase`, `ObserveAuthenticationOutcomesUseCase` | 기존 `<동사><명사>UseCase` 규약 (R-001) |
| Data Remote 구현 | `HTTPProjectRemote`, `HTTPAuthenticationRemote`, `HTTPExternalRepositoryRemote` | 구현이 HTTP를 실제로 소유. 선례 `URLSessionTransport` (R-015) |
| Domain↔Data Adapter | `LearningProjectRepositoryAdapter`, `ExternalRepositoryLookupAdapter`, `AuthenticationRepositoryAdapter`, `LoginSessionRepositoryAdapter` | 충족하는 Domain 계약을 이름이 드러냄 (R-016) |
| Composition 조립 진입점 | `LearningProjectAssembly`, `AuthenticationAssembly`, `ExternalRepositoryAssembly` | `naming.md` §4의 Composition 문맥 "조립" (R-016) |

### rename 3건 *(이번 범위에 포함)*

전수 조사 결과 규약 위반은 `DomainLearningProject`의 초기 모델군과 Composition target
철자에 집중돼 있다. Data DTO·Endpoint, Infrastructure, `DomainAuthentication`, Domain의
`ExternalRepository`는 이미 규칙을 지킨다 (R-017).

| # | 대상 | 변경 | 단계 |
|---|---|---|---|
| 1 | 표준 약어 표기 | `projectId`→`projectID`, `githubRepoUrl`→`githubRepoURL`, `nextSetId`→`nextSetID`, `nextQuestionId`→`nextQuestionID`, `setId`→`setID` | Domain |
| 2 | UseCase 이름 | `ObserveAuthorizationChanges`→`ObserveAuthenticationOutcomes` | Domain |
| 3 | Tuist target | `CompositionAdepter`→`CompositionAdapter` (+`Tests`, 폴더 포함) | Composition |

**순수 rename 보장**: 연산 집합, 상태, 저장 위치, 값의 수명과 소유자, 비동기·오류·취소 동작,
패키지 책임, 의존 방향, 외부 API mapping을 함께 바꾸지 않는다(FR-065). rename 전후 동일
테스트 통과로 확인한다(FR-067, SC-020).

**rename 제외**: Data `CodingKeys`의 서버 원문 키와 테스트 JSON fixture(FR-066),
`docs/spec-kit/**`의 append-only 기록(R-019).

### 시그니처 결정

- 신설 Protocol 4개는 구현의 현재 시그니처를 문자 그대로 옮긴다. 레이블, 생략 레이블(`_`),
  `async`·`throws` 유무를 바꾸지 않는다 (R-012). 표기 rename은 레이블 철자만 바꾸며 이 원칙과
  충돌하지 않는다.
- `FetchLearningProjectsUseCase`의 `page`·`size`는 호출자가 항상 명시한다. Protocol
  requirement에는 기본 인자를 둘 수 없고, extension으로 기본값을 흉내 내지 않는다 (R-014).

### 표기 반전이 발생하지 않는다

Domain 단계에서 표기 rename을 끝내므로 Data 단계의 구현과 Composition 단계의 Adapter는
처음부터 `projectID`·`githubRepoURL` 표기로 작성된다. 직전 계획이 예고했던 Adapter의 표기
반전은 발생하지 않으며, SC-022가 이를 0건으로 검증한다.

### 범위 밖으로 남는 것

`ObserveAuthenticationOutcomes`의 **책임 분리**(authorization 관찰과 세션 복원의 분리)는
이름 교정과 별개의 설계 변경이므로 이번 범위에 넣지 않는다 (R-013).

## 복잡성 추적

> 원칙 위반을 새로 도입하지는 않는다. 아래는 `naming.md` §8의 **예외를 적용한 결정**과 그
> 근거다 (Constitution 원칙 3).

| 항목 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
|------|-------------|-------------------------------|
| 네이밍 rename 3건을 이 기능에 포함 (`naming.md` §8은 rename과 설계·동작 변경의 분리를 요구) | 이 기능이 Domain UseCase 계약을 정본으로 확정하고 Composition Adapter를 신설하는 시점이다. 지금 바로잡지 않으면 규칙 위반 이름이 새 계약에 고정되고 Domain↔Data 표기 반전이 영구화된다 (R-018) | 별도 선행 명세(014)로 분리하는 방식이 §8에 더 충실하지만, 사용자가 013 포함을 선택했다. rename을 각 패키지 단계의 선행 작업으로 분리하고 전후 동일 테스트 통과를 확인해 검증 범위를 구분한다 |
| App manifest의 target 이름 참조 1건 변경 ("App 변경 없음" 가정의 예외) | `CompositionAdapter` target rename이 App의 의존성 선언을 필연적으로 건드린다 (FR-064a) | App을 건드리지 않으려면 target rename을 포기해야 한다. 변경을 이름 참조 1건으로 좁히고 App 소스 파일 변경 0건을 SC-021로 검증한다 |
| `ObserveAuthenticationOutcomes`의 책임 분리 미수행 | 이름 교정은 순수 rename이지만 관찰과 세션 복원의 분리는 동작이 바뀔 수 있는 설계 변경이다 (R-013) | 이번에 함께 하면 rename의 "동작 보존" 검증(FR-067)이 성립하지 않는다 |

**미검증 범위**: rename이 순수 rename임은 기존 테스트 통과로만 확인한다. 기존 테스트가
다루지 않는 동작이 있다면 이 rename도 그 범위를 검증하지 못한다. 이 점을 PR에 함께
기록한다(FR-068).
