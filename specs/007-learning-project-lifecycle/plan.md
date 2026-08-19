# 구현 계획: 학습 프로젝트 생명주기 UseCase 구현

**Git-flow 유형**: `feature`

**브랜치**: `미생성 (예정: feature/learning-project-lifecycle)` — `before_plan` 생성 훅이 실행되지 않아 spec.md와 동일하게 미생성 상태를 유지한다.

**날짜**: 2026-08-19 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/007-learning-project-lifecycle/spec.md`의 기능 명세

## 요약

spec 006이 확정한 `Git-It-server-scheme.json` 계약과 `sources/docs/git-it-domain-usecases/`
문서를 바탕으로, 학습 프로젝트 생명주기의 5개 UseCase(`FetchExternalRepository`,
`CreateLearningProject`, `FetchLearningProjects`, `FetchLearningProjectDetail`,
`DeleteLearningProject`)를 `DomainAuthentication`/`DataAuthentication`과 동일한 레이어
경계로 실제 Swift 코드로 구현한다. 새 Domain 패키지 `DomainLearningProject`(Contracts·
Models·UseCases)와 새 Data 패키지 `DataLearningProject`(Contracts·DTOs·Errors)를
Tuist 모듈로 추가한다. `sources/docs/architecture.md`의 패키지 의존성 제약(Domain·Data는
서로 참조 불가, Data→Infrastructure 불가)에 따라 실제 HTTP 호출과 DTO↔Domain 모델 변환을
수행하는 Composition Adapter는 이 계획의 범위 밖이며, 각 계층은 Test Double로 대체 가능한
계약과 계약 테스트로 "실제로 동작함"을 검증한다(FR-025). Composition 배선과 Feature/UI
화면은 후속 스펙이 담당한다.

## 기술 맥락

**언어/버전**: Swift(iOS 26.0+ deployment target, 기존 프로젝트와 동일 — `Target+Module.swift`
`deploymentTargets: .iOS("26.0")`)

**주요 의존성**: 프로젝트 내부 의존성만 사용한다 — Domain·Data 신규 target은 Swift 표준
라이브러리 외 의존성을 추가하지 않는다(`sources/docs/architecture.md` §6 외부 패키지
의존성 정책, Domain/Data 행: `Swift Standard Library`). 외부 서버·GitHub API 호출은 이
계획이 아닌 후속 Composition 구현이 `003-http-client`의 `InfrastructureNetworkClient`
(`HTTPClient`)를 재사용한다(가정, spec.md `가정` 절).

**저장소**: N/A — 이 5개 UseCase는 로컬 캐싱·영속화를 구현하지 않는다(FR-010, FR-021,
spec.md `범위 밖`).

**테스트**: Swift Testing(`import Testing`, `@Suite`/`@Test`/`#expect`) — `DomainAuthenticationTests`/
`DataAuthenticationTests`와 동일한 프레임워크·명명 관례(한국어 `@Suite`/`@Test` 설명,
백틱 테스트 함수 이름).

**대상 플랫폼**: iOS 26.0+(기존 프로젝트와 동일). 이 기능 자체는 UI를 구현하지 않는다.

**프로젝트 유형**: Tuist 기반 iOS 멀티 패키지 앱의 Domain·Data 패키지 확장.

**성능 목표**: N/A — 도메인 로직·계약 정의 수준으로, 명시적 성능 목표가 없다.

**제약 조건**: `sources/docs/architecture.md` §3.1 패키지 의존성 표(Domain: `—`, Data:
`—`)와 §7.1 금지 의존성 목록(`Data → Infrastructure`, `Domain → Data`, `Data → Domain`
포함)을 위반할 수 없다. `sources/docs/package-rules/domain.md`·`data.md`의 제약조건
(Domain은 Data 모델·DTO·서버 API 형식 참조 금지, Data는 Domain 타입 참조·Domain
Repository 구현 금지)도 동일하게 적용된다.

**규모/범위**: 신규 Domain target 1개(`DomainLearningProject` + 테스트 target), 신규
Data target 1개(`DataLearningProject` + 테스트 target), UseCase 5개, Domain 계약 2개,
Data 계약 2개, Domain 모델 8종, Data DTO 7종, Domain/Data 오류 타입 각 2종.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

- **명시적인 경계(원칙 1)**: 신규 `DomainLearningProject`/`DataLearningProject`는
  `sources/docs/architecture.md` §3.1 의존성 표를 그대로 따른다 — 두 패키지 모두 프로젝트
  내부의 다른 패키지에 의존하지 않는다(Tuist에 의존성을 선언하지 않음). **통과**(설계로
  보장, 아래 "설계 후 재점검" 참고).
- **상태와 데이터 안전성(원칙 2)**: UseCase는 `async throws` 비동기 함수로 오류 경로를
  명시적인 Domain 오류 타입(`ExternalRepositoryError`, `LearningProjectError`)으로
  드러낸다. 취소 경로는 Swift Concurrency의 `Task` 취소 전파에 위임하며 별도 취소 처리
  로직을 추가하지 않는다(불필요한 복잡성 회피). 개인정보(GitHub URL, 프로젝트 정보)는
  UseCase 입력·출력 범위를 벗어나 저장하지 않는다(FR-010, FR-021). **통과**.
