# 013-ui-convention-refactor 문제 해결 기록

**대상 기능**: `013-ui-convention-refactor`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260821-001: 누락된 feature.json을 기존 파일로 갱신하려 한 명세 생성 실패

**기록일**: 2026-08-21
**상태**: 해결
**발생 단계**: `speckit-specify` 명세 산출물 생성
**관련 항목**: `.specify/feature.json`, `specs/013-ui-convention-refactor/spec.md`

### 증상

명세와 체크리스트, `.specify/feature.json`을 한 patch로 생성하는 과정에서 `.specify/feature.json`을 기존 파일로 갱신하려 했고, 해당 파일이 존재하지 않아 patch 전체가 적용되지 않았다.

### 영향

초기 명세 산출물 생성이 중단되어 활성 기능 경로를 기록할 수 없었다.

### 근거

- `apply_patch`: `Failed to read file to update /Users/jerry/Desktop/codex/Git-It-iOS/.specify/feature.json: No such file or directory` 오류를 반환했다.
- `test -e .specify/feature.json`: 종료 상태 `1`로 파일 부재를 확인했다.

### 원인

`.specify/feature.json`이 항상 존재한다는 잘못된 가정으로 Update File 연산을 사용했다.

### 조치

`.specify/feature.json`을 새 파일로 생성하고, 활성 기능의 `spec.md`와 품질 체크리스트를 별도 생성 patch에 포함했다.

### 검증

- `.specify/scripts/bash/check-prerequisites.sh --json --paths-only`: `FEATURE_DIR`과 `FEATURE_SPEC`가 `specs/013-ui-convention-refactor`를 가리키는 것을 확인했다.
- `git diff --check`: 오류 없이 통과했다.

### 재발 방지

새 Spec Kit 기능을 만들 때는 `.specify/feature.json`의 존재를 먼저 확인하고, 부재하면 Update File 대신 Add File 연산을 사용한다.

### 연결

없음

## TS-20260822-001: Figma page node의 디자인 컨텍스트 조회 실패

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-clarify` Figma 근거 확인
**관련 항목**: `specs/013-ui-convention-refactor/spec.md`, Figma node `86:761`

### 증상

Figma page node `86:761`을 대상으로 `get_design_context`를 실행하자 선택된 layer가 없다는 오류가 발생해 컴포넌트 정보를 바로 읽지 못했다.

### 영향

명세의 Figma section 우선순위와 컴포넌트별 공개 계약을 확인하는 작업이 일시적으로 중단되었다. 제품 코드나 명세 파일의 내용은 이 실패로 변경되지 않았다.

### 근거

- `get_design_context(nodeId: "86:761")`: `You currently have nothing selected. You need to select a layer first before using this tool.` 오류와 Figma Debug UUID `7cf81378-eef8-4563-9a88-19adb0443d47`를 반환했다.
- `get_metadata(nodeId: "86:761")`: page 아래의 `사용한 컴포넌트` node `739:24524`를 포함한 section 구조를 반환했다.

### 원인

디자인 컨텍스트가 필요한 구체 layer가 아니라 page 자체를 첫 조회 대상으로 지정했다. page 수준에서는 선택된 layer가 없어 `get_design_context`가 처리할 대상을 결정하지 못했다.

### 조치

page에는 `get_metadata`를 사용해 section과 하위 컴포넌트 node를 탐색하고, `Button` node `739:27351`과 `SelectCardList` node `585:13689`처럼 구체적인 대상에 `get_design_context`를 다시 실행했다.

### 검증

- `get_design_context(nodeId: "739:27351")`: `Button`의 크기, 스타일과 `Default`·`Pressing`·`Disabled`·`Error` 상태 정보를 반환했다.
- `get_design_context(nodeId: "585:13689")`: `SelectCardList`의 `Default`·`1`…`5` 선택 상태와 카드 속성 정보를 반환했다.

### 재발 방지

Figma page URL을 받으면 먼저 `get_metadata`로 section과 하위 layer ID를 식별하고, 디자인 컨텍스트는 필요한 구체 component 또는 frame node에 요청한다.

### 연결

없음

## TS-20260822-002: 셸 검증 검색식의 backtick 실행 오류

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-clarify` 명세 반영 검증
**관련 항목**: `specs/013-ui-convention-refactor/spec.md`

