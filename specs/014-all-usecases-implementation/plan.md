# 구현 계획: UC01~UC20 전체 UseCase end-to-end 구현

**Git-flow 유형**: `feature`

**브랜치**: `미생성 (예정: feature/all-usecases-implementation)`

**날짜**: 2026-08-22 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/014-all-usecases-implementation/spec.md`의 기능 명세

**참고**: 이 템플릿은 `/speckit-plan`이 채운다. 스킬 정의에는 실행 흐름이 설명되어 있다.

## 요약

현재 저장소는 UC01~UC05 일부의 Domain·Data·Composition 기반만 갖췄고 Feature production 구현과 App root 연결이 없어 사용자가 호출 가능한 UseCase가 없다. 이 계획은 `private/CONVENTION-BASELINE.md`(커밋 사본: [research.md](./research.md))가 고정한 패키지 책임·의존 방향·객체 수명 규칙을 그대로 적용해, UC01~UC20 Domain 계약(Protocol·모델·오류) → Infrastructure 범용 기술 API → Data concrete Remote → CompositionAdapter live graph → U01~U08 Feature → App root 순으로 [아키텍처 문서](../../docs/architecture.md) 3.1의 의존성 위상을 따라 단계적으로 구현한다. UC12(refresh)·UC14(revoke)는 서버 capability 미확보(`INT-API-001`)로 "구조 완료 / production 차단"으로 분리 표시하고, 임의 endpoint·DTO를 만들지 않는다.

## 기술 맥락

**언어/버전**: Swift (Xcode 최신 안정 버전), iOS 26.0+ 배포 대상

**주요 의존성**: SwiftUI, The Composable Architecture(TCA), Tuist(멀티 패키지 조립), AuthenticationServices(Apple 로그인)

**저장소**: 서버 REST API(HTTP, `Git-it-Server main@8641bc9...` 기준), Keychain(SessionRecord 보호 저장), 영속 DB 없음(전체 snapshot 재조회 방식)

**테스트**: Swift Testing 기본(`docs/conventions/test.md`), UI 자동화가 필요한 경로만 XCTest, TCA `TestStore`로 Feature reducer 검증

**대상 플랫폼**: iOS 26.0+ (iPhone), Simulator 기본 destination `iPhone 17 Pro`

**프로젝트 유형**: 모바일 앱 — Tuist 기반 멀티 패키지(App, Composition, Feature, Domain, Data, Infrastructure, UI)

**성능 목표**: 해당 없음(N/A) — 이 기능은 수치 SLA가 아니라 UC01~UC20의 구조적 완결성(Domain→App 도달성)을 목표로 한다

**제약 조건**: `private/CONVENTION-BASELINE.md`(커밋 사본: research.md)의 패키지 의존 방향·네이밍·객체 수명 규칙을 재해석하지 않고 적용; 서버 refresh/revoke endpoint(`INT-API-001`)·배포 OpenAPI(`INT-API-002`)·승인 약관(`INT-LEGAL-001`)·오픈소스 notice(`INT-LEGAL-002`)·production/staging base URL(`INT-ENV-001`) 미확보 상태에서는 해당 범위를 임의로 완성하지 않음; CI `GIT_IT_CI_VALIDATION_ENABLED` global flag로 인한 required job skip을 merge-ready로 취급하지 않음

**규모/범위**: UseCase 20개(UC01~UC20), Feature 화면 8개(U01~U08), 영향 패키지 7개(Domain, Infrastructure, Data, Composition, UI, Feature, App)

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

- **원칙 1(명시적 경계)**: 통과 — 패키지 의존은 [아키텍처 문서](../../docs/architecture.md) 3.1의 표를 그대로 따르며 새 의존 방향을 발명하지 않는다.
- **원칙 3(검증 가능한 변경)**: 통과 — 각 패키지 단계는 실제 build/test 실행 결과를 사용자에게 보고한 뒤에만 다음 단계로 진행한다(아래 "패키지 진행" 참고).
- **원칙 4(스킬별 수정 경로)**: 통과 — 이 계획은 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 수정한다. 구현 파일 경로는 `tasks.md`에서 확정한다.
- **원칙 5(Spec-Kit 범위)**: 통과 — 표에 정의된 스킬별 허용 경로를 그대로 따른다.
- **원칙 6(한국어 Spec-Kit 산출물)**: 통과 — 이 문서와 이후 산출물의 자연어 본문은 한국어로 작성한다.
- **원칙 7(패키지 단위 구현 진행)**: 통과 — 아래 "패키지 진행" 절이 의존성 위상 순서, 근거, 승인 게이트를 명시한다.
- **원칙 10(책임과 문맥에 따른 네이밍)**: 통과 — UseCase Protocol/concrete 명명은 `docs/conventions/naming.md`와 `private/CONVENTION-BASELINE.md`(research.md) 10장의 약어·접두어 규칙을 따른다.

**브랜치 네임스페이스**: 이 헌법 개정 후 새로 생성한 브랜치는 `feature/`, `hotfix/`,
`release/` 중 목적에 맞는 네임스페이스를 사용해야 한다. `/speckit-specify` 단계에서 `before_specify` 훅이 실행되지 않아 브랜치는 아직 생성되지 않았으며, 실제 생성된 것처럼 기록하지 않는다. 예정 이름은 `feature/all-usecases-implementation`이다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정할 수 있다. 이 산출물 밖의 구현 파일은 정확한
경로를 `tasks.md`에 기록하며 계획 단계에서는 수정하지 않는다.

**세션 지식 기록**: 실제 문제가 발생하면 `/speckit-troubleshooting`, 여러 세션의 독립
근거에서 암묵적인 판단 기준을 해석하면 `/speckit-tacit-knowledge`가 각 전용 파일에
append-only로 기록한다. 두 파일은 계획 산출물이나 구현 작업이 아니며 조건을 충족하지
않으면 빈 파일을 만들지 않는다.

**Git 실행 직렬화**: 같은 checkout에서 `git commit`, pre-commit과 staged formatter처럼
Git index, 작업 파일 또는 공유 formatter cache를 사용하는 변경 체인은 하나만 실행한다.
기존 체인의 종료와 결과를 확인하기 전에는 재시도하지 않으며, 중복 실행을 발견하면 실행
소유자와 index·작업 파일 상태를 확인하고 사용자 승인 없이 임의로 종료하지 않는다. 읽기
전용 Git 조회, 서로 다른 checkout과 실행별로 격리된 build·test 경로는 이 제한에서 제외한다.

**책임 기반 네이밍**: 프로젝트가 소유하는 공개 API와 경계를 넘는 값은 실제 책임과 필요한
최소 문맥을 드러내야 한다. 표면적인 통일만을 위한 공통 접두어·접미어·축약은 적용하지 않고,
저장·전달되는 값은 독립적으로 목적을 식별할 수 있게 계획한다. 외부 계약의 고정 이름은
보존하고 공급자 중립 경계에는 특정 공급자나 저장 기술의 용어를 노출하지 않는다. 네이밍과
설계·동작 변경이 함께 필요하면 범위와 검증을 분리한다. `docs/conventions/naming.md`를
Constitution 원칙 10과 함께 적용하며, `private/CONVENTION-BASELINE.md`(research.md) 10장의
약어 표기 규칙(예: `projectID`, `idToken`, `HTTPClient`)을 세부 기준으로 사용한다.

**패키지 진행**: 아래 "프로젝트 구조 > 패키지 진행 순서" 절이 이 명세가 변경하는 7개 패키지
전체를 의존성 위상 순서로 계획하고 각 순서의 근거를 남긴다. 이 명세가 변경하지 않는 패키지는
없다(App, Composition, Feature, Domain, Data, Infrastructure, UI 모두 대상). 각 적용 대상
패키지는 구현·검증·결과 보고·사용자 승인 후에만 다음 패키지로 진행한다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/014-all-usecases-implementation/
├── plan.md                        # 이 파일(/speckit-plan 산출물)
├── research.md                    # 0단계 산출물 — CONVENTION-BASELINE.md 커밋 사본과 정합 근거
├── data-model.md                  # 1단계 산출물 — Domain 엔터티·오류 정본
├── quickstart.md                  # 1단계 산출물 — 패키지별 빌드·테스트 검증 가이드
├── contracts/
│   └── usecase-catalog.md         # 1단계 산출물 — UC01~UC20 Protocol 계약(private/spec.md 7장 커밋 사본)
├── checklists/
│   └── requirements.md            # /speckit-specify, /speckit-clarify 산출물
└── tasks.md                       # 2단계 산출물(/speckit-tasks가 생성, 이 계획은 생성하지 않음)
```