- **검증 가능한 변경(원칙 3)**: 각 UseCase는 성공 1개 이상·오류 전 경로 계약 테스트를
  가진다(FR-025, quickstart.md). 이 계획 단계에서 Git index나 작업 파일을 바꾸는 명령을
  실행하지 않았다. **통과**.
- **스킬별 수정 경로(원칙 4·5)**: 이 명령은 `plan.md`, `research.md`, `data-model.md`,
  `quickstart.md`, `contracts/**`만 생성·수정했다. `sources/**` 실제 구현 파일은 아래
  "프로젝트 구조"에 예상 경로만 기록하며 이 단계에서 생성·수정하지 않는다. **통과**.
- **Git 실행 직렬화(원칙 3)**: 이 계획은 Git index 변경 체인을 실행하지 않는다. 해당 없음.
- **책임 기반 네이밍(원칙 10)**: Domain 모델(`ExternalRepository`, `LearningProjectSummary`,
  `LearningProjectDetail`, `LearningProjectRegistration` 등)은 목록·상세·등록 응답의
  서로 다른 책임을 하나의 이름으로 뭉치지 않고 분리했다(data-model.md 참고, naming.md §3
  "하나의 모델 이름으로 외부 계약, 저장 모델과 Domain 모델을 동시에 표현하지 않는다").
  외부 고정 이름(`projectId`, `quizLevel`, `githubRepoUrl` 등)은 보존했다. **통과**.
- **패키지 진행(원칙 7)**: 이 명세가 변경하는 패키지는 Domain·Data 두 개뿐이다(Infrastructure·
  Composition·UI·Feature·App은 spec.md `범위 밖`에 따라 변경하지 않음). 순서는
  `Domain(DomainLearningProject) → Data(DataLearningProject)`다. 공용 Tuist 구성 파일
  (`ProjectName.swift`, 신규 `DomainModuleName.swift`/`DataModuleName.swift` 항목)의
  변경은 각 파일이 참조하는 패키지 단계로 분리한다 — `ProjectName.swift`의 Domain
  스킴 목록 수정은 Domain 단계, Data 스킴 목록 수정은 Data 단계에 배정한다(아래
  "프로젝트 구조" 참고). `tasks.md`는 이 순서와 단계별 검증·승인 게이트를 명시해야 한다.
- **Git-flow 브랜치 네임스페이스(원칙 8)**: 브랜치는 spec.md와 동일하게
  `미생성 (예정: feature/learning-project-lifecycle)` 상태이며 생성된 것처럼 기록하지
  않는다.
- **Spec Kit 세션 지식 기록(원칙 9)**: 이 계획 단계에서 조사 중 spec.md FR-007의 서술과
  `Git-It-server-scheme.json`의 `RegisterProjectResponse` 스키마 사이에 실제 코드 오류나
  세션 실패는 없었고, 스키마가 `quizLevel`을 응답 필드로 포함하지 않는다는 사실을 확인해
  설계 결정(research.md 결정 7)으로 해소했다 — 이는 계획 단계의 정상적인 모호성 해소이므로
  `trouble-shooting.md`/`tacit-knowledge.md`에 추가 기록하지 않는다.

### 설계 후 재점검

`data-model.md`·`contracts/`를 작성하며 아래를 재확인했다.

- Domain 계약(`ExternalRepositoryLookup`, `LearningProjectRepository`)과 Domain 모델은
  Data DTO·서버 schema 용어를 노출하지 않는다(`domain.md` 제약조건 준수).
- Data 계약(`ExternalRepositoryRemote`, `LearningProjectRemote`)과 DTO는 Domain 타입을
  전혀 참조하지 않으며, Domain Repository를 구현하지 않는다(`data.md` 제약조건 준수).
