---
name: "speckit-tasks"
description: "Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/tasks.md"
---


## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## 공통 규칙

이 스킬은 [Spec Kit 스킬 공통 규칙](../../../.specify/memory/speckit-common-rules.md)의
산출물 언어, 세션 지식 기록 위임, 인자 이스케이프 규칙을 그대로 따른다.

## Pre-Execution Checks

**Check for extension hooks (before tasks generation)**: [공통 확장 훅 프로토콜](../../../.specify/memory/speckit-common-rules.md#확장-훅extension-hooks-프로토콜)을
따르되 훅 키는 `hooks.before_tasks`, 필수 훅의 "Wait for..." 대상 섹션은 "the Outline"이다.

## Outline

## Allowed Write Paths

This skill may modify only `specs/<feature>/tasks.md`. Every generated task that
changes a file MUST include its exact repository-relative path; this is the write
allowlist that `/speckit-implement` will use.

공용 문서 경로는 공개 경로 판독기의 `GIT_IT_DOCS_ROOT`로 확인하고 현재 `docs/**`
상대경로만 작업에 사용한다. `sources/docs/**` 구 경로를 전파하지 않는다. 문서 변경은
정확한 파일 경로 하나와 책임 패키지를 명시해야 하며 `docs/` 디렉터리나 glob을 구현
allowlist로 만들 수 없다. 문서를 읽기만 하는 검증은 `[no-write]`로 표시한다.

`docs/spec-kit/<feature>/trouble-shooting.md`와
`docs/spec-kit/<feature>/tacit-knowledge.md`는 구현 작업으로 생성하지 않는다. 실제 문제나
복수 세션 기반 암묵지 해석이 발생한 세션에서 각 전용 기록 스킬이 별도로 처리한다.

1. **Setup**: Run `.specify/scripts/bash/setup-tasks.sh --json` from repo root and parse FEATURE_DIR, TASKS_TEMPLATE, and AVAILABLE_DOCS list. `FEATURE_DIR` and `TASKS_TEMPLATE` must be absolute paths when provided. `AVAILABLE_DOCS` is a list of document names/relative paths available under `FEATURE_DIR` (for example `research.md` or `contracts/`). For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load design documents**: Read from FEATURE_DIR:
   - **Required**: plan.md (tech stack, libraries, structure), spec.md (prioritized change scenarios)
   - **Optional**: data-model.md (entities), contracts/ (interface contracts), research.md (decisions), quickstart.md (test scenarios)
   - **IF EXISTS**: Load `.specify/memory/constitution.md` for project principles and governance constraints
   - Note: Not all projects have all documents. Generate tasks based on what's available.

3. **Execute task generation workflow**:
   - Load plan.md and extract tech stack, libraries, project structure
   - Load spec.md and extract change scenarios with their priorities (P1, P2, P3, etc.)
   - Preserve each scenario's source label: use `[S#]` for the current template and keep `[US#]`
     when processing an existing specification that already uses legacy user-story labels
   - If data-model.md exists: Extract entities and map to change scenarios
   - If contracts/ exists: Map interface contracts to change scenarios
   - If research.md exists: Extract decisions for setup tasks
   - 실행 단위를 최상위 구조로 작업을 생성하고 변경 시나리오는 각 단위 안의 추적 라벨로 유지
   - Generate dependency graph showing change scenario completion order
   - 현재 실행 단위 내부에서만 허용되는 병렬 실행 예시 생성
   - Validate task completeness (each change scenario has all needed tasks and is independently testable)
   - 파일 변경 작업을 책임 패키지에 배정하고 의존성 위상 순서로 실행 단위를 구성. 단일
     패키지 단위를 기본으로 하되 분리하면 compile되지 않는 공개 API 이전, 공용 manifest와
     migration은 불가분한 다중 패키지 integration unit으로 표시하고 근거와 통합 검증을 명시
   - 각 실행 단위 끝에 검증과 결과 보고를 두되 같은 기능 범위의 다음 단위나 읽기 전용 전체
     검증을 위한 승인 게이트는 생성하지 않음. 새 범위·파괴적 작업·외부 상태 변경·새 제품
     결정처럼 새로운 권한이 필요한 경우에만 승인 작업을 둠
   - 작업은 정확한 경로와 의존성을 가진 원자적 실행 항목으로 유지하고 커밋 단위를 tasks.md에
     미리 고정하지 않음. `/speckit-implement`가 선택 실행 단위의 미완료 작업을 실행 시점에
     논리적 커밋 단위로 설계할 수 있을 만큼 각 작업 경계가 명확한지 검증

4. **Generate tasks.md**: Read the tasks template from TASKS_TEMPLATE (from the JSON output above) and use it as structure. If TASKS_TEMPLATE is empty, fall back to `.specify/templates/tasks-template.md`. Fill with:
   - Correct feature name from plan.md
   - 정해진 순서에 따른 실행 단위. 단일 패키지가 기본이며 허용된 integration unit에는
     관련 패키지, 분리 불가 근거, 정확한 경로와 통합 검증을 명시하고 변경 시나리오 라벨 유지
   - Each phase includes: scenario goal, independent test criteria, tests (if requested), implementation tasks
   - 마지막 적용 대상 패키지 뒤에는 파일을 변경하지 않는 전체 기능 검증만 배치
   - All tasks must follow the strict checklist format (see Task Generation Rules below)
   - Clear file paths for each task
   - Dependencies section showing scenario completion order
   - 현재 실행 단위 내부 병렬 실행 예시
   - 위험 기반 승인 조건과 변경 시나리오 추적 전략

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

If no hooks are registered under `hooks.after_tasks`, skip to the Completion Report. Otherwise
apply the [공통 확장 훅 프로토콜](../../../.specify/memory/speckit-common-rules.md#확장-훅extension-hooks-프로토콜)
with hook key `hooks.after_tasks`. For a mandatory hook you MUST emit `EXECUTE_COMMAND:` and
actually invoke it before continuing to the Completion Report.

## Completion Report

Output path to generated tasks.md and summary:
- Total task count
- Task count per change scenario
- Parallel opportunities identified
- Independent test criteria for each change scenario
- Suggested minimum valuable scope (보통 Scenario 1이며 새 권한이 필요하지 않으면 연속 진행)
- Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)
- Git handoff: 생성·수정된 tasks.md의 blob hash와 전체 diff를 실행 기준선으로 사용하며,
  별도 기준선 commit은 사용자가 요청했거나 협업상 필요한 경우에만 선택한다고 명시

Context for task generation: $ARGUMENTS

After its baseline is captured, tasks.md should be immediately executable: each task must be specific
enough that an LLM can complete it without additional context.

## Task Generation Rules

**CRITICAL**: 작업은 논리적 실행 단위를 최상위 구조로 구성한다. 단일 패키지 단위가 기본이며
허용된 integration unit만 여러 패키지를 포함한다. 변경 시나리오는 각 단위 안에서 추적한다.

**SESSION RECORDS ARE NOT TASKS**: `trouble-shooting.md`와 `tacit-knowledge.md`의
생성·추가를 작업 ID, 패키지 작업 또는 전체 완료 검증으로 만들지 않는다.

**Tests are OPTIONAL**: Only generate test tasks if explicitly requested in the feature specification or if user requests TDD approach.

**COMMIT UNITS ARE IMPLEMENT-TIME PLANS**: tasks.md에는 커밋 제목, 커밋 그룹 또는 commit
checkbox를 생성하지 않는다. 한 작업 ID는 부분 완료로 나눌 필요가 없는 원자적 변경이어야
하며, `/speckit-implement`가 같은 실행 단위 안에서 하나 이상의 작업을 논리적 커밋 단위로 묶는다.

### Checklist Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [P?] [Scenario?] Description with file path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]` (markdown checkbox)
2. **Task ID**: Sequential number (T001, T002, T003...) in execution order
3. **[P] marker**: Include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)
4. **[Scenario] label**: 변경 시나리오 요구사항을 구현하는 작업에 사용
   - Format: [S1], [S2], [S3], etc. (maps to scenarios from the current spec template)
   - Legacy format: existing specs that already use [US1], [US2], [US3] keep those labels
   - 공통 패키지 기반 작업: 시나리오 라벨 없음
   - 변경 시나리오 관련 작업: 해당 `[S#]` 또는 기존 `[US#]` 라벨 필수
   - 패키지 검증과 전체 읽기 전용 검증: 시나리오 라벨 선택
