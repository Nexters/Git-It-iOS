---
name: "speckit-specify"
description: "Create a validated Git-flow branch immediately, then create or update the feature specification from a natural language feature description."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/specify.md"
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

**Create the Git-flow branch before dispatching `before_specify` hooks**:
- Require a non-empty feature description before deriving a name or changing Git state. If it is
  empty, stop with `기능 설명이 제공되지 않았습니다` and do not create a branch.
- Derive `SHORT_NAME` from the feature description using the short-name rules in step 1 below.
- Determine `BRANCH_NAMESPACE` before branch creation:
  - Use the user's explicit `feature`, `hotfix`, or `release` type when provided.
  - Use `hotfix` only for an urgent fix to a production release.
  - Use `release` for release preparation or stabilization.
  - Otherwise default to `feature`, including ordinary defect work that is not a production hotfix.
  - If explicit inputs indicate conflicting types, stop before creating a branch and resolve the conflict.
- Construct `GIT_BRANCH_NAME` as `feature/<short-name>`, `hotfix/<short-name>`, or
  `release/<version-or-short-name>`. Use lowercase kebab-case for feature/hotfix suffixes; a release
  suffix may instead be a version identifier such as `v1.2.3`. A suffix MUST be non-empty and MUST
  NOT contain another `/` or a repeated namespace.
- If the user explicitly provided `GIT_BRANCH_NAME`, do not rewrite it. Validate that it has exactly
  one allowed namespace and a valid suffix. An invalid explicit name is an error, not a policy bypass.
- Run `git check-ref-format --branch "$GIT_BRANCH_NAME"` after the policy validation. Both checks
  MUST pass before the branch can be created or reused.
- Verify that the repository is a Git worktree and resolve the current symbolic branch. A detached
  HEAD or a Git lookup failure is an error.
- Define the branch invariant as both (a) the current symbolic name equals `GIT_BRANCH_NAME`, and
  (b) `refs/heads/$GIT_BRANCH_NAME^{commit}` resolves to a commit. An unborn or dangling symbolic
  branch never satisfies reuse, creation, or a hook checkpoint.
- Create or resume the branch before any hook or specification file operation:
  - If the current branch already equals `GIT_BRANCH_NAME`, treat this as a resumed invocation and set
    `BRANCH_STATUS` to `재사용` without creating another branch, but only after the full branch
    invariant passes.
  - Use `git show-ref --verify --quiet "refs/heads/$GIT_BRANCH_NAME"` to check the local target. If it
    exists while another branch is current, reuse it only when the current invocation contains an
    explicit user decision to reuse that exact branch. Before switching, inspect staged, unstaged, and
    untracked paths. If any exist, require a separate explicit decision to carry that exact listed
    worktree/index state; branch reuse approval alone is insufficient. Then run
    `git switch "$GIT_BRANCH_NAME"` and set
    `BRANCH_STATUS` to `재사용`. Without that decision, stop and report both branch names plus the two
    safe continuations: switch to the target branch manually, or rerun with explicit reuse approval.
    Do not recreate, delete, or overwrite the existing branch.
  - If no local target exists, inspect local remote-tracking refs for the exact
    `*/$GIT_BRANCH_NAME` name before creating anything. If any exist, do not create an unrelated local
    branch from the current HEAD. With an explicit decision naming exactly one remote ref, run
    the same staged/unstaged/untracked carry-over check above, then
    `git switch --track -c "$GIT_BRANCH_NAME" "<remote>/$GIT_BRANCH_NAME"` and set `BRANCH_STATUS` to
    `재사용`; otherwise stop and report the candidate refs so the user can choose or switch manually.
    This check does not fetch or mutate a remote.
  - Only when neither a local target nor a matching remote-tracking ref exists, run
    `git switch -c "$GIT_BRANCH_NAME"` from the current HEAD and set `BRANCH_STATUS` to `생성`.
  - Recheck the full branch invariant. After an existing-branch switch, also require the previously
    listed carry-over paths and index state to remain exactly accounted for. If creation, switching, or
    verification fails, stop before dispatching hooks or creating/updating specification artifacts.
