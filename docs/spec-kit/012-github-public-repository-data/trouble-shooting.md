# 012-github-public-repository-data 문제 해결 기록

**대상 기능**: `012-github-public-repository-data`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260821-001: 계획 교체 패치와 문서 루트 검증 실패

**기록일**: 2026-08-21
**상태**: 해결
**발생 단계**: `speckit-plan` 산출물 작성 및 `speckit-troubleshooting` 대상 경로 확인
**관련 항목**: `specs/012-github-public-repository-data/plan.md`

### 증상

`plan.md`를 한 patch에서 삭제한 뒤 같은 경로에 다시 추가하려 하자 `apply_patch`가
`multiple operations target .../plan.md` 검증 오류로 전체 patch를 거부했다. 이후
`GIT_IT_DOCS_ROOT` 판독값 `docs`를 절대경로만 허용하는 검사식으로 확인해
`DOCS_ROOT_OUTSIDE_REPOSITORY`로 잘못 판정했다.

### 영향

첫 실패에서는 계획 산출물 쓰기가 시작되지 않았고, 두 번째 실패에서는 문제 해결 기록 대상
경로 확인이 중단됐다. source, test와 기존 Spec Kit 문서는 두 실패로 변경되지 않았다.

### 근거

- `apply_patch`: `invalid patch: multiple operations target .../plan.md`를 반환했다.
- `git status --short`와 `sed -n '1,24p' .../plan.md`: 첫 실패 뒤 template 내용이 그대로였고
  새 설계 산출물은 없었다.
- `./tools/repository-paths/bin/repository-paths.sh GIT_IT_DOCS_ROOT`: 상대경로 `docs`를 반환했다.
- 저장소 루트와 결합한 경로 검사: 실제 문서 루트가 저장소 내부의
  `/Users/jerry/Codex-Workspace/라이브러리/Git-It-iOS/docs`임을 확인했다.

### 원인

첫 실패의 확정 원인은 한 patch 안에서 동일 파일에 `Delete File`과 `Add File`을 함께 지정한
것이다. 두 번째 실패의 확정 원인은 repository path helper가 상대경로를 반환할 수 있다는
계약을 고려하지 않고 절대경로 형식만 허용한 검사식이다.

### 조치

`plan.md` 삭제와 재생성을 별도 `apply_patch` 호출로 나눈 뒤 나머지 산출물을 추가했다. 문서
루트는 절대경로이면 그대로 사용하고 상대경로이면 저장소 루트와 결합한 뒤, 존재 여부와 저장소
내부 경로 여부를 검증하도록 확인 절차를 교정했다.

### 검증

- `sed -n '1,24p' specs/012-github-public-repository-data/plan.md`: 재생성 전 template 보존을
  확인한 뒤 분리 patch로 계획 본문 작성에 성공했다.
- 교정된 문서 루트 검사: `DOCS_ROOT_ABSOLUTE=.../Git-It-iOS/docs`와 디렉터리 존재를 확인했다.
- 계획 산출물 전체 Markdown·허용 경로 검증: 후속 최종 검사에서 확인한다.

### 재발 방지

동일 파일을 교체할 때 한 patch에 삭제·추가 연산을 중복 지정하지 않고, 기존 파일이면
`Update File`을 사용하거나 삭제와 추가를 별도 호출로 나눈다. repository path helper 결과는
절대경로라고 가정하지 않고 저장소 루트 기준으로 정규화한 뒤 범위를 판정한다.

### 연결

없음

## TS-20260821-010: PyYAML 부재 시 수동 스킬 검증 완료

**기록일**: 2026-08-21
**상태**: 완화
**발생 단계**: `skill-creator` 포맷 스킬 변경 검증
**관련 항목**: TS-20260821-009, `.agents/skills/speckit-swift-format-run/SKILL.md`

### 증상

TS-20260821-009의 공식 `quick_validate.py`는 계속 실행할 수 없었지만, 저장소에 이미 있는
도구로 스킬과 확장 문서의 구조·연결을 검증할 수 있었다.

### 영향

공식 검증기의 frontmatter·이름 검사는 미실행 상태로 남았다. YAML 구문, 확장 manifest와
registry 연결, Spec Kit 포맷 훅 회귀는 대체 검증으로 확인했다.

### 근거