5. **Description**: Clear action with exact file path

**Examples**:

- ✅ CORRECT: `- [ ] T001 Create Domain model in sources/Projects/Domain/FeatureName/FeatureName.swift`
- ✅ CORRECT: `- [ ] T005 [P] Implement Domain model in sources/Projects/Domain/FeatureName/Model.swift`
- ✅ CORRECT: `- [ ] T012 [P] [S1] Create User model in src/models/user.py`
- ✅ CORRECT: `- [ ] T014 [S1] Implement UserService in src/services/user_service.py`
- ❌ WRONG: `- [ ] Create User model` (missing ID and Scenario label)
- ❌ WRONG: `T001 [S1] Create model` (missing checkbox)
- ❌ WRONG: `- [ ] [S1] Create User model` (missing Task ID)
- ❌ WRONG: `- [ ] T001 [S1] Create model` (missing file path)

### Task Organization

1. **실행 단위 소유권 — PRIMARY ORGANIZATION**:
   - 명세가 변경하는 패키지만 의존성 위상 순서의 최상위 단계로 생성. 피의존 패키지를 먼저
     두고, 채택한 순서와 근거를 tasks.md에 남긴다
   - 파일 변경 작업은 책임 패키지 단계에 배치하는 것을 기본으로 함
   - 공용 파일이나 공개 API 이전을 분리하면 중간 상태가 compile되지 않는 경우에는 관련
     패키지를 포함한 integration unit을 만들고 분리 불가 근거와 통합 검증을 기록
   - 책임 단위가 모호하거나 정확한 경로와 검증을 정할 수 없으면 tasks.md를 생성하지 말고 ERROR

