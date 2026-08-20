# 구현 계획: GitHub·Git-It 프로젝트 API Composition Adapter 구축

**Git-flow 유형**: `feature`

**브랜치**: `미생성 (예정: feature/network-composition-adapters)` — `before_plan` 생성 훅이
없어 spec.md와 동일하게 미생성 상태를 유지한다.

**날짜**: 2026-08-20 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/008-network-composition-adapters/spec.md`의 기능 명세

## 요약

007-learning-project-lifecycle이 Domain·Data 계약까지만 구현하고 남겨둔 실제 네트워크
호출 공백을 메운다. `ExternalRepositoryLookup`(GitHub)과 `LearningProjectRepository`
(Git-It 서버) 각각에 대해 Domain↔Data Adapter 1개 + Data↔Infrastructure Adapter 1개, 총
4개의 Composition Adapter를 `sources/Projects/Composition/Composition/LearningProjectLifecycle/`에
구현한다. `003-http-client`의 `HTTPClient`를 그대로 재사용하고, Git-It 서버 요청의
Bearer 토큰은 `001-apple-social-login`이 이미 정의한 `LoginSessionStorage`를 소비해
첨부한다(그 프로덕션 구현은 범위 밖). 재시도와 로깅은 하지 않는다(`/speckit-clarify`
2026-08-20 결정). 이 기능이 변경하는 패키지는 `Composition` 하나뿐이며, 007의
`DomainLearningProject`/`DataLearningProject`가 먼저 구현되어 있어야 실제로 구현할 수
있다(research.md 결정 0).

## 기술 맥락

**언어/버전**: Swift(iOS 26.0+ deployment target, 기존 프로젝트와 동일)

**주요 의존성**: 프로젝트 내부 의존성만 사용한다 — `architecture.md` §6 외부 패키지
의존성 정책의 Composition 행("제한적 허용... 외부 기술 사용은 Infrastructure API를 통해
수행")에 따라 새 외부 패키지를 추가하지 않는다. `003-http-client`의 `HTTPClient`,
007의 `DomainLearningProject`/`DataLearningProject`, 001의 `DataAuthentication`
(`LoginSessionStorage`)을 그대로 재사용한다.

**저장소**: N/A — 이 기능은 상태를 저장하지 않는다. `LoginSessionStorage`를 소비만
하며 그 저장소 구현(Keychain 등)은 범위 밖이다.

**테스트**: Swift Testing(`import Testing`, `@Suite`/`@Test`/`#expect`) — 기존
`CompositionTests` 관례를 따른다. 실제 네트워크 호출 대신 Fake `HTTPTransport`(`003`이
정의한 시드포인트)와 Fake `LoginSessionStorage`를 주입해 `HTTPClient`의 실제 요청
구성·응답 해석 경로를 그대로 실행한다(research.md, contracts/).

**대상 플랫폼**: iOS 26.0+(기존 프로젝트와 동일). 이 기능은 UI를 구현하지 않는다.

**프로젝트 유형**: Tuist 기반 iOS 멀티 패키지 앱의 기존 `Composition` target 확장(새
target을 만들지 않는다).

**성능 목표**: N/A — `HTTPClient`의 기본 응답 대기 한도(15초, `003` 결정)를 그대로
따르며 이 기능이 별도 목표를 추가하지 않는다.

**제약 조건**: `architecture.md` §3.1 패키지 의존성 표(Composition: Domain·Data·
Infrastructure 참조 가능)와 §7.1 금지 의존성 목록을 위반할 수 없다.
`docs/package-rules/composition.md`의 제약조건(비즈니스 규칙·캐시 정책·화면
상태를 Adapter에 두지 않음, 외부 라이브러리 직접 사용 금지)도 동일하게 적용된다.

**규모/범위**: 신규 Composition Adapter 4종(`ExternalRepositoryRemoteAdapter`,
`ExternalRepositoryLookupAdapter`, `LearningProjectRemoteAdapter`,
`LearningProjectRepositoryAdapter`), 기존 `CompositionModuleName.swift` 의존성 선언
확장 1건. 신규 Domain/Data/Infrastructure 코드 없음(모두 007·003·001 재사용).

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