- Ruby YAML parser가 스킬, 확장 명령, 확장 manifest와 `.specify/extensions.yml`을 모두
  오류 없이 읽었다.
- 확장 manifest SHA-256과 `.specify/extensions/.registry`의 `manifest_hash`가 일치했다.
- `tools/githooks/swift-format/tests/test-speckit-hook.sh`가 성공했다.

### 원인

TS-20260821-009의 PyYAML 부재는 유지된다. 추가 제품 코드 또는 프로젝트 스크립트 결함은
관찰되지 않았다.

### 조치

YAML parsing, registry hash 비교, 남은 구문 검색, `git diff --check`와 전용 회귀 테스트를
공식 검증기의 대체 검증으로 실행했다.

### 검증

- Ruby YAML parsing: 성공했다.
- registry manifest hash 비교: `REGISTRY_HASH_OK`를 확인했다.
- `test-speckit-hook.sh`: `PASS: speckit swift-format hook`을 확인했다.
- `git diff --check`: 성공했다.

### 재발 방지

공식 스킬 검증기 실행 환경에 PyYAML이 없을 때는 검증기 미실행을 명시하고 YAML 구문,
manifest hash와 저장소 전용 회귀를 독립적으로 확인한다.

### 연결

TS-20260821-009

## TS-20260821-002: zsh 파일 목록 검증의 잘못된 누락 판정

**기록일**: 2026-08-21
**상태**: 해결
**발생 단계**: `speckit-plan` 최종 산출물 검증
**관련 항목**: `specs/012-github-public-repository-data/{plan.md,research.md,data-model.md,quickstart.md,contracts/**}`

### 증상

필수 파일 경로를 공백으로 구분한 단일 scalar 변수에 저장한 뒤 `for`로 순회하자 zsh가 값을
자동 분할하지 않았다. 검사식은 전체 문자열을 하나의 파일 경로로 취급해
`MISSING_OR_EMPTY=<전체 목록>`을 출력했다.

### 영향

실제 산출물이 존재하는데도 누락된 것으로 잘못 판정해 최종 검증이 한 차례 중단됐다. 산출물
내용과 Git index는 변경되지 않았다.

### 근거

- 최초 검증 출력: `MISSING_OR_EMPTY=` 뒤에 여섯 경로가 하나의 문자열로 이어졌다.
- 배열 기반 재검증 출력: `REQUIRED_ARTIFACTS_PRESENT`, `NO_UNRESOLVED_PLACEHOLDERS`,
  `DIFF_CHECK_PASSED`를 모두 확인했다.
- 배열 기반 `wc -l`: 필수 여섯 파일이 모두 0보다 큰 줄 수를 반환했다.

### 원인

확정 원인은 zsh의 기본 scalar 확장에 POSIX sh식 암시적 공백 분할이 적용된다고 잘못 가정한
것이다.

### 조치

필수 경로를 zsh 배열로 선언하고 `for required_file in "${required_files[@]}"`로 각 원소를
독립적으로 검사했다.

### 검증

- 교정된 최종 검사: 필수 산출물 존재, 미해결 placeholder 부재, `git diff --check` 통과를
  확인했다.
- `.specify/extensions.yml` 검사: `after_plan` 훅이 없음을 확인했다.

### 재발 방지

zsh에서 여러 경로를 반복 처리할 때 scalar의 암시적 분할에 의존하지 않고 배열과 quoted
expansion을 사용한다.

### 연결

TS-20260821-001

## TS-20260821-005: 최종 placeholder 검사 범위 오탐 재발

**기록일**: 2026-08-21
**상태**: 해결
**발생 단계**: 개선 산출물 최종 정합성 검증
**관련 항목**: `specs/012-github-public-repository-data/checklists/requirements.md`,
`docs/spec-kit/012-github-public-repository-data/trouble-shooting.md`, TS-20260821-003

### 증상

최종 placeholder 검사에서 체크리스트의 정상 문장 `[NEEDS CLARIFICATION] 표식이 남아 있지
않다`와 기존 troubleshooting 기록에 증거로 인용된 `[FEATURE NAME]`, `TXXX`,
`NEXT APPLICABLE PACKAGE`가 검색되어 검사가 실패했다.

### 영향

활성 spec·plan·tasks에는 미해결 표식이 없었지만 검증 대상에 체크리스트와 이력 문서를 함께
넣어 최종 검사가 한 차례 중단됐다. 산출물과 Git index는 변경되지 않았다.

