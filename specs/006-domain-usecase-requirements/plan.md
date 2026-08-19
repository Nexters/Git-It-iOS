# 구현 계획: Git-It 학습 도메인 UseCase 요구사항

**Git-flow 유형**: `feature`

**브랜치**: `미생성 (예정: feature/domain-usecase-requirements)`

**날짜**: 2026-08-19 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/006-domain-usecase-requirements/spec.md`의 기능 명세

## 요약

`sources/docs/git-it-domain-usecases/`의 10개 도메인 UseCase 문서와
`Git-It-server-scheme.json`(Git-It 서버 OpenAPI 스키마)을 대조해 확정한 요구사항
(FR-001~042, `/speckit-clarify` 3회 세션으로 7건 명확화)을, 후속 UseCase별 구현
스펙이 API를 재조사하지 않고 바로 쓸 수 있는 참고 자료로 formalize한다. **이 계획은
어떤 소스 패키지도 변경하지 않는다** — spec.md `범위 밖`에 명시된 대로 실제 Swift
`protocol`/DTO/Repository Adapter 구현은 UseCase별 후속 `/speckit-specify`가 각각
담당한다(사전 확인 질문에서 사용자가 "이 문서에 대한 계획 실행"을 선택해 확정).
산출물은 `data-model.md`(엔터티 9개), `contracts/`(UseCase별 계약 10개),
`quickstart.md`(문서 커버리지 대조 절차)다.

## 기술 맥락

**언어/버전**: N/A — 이 계획은 코드를 작성하지 않는다. 계약 문서는 기존 프로젝트와
동일한 Swift 5 모드·iOS 26.0+ 컨텍스트(후속 구현 기준)를 전제로만 서술한다.

**주요 의존성**: 없음(코드 의존성 없음). 참고 자료는 `Git-It-server-scheme.json`
(OpenAPI 3.x)과 `sources/docs/git-it-domain-usecases/`.

**저장소**: N/A — 영속 데이터 변경 없음.

**테스트**: N/A — 실행 가능한 테스트 없음. 문서 커버리지는 `quickstart.md`의 대조
절차(시나리오 A~D)로 검증한다.

**대상 플랫폼**: N/A(문서 산출물). 후속 구현은 기존 프로젝트와 동일하게 iOS 26.0+.

**프로젝트 유형**: Tuist 기반 iOS 멀티 패키지 앱의 사전 설계 문서 — 이 기능 자체는
어떤 패키지도 구현하지 않는다.

**성능 목표**: N/A.

**제약 조건**: `contracts/`·`data-model.md`는 `Git-It-server-scheme.json`과
`spec.md` FR-001~042에 100% 대응해야 한다(spec.md SC-001~004, quickstart.md
시나리오 B·C).

**규모/범위**: UseCase 10개, 계약 파일 10개(`contracts/`), 엔터티 9개
(`data-model.md`). 소스 코드 변경 0건.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

- **명시적인 경계(원칙 1)**: 이 계획은 어떤 소스 패키지도 변경하지 않는다. Domain,
  Data, Infrastructure, Composition, UI, Feature, App 전부 해당 없음. **통과**.
- **상태와 데이터 안전성(원칙 2)**: N/A — 코드·상태·개인정보 처리 변경 없음. **통과**.
- **검증 가능한 변경(원칙 3)**: 빌드·테스트 실행 대신 `quickstart.md`의 문서 대조
  절차로 검증 가능성을 남긴다. 이 계획 단계에서 Git index나 작업 파일을 바꾸는 명령을
  실행하지 않았다. **통과**.
- **스킬별 수정 경로(원칙 4·5)**: `plan.md`, `research.md`, `data-model.md`,
  `quickstart.md`, `contracts/**`만 생성·수정했다. `sources/**`는 이 계획에서 전혀
  건드리지 않는다(패키지 진행 게이트가 트리거되지 않는 이유). **통과**.
- **Git 실행 직렬화(원칙 3)**: 이 계획은 Git index 변경 체인을 실행하지 않는다.
  해당 없음.
- **책임 기반 네이밍(원칙 10)**: `data-model.md`·`contracts/`의 필드명은 서버
  스키마(외부 계약)의 고정 이름을 그대로 보존했다(`projectId`, `quizLevel`,
  `setId` 등). 아직 소유 패키지가 없는 Swift 타입 이름은 이 계획이 확정하지 않는다
  (research.md §2). **통과**.
- **패키지 진행(원칙 7)**: **해당 없음** — 현재 명세가 변경하는 패키지가 없으므로
  `Domain → Data → Infrastructure → Composition → UI → Feature → App` 순서 게이트가
  이 계획에서는 트리거되지 않는다. 후속 UseCase별 구현 스펙이 각자의 `tasks.md`에서
  이 순서를 적용한다.
- **Git-flow 브랜치 네임스페이스(원칙 8)**: `before_specify` 훅이 실행되지 않아
  브랜치는 `미생성 (예정: feature/domain-usecase-requirements)` 상태다(spec.md와
  동일). 생성된 것처럼 기록하지 않는다.
- **Spec Kit 세션 지식 기록(원칙 9)**: `/speckit-specify`·`/speckit-clarify` 단계에서
  실제 문제 2건(`trouble-shooting.md` TS-20260819-001, -002)과 암묵지 2건
  (`tacit-knowledge.md` TK-20260819-001, -002)을 이미 각 전용 스킬로 기록했다. 이
  계획 단계에서는 새로 관찰된 문제나 암묵지가 없어 추가 기록을 만들지 않는다.

### 설계 후 재점검

`data-model.md`·`contracts/`·`quickstart.md` 작성 과정에서 `sources/**` 파일을 읽기
전용으로만 참조했고 수정하지 않았음을 확인했다. 새로 발견한 위반이나 정당화가 필요한
예외는 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/006-domain-usecase-requirements/
├── spec.md
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md        # 1단계 산출물(/speckit-plan)
├── quickstart.md        # 1단계 산출물(/speckit-plan)
├── contracts/           # 1단계 산출물(/speckit-plan) — UseCase별 계약 10개
│   ├── fetch-external-repository.md
│   ├── create-learning-project.md
│   ├── fetch-learning-projects.md
│   ├── fetch-learning-project-detail.md
│   ├── delete-learning-project.md
│   ├── fetch-learning-set.md
│   ├── submit-choice-answer.md
│   ├── submit-essay-answer.md
│   ├── set-question-bookmark.md
│   └── fetch-bookmarked-questions.md
├── checklists/requirements.md
├── trouble-shooting.md  # /speckit-troubleshooting 기록 2건
└── tacit-knowledge.md   # /speckit-tacit-knowledge 기록 2건
```

### 소스 코드(저장소 루트)

이 기능은 `sources/**`의 어떤 파일도 생성·수정·삭제하지 않는다. 후속 UseCase별
구현 스펙이 담당할 예상 구현 경계만 참고용으로 기록한다(실제 파일 경로와 작업
분해는 그 스펙의 `tasks.md`가 결정한다):

```text
sources/Projects/
├── Domain/        # UseCase 프로토콜, 도메인 모델(data-model.md 엔터티 대응)
├── Data/          # Repository 구현, DTO ↔ Domain 모델 매핑(contracts/ 응답 스키마 대응)
├── Infrastructure/# 기존 HTTP 클라이언트 재사용(신규 Infrastructure 불필요 — 인증
│                  # 포함 Bearer 호출은 001-apple-social-login·003-http-client 범위)
├── Composition/   # Domain↔Data Adapter 조립
├── UI, Feature, App/  # 필요 시 후속 스펙에서 개별적으로 범위를 정함
```

**구조 결정**: 이 계획은 위 트리를 만들지 않는다 — Tuist 기반 iOS 멀티 패키지 구조
(`sources/Projects/{Domain,Data,Infrastructure,Composition,UI,Feature,App}`)는
`sources/docs/architecture.md`에 이미 정의돼 있으며, 후속 UseCase별 스펙이 각자
필요한 범위만 골라 구현한다.

## 복잡성 추적

이 계획은 헌법 점검을 모두 통과했고 정당화가 필요한 위반이 없다. 표를 작성하지 않는다.