### 소스 코드(저장소 루트)

```text
sources/
└── Projects/
    ├── Domain/
    │   ├── DomainAuthentication/          # UC11~UC14, RestoreSession, ObserveAuthenticationOutcomes
    │   ├── DomainLearningProject/         # UC01~UC10
    │   └── DomainMember/                  # 신규 target — UC15~UC20
    ├── Infrastructure/                    # 범용 HTTP·Keychain·Apple·알림 인증 기술 API(신규 API만 확장)
    ├── Data/
    │   ├── DataAuthentication/            # UC11~UC14 concrete Remote
    │   ├── DataExternalRepository/        # UC01 concrete Remote(기존 유지·검증)
    │   ├── DataLearningProject/           # UC02~UC10 concrete Remote(신규: Set/Answer/Bookmark)
    │   └── DataMember/                    # 신규: UC15~UC20 concrete Remote(HTTPMemberRemote)
    ├── Composition/
    │   └── CompositionAdapter/            # Authentication/ExternalRepository/LearningProject/Member Assembly, AppComposition
    ├── UI/
    │   ├── DesignSystem/                  # 기존 token 재사용
    │   └── UIComponent/                   # 누락 component(TextField, setting row, set row, question/answer), UIComponentPreviewApp rename
    ├── Feature/                           # U01~U08 reducer/view, FeatureTests(신규 target)
    └── App/
        └── GitIt/                         # composition root, RootFeature, navigation, lifecycle
```