- **명시적인 경계(원칙 1)**: `Composition`은 `architecture.md` §3.1 표에 따라 Domain·
  Data·Infrastructure에 의존할 수 있다. 이 기능은 그 허용 범위 안에서만 의존성을
  추가한다(research.md 결정 7). **통과**.
- **상태와 데이터 안전성(원칙 2)**: 4개 Adapter는 `async throws`(표준 throws)로 오류
  경로를 명시적인 Data/Domain 오류 타입으로 드러낸다. `HTTPClient`의 typed throws
  (`HTTPClientError`)는 Data↔Infrastructure Adapter 경계에서 즉시 표준 throws로
  브리지하고 그 밖으로 전파하지 않는다(research.md 결정 5). 취소는 `Task` 취소 전파에
  위임한다. 액세스 토큰은 로그·기록에 남기지 않는다(FR-016). **통과**.
- **검증 가능한 변경(원칙 3)**: 4개 Adapter는 각각 성공 1개 이상·오류 전 경로 계약
  테스트를 가진다(FR-014, quickstart.md). 이 계획 단계에서 Git index나 작업 파일을
  바꾸는 명령을 실행하지 않았다. **통과**.
- **스킬별 수정 경로(원칙 4·5)**: 이 명령은 `plan.md`, `research.md`, `data-model.md`,
  `quickstart.md`, `contracts/**`만 생성·수정했다. `sources/**` 실제 구현 파일은 아래
  "프로젝트 구조"에 예상 경로만 기록하며 이 단계에서 생성·수정하지 않는다. **통과**.
- **Git 실행 직렬화(원칙 3)**: 이 계획은 Git index 변경 체인을 실행하지 않는다. 해당
  없음.
- **책임 기반 네이밍(원칙 10)**: Adapter 이름(`ExternalRepositoryRemoteAdapter`,
  `ExternalRepositoryLookupAdapter`, `LearningProjectRemoteAdapter`,
  `LearningProjectRepositoryAdapter`)은 `composition.md` 정책대로 Adapter·조립 책임만
  드러내고 새 Domain·Data 책임을 암시하지 않는다. `LoginSessionStorage`처럼 저장 기술
  용어를 노출하지 않는 기존 계약명을 그대로 재사용한다. **통과**.
- **패키지 진행(원칙 7)**: 이 명세가 변경하는 패키지는 `Composition` 하나뿐이다
  (Domain·Data·Infrastructure는 007·003·001이 이미 소유하며 이 기능이 재정의하지
  않는다). 단, `Composition`이 참조하는 `DomainLearningProject`/`DataLearningProject`가
  아직 구현되지 않았음을 확인했다(research.md 결정 0) — `tasks.md`는 007의 Domain·Data
  구현·검증·승인이 끝난 뒤에만 `Composition` 작업을 시작할 수 있다는 선행 조건을
  명시해야 한다.
- **Git-flow 브랜치 네임스페이스(원칙 8)**: 브랜치는 spec.md와 동일하게 `미생성 (예정:
  feature/network-composition-adapters)` 상태이며 생성된 것처럼 기록하지 않는다.
- **Spec Kit 세션 지식 기록(원칙 9)**: 이 계획 단계에서 실제 오류나 세션 실패는
  없었다. 다만 여러 세션·저장소 근거(007·001·003의 spec.md·plan.md, 실제 소스 트리,
  `Git-It-server-scheme.json`)를 종합해 "이 저장소의 모든 이전 스펙이 Composition
  Adapter 구현을 일관되게 후속 작업으로 미뤄왔다"는 문서화되지 않은 패턴과
  "`LoginSessionStorage`를 액세스 토큰 공급 지점으로 재사용한다"는 설계 기준을
  해석했다 — 이는 `/speckit-tacit-knowledge` 기록 대상 후보이며, 이 계획 스킬은 직접
  기록하지 않고 최종 보고에서 별도 실행을 권장한다.