### 근거

- 최초 검사 출력: `requirements.md:16`, `trouble-shooting.md:148-149`를 일치 항목으로
  반환했다.
- 교정된 검사 출력: `NO_UNRESOLVED_PLACEHOLDERS`, `NO_TRAILING_WHITESPACE`,
  `TASK_IDS_SEQUENTIAL`, `REMEDIATION_TRACE_OK`, `DIFF_CHECK_OK`를 확인했다.

### 원인

확정 원인은 TS-20260821-003의 재발로, 미해결 표식이 존재할 수 없는 이력 문서까지 활성 산출물
placeholder 검사에 포함하고 `[NEEDS CLARIFICATION:]` 대신 정상 체크리스트 문구까지 매칭하는
넓은 패턴을 사용한 것이다.

### 조치

placeholder 검사는 활성 `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/**`,
`quickstart.md`, `tasks.md`로 제한하고 명확화 표식은 콜론이 포함된
`NEEDS CLARIFICATION:` 구문만 검사했다. 체크리스트와 troubleshooting 기록은 후행 공백 검사만
별도로 수행했다.

### 검증

- 교정된 placeholder 검사: 미해결 표식 없음.
- task 검사: T001~T022 순차 ID, 22개 checklist line, 9개 병렬 작업을 확인했다.
- 전체 문서 후행 공백 검사와 `git diff --check`: 성공했다.

### 재발 방지

placeholder 검사는 생성 이력이나 품질 체크 문구가 아닌 활성 실행 산출물에만 적용하고, 실제
미해결 delimiter를 포함한 고정 구문으로 제한한다.

### 연결

TS-20260821-003

## TS-20260821-003: tasks placeholder 검사 정규식의 정상 문장 오탐

**기록일**: 2026-08-21
**상태**: 해결
**발생 단계**: `speckit-tasks` 최종 형식 검증
**관련 항목**: `specs/012-github-public-repository-data/tasks.md`

### 증상

tasks template placeholder 잔존 여부를 확인한 정규식의 `정확한 .* 경로` 패턴이 실제 작업
설명과 참고 문장에 포함된 “정확한 allowlist 경로”, “정확한 repository-relative 파일 경로”를
매칭해 `UNRESOLVED_PLACEHOLDER_FOUND`로 판정했다.

### 영향

작업 목록의 정상 문장을 template placeholder로 잘못 분류해 최종 검증이 한 차례 중단됐다.
`tasks.md` 내용과 Git index는 이 오탐으로 변경되지 않았다.

### 근거

- 최초 검사 출력: `tasks.md:71`, `tasks.md:169`의 완성된 정상 문장을 출력한 뒤
  `UNRESOLVED_PLACEHOLDER_FOUND`로 종료했다.
- 같은 실행에서 task 19개, T001~T019 순차 ID, checklist 형식 19개, 변경 작업 경로 존재,
  S1 2개·S2 2개·S3 4개를 먼저 통과했다.
- 교정된 검사: 실제 template 표식만 검사해 `NO_UNRESOLVED_PLACEHOLDERS`,
  `NO_TRAILING_WHITESPACE`, `NO_SESSION_RECORD_TASKS`, `NO_AFTER_TASKS_HOOK`을 확인했다.

### 원인

확정 원인은 placeholder의 고정 구문이 아니라 일반적인 한국어 표현까지 허용하는 넓은 정규식을
사용한 것이다.

### 조치

검사 대상을 `[FEATURE NAME]`, `[###-feature-name]`, `TXXX`,
`NEXT APPLICABLE PACKAGE`, `[정확한`처럼 template에 실제로 남을 수 있는 고정 표식으로
좁혔다.

### 검증

- 교정된 placeholder 검사: 미해결 표식 없음.
- task 형식 검사: 19개 ID가 순차적이고 모든 checkbox line이 요구 형식을 충족함.
- 세션 기록 작업 검사: troubleshooting·tacit-knowledge 생성 또는 수정 task 없음.

### 재발 방지

생성 문서의 placeholder 검사는 자연어 의미를 추측하는 포괄 패턴 대신 template의 고정
delimiter와 literal token만 대상으로 한다.

### 연결

TS-20260821-001, TS-20260821-002