- After this first successful invariant, capture `SPECIFY_HEAD`. Every later branch-invariant checkpoint
  also requires both HEAD and `refs/heads/$GIT_BRANCH_NAME` to remain at `SPECIFY_HEAD`; this skill and
  its hooks do not own commit, reset, or ref movement.
- If a later hook or specification step fails after successful branch creation, preserve the branch
  and report the partial state. Do not delete it or switch back automatically; a retry reuses it.
- Do not stash, reset, clean, stage, commit, amend, rebase, or push existing changes as part of branch
  creation. Record pre-existing changes only to preserve ownership and report them separately.
- Pass the verified active `GIT_BRANCH_NAME` and `BRANCH_STATUS` to every executable
  `before_specify` hook. A hook may inspect the active branch but MUST NOT create or switch it.

**Check for extension hooks (before specification)**: [공통 확장 훅 프로토콜](../../../.specify/memory/speckit-common-rules.md#확장-훅extension-hooks-프로토콜)을
따르되 훅 키는 `hooks.before_specify`, 필수 훅의 "Wait for..." 대상 섹션은 "the Outline"이다.
- Immediately after every invoked mandatory hook returns, whether it succeeded or failed, recheck the
  full branch invariant. If it fails, stop before the Outline, do not switch automatically, and report
  the expected branch/ref, actual state, hook result, and partial state.
- If an invoked mandatory hook fails while the branch still matches, stop before the Outline, preserve
  the branch, and report the partial state. Do not treat emitting `EXECUTE_COMMAND:` as hook success.
- After all executable `before_specify` hooks finish, require the full branch invariant again before
  entering the Outline.

## Outline

## Allowed Write Paths

This skill may modify only the newly resolved `specs/<feature>/**` directory and
`.specify/feature.json`. It MUST NOT create `trouble-shooting.md` or
`tacit-knowledge.md` inside the feature directory, nor create, modify, or delete their
canonical `docs/spec-kit/<feature>/` records. Those two records remain exclusively
owned by their dedicated recording skills. It also MUST NOT modify application code,
project configuration, or any other feature directory. Before those file writes, this skill may
create the validated local `GIT_BRANCH_NAME`, or explicitly reuse its exact local/remote-tracking
branch, and switch HEAD to it as described above. That Git permission does not authorize deleting or
overwriting another branch, changing the Git index or existing commits, fetching, or pushing.

The text the user typed after `/speckit-specify` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Specifications are permitted for both user-visible behavior and non-user-visible changes such as
internal quality, architecture, operations, developer experience, style, or dependency work. Do not
reject a specification because no end-user behavior changes. For an internal change, identify the
actual stakeholder (for example, a developer, operator, or integrating system), describe verifiable
outcomes, and do not fabricate end-user value.

Given that feature description, do this:

1. **Generate or reuse the concise `SHORT_NAME`** (2-4 words) for the feature:
   - Analyze the feature description and extract the most meaningful keywords
   - Create a 2-4 word short name that captures the essence of the feature
   - Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
   - Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)
   - Keep it concise but descriptive enough to understand the feature at a glance
   - Examples:
     - "I want to add user authentication" → "user-auth"
     - "Implement OAuth2 integration for the API" → "oauth2-api-integration"
     - "Create a dashboard for analytics" → "analytics-dashboard"
     - "Fix payment processing timeout bug" → "fix-payment-timeout"

2. **Use the verified Git-flow branch** (required, core behavior):

   Require the Pre-Execution Checks to have created or resumed `GIT_BRANCH_NAME` and verified that it
   is the current symbolic branch. Do not defer branch creation to a hook, and do not continue with a
   planned-but-uncreated branch. If a hook reports a different branch or switches HEAD, treat that as
   an error and stop before creating/updating specification artifacts.

   `.specify/scripts/bash/create-new-feature.sh`를 사용할 때도 출력의 `BRANCH_NAME`은 현재
   canonical Git-flow branch, `FEATURE_NUM`은 artifact sequence로 해석합니다. 스크립트가
   branch를 생성하거나 전환하는 대신 Pre-Execution Checks가 이 상태를 먼저 확정합니다.