### 증상

`rg` 검색식을 double quote로 감싼 상태에서 패턴 안의 `` `State` `` 표기를 사용하자 zsh가 backtick을 명령 치환으로 해석해 `zsh:1: command not found: State`를 출력했다.

### 영향

명세 반영 결과를 검색하는 검증 명령 한 번이 의도대로 실행되지 않았다. 앞서 적용한 파일 변경에는 영향이 없었다.

### 근거

- backtick을 포함한 double-quoted `rg` 검색 명령: `zsh:1: command not found: State`를 출력했다.
- `git diff --check -- specs/013-ui-convention-refactor/spec.md`: 명세 파일의 whitespace 오류 없이 성공했다.

### 원인

zsh에서 double quote 안의 backtick도 명령 치환된다는 점을 고려하지 않고 Markdown code span을 포함한 검색식을 구성했다.

### 조치

검색 패턴을 single quote로 감싸거나 backtick이 필요 없는 안정적인 식별자 패턴으로 바꿔 검증을 다시 실행했다.

### 검증

- `rg -n 'FR-012|SC-008|SelectionCardList' specs/013-ui-convention-refactor/spec.md`: 추가한 요구사항과 성공 기준을 정상적으로 찾았다.
- `git diff --check -- specs/013-ui-convention-refactor/spec.md specs/013-ui-convention-refactor/checklists/requirements.md`: 오류 없이 통과했다.

### 재발 방지

셸 검색 패턴에 backtick이나 `$()` 같은 명령 치환 문자가 포함되면 single quote를 사용하고, 가능하면 Markdown 장식 문자를 제외한 식별자로 검색한다.

### 연결

없음

## TS-20260822-003: 미해결 표식 검사에서 완료 문구를 오탐

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-clarify` 최종 명세 품질 검증
**관련 항목**: `specs/013-ui-convention-refactor/spec.md`, `specs/013-ui-convention-refactor/checklists/requirements.md`

### 증상

명세와 체크리스트에서 `[NEEDS CLARIFICATION]` 또는 미체크 항목을 찾는 검증 명령이 체크리스트의 완료 문장인 `- [x] [NEEDS CLARIFICATION] 표식이 남아 있지 않다`를 미해결 표식으로 인식해 종료 상태 `1`을 반환했다.

### 영향

최종 명세 품질 검증이 한 차례 중단되었으나 명세나 체크리스트 내용에는 결함이 없었다.

### 근거

- `rg -n '\[NEEDS CLARIFICATION\]|\[ \]' specs/013-ui-convention-refactor/spec.md specs/013-ui-convention-refactor/checklists/requirements.md`: 완료된 체크리스트의 16번째 줄을 출력한 뒤 검증 절차가 실패했다.
- `rg -c '^- \[x\]' specs/013-ui-convention-refactor/checklists/requirements.md`: 완료 항목 `16`개를 반환했다.

### 원인

미해결 표식이 실제로 존재할 수 있는 명세와 표식 부재를 확인하는 체크리스트 문장을 구분하지 않고 같은 정규식으로 검색했다.

### 조치

`[NEEDS CLARIFICATION]` 검사는 명세 파일로 한정하고, 체크리스트는 줄 시작의 미체크 항목 `- [ ]`만 별도로 검사했다.

### 검증

- `rg -n '\[NEEDS CLARIFICATION(:[^]]*)?\]' specs/013-ui-convention-refactor/spec.md`: 결과가 없어 미해결 표식이 없음을 확인했다.
- `rg -n '^- \[ \]' specs/013-ui-convention-refactor/checklists/requirements.md`: 결과가 없어 미체크 항목이 없음을 확인했다.

### 재발 방지

명세의 명확화 표식과 체크리스트의 완료 상태를 서로 다른 파일·정규식으로 검사하고, 표식 부재를 설명하는 체크리스트 문구 자체는 명확화 표식 검사 대상에서 제외한다.

### 연결

`TS-20260822-002`

## TS-20260822-004: 일반 patch 문맥으로 문제 기록이 파일 중간에 삽입됨

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-troubleshooting` 기록 추가
**관련 항목**: `docs/spec-kit/013-ui-convention-refactor/trouble-shooting.md`, `TS-20260822-003`