## TS-20260821-006: 임시 상태 파일 정리 명령이 실행 정책에서 거부됨

**기록일**: 2026-08-21
**상태**: 완화
**발생 단계**: `speckit-implement` T006 포맷 전후 상태 비교
**관련 항목**: `specs/012-github-public-repository-data/tasks.md` T006

### 증상

포맷 전후 `git status`를 임시 파일에 저장하고 끝에서 `rm -f`로 정리하는 검증 명령이 실행 정책에서 거부되어 포맷과 상태 비교가 시작되지 않았다.

### 영향

T006이 한 차례 중단됐으며, 테스트 파일 포맷과 Git 상태 비교 결과는 아직 확인되지 않았다. source와 test 파일은 이 거부로 변경되지 않았다.

### 근거

- `exec_command`: `rm -f style commands are not permitted. Use a safer approach`를 반환했다.
- 거부된 명령: `GIT_IT_SWIFT_FORMAT_RUNNER` 실행 전에 명령 전체가 거부됐다.

### 원인

확정 원인은 검증용 임시 파일을 정리하는 `rm -f` 구문이 현재 실행 정책의 허용 범위를 벗어난 것이다.

### 조치

임시 파일을 만들거나 삭제하지 않고, 포맷 대상과 허용된 변경 경로를 `git status` 및 `git diff --name-only`로 직접 비교하는 방식으로 검증 절차를 변경한다.

### 검증

- 교정된 T006 명령: 미실행.

### 재발 방지

검증 명령은 명시적인 파일 삭제 없이 실행할 수 있는 비교 방식을 우선 사용한다.

### 연결

없음

## TS-20260821-007: Red 검증 시작 전 GitIt.xcworkspace 부재

**기록일**: 2026-08-21
**상태**: 환경 제약
**발생 단계**: `speckit-implement` T007 Red 확인
**관련 항목**: `specs/012-github-public-repository-data/tasks.md` T007

### 증상

T007의 `xcodebuild build-for-testing -workspace GitIt.xcworkspace`가 production 선언 부재를 컴파일하기 전에 `GitIt.xcworkspace does not exist`로 종료됐다.

### 영향

테스트 Red 상태가 production 선언 부재만으로 발생하는지는 아직 확인하지 못했다. source와 test 파일은 이 실행으로 변경되지 않았다.

### 근거

- `xcodebuild build-for-testing -workspace GitIt.xcworkspace -scheme Data ...`: `xcodebuild: error: 'GitIt.xcworkspace' does not exist.`를 반환했다.

### 원인

확정 원인은 현재 checkout에 Tuist가 생성하는 루트 workspace가 아직 없다는 것이다.

### 조치

저장소 셋업 지침에 따라 `make tuist`로 workspace를 생성한 뒤 같은 T007 명령을 재실행한다.

### 검증

- `make tuist`: 미실행.
- T007 재실행: 미실행.

### 재발 방지

xcodebuild 기반 검증 전에 루트 `GitIt.xcworkspace` 존재 여부를 먼저 확인하고, 없으면 Tuist 생성을 선행한다.

### 연결

없음

## TS-20260821-008: placeholder 삭제 후 생성 workspace의 입력 목록 불일치

**기록일**: 2026-08-21
**상태**: 환경 제약
**발생 단계**: `speckit-implement` T016 Data build-for-testing
**관련 항목**: `specs/012-github-public-repository-data/tasks.md` T012, T016

### 증상

`DataLearningProjectPlaceholder.swift`를 T012에서 삭제한 뒤 T016을 실행하자, 생성된 Data project가 삭제 전 입력 목록을 유지해 해당 파일을 찾지 못했다.

### 영향

production 계약과 테스트의 컴파일 결과를 아직 판정할 수 없다. 실패 원인은 Swift 코드 진단이 아니라 stale generated workspace 입력 경로다.

### 근거

- `xcodebuild build-for-testing -workspace GitIt.xcworkspace -scheme Data ...`: `Build input file cannot be found: .../DataLearningProjectPlaceholder.swift`를 반환했다.
- `sources/Projects/Data/LearningProject/DataLearningProjectPlaceholder.swift`: T012에 따라 삭제되어 존재하지 않는다.

### 원인

확정 원인은 소스 파일 추가·삭제 후 `tuist generate`를 다시 실행하지 않아 생성 Xcode project가 이전 파일 목록을 참조한 것이다.

