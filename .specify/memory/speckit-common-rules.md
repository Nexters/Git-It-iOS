# Spec Kit 스킬 공통 규칙

이 문서는 `.agents/skills/speckit-*/SKILL.md` 워크플로 스킬(analyze, checklist, clarify,
constitution, converge, implement, plan, specify, tasks, taskstoissues)이 공유하는 규칙을
한 곳에 모은 것이다. 각 스킬 파일은 아래 규칙을 직접 반복하지 않고 이 문서를 참조한다.
`speckit-troubleshooting`과 `speckit-tacit-knowledge`는 별도의 기록 전용 규약을 따르며 이
문서의 대상이 아니다.

이 문서의 규칙은 각 스킬 파일에 스킬 고유 값(훅 키 이름, 다음 섹션 이름 등)과 함께
적용된다. 스킬 파일에 더 구체적인 규칙이 있으면 그 스킬 파일이 우선한다.

## 사용자 입력 처리

모든 스킬은 `$ARGUMENTS`로 전달된 사용자 입력을 다음 형식으로 다룬다.

```text
$ARGUMENTS
```

입력이 비어 있지 않으면 진행 전에 반드시 고려한다.

## 산출물 언어

이 스킬이 생성·수정하거나 사용자에게 보고하는 모든 자연어 문장은 한국어로 작성한다.
코드 식별자, 명령어, 파일 경로, 환경 변수, 라이브러리·API 고유 명칭, BDD 키워드는
원문을 유지한다. 이 규칙은 각 스킬 문서의 영어 예시와 기본 템플릿의 고정 문구보다
우선한다.

## 세션 지식 기록 위임

- 기록 적용 여부와 문턱은 Constitution 원칙 9를 단일 정본으로 따른다.
- 각 워크플로 스킬은 `trouble-shooting.md`, `tacit-knowledge.md` 두 기록 파일을 직접
  수정하지 않는다. 조건을 충족하면 전용 `$speckit-troubleshooting` 또는
  `$speckit-tacit-knowledge`를 별도로 적용한다.

## 인자 이스케이프 규칙

셸 스크립트(`.specify/scripts/bash/*.sh`)에 전달하는 인자에 작은따옴표가 포함되면
이스케이프 구문을 사용한다. 예: "I'm Groot" → `'I'\''m Groot'` (또는 가능하면 큰따옴표로
`"I'm Groot"`).

## 확장 훅(Extension Hooks) 프로토콜

모든 워크플로 스킬은 실행 전(`before_<phase>`)과 실행 후(`after_<phase>`) 두 시점에
동일한 방식으로 `.specify/extensions.yml`의 확장 훅을 확인한다. `<phase>`는 스킬마다
다른 값(`analyze`, `checklist`, `clarify`, `constitution`, `converge`, `implement`,
`plan`, `specify`, `tasks`, `taskstoissues`)을 쓴다.

**탐지 및 필터링**:

- `.specify/extensions.yml`이 프로젝트 루트에 있는지 확인한다.
- 있으면 읽어서 `hooks.before_<phase>` 또는 `hooks.after_<phase>` 키 아래 항목을 찾는다.
- YAML을 파싱할 수 없거나 유효하지 않으면 조용히 건너뛰고 정상 진행한다.
- `enabled`가 명시적으로 `false`인 훅은 제외한다. `enabled` 필드가 없으면 기본으로
  활성 상태로 취급한다.
- 남은 각 훅에 대해 `condition` 표현식을 직접 해석·평가하지 않는다.
  - `condition` 필드가 없거나 null/빈 값이면 실행 가능으로 취급한다.
  - 비어 있지 않은 `condition`이 있으면 해당 훅을 건너뛰고 조건 평가는
    HookExecutor 구현에 맡긴다.
- 훅 명령 이름으로 슬래시 명령을 구성할 때 점(`.`)을 하이픈(`-`)으로 바꾼다.
  예: `speckit.git.commit` → `/speckit-git-commit`.

**출력 형식**: 실행 가능한 각 훅에 대해 `optional` 플래그에 따라 다음을 출력한다.

- **선택 훅** (`optional: true`), 실행 전:

  ```text
  ## Extension Hooks

  **Optional Pre-Hook**: {extension}
  Command: `/{command}`
  Description: {description}

  Prompt: {prompt}
  To execute: `/{command}`
  ```

- **선택 훅** (`optional: true`), 실행 후: 위와 동일하되 레이블을 `**Optional Hook**`으로
  쓴다.

- **필수 훅** (`optional: false`), 실행 전:

  ```text
  ## Extension Hooks

  **Automatic Pre-Hook**: {extension}
  Executing: `/{command}`
  EXECUTE_COMMAND: {command}

  Wait for the result of the hook command before proceeding to <다음 섹션 이름>.
  ```

- **필수 훅** (`optional: false`), 실행 후: 위와 동일하되 레이블을
  `**Automatic Hook**`으로 쓰고 "Wait for..." 문장은 생략한다. 완료 보고 전에 실행해야
  하는 스킬(예: `Mandatory Post-Execution Hooks`로 표기하는 스킬)은 "You MUST emit
  `EXECUTE_COMMAND:` for each mandatory hook"을 함께 명시한다.

  위 블록을 출력한 뒤에는 반드시 해당 훅을 실제로 호출하고 완료될 때까지 기다린 다음
  진행한다. 이 에이전트/세션에서 직접 그 명령을 실행하듯 동일한 방식으로 실행한다(예:
  스킬 모드 에이전트는 `/skill:speckit-...` 또는 `$speckit-...`로 호출할 수 있다). 블록을
  출력하는 것만으로는 훅이 실행되지 않는다.

- 등록된 훅이 없거나 `.specify/extensions.yml`이 없으면 조용히 건너뛴다.

**적용 예시** (`speckit-plan`의 실행 전 훅):

```text
**Check for extension hooks (before planning)**:
훅 프로토콜은 [speckit-common-rules.md § 확장 훅 프로토콜](../../.specify/memory/speckit-common-rules.md)을
따르며 훅 키는 `hooks.before_plan`, 다음 섹션은 "Outline"이다.
```
