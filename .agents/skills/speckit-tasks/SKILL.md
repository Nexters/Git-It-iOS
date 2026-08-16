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

## 산출물 언어

이 스킬이 생성·수정하거나 사용자에게 보고하는 모든 자연어 문장은 한국어로 작성한다.
코드 식별자, 명령어, 파일 경로, 환경 변수, 라이브러리·API 고유 명칭, BDD 키워드는
원문을 유지한다. 이 규칙은 이 문서의 영어 예시와 기본 템플릿의 고정 문구보다 우선한다.

## 세션 지식 기록 위임

- 실행 중 실제 오류, 실패, 잘못된 판단, 복구 또는 환경 제약이 발생하면 근거를 보존한 뒤
  최종 보고 전에 `$speckit-troubleshooting`을 별도로 적용한다.
- 여러 세션과 저장소의 독립 근거에서 문서에 없는 판단 기준이나 책임 경계를 해석하면
  `$speckit-tacit-knowledge`를 별도로 적용한다.
- 이 스킬이 두 기록 파일을 직접 수정해서는 안 된다. 가설적 위험, 단일 추측, 이미 명시된
  사실에는 기록 스킬을 적용하지 않으며 조건이 없으면 파일을 만들지 않는다.

## Pre-Execution Checks

**Check for extension hooks (before tasks generation)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_tasks` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing slash commands from hook command names, replace dots (`.`) with hyphens (`-`). For example, `speckit.git.commit` → `/speckit-git-commit`.
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```
    After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Outline

## Allowed Write Paths

This skill may modify only `specs/<feature>/tasks.md`. Every generated task that
changes a file MUST include its exact repository-relative path; this is the write
allowlist that `/speckit-implement` will use.

`trouble-shooting.md`와 `tacit-knowledge.md`는 구현 작업으로 생성하지 않는다. 실제 문제나
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
   - 패키지를 최상위 실행 단위로 작업을 생성하고 변경 시나리오는 패키지 내부 추적 라벨로 유지
   - Generate dependency graph showing change scenario completion order
   - 현재 패키지 내부에서만 허용되는 병렬 실행 예시 생성
   - Validate task completeness (each change scenario has all needed tasks and is independently testable)
   - 모든 파일 변경 작업을 정확히 하나의 패키지 단계에 명시적으로 배정하고, 명세가 변경하지 않는 패키지는
     제외한 `Domain → Data → Infrastructure → Composition → UI → Feature → App` 순서로 패키지 단계를
     최상위 실행 순서로 구성
   - 각 적용 대상 패키지 단계 끝에 패키지 검증, 결과 보고와 다음 적용 대상 패키지 진행에
     대한 명시적 사용자 승인 게이트를 두고, 패키지 단계 안에서 변경 시나리오 추적성을 유지

4. **Generate tasks.md**: Read the tasks template from TASKS_TEMPLATE (from the JSON output above) and use it as structure. If TASKS_TEMPLATE is empty, fall back to `.specify/templates/tasks-template.md`. Fill with:
   - Correct feature name from plan.md
   - 정해진 순서에 따른 적용 대상 패키지별 단계. 준비·기반·마무리 작업도 별도 단계로 두지
     않고 책임 패키지 단계에 배치하며 변경 시나리오 라벨 유지
   - Each phase includes: scenario goal, independent test criteria, tests (if requested), implementation tasks
   - 마지막 적용 대상 패키지 뒤에는 파일을 변경하지 않는 전체 기능 검증만 배치
   - All tasks must follow the strict checklist format (see Task Generation Rules below)
   - Clear file paths for each task
   - Dependencies section showing scenario completion order
   - 현재 패키지 내부 병렬 실행 예시
   - 패키지별 승인 진행과 변경 시나리오 추적 전략

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