### 조치

`sources`에서 `tuist generate`로 workspace를 재생성한 뒤 T016과 T017을 같은 DerivedData 경로에서 순서대로 재실행한다.

### 검증

- `tuist generate`: 미실행.
- T016 재실행: 미실행.
- T017 재실행: 미실행.

### 재발 방지

target source root 안의 파일을 추가하거나 삭제한 뒤 Xcode build 전에 `tuist generate`를 실행해 생성 project의 입력 목록을 최신화한다.

### 연결

TS-20260821-007

## TS-20260821-004: tasks 재생성 patch의 동일 경로 다중 작업 재발

**기록일**: 2026-08-21
**상태**: 해결
**발생 단계**: `speckit-tasks` 개선 작업 목록 재생성
**관련 항목**: `specs/012-github-public-repository-data/tasks.md`, TS-20260821-001

### 증상

기존 `tasks.md`를 한 patch에서 삭제한 뒤 같은 경로에 다시 추가하려 하자 `apply_patch`가
`multiple operations target .../tasks.md` 검증 오류로 전체 patch를 거부했다.

### 영향

개선된 작업 목록 교체가 한 차례 중단됐다. 실패한 patch는 원자적으로 거부되어 기존
`tasks.md`와 Git index는 변경되지 않았다.

### 근거

- 최초 `apply_patch`: `invalid patch: multiple operations target .../tasks.md`를 반환했다.
- 분리된 삭제와 추가 `apply_patch`: 두 호출이 모두 성공했다.
- 재생성 후 검사: `SEQUENTIAL_IDS_OK`, `TASKS=22`, `PARALLEL=9`, `S1=2`, `S2=2`,
  `S3=4`를 확인했다.

### 원인

확정 원인은 TS-20260821-001과 동일하게 `apply_patch` 한 요청에서 같은 경로에 Delete와 Add
작업을 함께 지정한 것이다.

### 조치

기존 `tasks.md` 삭제와 개선본 추가를 별도 `apply_patch` 호출로 분리했다.

### 검증

- task ID 검사: T001~T022가 중복과 누락 없이 순차적이었다.
- checklist 형식 검사: 22개 task가 모두 `- [ ] T###` 형식이었다.
- `git diff --check -- specs/012-github-public-repository-data/tasks.md`: 성공했다.

### 재발 방지

기존 파일을 전체 교체할 때 동일 patch에서 같은 경로에 Delete와 Add를 함께 지정하지 않는다.
가능하면 Update patch를 사용하고, 전체 재생성이 필요하면 삭제와 추가를 별도 호출로 실행한다.

### 연결

TS-20260821-001

## TS-20260821-006: TS-005 항목의 append-only 위치 위반

**기록일**: 2026-08-21
**상태**: 완화
**발생 단계**: `speckit-troubleshooting` TS-005 기록
**관련 항목**: `docs/spec-kit/012-github-public-repository-data/trouble-shooting.md`,
TS-20260821-005

### 증상

TS-005를 추가한 Update patch가 파일 끝의 고유 문맥이 아니라 먼저 발견된
`### 연결`과 `TS-20260821-001` 문맥에 적용되어 TS-002와 TS-003 사이에 항목을 삽입했다.

### 영향

기존 문장 자체는 삭제·수정되지 않았지만 새 항목이 파일 끝에 추가되어야 한다는 append-only
순서 규칙을 위반했다. 현재 ID 표시 순서는 001, 002, 005, 003, 004, 006이다.

### 근거

- `rg -n '^## TS-'`: TS-005가 114행, TS-003이 168행, TS-004가 221행에 있음을 확인했다.
- TS-005 추가 patch의 context는 `### 연결`과 `TS-20260821-001`뿐이어서 파일 안에서 고유하지
  않았다.

### 원인

확정 원인은 append 위치를 지정할 때 파일 끝의 고유한 직전 항목 문맥을 사용하지 않은 것이다.

### 조치

기존 기록의 byte와 현재 순서를 더 변경하지 않고 이 후속 항목을 실제 파일 끝에 추가했다.
TS-005의 내용은 유효하므로 중복 복사하지 않았다.

### 검증