- FR-024 "그 구현은 Data 패키지에서 서버 API 호출과 DTO↔Domain 모델 변환을 담당해야
  한다"는 문자 그대로 두면 `architecture.md`(Data → Infrastructure 금지, Data는 Domain
  모델로 변환하는 API 제공 금지)와 충돌한다. Constitution 적용 절("하위 문서가 이 문서와
  충돌하면 이 문서에 맞게 하위 문서를 수정")에 따라, 이 계획은 FR-024를 "Data는 실제 서버
  호출에 필요한 계약(Remote)과 요청·응답 DTO를 소유하고, 실제 HTTP 호출 수행과 DTO↔Domain
  변환은 이를 위임받는 Composition Adapter가 담당한다"로 해석한다(research.md 결정 6).
  이는 `DomainAuthentication`/`DataAuthentication`이 이미 따르고 있는 것과 동일한 경계다
  (두 패키지 모두 아직 production Adapter가 없다). 새로 발견한, 정당화가 필요한 위반은
  없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/007-learning-project-lifecycle/
├── spec.md
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md         # 1단계 산출물(/speckit-plan)
├── quickstart.md         # 1단계 산출물(/speckit-plan)
├── contracts/            # 1단계 산출물(/speckit-plan) — UseCase별 계약 5개
│   ├── fetch-external-repository.md
│   ├── create-learning-project.md
│   ├── fetch-learning-projects.md
│   ├── fetch-learning-project-detail.md
│   └── delete-learning-project.md
└── checklists/requirements.md
```

### 소스 코드(저장소 루트)

이 계획은 아래 경로를 생성·수정하지 않는다 — `tasks.md`가 각 파일을 정확히 하나의
패키지 단계에 배정해 실제 작업 목록으로 만든다. 배치는 `DomainAuthentication`/
`DataAuthentication`의 기존 폴더 관례(`Contracts/`, `Models/`, `DTOs/`, `Errors/`)를
따르고, FR-023이 요구하는 `UseCases/` 폴더를 Domain에 새로 도입한다(research.md 결정 2 —
`DomainAuthentication`은 아직 이 폴더를 쓰지 않지만 FR-023이 명시적으로 요구한다).

```text
sources/Projects/Domain/
├── DomainLearningProject/                         # [Domain 단계]
│   ├── Contracts/
│   │   ├── ExternalRepositoryLookup.swift          # GitHub 조회 계약(FR-001~004)
│   │   └── LearningProjectRepository.swift         # Git-It 서버 CRUD 계약(FR-005~022)
│   ├── Models/
│   │   ├── ExternalRepository.swift
│   │   ├── ExternalRepositoryError.swift
│   │   ├── QuizLevel.swift
│   │   ├── QuizGenerationStatus.swift
│   │   ├── LearningProjectRegistration.swift        # CreateLearningProject 응답
│   │   ├── LearningProjectSummary.swift             # 목록 항목
│   │   ├── LearningProjectPage.swift                # 목록 + hasNext
│   │   ├── LearningProjectDetail.swift              # 상세(다음 세트 계산 포함, FR-019)
│   │   ├── LearningProjectSetProgress.swift         # 상세의 sets[] 항목
│   │   └── LearningProjectError.swift
│   └── UseCases/
│       ├── FetchExternalRepository.swift            # URL 파싱 포함(FR-001)
│       ├── CreateLearningProject.swift
│       ├── FetchLearningProjects.swift
│       ├── FetchLearningProjectDetail.swift
│       └── DeleteLearningProject.swift
└── DomainLearningProjectTests/                      # [Domain 단계]
    ├── Contracts/ (계약 테스트 — Test Double 기반)
    ├── Models/ (모델·오류·다음 세트 계산 단위 테스트)
    └── UseCases/ (FR-025 성공 1개 이상 + 문서화된 모든 오류 경로)

sources/Projects/Data/
├── DataLearningProject/                             # [Data 단계]
│   ├── Contracts/
│   │   ├── ExternalRepositoryRemote.swift
│   │   └── LearningProjectRemote.swift
│   ├── DTOs/
│   │   ├── GitHubRepositoryResponseDTO.swift
│   │   ├── RegisterProjectRequestDTO.swift
│   │   ├── RegisterProjectResponseDTO.swift
│   │   ├── ProjectListResponseDTO.swift
│   │   ├── ProjectListItemDTO.swift
│   │   ├── ProjectDetailResponseDTO.swift
│   │   └── ProjectSetSummaryDTO.swift
│   └── Errors/
│       ├── DataExternalRepositoryError.swift
│       └── DataLearningProjectError.swift
└── DataLearningProjectTests/                        # [Data 단계]
    ├── Contracts/ (계약 테스트 — Test Double 기반)
    ├── DTOs/ (디코딩 테스트, 서버 예시 JSON 기반)
    └── Errors/ (오류 타입 단위 테스트)

sources/Tuist/ProjectDescriptionHelpers/Projects/
├── DomainModuleName.swift    # DomainLearningProject/Tests case 추가 — [Domain 단계]
└── DataModuleName.swift      # DataLearningProject/Tests case 추가 — [Data 단계]

sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift
    # 공용 파일 — .module(name: "DomainLearningProject", ...) 스킴 항목 추가는
    # [Domain 단계], .module(name: "DataLearningProject", ...) 스킴 항목 추가는
    # [Data 단계]로 분리해 각 단계에서 각자의 항목만 수정한다.
```

**구조 결정**: 기존 `DomainAuthentication`/`DataAuthentication` 패키지 옆에 동일한 형태의
새 패키지 쌍(`DomainLearningProject`/`DataLearningProject`)을 추가한다. `ExternalRepository`
확인(GitHub)과 `LearningProject` CRUD(Git-It 서버)는 서로 다른 외부 시스템이지만, spec.md가
이 둘을 "학습 프로젝트 생명주기"라는 하나의 시나리오·bounded context로 묶었고(006의
계약 문서 그룹핑과 동일) 두 계약 모두 등록 흐름의 입력·출력으로 직접 연결되므로 패키지를
나누지 않는다(research.md 결정 1). Composition·Infrastructure·UI·Feature·App은 이 기능이
변경하지 않으므로 구조에 포함하지 않는다.

## 복잡성 추적

이 계획은 헌법 점검을 모두 통과했고 정당화가 필요한 위반이 없다. 표를 작성하지 않는다.