2. **From Change Scenarios (spec.md)** - PACKAGE-INTERNAL TRACEABILITY:
   - Map all related components to their scenario within each owning package:
     - Models needed for that scenario
     - Services needed for that scenario
     - Interfaces/UI or internal boundaries needed for that scenario
     - If tests requested: Tests specific to that scenario
   - 변경 시나리오 독립성은 전체 패키지가 완료된 뒤의 수용 기준으로 유지

3. **From Contracts**:
   - Map each interface contract → to the change scenario it serves
   - If tests requested: 각 계약 테스트를 소유 패키지의 구현 전에 배치

4. **From Data Model**:
   - Map each entity to the change scenario(s) that need it
   - 여러 시나리오가 사용하는 엔터티도 소유 패키지 단계에 배치하고 필요한 시나리오 라벨을 병기
   - Relationships → 소유 패키지의 적절한 작업에 배치

5. **From Setup/Infrastructure/Polish**:
   - 별도의 Setup, Foundational, Polish 구현 단계를 만들지 않음
   - 준비·기반·정리 작업은 책임 패키지 단계에 배치
   - 패키지에 속하지 않는 파일은 최초로 필요로 하는 책임 패키지를 명시
   - 여러 패키지에 걸친 공용 파일 변경은 분리 가능한 경우 패키지별로 나누고, 불가분하면
     integration unit에 배치
   - 전체 기능 검증은 마지막 패키지 뒤의 `[no-write]` 작업으로만 구성

### Phase Structure

- **실행 단위 단계**: 적용 대상만 아키텍처 의존성 표와 tasks.md가 확정한 위상 순서로 생성
  - 각 단계 내부: 준비 → 테스트(요청된 경우) → 구현 → 정리 → 패키지 검증
  - 각 단계 끝: 변경 파일과 검증 결과 보고 → 같은 범위의 다음 단위로 연속 진행
- **전체 완료 검증**: 마지막 적용 대상 패키지 뒤에 읽기 전용 검증만 배치

## Done When

- [ ] tasks.md generated with all phases, task IDs, and file paths
- [ ] 실행 단위가 근거 있는 의존성 순서로 배치되고 integration unit의 분리 불가 근거 확인
- [ ] 각 작업이 부분 완료 없이 implement 시점의 논리적 커밋 단위에 배정 가능한 원자성 확인
- [ ] 각 실행 단위 검증·결과 보고와 위험 기반 승인 조건, 마지막 읽기 전용 전체 검증 확인
- [ ] Completion Report에서 tasks.md 기준선 snapshot 후 implement 실행 순서 안내
- [ ] Extension hooks dispatched or skipped according to the rules in Mandatory Post-Execution Hooks above
- [ ] Completion reported to user with task count, scenario breakdown, and minimum valuable scope