3. **Create the spec feature directory**:

   Resolve the repository root and canonical `SPECS_ROOT` (`<repo>/specs`) before inspecting a feature
   path. Every explicit, persisted, discovered, or generated feature directory MUST normalize to
   exactly one direct child `SPECS_ROOT/<feature>` and MUST NOT escape through an absolute external
   path, `..`, or a symlink. Reject an explicit or generated unsafe path before any read or write.
   Treat an unsafe `.specify/feature.json` pointer as invalid without reading through it, and report it
   as stale. Existing feature directories and `spec.md`, `checklists/`, or `requirements.md` artifacts
   that are symlinks are not valid read or write targets. `.specify/feature.json` itself must be absent
   or a regular non-symlink file.

   **Resolution order for `SPECIFY_FEATURE_DIRECTORY`**:
   1. Regardless of `BRANCH_STATUS`, collect canonical existing candidates from a safe
      `.specify/feature.json` pointer and every direct-child `specs/*/spec.md`. A candidate matches when
      its metadata records either the actual `GIT_BRANCH_NAME` or the exact legacy value
      `미생성 (예정: <GIT_BRANCH_NAME>)`. The legacy form is a migration candidate, not permission to
      match a different planned branch. Deduplicate candidates by canonical directory. A safe pointer
      whose spec records another branch is stale for this invocation and is not a candidate.
   2. If the user explicitly provided `SPECIFY_FEATURE_DIRECTORY` (via environment variable, argument,
      or configuration), canonicalize it first. If any matching candidate resolves to another
      directory, stop instead of creating a duplicate. Reuse the explicit directory only when its
      existing `spec.md` matches the actual or exact legacy branch value above. A nonexistent or empty
      direct-child directory is allowed only when no matching candidate exists. A non-empty directory
      without a matching `spec.md`, or a spec associated with another branch, is an error.
   3. Without an explicit directory, reuse a candidate only when the deduplicated set contains exactly
      one directory. If multiple candidates exist, stop and report all of them instead of choosing. If
      none exists, auto-generate under `SPECS_ROOT`:
      - Check `.specify/init-options.json` for `feature_numbering` (preferred) or `branch_numbering` (deprecated, migration only — will be removed in a future release)
      - If `"timestamp"`: prefix is `YYYYMMDD-HHMMSS` (current timestamp)
      - If `"sequential"` or absent: prefix is `NNN` (next available 3-digit number after scanning existing directories in `specs/`)
      - Construct the directory name: `<prefix>-<short-name>` (e.g., `003-user-auth` or `20260319-143022-user-auth`)
      - Set `SPECIFY_FEATURE_DIRECTORY` to `specs/<directory-name>`
      - If `branch_numbering` was used (and `feature_numbering` was absent), emit a one-line warning: "⚠️ `branch_numbering` in init-options.json is deprecated. Rename to `feature_numbering`."

   **Create the directory and spec file**:
   - Immediately before the first artifact write, revalidate the canonical direct-child path and
     require the full branch invariant.
   - Resolve the active `spec-template` through the Spec Kit preset/template resolution stack (equivalent to `specify preset resolve spec-template`)
     before creating a new directory, so template-resolution failure leaves no orphan directory.
   - Record whether the target directory and spec existed. For a new spec, treat target setup, template
     rendering, verified Git-flow type/branch/status association, and final installation as one atomic
     transaction: build and validate the associated spec at a unique temporary path, then expose it as
     `SPECIFY_FEATURE_DIRECTORY/spec.md` only by an atomic no-clobber install. Never expose a placeholder
     or partially associated spec at the final path.
   - On any ordinary failure before the atomic install, remove only the exact temporary artifact and
     newly created empty directory owned by this invocation. On interruption, a retry must recognize,
     validate, and clean or resume the exact transaction artifact before choosing another automatic
     feature number; it MUST NOT create a second directory. Never remove or overwrite a pre-existing
     artifact. If the spec exists through the verified reuse path, load and update it without replacing
     it with the template.
   - Set `SPEC_FILE` to `SPECIFY_FEATURE_DIRECTORY/spec.md`

   **IMPORTANT**:
   - You must only create one feature per `/speckit-specify` invocation
   - The spec directory name and the git branch name are independent. The directory name MUST NOT
     include the Git-flow namespace or `/`.
   - The spec directory and file are always created by this command, never by the hook

4. Load the resolved active `spec-template` file to understand required sections.