Check if `.specify/extensions.yml` exists in the project root.
- If it does not exist, or no hooks are registered under `hooks.after_tasks`, skip to the Completion Report.
- If it exists, read it and look for entries under the `hooks.after_tasks` key.
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue to the Completion Report.
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing slash commands from hook command names, replace dots (`.`) with hyphens (`-`). For example, `speckit.git.commit` → `/speckit-git-commit`.
- For each executable hook, output the following based on its `optional` flag:
  - **Mandatory hook** (`optional: false`) — **You MUST emit `EXECUTE_COMMAND:` for each mandatory hook**:
    ```
    ## Extension Hooks

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```

## Completion Report

Output path to generated tasks.md and summary:
- Total task count
- Task count per change scenario
- Parallel opportunities identified
- Independent test criteria for each change scenario
- Suggested minimum valuable scope (보통 Scenario 1이지만 패키지 순서와 승인 게이트는 모두 유지)
- Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)

Context for task generation: $ARGUMENTS

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.

## Task Generation Rules

**CRITICAL**: 작업은 패키지를 최상위 실행 단위로 구성한다. 변경 시나리오는 각 패키지
단계 안에서 추적하고 독립 검증 기준을 유지한다.

**SESSION RECORDS ARE NOT TASKS**: `trouble-shooting.md`와 `tacit-knowledge.md`의 생성·추가를
작업 ID, 패키지 작업 또는 전체 완료 검증으로 만들지 않는다.

**Tests are OPTIONAL**: Only generate test tasks if explicitly requested in the feature specification or if user requests TDD approach.

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

- ✅ CORRECT: `- [ ] T001 Create Domain structure in sources/Projects/Domain/FeatureName/`
- ✅ CORRECT: `- [ ] T005 [P] Implement Domain model in sources/Projects/Domain/FeatureName/Model.swift`
- ✅ CORRECT: `- [ ] T012 [P] [S1] Create User model in src/models/user.py`
- ✅ CORRECT: `- [ ] T014 [S1] Implement UserService in src/services/user_service.py`
- ❌ WRONG: `- [ ] Create User model` (missing ID and Scenario label)
- ❌ WRONG: `T001 [S1] Create model` (missing checkbox)
- ❌ WRONG: `- [ ] [S1] Create User model` (missing Task ID)
- ❌ WRONG: `- [ ] T001 [S1] Create model` (missing file path)

### Task Organization

1. **패키지 소유권 — PRIMARY ORGANIZATION**:
   - 명세가 변경하는 패키지만 `Domain → Data → Infrastructure → Composition → UI → Feature → App`
     순서의 최상위 단계로 생성
   - 모든 파일 변경 작업은 정확히 하나의 패키지 단계에 배치
   - 공용 파일이 여러 패키지 선언을 바꾸면 패키지별 작업으로 분리하고 해당 단계에서 필요한
     선언만 변경하도록 설명
   - 패키지 소유권이 모호하거나 분리할 수 없으면 tasks.md를 생성하지 말고 ERROR

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
   - 여러 패키지에 걸친 공용 파일 변경은 패키지별 작업으로 분리
   - 전체 기능 검증은 마지막 패키지 뒤의 `[no-write]` 작업으로만 구성

### Phase Structure

- **패키지 단계**: 적용 대상만 헌법 순서로 생성
  - 각 단계 내부: 준비 → 테스트(요청된 경우) → 구현 → 정리 → 패키지 검증
  - 각 단계 끝: 변경 파일과 검증 결과 보고 → 다음 적용 대상 패키지 명시적 승인 게이트
- **전체 완료 검증**: 마지막 적용 대상 패키지 뒤에 읽기 전용 검증만 배치

## Done When

- [ ] tasks.md generated with all phases, task IDs, and file paths
- [ ] 적용 대상 패키지가 헌법 순서로 배치되고 모든 파일 변경 작업의 단일 패키지 소유권 확인
- [ ] 각 패키지 검증·결과 보고·승인 게이트와 마지막 읽기 전용 전체 검증 확인
- [ ] Extension hooks dispatched or skipped according to the rules in Mandatory Post-Execution Hooks above
- [ ] Completion reported to user with task count, scenario breakdown, and minimum valuable scope
