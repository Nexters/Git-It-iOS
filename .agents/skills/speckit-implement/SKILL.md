---
name: "speckit-implement"
description: "Execute tasks.md one package at a time by designing logical commit units, validating and committing each unit before continuing."
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

**Run the read-only pre-hook safety guard**:
- Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` so feature resolution does not
  persist or modify `.specify/feature.json`. Read the resolved spec and require its actual feature
  branch to equal the current symbolic Git branch.
- Verify the repository is a Git worktree, HEAD resolves to a commit, and no existing `git commit`,
  commit hook, formatter, lock owner, or other Git-index-changing chain is still active in this
  checkout. Do not delete locks or terminate processes; wait for a known active owner, otherwise stop.
- Capture `PRE_HOOK_HEAD` and the symbolic branch for invariant checking only. Do not initialize the
  implementation baseline until all mandatory pre-hooks finish.

**Check for extension hooks (before implementation)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_implement` key
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
    After the hook returns, require the symbolic branch and HEAD to remain at the pre-hook invariant and
    confirm its Git-changing process has ended. If the hook fails or the invariant does not hold, stop
    before the Outline, preserve its state for diagnosis, and do not start implementation.
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently
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
unit names that exact current path and assigns it to one responsible package. Resolve the document root through
`GIT_IT_DOCS_ROOT`; reject stale
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
   - **패키지 단계**: Derive applicable packages and their topological order from the architecture
     dependency table and the order explicitly fixed by tasks.md. Do not use a hard-coded package list
     or infer a new order during implementation.
   - **전체 최종화 작업**: Before package selection, map global `[no-write]` tasks under the whole
     completion-validation section, including an appended convergence phase's `전체 수렴 완료 검증`,
     to the last applicable package as `FINALIZATION_TASKS`. This is an execution mapping only and MUST
     NOT restructure tasks.md. It lets the last package be selected for finalization even when every
     file-changing package task is already complete.
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, exact file paths, `[no-write]`, and parallel markers [P]
   - **Execution flow**: Order, dependency, and explicit approval-gate requirements
   - **패키지 소유권**: Every incomplete file-changing task and every resume task must be assigned to
     exactly one applicable package in tasks.md, except global `FINALIZATION_TASKS`, whose sole allowed
     ownership is the explicit execution mapping to the last applicable package above.

   Do not infer or invent package ownership from a path or description. If ownership is absent,
   spans packages, or creates a separate preparation/foundation/cleanup implementation phase, stop
   before file changes and request a `/speckit-tasks` correction.

   **Classify the complete active tasks.md diff before selecting a package**:
   - Inspect HEAD, index, and worktree versions of the entire active tasks.md. Classify every checkbox
     and every diff hunk as one of: already committed, one current interrupted unit, or invalid.
   - A HEAD-relative `[X]` file-changing task is a resume task only when its exact task-file diff exists.
     A HEAD-relative `[X]` `[no-write]` task may form a tasks-only resume unit without a source diff;
     this applies to package validation and finalization tasks, not only the final task in the file.
   - All uncommitted `[X]` transitions must belong to exactly one logical unit and one package (or that
     package's `FINALIZATION_TASKS`). A checkbox reversal, an `[X]` file task without its exact file
     diff, changes from multiple units/packages, wording or structure edits, or any other tasks.md hunk
     is invalid and blocks implementation.
   - Because the transaction stages tasks.md as one exact file, any pre-existing tasks.md change not
     owned by that single resume unit would be consumed by the commit. Stop before modifying or staging
     when such a hunk exists; require it to be committed, reverted by its owner, or otherwise resolved.
   - Existing exact file changes for still-incomplete tasks may be treated as an interrupted unmarked
     unit only when session evidence or an explicit user statement proves their ownership and all such
     paths form one logical unit in one package. Otherwise preserve them and stop.

   **Classify the remaining Git state**:
   - Existing staged changes block a new unit. They may be resumed only when every staged path is the
     active tasks.md or an exact path of the one proven interrupted unit, and the staged plus unstaged
     diff contains nothing outside that unit.
   - Changes on a selected-unit path whose ownership cannot be proven block the run. Matching an exact
     path is insufficient: every diff hunk in that file must belong to the one unit, because exact-file
     staging would otherwise consume a user's same-file change. Unrelated unstaged changes elsewhere
     remain baseline: preserve them and never stage or modify them.

   **Select and authorize one package boundary**:
   - A proven interrupted unit takes precedence, but it must be at the earliest incomplete/resume
     boundary after all predecessor packages; otherwise stop for an inconsistent execution order.
   - With no interrupted unit, select the first package in the fixed topological order that has an
     incomplete task. If only incomplete `FINALIZATION_TASKS` remain, select the last applicable
     package in finalization state. Skip only packages with neither incomplete, resume, nor mapped
     finalization work. If tasks.md lacks its package order and rationale, request `/speckit-tasks`.
   - Starting the first package, resuming a proven unit, or continuing a package that already has
     committed progress needs no new cross-package approval. Starting a later untouched package
     requires the current user-triggered input to explicitly approve `next` or that selected package
     after the preceding package's results were reported. An automatic continuation or older generic
     approval is insufficient; if unclear, stop and ask for approval without changing files.
   - If tasks.md places an explicit approval gate between last-package work and whole-feature
     validation, honor it. Commit and report the ordinary last-package units first, then run the
     mapped tasks-only finalization unit only after the user's subsequent explicit approval. Do not
     silently fold validation or hooks across that gate.
   - During this run, do not modify files owned by any later package.

6. **파일을 수정하기 전에 커밋 단위를 설계하고 인세션 계획으로 보고한다**:
   - 선택 패키지의 각 미완료 작업 ID와 위에서 식별한 미커밋 `[X]` 재개 작업을 정확히 하나의
     순서화된 커밋 단위에 배정한다. 작업 하나가 너무 넓어 논리적으로 분리해야 하지만
     checkbox 하나로 부분 완료를 표현할 수 없으면 구현하지 말고 `/speckit-tasks` 갱신을
     요청한다.
   - 각 단위에 `단위 ID`, 하나의 논리적 `목적`, 포함 `작업 ID`, 정확한 `파일 경로`, 실행할
     `검증`, `.github/COMMIT_CONVENTION.md`를 따르는 `[Tag] Message`를 명시한다.
   - 하나의 단위는 선택 패키지만 포함하고 독립적으로 리뷰하고 되돌릴 수 있어야 한다. 직접
     관련된 production 코드와 테스트는 함께 둘 수 있지만 독립적인 기능, refactor, rename,
     현재 목적과 무관하거나 독립적으로 되돌릴 수 있는 build 설정, 대규모 포맷 변경은
     분리한다. 코드와 함께 있어야 compile되는 target/source 연결은 같은 목적의 단위에 둘 수
     있다.
   - 현재 단위의 정확한 파일에 commit hook이나 필수 formatter가 적용한 정규화 결과는 그
     단위가 저장소 검증을 통과하기 위한 필수 결과이므로 같은 단위에 포함한다.
     `.github/COMMIT_CONVENTION.md`의 자동 포맷 분리 규칙은 현재 목적과 무관한 독립적 또는
     대규모 포맷 변경에 적용한다.
   - `[P]` 작업은 같은 커밋 단위 안에서 서로 다른 파일을 다룰 때만 병렬 실행할 수 있다.
     서로 다른 커밋 단위와 모든 Git index/commit 작업은 직렬로 실행한다.
   - 패키지 검증 `[no-write]` 작업은 해당 패키지의 마지막 ordinary unit에 배정한다. 명시적
     승인 게이트가 가로막지 않으면 마지막 적용 패키지의 `FINALIZATION_TASKS`와 필수 post hook도
     마지막 ordinary unit에 배정해 `FINAL_UNIT`으로 표시한다. 명시적 게이트가 있으면 후속 승인
     뒤 tasks.md 완료 표시만 담는 tasks-only `FINAL_UNIT`을 둔다. 파일 변경 단위만 이미 commit된
     단순 재개이고 게이트가 없으면 현재 실행에서 추가 승인 없이 tasks-only `FINAL_UNIT`을 둔다.
     입증된 중단 상태에서는 비최종 `[no-write]` tasks-only unit도 첫 재개 단위가 될 수 있다.
   - 각 단위를 시작하기 직전에 계획한 작업 ID와 경로를 `UNIT_TASK_IDS`와 `UNIT_PATHS`로
     snapshot한다. 이후 formatter나 hook이 허용 경로를 바꾸지 못하며 commit 성공 또는 중단
     전에는 snapshot을 재설계하거나 다음 단위를 활성화하지 않는다.
   - 이 계획은 tasks.md 구조를 수정하지 않는다. tasks.md에서는 검증을 마친 기존 checkbox의
     상태만 바꾼다.

7. 선택한 패키지의 커밋 단위를 계획 순서대로 하나씩 구현한다:
   - **패키지 내부 실행**: 선택한 패키지 단계의 준비, 테스트, 구현, 정리, 검증 순서 준수
   - **Respect dependencies**: Run sequential tasks in order; parallel tasks [P] can run together
     only inside the current commit unit
   - **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
   - **File-based coordination**: Tasks affecting the same files must run sequentially
   - **단위 경계**: 현재 단위의 정확한 파일만 수정하고, 완료·검증·커밋 성공을 확인하기
     전에는 다음 단위 파일을 수정하지 않음

8. Implementation execution rules:
   - **패키지 준비 우선**: 선택한 패키지에 명시적으로 배정된 구조·의존성·구성 작업만 수행
   - **Tests before code**: If you need to write tests for contracts, entities, and integration scenarios
   - **Infrastructure development**: Implement models, services, CLI commands, endpoints
   - **Integration work**: Database connections, middleware, logging, external services
   - **정리와 검증**: 선택한 패키지 소유 작업만 수행하고 전체 읽기 전용 검증은 마지막 적용
     대상 패키지 완료 뒤에만 수행

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
   5. staging 직전에 HEAD 대비 전체 tasks.md diff가 `UNIT_TASK_IDS`의 checkbox 전이만 포함하고
      다른 hunk가 없음을 다시 확인한다. 그다음 `UNIT_PATHS`와 활성 `tasks.md`만
      `git add -- <exact-unit-path>... <active-tasks.md>`로 stage한다. Tasks-only unit이면 빈 경로
      인수를 만들지 말고 활성 `tasks.md`만 명시한다.
   6. `git diff --cached --name-status`, 전체 cached diff와 `git diff --cached --check`를
      확인한다. 계획한 경로와 checkbox만 포함되는지, 임시·디버그 파일이 없는지, 실제 diff와
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
   - 선택한 실행 경계의 모든 필수 작업이 완료되었는지 확인. 명시적 최종화 승인 게이트가
     남았다면 ordinary package work만 완료로 보고하고 `FINALIZATION_TASKS`는 완료로 표시하지 않음
   - 선택한 패키지 구현이 원래 명세와 일치하는지 확인
   - 선택한 패키지의 필수 테스트 통과와 커버리지 요구사항 충족 여부 검증
   - Confirm the implementation follows the technical plan
   - 선택한 패키지의 각 커밋 SHA, 메시지, 작업 ID, 변경 파일과 정확한 검증 결과 보고
   - 선택 패키지에서 이번 실행이 소유한 staged/unstaged 변경이 남지 않았고, 무관한 baseline
     변경이 그대로 보존됐는지 확인
   - 이후 적용 대상 패키지 또는 승인 대기 중인 finalization boundary가 남아 있으면 명시적
     사용자 승인을 요청하고 중단. 기능 구현이 완료되지 않았으므로 이 시점에는 필수 사후 훅을
     실행하지 않음

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/speckit-tasks` first to regenerate the task list.

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

모든 적용 대상 패키지와 전체 읽기 전용 검증이 완료된 뒤에만 이 훅을 실행한다. 마지막 적용
패키지의 마지막 commit 단위에서는 위 9단계 트랜잭션의 staging 전에 이 섹션을 실행하고,
hook 결과와 완료된 `tasks.md`를 그 최종 commit에 포함한다. 최종 commit 성공 뒤 이 섹션을
다시 실행하지 않는다. 이후 적용 대상 패키지가 남아 있으면 훅을 실행하지 않고 11단계의
패키지 승인 게이트에서 중단한다.

이 섹션을 9단계의 최종 commit 전 절차로 실행한 경우, hook 실행 또는 생략 처리가 끝나면
Completion Report로 건너뛰지 말고 9단계 5번의 정확한 staging으로 돌아간다. 최종 commit
확인 뒤 문서 순서상 이 섹션에 다시 도달하면 이미 처리한 결과를 재사용하고 Completion
Report로 진행한다.

Check if `.specify/extensions.yml` exists in the project root.
- If it does not exist, or no hooks are registered under `hooks.after_implement`, mark hook handling
  as skipped and return to the caller described above.
- If it exists, read it and look for entries under the `hooks.after_implement` key.
- If the YAML cannot be parsed or is invalid, skip hook checking silently and return to the caller
  described above.
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
    If the mandatory hook fails, preserve the `FINAL_UNIT`, do not stage or commit it, and stop with the
    exact hook result. Only a successful mandatory hook may return to 9단계 5번.
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```

After all executable mandatory hooks succeed, return to 9단계 5번 when this section was invoked before
the final commit. Otherwise continue to the Completion Report.

## Completion Report

Report final status with the selected package, commit-unit plan, verified commit SHA/message/path
for every completed unit, exact validation results, preserved baseline changes, and whether the next
package requires approval.

## Done When

- [ ] 선택한 실행 경계의 작업만 완료하고 `[X]`로 표시하며 승인 대기 작업은 미완료로 보존
- [ ] Implementation validated against specification, plan, and test coverage
- [ ] 파일 수정 전에 선택 패키지의 커밋 단위 계획을 인세션에서 확정하고 보고
- [ ] tasks.md의 모든 기존 diff hunk와 checkbox를 단일 재개 단위 또는 오류로 분류
- [ ] 각 단위를 정확한 파일과 checkbox만으로 검증·commit하고 SHA와 범위 확인
- [ ] 선택 패키지 소유 변경은 남지 않고 무관한 baseline 변경은 그대로 보존
- [ ] 모든 적용 대상 패키지가 완료된 경우에만 최종 commit 전에 확장 훅 실행 또는 생략 처리
- [ ] 패키지, 커밋, 변경 파일과 검증 결과를 보고하고 다음 적용 대상 패키지 전에 명시적 승인 요청