### 증상

`TS-20260822-003`을 파일 끝에 추가하려 했으나 patch가 첫 번째 `### 연결`과 `없음` 문맥에 일치해 기존 `TS-20260821-001`과 `TS-20260822-001` 사이에 항목이 삽입되었다.

### 영향

기존 문장은 변경되지 않았지만 신규 항목의 ID 순서와 파일 끝 추가 원칙을 일시적으로 위반해 재배치가 필요했다.

### 근거

- `rg -n '^## TS-' docs/spec-kit/013-ui-convention-refactor/trouble-shooting.md`: `TS-20260821-001`, `TS-20260822-003`, `TS-20260822-001`, `TS-20260822-002` 순서를 반환했다.

### 원인

파일에 반복되는 일반 문맥만 patch anchor로 사용해 첫 번째 일치 지점이 선택되었다.

### 조치

이번 세션에서 새로 작성한 `TS-20260822-003` 블록을 제거한 뒤 `TS-20260822-002`의 고유한 재발 방지 문장과 마지막 연결 절을 anchor로 사용해 파일 끝으로 옮겼다.

### 검증

- `rg -n '^## TS-' docs/spec-kit/013-ui-convention-refactor/trouble-shooting.md`: ID가 `TS-20260821-001`, `TS-20260822-001`, `TS-20260822-002`, `TS-20260822-003`, `TS-20260822-004` 순서로 나타나는지 확인한다.
- `git diff --no-index --check /dev/null docs/spec-kit/013-ui-convention-refactor/trouble-shooting.md`: whitespace 오류가 없는지 확인한다.

### 재발 방지

append-only 문서에는 마지막 항목에만 존재하는 제목이나 문장을 anchor로 사용하고, 적용 직후 전체 항목 제목의 줄 순서를 검사한다.

### 연결

`TS-20260822-003`

## TS-20260822-005: 존재하지 않는 build runner 경로를 조사 대상으로 지정

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-plan` build·test 진입점 조사
**관련 항목**: `specs/013-ui-convention-refactor/quickstart.md`

### 증상

패키지 의존성 검사 위치를 찾는 `rg` 명령에 존재하지 않는 `tools/project-build-runner`를
포함해 `rg: tools/project-build-runner: No such file or directory (os error 2)`가 출력됐다.

### 영향

저장소의 실제 project build runner 명령 목록을 확인하는 조사가 한 차례 불완전하게
실행됐다. 파일 변경에는 영향이 없었다.

### 근거

- `rg ... tools/project-build-runner ...`: 해당 경로가 없다는 오류를 출력했다.
- `./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER`:
  `tools/githooks/project-build/bin/run.sh`를 반환했다.

### 원인

저장소 공용 경로 판독 명령을 먼저 사용하지 않고 build runner의 물리 경로를 추측했다.

### 조치

`GIT_IT_PROJECT_BUILD_RUNNER` 공개 진입점으로 실제 경로를 판독한 뒤 해당 스크립트와
`core/scheme-policy.sh`를 읽어 지원 명령을 확인했다.

### 검증

- `sed -n '1,260p' tools/githooks/project-build/bin/run.sh`: `build`, `compile`, `test`,
  `compile-unit`, `test-unit`, `compile-ui`, `test-ui` 공개 명령을 확인했다.

### 재발 방지

저장소 도구 위치는 디렉터리 이름을 추측하지 않고 `tools/repository-paths`의 공개 key로
먼저 판독한다.

### 연결

없음

## TS-20260822-006: 같은 파일을 한 patch에서 삭제·생성하려 한 계획 작성 실패

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-plan` plan·research 작성
**관련 항목**: `specs/013-ui-convention-refactor/plan.md`, `research.md`

