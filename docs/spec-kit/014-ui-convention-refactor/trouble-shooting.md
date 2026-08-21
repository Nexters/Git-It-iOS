# 014-ui-convention-refactor 문제 해결 기록

**대상 기능**: `014-ui-convention-refactor`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260822-001: feature.json 부재로 초기 명세 패치 중단

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-specify` 기능 디렉터리 생성
**관련 항목**: `.specify/feature.json`, `specs/014-ui-convention-refactor/spec.md`

### 증상

초기 패치가 `.specify/feature.json`을 기존 파일로 갱신하려 했으나 파일이 없어 검증 단계에서 중단됐다. 패치는 원자적으로 실패해 명세와 체크리스트도 부분 생성되지 않았다.

### 영향

활성 기능 경로를 저장하지 못해 명세 생성 절차가 일시 중단됐다. application source와 기존 기능 디렉터리에는 변경이 발생하지 않았다.

### 근거

- `apply_patch`: `Failed to read file to update .../.specify/feature.json: No such file or directory (os error 2)`를 반환했다.
- `.specify/feature.json` 존재 확인: 초기 패치 시점에 파일이 없었다.

### 원인

새 저장소 상태에서는 `.specify/feature.json`이 아직 생성되지 않았는데 기존 파일이라고 가정하고 `Update File` 연산을 사용했다.

### 조치

부분 적용이 없음을 확인한 뒤 동일 내용을 다시 적용하면서 `.specify/feature.json`을 `Add File` 연산으로 생성했다.

### 검증

- `.specify/scripts/bash/check-prerequisites.sh --json --paths-only`: 성공, `FEATURE_DIR`을 `specs/014-ui-convention-refactor`로 판독했다.
- `git diff --check -- specs/014-ui-convention-refactor .specify/feature.json`: 성공, whitespace 오류가 없었다.

### 재발 방지

활성 기능 경로를 저장하기 전에 `.specify/feature.json`의 존재 여부를 확인하고, 존재 여부에 맞춰 생성 또는 갱신 연산을 선택한다.

### 연결

없음

## TS-20260822-002: 지원되지 않는 project-build help action 실행

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-plan` 검증 진입점 조사
**관련 항목**: `tools/githooks/project-build/bin/run.sh`, `specs/014-ui-convention-refactor/quickstart.md`

### 증상

검증 runner의 지원 action을 조사하는 과정에서 `./tools/githooks/project-build/bin/run.sh help`를 실행했고, runner가 unsupported ACTION 오류와 exit 2를 반환했다.

### 영향

읽기 전용 조사 명령 하나가 실패했으나 파일 변경이나 build/test 실행은 발생하지 않았다. 지원 action을 별도 근거로 다시 확인해야 했다.

### 근거

- `./tools/githooks/project-build/bin/run.sh help`: unsupported ACTION, exit 2.
- `tools/githooks/project-build/bin/run.sh:8`: 지원 공개 action을 오류 메시지로 열거한다.

### 원인

runner가 help subcommand를 제공하는지 먼저 source에서 확인하지 않고 일반적인 CLI 관례를 적용했다.

### 조치

runner source와 관련 script tests를 읽어 `build`, `build-app`, `compile`, `test`, `compile-unit`, `test-unit`, `compile-ui`, `test-ui`를 지원 action으로 확인하고 quickstart에는 실제 공개 action만 기록했다.

### 검증

- `rg -n 'compile-ui|test-ui|project-build' tools/githooks/project-build tools/script-tests README.md`: 성공, UI 검증 action과 scheme policy 근거를 확인했다.
- `git status --short`: 실행으로 인한 추가 파일 변경이 없음을 확인했다.

### 재발 방지

프로젝트 소유 CLI의 도움말 지원 여부와 공개 action은 실행 전에 source 또는 README에서 확인한다.

### 연결

없음

## TS-20260822-003: 동일 plan 파일의 Delete와 Add를 한 패치에 지정

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-plan` 산출물 작성
**관련 항목**: `specs/014-ui-convention-refactor/plan.md`

### 증상

계획 템플릿을 완성본으로 교체하는 패치에서 같은 `plan.md`를 `Delete File`과 `Add File` 대상으로 동시에 지정해 patch validation이 실패했다. 부분 적용은 발생하지 않았다.

### 영향

계획 산출물 작성이 한 차례 중단됐으나 기존 template과 다른 파일은 해당 실패로 변경되지 않았다.

### 근거

- `apply_patch`: `invalid patch: multiple operations target .../specs/014-ui-convention-refactor/plan.md`를 반환했다.
- 후속 `find specs/014-ui-convention-refactor -maxdepth 2 -type f`: 복구 뒤 계획 산출물 전체가 존재했다.

### 원인

한 `apply_patch` 호출에서 같은 경로에 복수 연산을 적용할 수 없다는 도구 제약을 위반했다.

### 조치

`plan.md` 삭제와 완성본 추가를 별도 patch 호출로 분리하고, 나머지 설계 산출물을 허용 경로에 생성했다.

### 검증

- `git diff --check -- specs/014-ui-convention-refactor`: 성공, whitespace 오류가 없었다.
- unresolved placeholder 검색: template placeholder는 0건이며 `NEEDS CLARIFICATION`은 해결 완료를 설명하는 문장에만 존재했다.

### 재발 방지

파일 전체 교체가 필요하면 단일 `Update File` 연산을 사용하거나 삭제와 추가를 별도 호출로 분리한다.

### 연결

없음