5. **IF EXISTS**: Load `.specify/memory/constitution.md` for project principles and governance constraints.

6. Follow this execution flow:
    1. Parse user description from arguments
       If empty: ERROR "기능 설명이 제공되지 않았습니다"
    2. Extract key concepts from description
       Identify: stakeholders/actors, actions or system conditions, data, constraints
    3. For unclear aspects:
       - Make informed guesses based on context and industry standards
       - Only mark with [NEEDS CLARIFICATION: specific question] if:
         - The choice significantly impacts scope, safety, quality, operations, or stakeholder experience
         - Multiple reasonable interpretations exist with different implications
         - No reasonable default exists
       - **LIMIT: Maximum 3 [NEEDS CLARIFICATION] markers total**
       - Prioritize clarifications by impact: scope > security/privacy > quality/operations > stakeholder experience > technical details
    4. Fill Change Scenarios & Testing section
       - For user-visible work, describe user journeys
       - For internal work, describe developer/operator/integrating-system workflows or system conditions
       If no independently testable change scenario can be determined: ERROR "Cannot determine change scenarios"
    5. Generate Functional Requirements
       Each requirement must be testable
       Use reasonable defaults for unspecified details (document assumptions in Assumptions section)
    6. Define Success Criteria
       Create measurable outcomes focused on the required result rather than a chosen implementation
       Include metrics appropriate to the actual stakeholder or system (time, performance, volume,
       compatibility, reliability, operational effort, task completion, or satisfaction)
       Preserve a named technology, contract, tool, or version only when it is itself an explicit constraint
       Each criterion must be verifiable without requiring an unstated design choice
    7. Identify Key Entities (if data involved)
    8. Return: SUCCESS (spec ready for planning)

7. Write the specification to SPEC_FILE using the template structure, replacing placeholders with
   concrete details derived from the feature description (arguments) while preserving section order
   and headings. Fill `Git-flow 유형` with `BRANCH_NAMESPACE` and `기능 브랜치` with the verified
   active `GIT_BRANCH_NAME`. Record `BRANCH_STATUS` separately as `생성` or `재사용`; never write a
   planned or uncreated branch as the feature branch.
   - For a reused spec, treat its current contents as the merge baseline instead of regenerating the
     file. Apply only the requested delta and necessary validation corrections. Preserve requirement
     IDs, prior clarification answers, manual notes, unknown sections, and content not contradicted by
     the current request. Do not truncate the file or remove established scope unless the user
     explicitly requested that removal.
   - When reusing an exact legacy planned-branch candidate, replace that metadata with the verified
     active branch and `BRANCH_STATUS`; preserve the rest under the same merge rules.

