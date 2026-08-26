---
name: "speckit-analyze"
description: "Perform a non-destructive cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md after task generation."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/analyze.md"
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

**Check for extension hooks (before analysis)**: [공통 확장 훅 프로토콜](../../../.specify/memory/speckit-common-rules.md#확장-훅extension-hooks-프로토콜)을
따르되 훅 키는 `hooks.before_analyze`, 필수 훅의 "Wait for..." 대상 섹션은 "the Goal"이다.

## Goal

Identify inconsistencies, duplications, ambiguities, and underspecified items across the three core artifacts (`spec.md`, `plan.md`, `tasks.md`) before implementation. This command MUST run only after `/speckit-tasks` has successfully produced a complete `tasks.md`.

## Operating Constraints

**STRICTLY READ-ONLY**: Do **not** modify any files. Output a structured analysis report. Offer an optional remediation plan (user must explicitly approve before any follow-up editing commands would be invoked manually).

## Allowed Write Paths

None. This skill is read-only, including feature artifacts, source files, task checkboxes,
and configuration.

**Constitution Authority**: The project constitution (`.specify/memory/constitution.md`) is **non-negotiable** within this analysis scope. Constitution conflicts are automatically CRITICAL and require adjustment of the spec, plan, or tasks—not dilution, reinterpretation, or silent ignoring of the principle. If a principle itself needs to change, that must occur in a separate, explicit constitution update outside `/speckit-analyze`.

## Execution Steps

### 1. Initialize Analysis Context

Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` once from repo root and parse JSON for FEATURE_DIR and AVAILABLE_DOCS. Derive absolute paths:

- SPEC = FEATURE_DIR/spec.md
- PLAN = FEATURE_DIR/plan.md
- TASKS = FEATURE_DIR/tasks.md

Abort with an error message if any required file is missing (instruct the user to run missing prerequisite command).
For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### 2. Load Artifacts (Progressive Disclosure)

Load only the minimal necessary context from each artifact:

**From spec.md:**

- Overview/Context
- Functional Requirements
- Success Criteria (measurable outcomes — e.g., performance, security, availability, user success, business impact)
- Change Scenarios (including user, developer, operator, or integrating-system scenarios)
- Edge Cases (if present)

**From plan.md:**

- Architecture/stack choices
- Data Model references
- Phases
- Technical constraints

**From tasks.md:**

- Task IDs
- Descriptions
- Phase grouping
- Parallel markers [P]
- Referenced file paths

**From constitution:**

- Load `.specify/memory/constitution.md` for principle validation

### 3. Build Semantic Models

Create internal representations (do not include raw artifacts in output):

- **Requirements inventory**: For each Functional Requirement (FR-###) and Success Criterion (SC-###), record a stable key. Use the explicit FR-/SC- identifier as the primary key when present, and optionally also derive an imperative-phrase slug for readability (e.g., "User can upload file" → `user-can-upload-file`). Include only Success Criteria items that require buildable work (e.g., load-testing infrastructure, security audit tooling), and exclude post-launch outcome metrics and business KPIs (e.g., "Reduce support tickets by 50%").
- **Change scenario/action inventory**: Discrete stakeholder actions or system conditions with acceptance criteria
- **Task coverage mapping**: Map each task to one or more requirements or change scenarios (inference by keyword / explicit reference patterns like IDs or key phrases)
- **Constitution rule set**: Extract principle names and MUST/SHOULD normative statements

### 4. Detection Passes (Token-Efficient Analysis)

Focus on high-signal findings. Limit to 50 findings total; aggregate remainder in overflow summary.

#### A. Duplication Detection

- Identify near-duplicate requirements
- Mark lower-quality phrasing for consolidation

#### B. Ambiguity Detection

- Flag vague adjectives (fast, scalable, secure, intuitive, robust) lacking measurable criteria
- Flag unresolved placeholders (TODO, TKTK, ???, `<placeholder>`, etc.)

#### C. Underspecification

- Requirements with verbs but missing object or measurable outcome
- Change scenarios missing acceptance criteria alignment
- Tasks referencing files or components not defined in spec/plan

#### D. Constitution Alignment

- Any requirement or plan element conflicting with a MUST principle
- Missing mandated sections or quality gates from constitution

#### E. Coverage Gaps

- Requirements with zero associated tasks
- Tasks with no mapped requirement/change scenario
- Success Criteria requiring buildable work (performance, security, availability) not reflected in tasks

#### F. Inconsistency

- Terminology drift (same concept named differently across files)
- Data entities referenced in plan but absent in spec (or vice versa)
- Task ordering contradictions (e.g., integration tasks before foundational setup tasks without dependency note)
- Conflicting requirements (e.g., one requires Next.js while other specifies Vue)

### 5. Severity Assignment

Use this heuristic to prioritize findings:

- **CRITICAL**: Violates constitution MUST, missing core spec artifact, or requirement with zero coverage that blocks baseline functionality
- **HIGH**: Duplicate or conflicting requirement, ambiguous security/performance attribute, untestable acceptance criterion
- **MEDIUM**: Terminology drift, missing non-functional task coverage, underspecified edge case
- **LOW**: Style/wording improvements, minor redundancy not affecting execution order

### 6. Produce Compact Analysis Report

Output a Markdown report (no file writes) with the following structure:

## 명세 분석 보고서

| ID | 범주 | 심각도 | 위치 | 요약 | 권고 |
|----|------|--------|------|------|------|
| A1 | 중복 | 높음 | spec.md:L120-134 | 유사한 요구사항 두 개 ... | 표현을 통합하고 더 명확한 문구를 유지 |

(Add one row per finding; generate stable IDs prefixed by category initial.)

**추적 범위 요약 표:**

| 요구사항 키 | 작업 존재 여부 | 작업 ID | 참고 |
|------------|----------------|---------|------|

**헌법 정합성 문제:** (있는 경우)

**연결되지 않은 작업:** (있는 경우)

**지표:**

- 전체 요구사항 수
- 전체 작업 수
- 추적 범위 %(하나 이상의 작업이 있는 요구사항)
- 모호성 수
- 중복 수
- 중요 문제 수

### 7. 다음 작업 제시

보고서 끝에 간결한 다음 작업 블록을 출력한다.

- 중요 문제가 있으면 `/speckit-implement` 전에 해결하도록 권고한다.
- 낮음/보통 문제만 있으면 진행할 수 있음을 알리되 개선안을 제공한다.
- 예: "/speckit-specify로 명세 보완", "/speckit-plan으로 아키텍처 조정",
  "tasks.md에 performance-metrics 추적 작업을 직접 추가"처럼 구체적인 명령을 제안한다.

### 8. Offer Remediation

사용자에게 "상위 N개 문제에 대한 구체적인 개선 편집안을 제안할까요?"라고 묻는다.
(사용자 승인 없이 자동으로 적용하지 않는다.)

### 9. Check for extension hooks

After reporting, apply the [공통 확장 훅 프로토콜](../../../.specify/memory/speckit-common-rules.md#확장-훅extension-hooks-프로토콜)
with hook key `hooks.after_analyze` (post-execution: no "Wait for..." target section needed).

## Operating Principles

### Context Efficiency

- **Minimal high-signal tokens**: Focus on actionable findings, not exhaustive documentation
- **Progressive disclosure**: Load artifacts incrementally; don't dump all content into analysis
- **Token-efficient output**: Limit findings table to 50 rows; summarize overflow
- **Deterministic results**: Rerunning without changes should produce consistent IDs and counts

### Analysis Guidelines

- **NEVER modify files** (this is read-only analysis)
- **NEVER hallucinate missing sections** (if absent, report them accurately)
- **Prioritize constitution violations** (these are always CRITICAL)
- **Use examples over exhaustive rules** (cite specific instances, not generic patterns)
- **Report zero issues gracefully** (emit success report with coverage statistics)

## Context

$ARGUMENTS
