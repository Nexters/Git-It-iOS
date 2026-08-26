---
name: "speckit-implement"
description: "Execute tasks.md as ordered logical units, including justified multi-package integration units, validating and committing each unit before continuing."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/implement.md"
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

**Run the read-only pre-hook safety guard**:
- Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` so feature resolution does not
  persist or modify `.specify/feature.json`. Read the resolved spec and require its actual feature
  branch to equal the current symbolic Git branch.
- Verify the repository is a Git worktree, HEAD resolves to a commit, and no existing `git commit`,
  commit hook, formatter, lock owner, or other Git-index-changing chain is still active in this
  checkout. Do not delete locks or terminate processes; wait for a known active owner, otherwise stop.
- Capture `PRE_HOOK_HEAD` and the symbolic branch for invariant checking only. Do not initialize the
  implementation baseline until all mandatory pre-hooks finish.

**Check for extension hooks (before implementation)**: [공통 확장 훅 프로토콜](../../../.specify/memory/speckit-common-rules.md#확장-훅extension-hooks-프로토콜)을
따르되 훅 키는 `hooks.before_implement`, 필수 훅의 "Wait for..." 대상 섹션은 "the Outline"이다.
After the hook returns, require the symbolic branch and HEAD to remain at the pre-hook invariant and
confirm its Git-changing process has ended. If the hook fails or the invariant does not hold, stop
before the Outline, preserve its state for diagnosis, and do not start implementation.
- After all mandatory pre-hooks succeed or hook handling is skipped, recheck the read-only guard before
  entering the Outline. Hook-created file changes remain subject to the baseline and ownership
  classification below; hook success does not grant them implementation ownership.

## Outline

## Allowed Write Paths

This skill may modify only (1) files named by an incomplete task in the active `tasks.md`,
(2) files named by a HEAD-relative uncommitted `[X]` task that is proven to belong to one
interrupted commit unit, and (3) checkbox states for completed tasks in that same `tasks.md`.
When a commit unit is planned, freeze its task IDs and exact paths as `UNIT_TASK_IDS` and
`UNIT_PATHS`. That snapshot, derived only from (1) or (2), remains authorized after its checkboxes
change to `[X]` until the unit commits successfully or the skill stops. It does not admit any path
added later or another unit's changes.
Each file-changing implementation task MUST name an exact repository-relative path. A directory
such as `sources/**` or `docs/**` is not a blanket allowance. If a needed file is absent from the
task list, stop and request an updated task instead of modifying it. A `docs/**` file may be
modified only when an incomplete task, a proven interrupted `[X]` resume task, or the active frozen
unit names that exact current path and assigns it to one responsible execution unit. A unit defaults
to one package, but may be an explicitly justified multi-package integration unit. Resolve the
document root through `GIT_IT_DOCS_ROOT`; reject stale
`sources/docs/**` task paths and request `/speckit-tasks` correction. Do not create or
amend ignore files unless an incomplete task, a proven interrupted `[X]` resume task, or the active
frozen unit explicitly names that exact ignore file.
`docs/spec-kit/<feature>/trouble-shooting.md` and
`docs/spec-kit/<feature>/tacit-knowledge.md` are never implementation-owned paths,
even if a task names them; use the dedicated recording skill instead.

For Git state, this skill may stage and create local commits containing only the exact files in the
current commit unit and the active `tasks.md`. It MUST NOT use `git add .`, `git add -A`, glob staging,
`git commit -a`, `--no-verify`, `--amend`, reset, stash, rebase, branch switching, or push. Git
permission does not expand the file write allowlist above.

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").
   - Verify this is a Git worktree with a symbolic current branch; detached HEAD is an error.
   - Before initializing a new chain or classifying a resume, check read-only process/lock evidence for
     an existing `git commit`, commit hook, formatter, or other Git-index-changing chain in this checkout.
     Do not delete a lock or terminate a process. If a chain is active, wait for and inspect its result;
     if ownership or liveness is ambiguous, stop and report it.
   - Capture `BASE_HEAD`, initialize `EXPECTED_HEAD=BASE_HEAD`, and record staged paths plus the
     staged/unstaged/untracked status only after no prior chain remains active. Preserve this baseline
     so unrelated user changes can be distinguished and left untouched.

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     - Completed items: Lines matching `- [X]` or `- [x]`
     - Incomplete items: Lines matching `- [ ]`
   - Create a status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - Calculate overall status:
     - **PASS**: All checklists have 0 incomplete items
     - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" or "wait" or "stop", halt execution
     - If user says "yes" or "proceed" or "continue", proceed to step 3

   - **If all checklists are complete**:
     - Display the table showing all checklists passed
     - Automatically proceed to step 3

3. Load and analyze the implementation context:
   - **REQUIRED**: Read spec.md for requirements, change scenarios, and the recorded feature branch
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **REQUIRED**: Read `.github/COMMIT_CONVENTION.md` for logical split and message rules
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read .specify/memory/constitution.md for governance constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios

4. **Project Setup Verification**:
   - Inspect ignore files only. Create or amend an ignore file only when an incomplete task, proven
     interrupted `[X]` resume task, or the active frozen unit explicitly names that exact file.

   **Detection & Creation Logic**:
   - Check if the following command succeeds to determine if the repository is a git repo. Inspect
     `.gitignore` if so, but create or amend it only when an incomplete task, proven interrupted `[X]`
     resume task, or the active frozen unit names `.gitignore` exactly:

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - Apply the following detection only to an ignore file named exactly by an incomplete task, proven
     interrupted `[X]` resume task, or the active frozen unit:
     Dockerfile* or Docker in plan.md → .dockerignore; .eslintrc* → .eslintignore;
     eslint.config.* → its `ignores`; .prettierrc* → .prettierignore; .npmrc or package.json
     when publishing → .npmignore; terraform files → .terraformignore; Helm charts → .helmignore.

   **If ignore file already exists**: Verify it contains essential patterns. Append missing critical
   patterns only when an incomplete task, proven interrupted `[X]` resume task, or the active frozen
   unit names that exact file.
   **If ignore file missing**: Create it only when an incomplete task, proven interrupted `[X]` resume
   task, or the active frozen unit names that exact file; otherwise report the gap and request a
   `/speckit-tasks` update.

   **Common Patterns by Technology** (from plan.md tech stack):
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `*.dll`, `autom4te.cache/`, `config.status`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **Tool-Specific Patterns**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

5. Parse tasks.md structure and establish the execution boundary:
   - **활성 브랜치**: Require the current symbolic branch to equal the actual feature branch recorded
     in spec.md. Do not create or switch branches from this skill.
   - **실행 단위 단계**: Derive package units and explicit integration units from tasks.md. Preserve
     package dependency order and do not invent a new unit during implementation.
   - **전체 최종화 작업**: Before package selection, map global `[no-write]` tasks under the whole
     completion-validation section, including an appended convergence phase's `전체 수렴 완료 검증`,
     to the last execution unit as `FINALIZATION_TASKS`. This is an execution mapping only and MUST
     NOT restructure tasks.md.
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, exact file paths, `[no-write]`, and parallel markers [P]
   - **Execution flow**: Order, dependency, and risk-based approval requirements
   - **실행 단위 소유권**: Every incomplete file-changing task and resume task must be assigned to one
     package unit or one explicitly declared integration unit, except global `FINALIZATION_TASKS`, which
     map to the last execution unit.

   Do not infer ownership from a path alone. If the responsible unit, exact paths, non-separability
   rationale, or validation is missing, stop before file changes and request `/speckit-tasks` correction.

   **Capture and classify the active tasks.md baseline before selecting an execution unit**:
   - Inspect HEAD, index, and worktree versions of the entire active tasks.md. Record its blob hash when
     tracked and hash the complete worktree content plus its staged/unstaged diff as `TASKS_BASELINE`.
     A separate baseline commit is optional and MUST NOT be required unless the user requested it or a
     durable collaboration boundary is necessary.
   - A HEAD-relative `[X]` file-changing task is a resume task only when its exact task-file diff exists.
     A HEAD-relative `[X]` `[no-write]` task may form a tasks-only resume unit without a source diff;
     this applies to package validation and finalization tasks, not only the final task in the file.
   - Uncommitted `[X]` transitions must belong to one proven interrupted unit. Checkbox reversals or an
     `[X]` file task without its exact file diff are invalid. Wording or structure edits are baseline
     content when their ownership is established by the current request; do not require a separate commit.
   - Because staging tasks.md consumes the whole file, freeze every baseline hunk. At commit time require
     the staged tasks.md to equal `TASKS_BASELINE` plus only the current unit's checkbox transitions.
     If another change appears, preserve it and stop before staging.
   - Existing exact file changes for still-incomplete tasks may be treated as an interrupted unmarked
     unit only when session evidence or an explicit user statement proves their ownership and all such
     paths form one logical execution unit. Otherwise preserve them and stop.

   **Classify the remaining Git state**:
   - Existing staged changes block a new unit unless they are (a) only the active tasks.md baseline with
     ownership established by the current request, or (b) exact paths of one proven interrupted unit.
     Freeze an accepted staged tasks.md baseline and never add unrelated staged paths to the unit.
   - Changes on a selected-unit path whose ownership cannot be proven block the run. Matching an exact
     path is insufficient: every diff hunk in that file must belong to the one unit, because exact-file
     staging would otherwise consume a user's same-file change. Unrelated unstaged changes elsewhere
     remain baseline: preserve them and never stage or modify them.

   **Select and authorize one execution-unit boundary**:
   - A proven interrupted unit takes precedence, but it must be at the earliest incomplete/resume
     boundary after all predecessor units; otherwise stop for an inconsistent execution order.
   - With no interrupted unit, select the first incomplete package or integration unit in the fixed
     dependency order. If only `FINALIZATION_TASKS` remain, select the last unit in finalization state.
   - The user's implementation request authorizes all ordinary units and read-only final validation in
     the fixed tasks.md scope. Report progress after each unit, but do not stop for package transitions.
   - Stop and request explicit approval only when the next action expands scope, is destructive or hard
     to recover, changes remote/external state, consumes user-owned changes, or introduces a new security,
     cost, or product decision. A package boundary alone is not an approval boundary.
   - During the current unit, do not modify files owned by a later unit.

6. **파일을 수정하기 전에 커밋 단위를 설계하고 인세션 계획으로 보고한다**:
   - 선택 실행 단위의 각 미완료 작업 ID와 위에서 식별한 미커밋 `[X]` 재개 작업을 정확히 하나의
     순서화된 커밋 단위에 배정한다. 작업 하나가 너무 넓어 논리적으로 분리해야 하지만
     checkbox 하나로 부분 완료를 표현할 수 없으면 구현하지 말고 `/speckit-tasks` 갱신을
     요청한다.
   - 각 단위에 `단위 ID`, 하나의 논리적 `목적`, 포함 `작업 ID`, 정확한 `파일 경로`, 실행할
     `검증`, `.github/COMMIT_CONVENTION.md`를 따르는 `[Tag] Message`를 명시한다.
   - 하나의 단위는 독립적으로 리뷰하고 되돌릴 수 있어야 한다. 단일 패키지가 기본이지만,
     tasks.md가 분리 불가 근거와 통합 검증을 명시한 integration unit은 여러 패키지를 포함할
     수 있다. 직접 관련된 production 코드와 테스트는 함께 둘 수 있지만 독립적인 기능, refactor, rename,
     현재 목적과 무관하거나 독립적으로 되돌릴 수 있는 build 설정, 대규모 포맷 변경은
     분리한다. 코드와 함께 있어야 compile되는 target/source 연결은 같은 목적의 단위에 둘 수
     있다.
   - 현재 단위의 정확한 파일에 commit hook이나 필수 formatter가 적용한 정규화 결과는 그
     단위가 저장소 검증을 통과하기 위한 필수 결과이므로 같은 단위에 포함한다.
     `.github/COMMIT_CONVENTION.md`의 자동 포맷 분리 규칙은 현재 목적과 무관한 독립적 또는
     대규모 포맷 변경에 적용한다.
   - `[P]` 작업은 같은 커밋 단위 안에서 서로 다른 파일을 다룰 때만 병렬 실행할 수 있다.
     서로 다른 커밋 단위와 모든 Git index/commit 작업은 직렬로 실행한다.
   - 패키지 검증 `[no-write]` 작업은 관련 ordinary unit에 배정한다. 마지막 실행 단위의
     `FINALIZATION_TASKS`와 필수 post hook은 마지막 ordinary unit에 배정해 `FINAL_UNIT`으로
     표시한다. 기존 tasks.md의 패키지 승인 게이트 문구만으로는 새 권한이 생기지 않으므로,
     Constitution 원칙 7의 위험 기준에 해당하지 않으면 반복 승인 없이 finalization을 진행한다.
     파일 변경 단위만 이미 commit된 단순 재개이면 tasks-only `FINAL_UNIT`을 둔다.
     입증된 중단 상태에서는 비최종 `[no-write]` tasks-only unit도 첫 재개 단위가 될 수 있다.
   - 각 단위를 시작하기 직전에 계획한 작업 ID와 경로를 `UNIT_TASK_IDS`와 `UNIT_PATHS`로
     snapshot한다. 이후 formatter나 hook이 허용 경로를 바꾸지 못하며 commit 성공 또는 중단
     전에는 snapshot을 재설계하거나 다음 단위를 활성화하지 않는다.
   - 이 계획은 tasks.md 구조를 수정하지 않는다. tasks.md에서는 검증을 마친 기존 checkbox의
     상태만 바꾼다.

7. 선택한 실행 단위의 커밋 단위를 계획 순서대로 하나씩 구현한다:
   - **실행 단위 내부 실행**: 선택한 단계의 준비, 테스트, 구현, 정리, 검증 순서 준수
   - **Respect dependencies**: Run sequential tasks in order; parallel tasks [P] can run together
     only inside the current commit unit
   - **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
   - **File-based coordination**: Tasks affecting the same files must run sequentially
   - **단위 경계**: 현재 단위의 정확한 파일만 수정하고, 완료·검증·커밋 성공을 확인하기
     전에는 다음 단위 파일을 수정하지 않음

8. Implementation execution rules:
   - **실행 단위 준비 우선**: 선택한 단위에 명시적으로 배정된 구조·의존성·구성 작업만 수행
   - **Tests before code**: If you need to write tests for contracts, entities, and integration scenarios
   - **Infrastructure development**: Implement models, services, CLI commands, endpoints
   - **Integration work**: Database connections, middleware, logging, external services
   - **정리와 검증**: 선택한 단위의 작업만 수행하고 전체 읽기 전용 검증은 마지막 구현 단위
     완료 뒤 같은 실행에서 수행

9. 각 커밋 단위를 다음 트랜잭션으로 완료한다:
   1. 예상 HEAD, 현재 브랜치, `UNIT_TASK_IDS`, `UNIT_PATHS`와 Git 상태를 다시 확인하고 baseline
      밖의 새 변경이 현재 단위 경로에 없는지 검증한다.
   2. 현재 단위의 작업만 수행하고 단위에 계획한 집중 검증을 실행한다. 검증 실패 시 checkbox,
      stage와 commit을 수행하지 않고 중단한다.
   3. 단위 전체가 검증된 뒤 그 단위에 포함된 아직 미완료인 작업 ID만 `[X]`로 바꾼다. 재개
      단위의 기존 미커밋 `[X]`는 유지하며 작업별 부분 완료를 미리 표시하지 않는다.
   4. 현재 단위가 계획에서 표시한 `FINAL_UNIT`이면 전체 읽기 전용 검증까지 완료해 모든
      `FINALIZATION_TASKS`를 `[X]`로 표시한 뒤, 아래 Mandatory Post-Execution Hooks를 이 commit
      전에 실행한다. Hook 대상이 될 수 있는 무관한 기존 Swift 변경이 있으면 실행하지 않고
      중단한다. Hook이 `UNIT_PATHS`를 바꾸면 변경 경로를 검사하고 영향받은 검증을 다시 실행해
      그 결과를 같은 최종 단위에 포함한다. snapshot 범위 밖 파일을 바꾸면 commit하지 않는다.
   5. staging 직전에 전체 tasks.md가 `TASKS_BASELINE`과 현재 `UNIT_TASK_IDS`의 checkbox 전이만
      포함하고 새 hunk가 없음을 다시 확인한다. 기준선 wording·structure가 현재 요청에 속한다면
      같은 파일 staging에 포함될 수 있으며 cached diff에서 별도로 식별한다. 그다음
      `UNIT_PATHS`와 활성 `tasks.md`만
      `git add -- <exact-unit-path>... <active-tasks.md>`로 stage한다. Tasks-only unit이면 빈 경로
      인수를 만들지 말고 활성 `tasks.md`만 명시한다.
   6. `git diff --cached --name-status`, 전체 cached diff와 `git diff --cached --check`를
      확인한다. 계획한 경로, 허용된 tasks.md baseline hunk와 checkbox만 포함되는지,
      임시·디버그 파일이 없는지, 실제 diff와
      예정 Tag/message가 일치하는지 검증한다. 범위 밖 staged 파일이 있으면 commit하지 않는다.
   7. 훅을 우회하지 않고 계획한 메시지로 `git commit`을 한 번 실행한다. 같은 checkout의
      다른 commit, pre-commit 또는 staged formatter 체인과 병렬 실행하지 않는다.
   8. commit 전후 HEAD, `git show --name-status --format=fuller HEAD`, 메시지, tasks checkbox와
      `git status --short`를 확인한다. 새 SHA와 정확한 파일 범위뿐 아니라 `UNIT_PATHS`와 활성
      tasks.md에 staged, unstaged, untracked 잔여가 없음을 확인한 뒤에만 다음 단위로 진행한다.
      성공하면 `EXPECTED_HEAD`를 새 SHA로 갱신한다. Commit이 생성됐지만 해당 경로에 잔여
      변경이 있으면 amend하지 말고 보존·보고 후 중단한다.
   9. pre-commit이 현재 단위 파일을 수정하고 commit이 생성되지 않은 경우에만, 기존 체인의
      종료를 먼저 확인한 뒤 정확한 단위 경로를 다시 stage하고 영향받은 검증과 cached 검사를
      반복할 수 있다. 동일 원인의 실패가 반복되면 자동 재시도하지 않고 변경을 보존해 중단한다.

10. Progress tracking and error handling:
   - Report progress and the verified commit SHA after each completed commit unit
   - Halt execution if any non-parallel task fails
   - For parallel tasks [P], wait for every result. If any task fails, preserve successful outputs for
     diagnosis but do not mark, stage, commit, or start another unit; report the failed tasks and stop
   - Provide clear error messages with context for debugging
   - Suggest next steps if implementation cannot proceed
   - A failed validation or commit leaves the current unit uncommitted and blocks every later unit.
     Preserve files and index for diagnosis; do not reset, amend a prior commit, or report the unit as
     committed.

11. Completion validation:
   - 선택한 실행 단위의 모든 필수 작업이 완료되었는지 확인하고, 같은 범위의 다음 단위 또는
     `FINALIZATION_TASKS`가 있으면 반복 승인 없이 계속함
   - 선택한 실행 단위 구현이 원래 명세와 일치하는지 확인
   - 선택한 실행 단위의 필수 테스트 통과와 커버리지 요구사항 충족 여부 검증
   - Confirm the implementation follows the technical plan
   - 선택한 실행 단위의 각 커밋 SHA, 메시지, 작업 ID, 변경 파일과 정확한 검증 결과 보고
   - 선택 단위에서 이번 실행이 소유한 staged/unstaged 변경이 남지 않았고, 무관한 baseline
     변경이 그대로 보존됐는지 확인
   - 새 범위, 파괴적 작업, remote·외부 상태 변경, 사용자 소유 변경 소비 또는 새 제품 결정이
     필요하면 그 작업 전에 중단하고 명시적 승인을 요청함
   - 미완료 실행 단위가 남으면 5단계로 돌아가 다음 단위를 선택하고, 모두 끝난 경우에만
     Mandatory Post-Execution Hooks와 Completion Report로 진행

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/speckit-tasks` first to regenerate the task list.

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

모든 실행 단위와 전체 읽기 전용 검증이 완료된 뒤에만 이 훅을 실행한다. 마지막
commit 단위에서는 위 9단계 트랜잭션의 staging 전에 이 섹션을 실행하고,
hook 결과와 완료된 `tasks.md`를 그 최종 commit에 포함한다. 최종 commit 성공 뒤 이 섹션을
다시 실행하지 않는다. 이후 실행 단위가 남아 있으면 훅을 실행하지 않고 다음 단위로 진행한다.

이 섹션을 9단계의 최종 commit 전 절차로 실행한 경우, hook 실행 또는 생략 처리가 끝나면
Completion Report로 건너뛰지 말고 9단계 5번의 정확한 staging으로 돌아간다. 최종 commit
확인 뒤 문서 순서상 이 섹션에 다시 도달하면 이미 처리한 결과를 재사용하고 Completion
Report로 진행한다.

If no hooks are registered under `hooks.after_implement`, mark hook handling as skipped and return to
the caller described above. Otherwise apply the [공통 확장 훅 프로토콜](../../../.specify/memory/speckit-common-rules.md#확장-훅extension-hooks-프로토콜)
with hook key `hooks.after_implement`. For a mandatory hook you MUST emit `EXECUTE_COMMAND:` and
actually invoke it; if it fails, preserve the `FINAL_UNIT`, do not stage or commit it, and stop with
the exact hook result. Only a successful mandatory hook may return to 9단계 5번.

After all executable mandatory hooks succeed, return to 9단계 5번 when this section was invoked before
the final commit. Otherwise continue to the Completion Report.

## Completion Report

Report final status with the selected execution units, commit-unit plan, verified commit
SHA/message/path for every completed unit, exact validation results, preserved baseline changes, and
any boundary that required new authority.

## Done When

- [ ] 선택한 실행 단위의 작업을 완료하고 `[X]`로 표시하며 새 권한이 필요한 작업은 미완료로 보존
- [ ] Implementation validated against specification, plan, and test coverage
- [ ] 파일 수정 전에 선택 실행 단위의 커밋 계획을 인세션에서 확정하고 보고
- [ ] tasks.md의 blob hash와 전체 diff를 기준선으로 고정하고 기존 hunk의 소유권을 분류
- [ ] 각 단위를 정확한 파일과 checkbox만으로 검증·commit하고 SHA와 범위 확인
- [ ] 선택 실행 단위 소유 변경은 남지 않고 무관한 baseline 변경은 그대로 보존
- [ ] 모든 적용 대상 패키지가 완료된 경우에만 최종 commit 전에 확장 훅 실행 또는 생략 처리
- [ ] 실행 단위, 커밋, 변경 파일과 검증 결과를 보고하고 새 권한이 필요한 경우에만 승인 요청
