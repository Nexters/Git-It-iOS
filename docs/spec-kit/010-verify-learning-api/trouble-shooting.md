# 010-verify-learning-api 문제 해결 기록

**대상 기능**: `010-verify-learning-api`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260821-001: 작업 경로 제한 패치의 문맥 불일치

**기록일**: 2026-08-21
**상태**: 해결
**발생 단계**: `speckit-constitution` 연동 스킬·템플릿 동기화
**관련 항목**: `.agents/skills/speckit-tasks/SKILL.md`, `.specify/templates/tasks-template.md`

### 증상

여러 파일을 함께 갱신하는 `apply_patch`가 `- **Description**: Clear action with exact file path`
문맥을 찾지 못해 전체 패치를 적용하지 않았다.

### 영향

`speckit-implement`의 ignore 파일 제한, `speckit-tasks`의 정확한 파일 경로 예시와 작업
템플릿의 디렉터리 비허용 설명이 첫 시도에서는 반영되지 않았다. 실패한 패치는 원자적으로
중단되어 일부 파일만 변경되는 상태는 발생하지 않았다.

### 근거

- `apply_patch verification failed`: 예상한 목록 문맥이 실제 파일과 일치하지 않았다.
- `.agents/skills/speckit-tasks/SKILL.md:202`: 실제 문장은 번호가 포함된
  `5. **Description**: Clear action with exact file path`였다.

### 원인

패치가 번호 목록의 `5.` 접두어를 제외한 문장을 기대해 실제 원문과 일치하지 않았다.

### 조치

대상 세 파일의 실제 줄을 다시 읽고, 일치하지 않은 불필요한 문맥을 제거한 작은 패치로
나누어 재적용했다.

### 검증

- `git diff -- .agents/skills/speckit-implement/SKILL.md .agents/skills/speckit-tasks/SKILL.md .specify/templates/tasks-template.md`: 정확한 파일 allowlist와 ignore 파일 제한 변경이 모두 반영됨.

### 재발 방지

여러 파일 패치를 적용하기 전에 번호 목록이나 들여쓰기가 포함된 대상 줄을 `nl -ba`로
확인하고, 의미 없는 주변 문맥을 패치 조건에 포함하지 않는다.

### 연결

없음

## TS-20260821-002: zsh 특수 변수와 목록 분리 오판으로 기록 이동 실패

**기록일**: 2026-08-21
**상태**: 해결
**발생 단계**: 세션 기록의 `docs/spec-kit/<feature>/` 이전
**관련 항목**: `docs/spec-kit/**`, `specs/*/trouble-shooting.md`,
`specs/*/tacit-knowledge.md`

### 증상

첫 조회 명령은 반복 변수 `path`가 zsh의 특수 배열 `path`를 덮어써 같은 셸의 `git`을
찾지 못했다. 이어진 첫 이동 명령은 명령 치환 결과가 줄 단위로 분리될 것이라고 가정해
13개 파일 경로 전체를 하나의 `mv` 원본으로 전달했고, 개행이 포함된 빈 디렉터리를 만들고
실패했다.

### 영향

조회 명령의 마지막 `git status --short`가 실행되지 않았고 첫 파일 이동은 완료되지
않았다. 원본 기록 파일은 모두 `specs/` 아래에 보존됐지만 `docs/spec-kit/` 아래에 비정상
빈 디렉터리가 생겼다.

### 근거

- 조회 명령 출력 `zsh:4: command not found: git`: `path` 대입 뒤 명령 탐색 경로가
  사라졌다.
- 첫 이동 출력 `mv: rename ... No such file or directory`: 여러 줄의 파일 목록이 하나의
  인수로 전달됐다.
- 복구 전 `find docs/spec-kit -print | sed -n l`: 개행이 포함된 빈 디렉터리 계층이
  확인됐다.

### 원인

zsh에서 `path`가 `PATH`와 연결된 특수 배열이라는 점과 따옴표로 감싼 명령 치환 결과가
줄별 반복 항목으로 자동 분리되지 않는다는 점을 고려하지 않았다.

### 조치

`find docs/spec-kit -depth -type d -empty -delete`로 이번 실패가 만든 빈 디렉터리만
제거했다. 반복 변수 이름을 `record_file`로 바꾸고 `while IFS= read -r record_file`과
프로세스 치환으로 파일을 한 줄씩 처리해 13개 기록 파일을 다시 이동했다.

### 검증

