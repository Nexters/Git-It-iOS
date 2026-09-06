# 구현 계획: 레포지토리 생성 상태관리 Repository

**Git-flow 유형**: `feature`

**브랜치**: `feature/repository-creation-state`

**날짜**: 2026-09-06 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/028-repository-creation-state/spec.md`의 기능 명세

## 요약

레포지토리(GitHub repo) 등록이 진행 중(생성 중)인지 추적하는 새로운 Domain 계약
`RepositoryCreationStateRepository`를 도입한다. `CreateLearningProject` UseCase는 등록을
시작하기 전 정규화된 `githubRepoURL` 기준으로 중복 여부를 확인해 이미 진행 중이면 서버
호출 없이 `LearningProjectError`의 새 case로 즉시 거부하고, 등록 성공 시 발급된 `projectID`를
상태에 연결한다. `FetchLearningProjects` UseCase는 조회 결과에서 "생성 중"으로 기록된
`projectID`에 대응하는 항목을 제외한다. 상태 해제는 기존 `ObserveGenerationOutcomesUseCase`
스트림(성공/실패)과, 신호 유실에 대비한 15분(900초) 조회 시점 만료로 이뤄진다. 상태는
프로세스 메모리에만 유지하며 영속화하지 않는다(FR-008). 실제 저장·구독 구현은 Composition
계층의 단일 actor(예: `RepositoryCreationStateRepositoryAdapter`)가 맡아 기존
`GenerationCompletionReminderCoordinator`와 동일한 조립 패턴(App 부트스트랩에서
`observeGenerationOutcomes` 구독 시작)을 따른다.

## 기술 맥락

**언어/버전**: Swift 5.9+, iOS 26.0+ (Tuist 멀티 패키지, 기존 프로젝트 툴체인 그대로 사용)

**주요 의존성**: 없음(신규 외부 라이브러리 도입 없음). 기존 Domain `ObserveGenerationOutcomesUseCase`,
`GenerationOutcomeRepository`, `LearningProjectRepository`, TCA(Feature 계층, 이 기능에서는 변경
없음)를 재사용한다.

**저장소**: N/A — "생성 중" 상태는 Composition 계층의 in-memory actor에만 보관하며(FR-008)
디스크·서버·UserDefaults에 기록하지 않는다.

**테스트**: Swift Testing(프로젝트 기본), Domain UseCase는 in-memory 테스트 더블로 계약 테스트,
Composition adapter는 `Composition/Tests`의 기존 Adapter 테스트 패턴을 따른다.

**대상 플랫폼**: iOS 26+ App과 Share Extension 프로세스(둘 다 `LearningProjectAssembly`를 통해
`CreateLearningProjectUseCase`를 사용)

**프로젝트 유형**: 모바일 앱(Tuist 멀티 패키지: App/Composition/Feature/Domain/Data/Infrastructure/UI)

**성능 목표**: 특별한 처리량 목표 없음 — 사용자당 동시 "생성 중" 레포지토리 수는 통상 0~수개
수준이므로 상태 조회·기록은 단순 컬렉션 연산(O(n), n은 수십 이하)으로 충분하다.

**제약 조건**: 기존 `LearningProjectRepository`·`BookmarkRepository`의 공개 계약과 동작은
변경 전후 100% 동일해야 한다(SC-004). Domain은 Data·Composition·Feature에 의존하지 않는다.

**규모/범위**: 사용자당 동시 "생성 중" 레포지토리 수는 극소수(통상 0~수개)이며, 대량 동시
생성 시나리오는 이 기능의 범위가 아니다.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

- **명시적인 경계(원칙 1)**: 새 계약 `RepositoryCreationStateRepository`는 Domain의
  `LearningProject` 모듈에 위치하고, 실제 구현(in-memory actor)은 Composition의
  `Adapter/Adapters`에 위치한다. Domain은 Composition·Data를 참조하지 않는다. **통과**.
- **상태와 데이터 안전성(원칙 2)**: "생성 중" 상태는 Composition actor가 소유하며 명확한 수명
  범위(프로세스 생존 기간, 15분 만료)를 가진다. 등록 실패·완료·실패 신호·타임아웃 각각에서
  해제 경로가 정의되어 있다(FR-004, FR-005, FR-005a). **통과**.
- **검증 가능한 변경(원칙 3)**: Domain UseCase 변경과 Composition adapter 추가에 대해 각각
  단위 테스트를 추가하고 기존 `LearningProjectRepositoryAdapter`/`BookmarkRepositoryAdapter`
  테스트가 회귀 없이 통과하는지 확인한다. **통과 예정** — 1단계 설계 후 재확인.
- **스킬별 수정 경로 / Spec-Kit 범위(원칙 4, 5)**: 이 단계는 `plan.md`, `research.md`,
  `data-model.md`, `quickstart.md`, `contracts/**`만 수정한다. **통과**.
- **한국어 Spec-Kit 산출물(원칙 6)**: 이 문서와 하위 산출물은 한국어로 작성한다. **통과**.
- **위험 기반 실행 단위(원칙 7)**: 변경 대상 패키지는 Domain과 Composition 두 곳이며 서로
  독립적으로 컴파일·테스트 가능한 단일 패키지 단위로 나눌 수 있다(Domain 계약 추가 → Domain
  UseCase 수정 → Composition adapter 추가·배선 순서). 분리 시 중간 상태가 깨지는 공개 API
  이전이나 공용 manifest 변경이 없으므로 불가분한 다중 패키지 unit은 필요 없다. **통과**.
- **Git-flow 브랜치 네임스페이스(원칙 8)**: `feature/repository-creation-state` 브랜치를
  `/speckit-specify`가 이미 생성·검증했다. **통과**.

**게이트 결과**: 위반 없음. 복잡성 추적 섹션은 작성하지 않는다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/028-repository-creation-state/
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md         # 1단계 산출물(/speckit-plan)
├── quickstart.md        # 1단계 산출물(/speckit-plan)
├── contracts/           # 1단계 산출물(/speckit-plan) — Domain 계약 설명
└── tasks.md             # 2단계 산출물(/speckit-tasks, 이 계획은 만들지 않음)
```

### 소스 코드(저장소 루트)

기존 Tuist 멀티 패키지 구조를 그대로 사용하며 새 패키지를 만들지 않는다. 이 기능이 실제로
건드리는 범위만 아래에 표시한다(전체 구조는 [아키텍처 문서](../../docs/architecture.md) 참고).

```text
sources/Projects/
├── Domain/LearningProject/
│   ├── Contracts/
│   │   ├── LearningProjectRepository.swift        # 변경 없음(참고용)
│   │   └── RepositoryCreationStateRepository.swift # 신규 계약
│   ├── Errors/
│   │   └── LearningProjectError.swift              # 새 case 추가
│   ├── Models/LearningProject/
│   │   └── RepositoryCreationState.swift           # 신규 모델
│   ├── UseCases/CreateLearningProject/
│   │   └── CreateLearningProject.swift             # 중복 확인·상태 기록 로직 추가
│   └── UseCases/FetchLearningProjects/
│       └── FetchLearningProjects.swift             # 생성 중 항목 필터링 추가
├── Domain/Tests/LearningProject/UseCases/
│   ├── CreateLearningProjectTests.swift            # 회귀 + 신규 시나리오
│   └── FetchLearningProjectsTests.swift            # 회귀 + 신규 시나리오
└── Composition/Adapter/
    ├── Adapters/RepositoryCreationStateRepositoryAdapter.swift # 신규 actor(Domain 계약 구현 + outcome 구독, 기존 *Adapter 명명 관례 준수)
    ├── Assemblies/LearningProjectAssembly.swift          # adapter 생성·주입 배선
    └── Tests/Adapter/Adapters/RepositoryCreationStateRepositoryAdapterTests.swift # 신규 테스트

sources/Projects/Composition/App/Assemblies/AppComposition.swift  # repositoryCreationStateAdapter.start(observeGenerationOutcomes:) 부트스트랩 배선 추가(기존 GenerationCompletionReminderCoordinator 구독 시작과 동일한 자리, 단 이 타입 자체는 Adapter/Factories가 아닌 Adapter/Adapters에 위치)
```

**구조 결정**: 새 패키지나 새 모듈은 만들지 않는다. 기존 `LearningProject` Domain 모듈과
`Composition/Adapter` 모듈 안에 이 기능의 계약·모델·UseCase 변경·adapter를 추가하고, App
부트스트랩 한 지점에서 기존 `GenerationCompletionReminderCoordinator` 패턴과 동일하게
구독을 시작한다. Data 패키지는 변경하지 않는다(서버 API·DTO가 관여하지 않음). Feature/App/UI
패키지의 공개 UseCase 시그니처는 변경되지 않으므로 이 계층들의 소스 변경은 필요 없다.
