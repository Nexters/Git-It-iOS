---
name: "speckit-taskstoissues"
description: "Convert existing tasks into actionable, dependency-ordered GitHub issues for the feature based on available design artifacts."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/taskstoissues.md"
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

**Check for extension hooks (before tasks-to-issues conversion)**: [공통 확장 훅 프로토콜](../../../.specify/memory/speckit-common-rules.md#확장-훅extension-hooks-프로토콜)을
따르되 훅 키는 `hooks.before_taskstoissues`, 필수 훅의 "Wait for..." 대상 섹션은 "the Outline"이다.

## Outline

## Allowed Write Paths

This skill must not modify local files. Its only permitted mutation is creating GitHub
issues for tasks after the remote URL has been verified as the target repository.

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").
1. **IF EXISTS**: Load `.specify/memory/constitution.md` for project principles and governance constraints.
1. From the executed script, extract the path to **tasks**.
1. Get the Git remote by running:

```bash
git config --get remote.origin.url
```

> [!CAUTION]
> ONLY PROCEED TO NEXT STEPS IF THE REMOTE IS A GITHUB URL

1. **Fetch existing issues for deduplication**: Before creating anything, build the set of task IDs you are about to process from `tasks.md` (each is a `T` followed by three digits, e.g. `T001`). Then use the GitHub MCP server's `list_issues` tool to look for issues that already cover those IDs. Do not pass a `state` value, since omitting it makes the tool return both open and closed issues. Request `perPage: 100` to keep the number of calls down, and since the tool uses cursor-based pagination, request pages with the `after` parameter (using the `endCursor` from the previous response). For each issue title, match it against the task ID pattern `\bT\d{3}\b` (word boundaries so tokens like `ST001` or `T0010` are not matched by mistake; this also recognises titles written as `T001 ...`, `T001: ...` or `[T001] ...`) and, when it matches one of your task IDs, mark that ID as already having an issue. Stop paginating as soon as every task ID has been matched, or when there are no more pages, so you do not keep fetching the whole repository's issue history once all task IDs are accounted for. This bounds the number of calls on repos with large issue histories and still prevents duplicates when the command is re-run after `tasks.md` is regenerated or the skill is re-invoked.
1. For each task in the list, use the GitHub MCP server to create a new issue in the repository that is representative of the Git remote. Task lines in `tasks.md` start with a markdown checkbox, so first strip the leading `- [ ]` (and any `[P]` / `[S#]` / legacy `[US#]` markers) to recover the task ID and its description. Create the issue with a single canonical title of the form `T001: <description>`, with the ID written once followed by the task description (for example, the line `- [ ] T001 Create project structure` becomes the title `T001: Create project structure`).
   - **Skip** any task whose ID is already present in the set of existing issues from the previous step, and report it (for example, `T001 already has an issue, skipping`).
   - Only create issues for tasks that do not yet have a matching issue.

> [!CAUTION]
> UNDER NO CIRCUMSTANCES EVER CREATE ISSUES IN REPOSITORIES THAT DO NOT MATCH THE REMOTE URL

## Post-Execution Checks

**Check for extension hooks (after tasks-to-issues conversion)**: apply the [공통 확장 훅 프로토콜](../../../.specify/memory/speckit-common-rules.md#확장-훅extension-hooks-프로토콜)
with hook key `hooks.after_taskstoissues`.