- 수정한 이동 명령: 13개 원본과 대상 경로를 각각 출력하고 종료 코드 0으로 완료됐다.
- 후속 경로 회귀 검사: `specs/` 아래 기록 파일이 없고 `docs/spec-kit/` 아래 13개 기록
  파일이 존재하는지 확인한다.

### 재발 방지

zsh 자동화에서 `path`를 일반 변수명으로 사용하지 않고, 여러 파일을 처리할 때는 명령
치환의 암묵적 단어 분리에 의존하지 않는다. 이동 전 충돌 검사와 이동 후 원본·대상 개수
검사를 함께 실행한다.

### 연결

없음

## TS-20260821-003: 스킬 검사기의 의존성과 메타데이터 형식 불일치

**기록일**: 2026-08-21
**상태**: 해결
**발생 단계**: `skill-creator` 기반 Spec Kit 스킬 검증
**관련 항목**: `.agents/skills/speckit-troubleshooting/SKILL.md`,
`.agents/skills/speckit-tacit-knowledge/SKILL.md`, 기존 Spec Kit 스킬 frontmatter

### 증상

`quick_validate.py`가 시스템 Python과 번들 Python 모두에서 `PyYAML`을 찾지 못해
실행되지 않았다. 임시 의존성을 제공한 뒤에는 프로젝트의 기존 `compatibility` frontmatter
키를 검사기가 허용하지 않았고, 두 기록 스킬의 description에 사용한 `<feature>` 표기도
금지 문자로 판정됐다.

### 영향

첫 두 검증 시도는 스킬 유효성 결과를 만들지 못했다. 저장소 파일은 검사 과정에서 변경되지
않았으며, 기존 Spec Kit 통합 메타데이터를 검사기에 맞추려고 삭제하면 오히려 호환성을
훼손할 수 있었다.

### 근거

- `ModuleNotFoundError: No module named 'yaml'`: 두 Python 실행 환경에 `PyYAML`이 없었다.
- `Unexpected key(s) ... compatibility`: 범용 검사기의 허용 키와 기존 Spec Kit 형식이
  달랐다.
- `Description cannot contain angle brackets (< or >)`: 새 기록 스킬 description의 경로
  자리표시자가 검사 규칙을 위반했다.

### 원인

검사 스크립트의 런타임 의존성이 기본 환경에 포함되어 있지 않았고, 범용 skill-creator
검사 규칙과 GitHub Spec Kit에서 생성한 기존 스킬 frontmatter 형식이 완전히 같지 않았다.
또한 새 description에 검사기가 금지하는 꺾쇠 자리표시자를 사용했다.

### 조치

임시 디렉터리에만 `PyYAML`을 설치해 검사기에 `PYTHONPATH`로 제공했다. 기존
`compatibility` 키는 보존하고, 이번에 frontmatter를 직접 수정한 두 기록 스킬만 전용
검사 대상으로 제한했다. 두 description의 `<feature>`를 `기능별` 표현으로 바꿨다.

### 검증

- `quick_validate.py .agents/skills/speckit-tacit-knowledge`: `Skill is valid!`
- `quick_validate.py .agents/skills/speckit-troubleshooting`: `Skill is valid!`
- 임시 검사 디렉터리: 명령 종료 시 파일과 빈 디렉터리를 삭제했다.

### 재발 방지

범용 검사기를 실행할 때는 의존성을 격리된 임시 경로에 준비하고, 기존 통합 스킬은
frontmatter 형식 차이를 먼저 확인한다. 새 skill description에는 꺾쇠 자리표시자를 쓰지
않는다.

### 연결

없음

## TS-20260821-004: 반복 문맥으로 새 기록이 파일 중간에 삽입됨

**기록일**: 2026-08-21
**상태**: 해결
**발생 단계**: `speckit-troubleshooting` 항목 추가
**관련 항목**: `TS-20260821-003`

### 증상

`TS-20260821-003`을 추가한 패치가 파일에 반복되는 `### 연결`과 `없음` 문맥 중 첫 번째
위치에 결합되어 새 항목이 `TS-20260821-001`과 `TS-20260821-002` 사이에 삽입됐다.

### 영향

새 항목이 파일 끝에 추가되어야 한다는 append-only 순서와 ID 증가 순서가 최종화 전에
일시적으로 어긋났다. 기존 항목의 본문은 변경되지 않았다.

### 근거

- `rg -n '^## TS-'`: `TS-001`, `TS-003`, `TS-002` 순서를 출력했다.

### 원인

