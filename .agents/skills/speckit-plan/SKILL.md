---
name: "speckit-plan"
description: "Execute the implementation planning workflow using the plan template to generate design artifacts."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/plan.md"
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

**Check for extension hooks (before planning)**: [공통 확장 훅 프로토콜](../../../.specify/memory/speckit-common-rules.md#확장-훅extension-hooks-프로토콜)을
따르되 훅 키는 `hooks.before_plan`, 필수 훅의 "Wait for..." 대상 섹션은 "the Outline"이다.

## Outline

## Allowed Write Paths

This skill may modify only the active feature's `plan.md`, `research.md`,
`data-model.md`, `quickstart.md`, and `contracts/**`. It MUST record implementation
paths for later task generation instead of modifying source, tests, or configuration.

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC and `.specify/memory/constitution.md`. Load IMPL_PLAN template (already copied).

   Constitution 원칙 11에 따라 설계를 시작하기 전에 근거 문서도 함께 읽는다. 문서 루트는
   공개 경로 판독기의 `GIT_IT_DOCS_ROOT`로 확인하고 구 경로 `sources/docs/**`는 사용하지
   않는다.
   - `docs/conventions/README.md`와 이번 변경에 해당하는 인덱스 문서, 그 인덱스가 가리키는
     구체 명시 문서
   - 변경 대상 패키지의 `docs/package-rules/<패키지>.md`
   - `docs/architecture.md`(패키지 책임과 허용 의존 방향, 위상 순서의 근거)

   적재 범위는 이번 변경에 해당하는 문서로 한정하고, 산출물에는 내용을 재서술하지 않고
   저장소 상대경로로 참조한다. 이 문서들은 읽기 전용이며 이 스킬이 수정하지 않는다.

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - "적용 컨벤션" 표에 적용한 컨벤션·패키지 규칙 문서를 저장소 상대경로로 적고 각 문서가
     이번 설계에 부과한 구체적인 제약을 기록한다. 적용 대상이 없다고 판단하면 그 근거를 남긴다
   - 명세나 기존 구현 관행이 컨벤션과 충돌하면 산출물을 생성하지 말고 ERROR. 우선순위는
     Constitution → 컨벤션·패키지 규칙 → 계획·작업이며, 어느 쪽이 옳은지 불분명하면 사용자에게 확인
   - 컨벤션이 이번 요구를 다루지 않으면 결정과 근거를 복잡성 추적 또는 research.md에 기록하고
     컨벤션 문서 자체는 수정하지 않는다
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Re-evaluate Constitution Check post-design
   - 명세가 변경하는 패키지를 식별하고 의존성 위상 순서를 기록한다. 단일 패키지 단위를
     기본으로 하되, 공개 API 이전·공용 manifest·함께 변경해야 compile되는 migration은
     불가분한 다중 패키지 integration unit으로 계획하고 분리 불가 근거와 통합 검증을 명시한다
   - 각 실행 단위의 구현, 검증과 결과 보고는 같은 승인된 기능 범위에서 연속 진행한다.
     명시적 승인은 새 범위, 파괴적 작업, 외부 상태 변경 또는 새로운 제품 결정을 요구할 때만
     계획에 둔다
   - 패키지에 속하지 않는 파일은 책임 단위에 정확히 배정하고, 소유권이나 변경 범위를
     설명할 수 없으면 ERROR

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

If no hooks are registered under `hooks.after_plan`, skip to the Completion Report. Otherwise
apply the [공통 확장 훅 프로토콜](../../../.specify/memory/speckit-common-rules.md#확장-훅extension-hooks-프로토콜)
with hook key `hooks.after_plan`. For a mandatory hook you MUST emit `EXECUTE_COMMAND:` and
actually invoke it before continuing to the Completion Report.

## Completion Report

Command ends after Phase 1 design. Report branch, IMPL_PLAN path, and generated artifacts.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - 결정: [선택한 내용]
   - 근거: [선택한 이유]
   - 검토한 대안: [함께 평가한 다른 선택지]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Define interface contracts** (if project has external interfaces) → `/contracts/`:
   - Identify what interfaces the project exposes to users or other systems
   - Document the contract format appropriate for the project type
   - Examples: public APIs for libraries, command schemas for CLI tools, endpoints for web services, grammars for parsers, UI contracts for applications
   - Skip if project is purely internal (build scripts, one-off tools, etc.)

3. **Create quickstart validation guide** → `quickstart.md`:
   - Document runnable validation scenarios that prove the feature works end-to-end
   - Include prerequisites, setup commands, test/run commands, and expected outcomes
   - Use links or references to contracts and data model details instead of duplicating them
   - Do not include full implementation code, model/service/controller bodies, migrations, or complete test suites
   - Keep this artifact as a validation/run guide; implementation details belong in `tasks.md` and the implementation phase

**Output**: data-model.md, /contracts/*, quickstart.md

## Key rules

- Use absolute paths for filesystem operations; use project-relative paths for references in documentation
- ERROR on gate failures or unresolved clarifications

## Done When

- [ ] Plan workflow executed and design artifacts generated
- [ ] 컨벤션·패키지 규칙·아키텍처 문서를 읽고 "적용 컨벤션"에 근거와 제약을 기록
- [ ] Extension hooks dispatched or skipped according to the rules in Mandatory Post-Execution Hooks above
- [ ] Completion reported to user with branch, plan path, and generated artifacts