### 증상

계획 템플릿을 완성본으로 교체하면서 같은 patch 안에 `plan.md`의 Delete File과 Add File을
함께 넣자 apply_patch가 중복 대상 연산으로 거부했다.

### 영향

첫 plan·research 생성 patch가 적용되지 않아 문서 작성이 한 차례 중단됐다. 거부 시점에는
기존 계획 템플릿이 그대로 보존됐다.

### 근거

- `apply_patch`: `invalid patch: multiple operations target .../specs/013-ui-convention-refactor/plan.md`
  오류를 반환했다.

### 원인

apply_patch가 한 patch 안에서 같은 경로를 삭제 대상과 추가 대상으로 동시에 허용하지 않는
제약을 고려하지 않았다.

### 조치

기존 템플릿 삭제, 완성된 `plan.md` 추가, `research.md` 추가를 서로 다른 patch로 분리했다.

### 검증

- `find specs/013-ui-convention-refactor -maxdepth 2 -type f`: 완성된 `plan.md`와
  `research.md`가 존재함을 확인했다.
- placeholder 검색: 완성된 계획 산출물에서 템플릿 placeholder가 0건임을 확인했다.

### 재발 방지

같은 파일을 전체 교체할 때는 Update File을 사용하거나 Delete와 Add를 서로 다른 patch로
분리한다.

### 연결

없음

## TS-20260822-007: 전체 diff 검사가 범위 밖 Domain 변경의 공백 오류로 중단됨

**기록일**: 2026-08-22
**상태**: 환경 제약
**발생 단계**: `speckit-plan` 최종 산출물 검증
**관련 항목**: `sources/Projects/Domain/LearningProject/Contracts/LearningProjectRepository.swift`

### 증상

전체 작업 트리 `git diff --check`가 계획 산출물과 무관한 Domain 파일의 trailing whitespace
3건을 보고하고 종료됐다.

### 영향

작업 트리 전체에 대한 whitespace 통과를 이번 계획 세션의 성공 근거로 사용할 수 없다.
계획 산출물과 이번 대화에서 변경된 컨벤션 문서 검증은 별도 범위로 수행해야 했다.

### 근거

- `git diff --check`: `LearningProjectRepository.swift` 6, 11, 15행의 trailing whitespace를
  보고했다.
- `git status --short`: 같은 시점에 `LearningProjectRepository.swift`와
  `ExternalRepositoryLookup.swift`가 수정 상태였다.

### 원인

확인된 직접 원인은 현재 checkout에 계획 범위 밖 Domain 변경과 공백 오류가 함께 존재한
것이다. 해당 변경의 작성자와 목적은 확인하지 않았으며 사용자 변경으로 간주했다.

### 조치

Domain 파일을 수정하지 않고 계획 허용 경로의 untracked 문서는
`git diff --no-index --check`, 이번 대화의 tracked 컨벤션 문서는 경로 제한
`git diff --check -- <paths>`로 검증했다.

### 검증

- 계획 산출물별 `git diff --no-index --check /dev/null <file>`: whitespace 오류 없이 통과했다.
- `git diff --check -- docs/conventions/view.md docs/conventions/ui-component.md`: 오류 없이
  통과했다.
- 전체 `git diff --check`: Domain 변경이 남아 있어 미실행 상태로 전환하지 않았으며
  전체 통과를 주장하지 않는다.