- TS-006 추가 후 기존 TS-001~TS-005의 본문이 유지됨을 제목과 관련 근거로 확인했다.
- ID 순서 자체는 append-only 원칙상 교정하지 않았으므로 현재도 비순차 상태다.

### 재발 방지

append-only 기록은 `tail`로 마지막 항목의 고유 문맥을 확인하고, 제목·재발 방지 문장·연결을
함께 anchor로 사용한 patch만 적용한다. 적용 직후 `rg -n '^## TS-'`로 새 ID가 마지막인지
검증한다.

### 연결

TS-20260821-005

## TS-20260821-009: 스킬 검증기의 PyYAML 의존성 부재

**기록일**: 2026-08-21
**상태**: 환경 제약
**발생 단계**: `skill-creator` 포맷 스킬 변경 검증
**관련 항목**: `.agents/skills/speckit-swift-format-run/SKILL.md`

### 증상

`skill-creator`의 `quick_validate.py`를 시스템 Python과 Codex 번들 Python으로 각각 실행했지만
두 실행 모두 `yaml` 모듈을 import하지 못해 검증기가 시작되지 않았다.

### 영향

스킬 frontmatter와 이름을 공식 검증기로 확인할 수 없었다. 포맷 대상 필터 제거 문서 변경과
애플리케이션 소스에는 이 실패로 인한 추가 변경이 발생하지 않았다.

### 근거

- `python3 .../skill-creator/scripts/quick_validate.py .../speckit-swift-format-run`:
  `ModuleNotFoundError: No module named 'yaml'`을 반환했다.
- Codex 번들 `python3`로 실행한 동일 명령도 같은 오류를 반환했다.

### 원인

확정 원인은 두 Python 실행 환경에 `quick_validate.py`가 요구하는 PyYAML 패키지가 설치되어
있지 않은 것이다.

### 조치

외부 패키지를 설치해 환경을 변경하지 않고 YAML frontmatter 필수 필드, 남은 구문 참조,
Constitution 버전·날짜와 변경 diff를 저장소 명령으로 직접 검사했다.

### 검증

- `quick_validate.py`: 환경 의존성 부재로 실패했다.
- 수동 구조·일관성 검사: 성공 여부를 후속 검증에서 확인한다.

### 재발 방지

스킬 검증 전에 실행할 Python 환경에서 `import yaml` 성공 여부를 확인한다. 의존성이 없으면
환경 변경 권한을 확인한 뒤 설치하거나, 공식 검증 미실행 범위와 수동 검증 근거를 구분해
보고한다.

### 연결

없음

## TS-20260821-011: TS-010 후속 기록의 append 위치 위반

**기록일**: 2026-08-21
**상태**: 완화
**발생 단계**: `speckit-troubleshooting` TS-010 기록
**관련 항목**: TS-20260821-006, TS-20260821-009, TS-20260821-010

### 증상

TS-010을 추가한 Update patch가 파일 끝의 TS-009가 아니라 먼저 발견된 `### 연결`과 `없음`
문맥에 적용되어 TS-001과 TS-002 사이에 항목을 삽입했다.

### 영향

기존 문장은 삭제되거나 수정되지 않았지만 TS-010이 파일 끝에 추가되어야 한다는 append-only
순서 규칙을 위반했다. TS-010의 수동 검증 결과 자체는 유효하다.

### 근거

- `rg -n '^## TS-20260821-'`: TS-010이 64행, TS-009가 489행에 있음을 확인했다.
- TS-010 추가 patch는 문서 안에서 반복되는 `### 연결`과 `없음`만 anchor로 사용했다.

### 원인

확정 원인은 TS-20260821-006에 이미 기록된 비고유 append 문맥 사용을 다시 반복한 것이다.

### 조치

기존 기록과 TS-010의 위치를 변경하지 않고, TS-009의 고유한 재발 방지 문장과 연결 문맥을
anchor로 사용해 이 후속 항목을 실제 파일 끝에 추가했다.

### 검증

- `rg -n '^## TS-20260821-'`: TS-011이 마지막 항목인지 확인한다.
- 변경 대상 파일에 한정한 `git diff --check`: 확인한다.

### 재발 방지

append-only patch는 직전 마지막 항목의 제목 또는 고유 본문을 반드시 anchor에 포함하고,
반복 가능한 소제목과 값만으로 위치를 지정하지 않는다.

### 연결

TS-20260821-006, TS-20260821-010