8. **Specification Quality Validation**: After writing the initial spec, validate it against quality criteria:

   a. **Create or reuse Spec Quality Checklist**: If absent, generate a checklist file at
      `SPECIFY_FEATURE_DIRECTORY/checklists/requirements.md` using the checklist template structure
      with these validation items. If it exists, use it as the baseline and update only validation
      states, issue notes, and missing standard items required by the current spec; preserve manual
      notes and unrelated existing checklist content instead of replacing or truncating the file:

      ```markdown
      # 명세 품질 체크리스트: [기능 이름]

      **목적**: 계획 단계로 진행하기 전 명세의 완전성과 품질을 검증
      **생성일**: [날짜]
      **기능**: [spec.md 링크]

      ## 내용 품질

      - [ ] 구현 방법이 아니라 필요한 결과와 고정 제약에 집중한다
      - [ ] 실제 이해관계자 가치와 변경 목적에 집중한다
      - [ ] 대상 이해관계자가 이해할 수 있게 작성했다
      - [ ] 모든 필수 섹션을 작성했다

      ## 요구사항 완전성

      - [ ] [NEEDS CLARIFICATION] 표식이 남아 있지 않다
      - [ ] 요구사항이 검증 가능하고 모호하지 않다
      - [ ] 성공 기준이 측정 가능하다
      - [ ] 성공 기준이 결과 중심이며 불필요한 설계 선택에 종속되지 않는다
      - [ ] 모든 수용 시나리오를 정의했다
      - [ ] 예외·경계 사례를 식별했다
      - [ ] 범위를 명확히 한정했다
      - [ ] 의존성과 가정을 식별했다

      ## 기능 준비 상태

      - [ ] 모든 기능 요구사항에 명확한 수용 기준이 있다
      - [ ] 변경 시나리오가 핵심 흐름 또는 시스템 조건을 다룬다
      - [ ] 기능이 성공 기준의 측정 가능한 결과를 충족한다
      - [ ] 명세에 계획 단계에서 결정할 설계 세부 사항이 섞이지 않는다

      ## 참고

      - 미완료 항목은 `/speckit-clarify` 또는 `/speckit-plan` 전에 명세를 보완해야 한다
      ```

   b. **Run Validation Check**: Review the spec against each checklist item:
      - For each item, determine if it passes or fails
      - Document specific issues found (quote relevant spec sections)

   c. **Handle Validation Results**:

      - **If all items pass**: Mark checklist complete and proceed to the Mandatory Post-Execution Hooks section

      - **If items fail (excluding [NEEDS CLARIFICATION])**:
        1. List the failing items and specific issues
        2. Update the spec to address each issue
        3. Re-run validation until all items pass (max 3 iterations)
        4. If still failing after 3 iterations, document remaining issues in checklist notes and warn user

      - **If [NEEDS CLARIFICATION] markers remain**:
        1. Extract all [NEEDS CLARIFICATION: ...] markers from the spec
        2. **LIMIT CHECK**: If more than 3 markers exist, keep only the 3 most critical (by scope/security/UX impact) and make informed guesses for the rest
        3. For each clarification needed (max 3), present options to user in this format:

           ```markdown
           ## Question [N]: [Topic]

           **Context**: [Quote relevant spec section]

           **What we need to know**: [Specific question from NEEDS CLARIFICATION marker]

           **Suggested Answers**:

           | Option | Answer | Implications |
           |--------|--------|--------------|
           | A      | [First suggested answer] | [What this means for the feature] |
           | B      | [Second suggested answer] | [What this means for the feature] |
           | C      | [Third suggested answer] | [What this means for the feature] |
           | Custom | Provide your own answer | [Explain how to provide custom input] |

           **Your choice**: _[Wait for user response]_
           ```

        4. **CRITICAL - Table Formatting**: Ensure markdown tables are properly formatted:
           - Use consistent spacing with pipes aligned
           - Each cell should have spaces around content: `| Content |` not `|Content|`
           - Header separator must have at least 3 dashes: `|--------|`
           - Test that the table renders correctly in markdown preview
        5. Number questions sequentially (Q1, Q2, Q3 - max 3 total)
        6. Present all questions together before waiting for responses
        7. Wait for user to respond with their choices for all questions (e.g., "Q1: A, Q2: Custom - [details], Q3: B")
        8. Update the spec by replacing each [NEEDS CLARIFICATION] marker with the user's selected or provided answer
        9. Re-run validation after all clarifications are resolved

   d. **Update Checklist**: After each validation iteration, update the checklist file with current pass/fail status

9. **Persist the active feature pointer after a reportable spec exists**:
   - Do not replace `.specify/feature.json` while the spec is still a template or before its current
     validation state has been recorded in `checklists/requirements.md`.
   - Revalidate the full branch invariant and canonical feature directory, then atomically replace
     `.specify/feature.json` with the canonical repository-relative direct-child path:
     ```json
     {
       "feature_directory": "specs/<resolved-feature-directory>"
     }
     ```
   - If branch/path validation or the atomic pointer update fails, preserve the previous pointer, keep
     the new spec artifacts for diagnosis, and stop before post-execution hooks. This pointer lets
     downstream commands locate the feature independently of branch naming.

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