### 재발 방지

Spec Kit 산출물 검증 전에 전체 작업 트리 상태를 확인하고, 범위 밖 사용자 변경의 실패와
현재 스킬 산출물 실패를 분리해 보고한다.

### 연결

없음

## TS-20260822-008: 신규 Markdown 산출물 끝의 빈 줄 검사 실패

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-plan` Phase 1 산출물 검증
**관련 항목**: `specs/013-ui-convention-refactor/data-model.md`,
`contracts/ui-component-public-contracts.md`

### 증상

신규 문서를 `/dev/null`과 비교한 whitespace 검사에서 두 파일의 마지막 내용 뒤에 불필요한
빈 줄이 한 줄씩 있음을 순차적으로 발견했다.

### 영향

내용 의미에는 영향이 없었지만 산출물 whitespace 검증이 두 차례 중단됐다.

### 근거

- `git diff --no-index --check /dev/null specs/013-ui-convention-refactor/data-model.md`:
  `new blank line at EOF`를 보고했다.
- `git diff --no-index --check /dev/null specs/013-ui-convention-refactor/contracts/ui-component-public-contracts.md`:
  `new blank line at EOF`를 보고했다.

### 원인

Add File patch 본문 끝에 내용 종결 개행 외의 빈 줄을 하나 더 포함했다.

### 조치

두 문서의 마지막 빈 줄만 제거하고 마지막 내용 행의 종결 개행은 유지했다.

### 검증

- 두 파일의 `git diff --no-index --check /dev/null <file>`: 출력 없이 통과했다.

### 재발 방지

신규 Markdown을 추가할 때 patch의 마지막 내용 행 뒤에 빈 Markdown 행을 추가하지 않고,
전체 파일을 한 번에 검사해 동일 오류를 함께 수정한다.

### 연결

없음

## TS-20260822-009: 계획 템플릿 중복 파일 생성

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-plan` 계획 템플릿 교체 후 산출물 검증
**관련 항목**: `specs/013-ui-convention-refactor/plan 2.md`, `plan.md`

### 증상

산출물 목록 검사에서 작업 시작 시 없던 `plan 2.md`가 발견됐고, 내용은 미작성
`plan.md` 템플릿과 동일했다.

### 영향

허용된 계획 산출물 이름이 아닌 중복 템플릿이 기능 디렉터리에 남아 placeholder 검사와
후속 산출물 선택을 혼동시킬 수 있었다.

### 근거

- `ls -lT`: `plan 2.md`는 2026-08-22 00:41:35, 완성된 `plan.md`는 00:52:21로 표시됐다.
- `sed -n '1,220p' 'specs/013-ui-convention-refactor/plan 2.md'`: `[FEATURE]`, `[DATE]` 등
  원본 템플릿 placeholder가 남아 있었다.

### 원인

확인 중인 가설: `setup-plan.sh`가 만든 템플릿을 삭제·재생성하는 동안 파일 조정 계층이
원본 템플릿을 중복 이름으로 보존했다. 어떤 프로세스가 이름을 변경했는지는 확인하지 못했다.

### 조치

작업 시작 후 생성됐고 사용자 내용이 없는 원본 템플릿임을 확인한 뒤 `plan 2.md`만
제거하고 완성된 `plan.md`를 보존했다.

### 검증

- `find specs/013-ui-convention-refactor -maxdepth 2 -type f`: `plan 2.md`가 없고
  `plan.md`가 하나만 존재함을 확인한다.
- 계획 산출물 placeholder 검색: 결과 0건인지 확인한다.

### 재발 방지

setup으로 생성한 템플릿을 전체 교체한 직후 기능 디렉터리의 `plan*.md` 목록을 확인하고,
예상하지 않은 파일은 생성 시각·내용·작업 시작 전 목록을 대조한 뒤 처리한다.

### 연결

`TS-20260822-006`