**구조 결정**: 기존 Tuist 멀티 패키지 구조(App, Composition, Feature, Domain, Data, Infrastructure, UI)를 그대로 사용한다. 새 target은 `DomainMember`, `DomainMemberTests`, `DataMember`(신규 Infrastructure 의존 추가), `FeatureTests`뿐이며, 그 외에는 기존 target 안에 UC별 파일을 추가한다. Preview harness는 `UIComponentLayoutHarness` → `UIComponentPreviewApp`으로 이름만 교정한다(NFR-014-001~010, 상세는 research.md 12장 참고).

### 패키지 진행 순서

[아키텍처 문서](../../docs/architecture.md) 3.1의 의존성 표(`App→Feature,Composition,Domain`,
`Composition→Domain,Data,Infrastructure`, `Feature→Domain,UI`, `Domain→—`, `Data→Infrastructure`,
`Infrastructure→—`, `UI→—`)를 위상 정렬하면 다음과 같다.

| 순서 | 패키지 | 위상 근거 | 서로 의존하지 않는 패키지의 상대 순서 근거 |
|---|---|---|---|
| 1 | **Domain** | 피의존 패키지(`Domain→—`)이며 Data·Composition·Feature·App이 모두 Domain을 참조한다 | Infrastructure·UI와 상호 독립이지만, downstream(Data·Composition·Feature)의 public contract(UseCase Protocol·모델·오류)를 가장 먼저 고정해 이후 패키지의 재작업을 막기 위해 최우선으로 둔다 |
| 2 | **Infrastructure** | 피의존 패키지(`Infrastructure→—`)이며 Data가 필요로 한다 | Domain과 상호 독립이지만 Data가 즉시 필요로 하므로 Domain 다음, Data 이전에 둔다 |
| 3 | **Data** | `Data→Infrastructure`이므로 Infrastructure 이후에만 구현 가능하다 | 해당 없음(단일 선행 의존) |
| 4 | **Composition** | `Composition→Domain,Data,Infrastructure`이므로 세 패키지 이후에만 조립 가능하다 | 해당 없음(세 선행 의존 모두 확정된 뒤 진행) |
| 5 | **UI** | `UI→—`(피의존)이며 Feature가 필요로 한다 | Composition과 상호 독립이지만, live UseCase graph(Composition)를 먼저 검증한 뒤 UI/Feature로 이동하기 위해 Composition 다음에 둔다(`private/CONVENTION-BASELINE.md` 14장과 동일 근거) |
| 6 | **Feature** | `Feature→Domain,UI`이므로 Domain·UI 이후에만 구현 가능하다 | 해당 없음(두 선행 의존 모두 확정된 뒤 진행) |
| 7 | **App** | `App→Feature,Composition,Domain`이므로 세 패키지 이후에만 구현 가능하다 | 해당 없음(최종 조립 단계) |

이 순서는 `private/CONVENTION-BASELINE.md` 14장(커밋 사본: research.md)이 제시한 순서와 동일하며, 두 문서의 근거가 서로 모순되지 않는다. 이 명세의 구현이 끝날 때까지 이 순서를 바꾸지 않는다.

**공용 구성 파일 배정**: Tuist manifest(`Project.swift`) 변경 중 여러 패키지의 target 선언에 걸치는 항목(예: `DomainMember`/`DomainMemberTests` 신설, `DataMember→InfrastructureNetworkClient` 의존 추가, `CompositionAdapter→DomainMember,DataMember` 의존 추가, `Feature→DomainAuthentication,DomainMember` 의존 추가)은 그 target을 최초로 필요로 하는 책임 패키지 단계로 각각 분리해 배정한다. 구체적인 target별 배정은 `tasks.md`에서 확정한다.

## 복잡성 추적

> **헌법 점검에서 정당화해야 하는 위반이 있을 때만 작성한다**

해당 없음 — 이 계획은 기존 아키텍처 문서와 CONVENTION-BASELINE.md의 패키지 구조·의존 방향을 그대로 따르며 새로운 프로젝트나 패턴을 추가하지 않는다.