### 설계 후 재점검

`data-model.md`·`contracts/`를 작성하며 아래를 재확인했다.

- 4개 Adapter는 Domain↔Data / Data↔Infrastructure 두 계층으로 분리되어
  `composition.md`가 요구하는 책임 분리(DTO·오류 변환은 Domain↔Data가, wire 형식
  변환은 Data↔Infrastructure가)를 그대로 따른다(research.md 결정 1·4).
- `LoginSessionStorage` 재사용 결정(research.md 결정 2)이 `naming.md`의 중복 회피
  원칙과 `domain.md`/`data.md`의 계층 경계 제약을 위반하지 않음을 확인했다 — 이
  기능은 `LoginSessionStorage`를 소비만 하고 구현하지 않으므로 Data↔Infrastructure
  경계를 넘지 않는다.
- base URL을 생성자로 주입받는 구조(research.md 결정 3)가 Adapter 자체의 테스트
  가능성을 해치지 않음을 계약 테스트 설계(contracts/)로 확인했다.
- 새로 발견한, 정당화가 필요한 헌법 위반은 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/008-network-composition-adapters/
├── spec.md
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md         # 1단계 산출물(/speckit-plan)
├── quickstart.md         # 1단계 산출물(/speckit-plan)
├── contracts/            # 1단계 산출물(/speckit-plan) — Adapter 쌍별 계약 2개
│   ├── github-composition-adapter.md
│   └── git-it-server-composition-adapter.md
└── checklists/requirements.md
```

### 소스 코드(저장소 루트)

이 계획은 아래 경로를 생성·수정하지 않는다 — `tasks.md`가 각 파일을 실제 작업 목록으로
만든다. `Composition`은 기능별 target이 아닌 앱 전체 단일 target이므로, 이 기능은 새
target을 만들지 않고 기존 target 내부에 하위 폴더를 새로 도입한다(research.md 결정 6).

```text
sources/Tuist/ProjectDescriptionHelpers/Projects/
└── CompositionModuleName.swift
    # [Composition 단계] .Composition/.CompositionTests 케이스의 dependencies에
    # .fromDomain(.DomainLearningProject), .fromData(.DataLearningProject),
    # .fromInfrastructure(.InfrastructureNetworkClient) 추가(research.md 결정 7)

sources/Projects/Composition/
├── Composition/
│   └── LearningProjectLifecycle/                          # [Composition 단계]
│       ├── ExternalRepositoryRemoteAdapter.swift           # Data↔Infrastructure(GitHub)
│       ├── ExternalRepositoryLookupAdapter.swift           # Domain↔Data(GitHub)
│       ├── LearningProjectRemoteAdapter.swift               # Data↔Infrastructure(Git-It 서버)
│       └── LearningProjectRepositoryAdapter.swift            # Domain↔Data(Git-It 서버)
└── CompositionTests/
    └── LearningProjectLifecycle/                            # [Composition 단계]
        ├── ExternalRepositoryRemoteAdapterTests.swift
        ├── ExternalRepositoryLookupAdapterTests.swift
        ├── LearningProjectRemoteAdapterTests.swift
        └── LearningProjectRepositoryAdapterTests.swift
```

**구조 결정**: `Composition`은 앱 전체가 공유하는 단일 Tuist target이라 Domain/Data처럼
기능별 target을 새로 만들 수 없다(research.md 결정 6). 대신 007의 기능 이름을 그대로 딴
`LearningProjectLifecycle/` 하위 폴더를 도입해, 실제 구현이 하나도 없던 `Composition`에
후속 기능(예: 인증 Composition Adapter)이 따를 수 있는 폴더 전례를 만든다.

## 복잡성 추적

이 계획은 헌법 점검을 모두 통과했고 정당화가 필요한 위반이 없다. 표를 작성하지 않는다.