추가 패치의 고정 문맥이 파일 끝을 유일하게 식별하지 못했으며 같은 머리말이 모든 기록에
반복된다는 점을 고려하지 않았다.

### 조치

최종화되지 않은 `TS-003` 블록을 원래 위치에서 제거해 `TS-002`의 고유한 재발 방지 문단
뒤로 옮기고, 이 후속 항목을 파일 끝에 추가했다.

### 검증

- `rg -n '^## TS-'`: `TS-001`, `TS-002`, `TS-003`, `TS-004` 순서를 확인한다.
- 기존 `TS-001`과 `TS-002` 본문: 이동 교정 전후의 내용 변경이 없는지 diff로 확인한다.

### 재발 방지

append-only 파일에 항목을 추가할 때는 반복 머리말이 아니라 마지막 항목의 고유 문장을
문맥으로 사용하고, 직후 ID 순서를 검사한다.

### 연결

선행: `TS-20260821-003`

## TS-20260821-005: 프로젝트 설정 러너를 동작 인자 없이 호출함

**기록일**: 2026-08-21
**상태**: 해결
**발생 단계**: 루트 심볼릭 링크와 VS Code workspace 최종 동기화
**관련 항목**: `tools/project-setup/bin/run.sh`, `Makefile`

### 증상

`GIT_IT_PROJECT_SETUP_RUNNER`가 반환한 실행 파일을 인자 없이 호출해
`오류[common.invalid-input]: workspace-link 또는 developer-tools 동작이 필요합니다`로
종료됐다.

### 영향

첫 호출에서는 링크와 workspace가 다시 생성되지 않았다. 이어진 읽기 전용 확인으로 기존
상태가 올바른 것은 확인했지만 공개 진입점을 통한 재동기화 증거는 아직 없었다.

### 근거

- `tools/project-setup/bin/run.sh`: 정확히 하나의 `workspace-link` 또는
  `developer-tools` 인자를 요구한다.
- `Makefile`: 두 동작을 각각 `make tuist`와 `make init` 흐름에서 명시적으로 전달한다.

### 원인

JSON 판독 결과가 실행 파일 경로만 제공한다는 점은 확인했지만 해당 실행 파일의 필수 동작
인자를 호출 전에 확인하지 않았다.

### 조치

러너의 공개 사용 계약을 읽은 뒤 같은 실행 파일을 `workspace-link`, `developer-tools`
순서로 각각 호출했다.

### 검증

- `workspace-link`: `GitIt.xcworkspace -> sources/GitIt.xcworkspace` 재생성 성공.
- `developer-tools`: `CLAUDE.md -> AGENTS.md`, `.claude -> .agents` 재생성과
  `Git-It-iOS.code-workspace` 생성 성공.
- VS Code workspace: `specs`, `docs` 두 폴더가 포함됨을 확인했다.

### 재발 방지

JSON 경로 판독기는 실행 파일 위치만 반환한다고 가정하고, 공개 러너를 직접 호출하기 전에
Makefile 또는 진입점의 필수 동작 인자를 확인한다.

### 연결

없음

## TS-20260821-006: VS Code JSON을 plist 검사기로 검증함

**기록일**: 2026-08-21
**상태**: 해결
**발생 단계**: VS Code workspace 최종 형식 검증
**관련 항목**: `Git-It-iOS.code-workspace`

### 증상

`/usr/bin/plutil -lint Git-It-iOS.code-workspace`가 첫 줄의 `{`를 예상하지 못한 문자로
보고하며 실패했다.

### 영향

올바른 JSON 파일에 대해 형식 오류처럼 보이는 결과가 발생했다. workspace 생성 결과나
파일 내용은 변경되지 않았다.

### 근거

- `plutil`: `Unexpected character { at line 1`을 출력했다.
- `/usr/bin/python3 -m json.tool`: 같은 파일을 오류 없이 파싱했다.

### 원인

VS Code workspace의 JSON 형식을 plist 검사기에 전달해 검증 도구와 입력 형식이 맞지
않았다.

### 조치

표준 JSON 파서인 `python3 -m json.tool`로 형식을 검사하고, 별도 JSON 파싱으로 `folders`
값이 정확히 `specs`, `docs`인지 확인했다.

### 검증

- `python3 -m json.tool Git-It-iOS.code-workspace`: 성공.
- JSON `folders` assertion: `['specs', 'docs']` 확인.

### 재발 방지

`.code-workspace` 파일은 plist 도구가 아니라 JSON 파서로 검사한다.

### 연결

없음