If no hooks are registered under `hooks.after_specify`, mark hook handling as skipped and continue to
the final branch invariant below. Otherwise apply the [공통 확장 훅 프로토콜](../../../.specify/memory/speckit-common-rules.md#확장-훅extension-hooks-프로토콜)
with hook key `hooks.after_specify`. For a mandatory hook you MUST emit `EXECUTE_COMMAND:` and
actually invoke it; immediately after it returns, whether it succeeded or failed, recheck the full
branch invariant. If the invariant fails, do not switch automatically; stop and report the expected
branch/ref, actual state, hook result, completed artifacts, and partial state. If the invariant passes
but the mandatory hook failed, stop and report the partial state before completion.

After all executable hooks finish or hook handling is skipped, require the full branch invariant one
final time. A failure blocks the Completion Report and must be reported as partial completion without
an automatic branch switch.

## Completion Report

Report completion to the user with:
- `SPECIFY_FEATURE_DIRECTORY` — the feature directory path
- `SPEC_FILE` — the spec file path
- `BRANCH_NAMESPACE` and `GIT_BRANCH_NAME` — the selected Git-flow type and validated branch name
- Branch status — whether this invocation created the branch or explicitly reused an existing branch
- Checklist results summary
- Readiness for the next phase (`/speckit-clarify` or `/speckit-plan`)

**NOTE:** Branch creation is mandatory core behavior and completes before `before_specify` hooks.
Spec directory and file creation are also handled by this core command, after branch verification.

## Quick Guidelines

- Focus on **WHAT** outcome or constraint is needed and **WHY**.
- Avoid detailed HOW-to design unless a technology, API, contract, tool, or version is itself a fixed requirement.
- Write for the actual stakeholder: end user, business owner, developer, operator, or integrating system.
- DO NOT create any checklists that are embedded in the spec. That will be a separate command.

### Section Requirements

- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation

When creating this spec from a user prompt:

1. **Make informed guesses**: Use context, industry standards, and common patterns to fill gaps
2. **Document assumptions**: Record reasonable defaults in the Assumptions section
3. **Limit clarifications**: Maximum 3 [NEEDS CLARIFICATION] markers - use only for critical decisions that:
   - Significantly impact scope, safety, quality, operations, or stakeholder experience
   - Have multiple reasonable interpretations with different implications
   - Lack any reasonable default
4. **Prioritize clarifications**: scope > security/privacy > quality/operations > stakeholder experience > technical details
5. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
6. **Common areas needing clarification** (only if no reasonable default exists):
   - Feature scope and boundaries (include/exclude specific use cases)
   - Stakeholder/actor types and permissions (if multiple conflicting interpretations possible)
   - Security/compliance requirements (when legally/financially significant)

**Examples of reasonable defaults** (don't ask about these):

- Data retention: Industry-standard practices for the domain
- Performance targets: Standard web/mobile app expectations unless specified
- Error handling: User-friendly messages with appropriate fallbacks
- Authentication method: Standard session-based or OAuth2 for web apps
- Integration patterns: Use project-appropriate patterns (REST/GraphQL for web services, function calls for libraries, CLI args for tools, etc.)

### Success Criteria Guidelines

Success criteria must be:

1. **Measurable**: Include specific metrics (time, percentage, count, rate)
2. **Outcome-focused**: Describe the required result, not an arbitrary implementation approach
3. **Stakeholder-focused**: Describe outcomes for the actual user, business, developer, operator, or system boundary
4. **Constraint-aware**: Preserve named technology or version only when the change explicitly targets it
5. **Verifiable**: Can be tested or reviewed without an unstated design choice

**Good examples**:

- "Users can complete checkout in under 3 minutes"
- "System supports 10,000 concurrent users"
- "95% of searches return results in under 1 second"
- "Task completion rate improves by 40%"
- "All existing public contract checks pass before and after the refactoring"
- "Dependency update removes all findings associated with the superseded version"

**Bad examples** (implementation-focused):

- "Create three Swift helper types" (prescribes structure without a required outcome)
- "Use Redis for caching" (selects a design without stating the required behavior)
- "Refactor cleanly" (not measurable)
- "Upgrade dependencies" (does not identify the target constraint or completion evidence)

## Done When

- [ ] Specification written to `SPEC_FILE` and validated against quality checklist
- [ ] Git-flow branch created or resumed directly and verified before any specification artifact write
- [ ] Git-flow namespace, active branch, and `생성`/`재사용` status recorded accurately
- [ ] Feature directory is a canonical direct child of `specs/` and feature.json was updated only after validation state was recorded
- [ ] Reused spec and checklist content merged without unintended truncation
- [ ] Extension hooks dispatched or skipped according to the rules in Mandatory Post-Execution Hooks above
- [ ] Completion reported to user with feature directory, spec file path, and checklist results
