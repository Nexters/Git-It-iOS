# 작업 목록: GitHub CI 및 프리커밋 검증 개선

**입력**: `/specs/009-ci-precommit-optimization/`의 설계 문서

**선행 조건**: plan.md(필수), spec.md(변경 시나리오에 필수), research.md, quickstart.md

**테스트**: 기능 명세에서 셸 regression test와 CI 동작 검증을 요구하므로 검증 작업을 포함한다.

**구성**: 본 기능은 iOS 앱 패키지 소스를 변경하지 않는다. 변경 대상은 CI
workflow(`.github/`), 셸 스크립트(`tools/`), Tuist 프로젝트 설정(`sources/Tuist/`)이다.
Constitution 원칙 7의 패키지 순서 적용 대상이 아니므로 plan.md에서 정의한 단계별
경계(A~F)를 작업 패키지로 사용한다. 각 단계는 독립적으로 롤백 가능하며 순서대로
실행한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 단계 안에서 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: 작업이 지원하는 변경 시나리오(S1~S10)
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행 또는 수동 검증

## 작업 패키지 A: 변경 분류 및 gate 도입

**목표**: PR 변경 파일을 분류해 후속 CI job의 실행 조건을 결정하고, 항상 실행되는
단일 `CI / gate` job으로 차단 job 결과를 종합한다.

**소유 경로**: `tools/ci/`, `.github/workflows/ci.yml`,
`tools/script-verification/config/verification.conf`

**관련 변경 시나리오**: S1, S2, S5, S6

**독립 검증**: 문서 전용/셸 전용/Swift 전용/혼합 변경 PR에서 분류 결과가 올바르고
gate가 차단/비차단 정책을 정확히 반영하는지 확인한다.

### 준비와 기반

- [x] T001 [S1] [S2] `tools/ci/bin/classify-changes.sh`, `tools/ci/core/change-policy.sh`, `tools/ci/tests/test-classify-changes.sh` 신규 생성 — PR base↔head 사이 변경 파일을 NUL 경계로 분석해 `docs_only`, `scripts_changed`, `swift_changed`, `ui_changed`, `project_config_changed`, `workflow_changed`, `tests_changed` 7개 플래그를 `$GITHUB_OUTPUT`에 출력하고 `$GITHUB_STEP_SUMMARY`에 분류 결과 테이블을 표시한다. 한글·개행 경로, App/UI 리소스와 미분류 비문서 입력을 회귀로 고정한다. base SHA fetch 실패 시 종료 코드 1. `project_config_changed`와 미분류 비문서 입력은 하위 검사를 보수적으로 포함한다.
- [x] T002 [P] [S2] `tools/ci/bin/gate-evaluate.sh`, `tools/ci/core/gate-policy.sh`, `tools/ci/tests/test-gate-evaluate.sh` 신규 생성 — 변경 분류기를 포함한 차단 job 결과를 인자로 받아 최종 pass/fail을 결정한다. `skipped` → pass, `success` → pass, `failure`/`cancelled` → fail. `swift-lint` 결과는 평가에서 제외하고 `$GITHUB_STEP_SUMMARY`에 실행·생략·실패 job 테이블을 출력한다.

### 구현

- [x] T003 [S1] [S2] [S5] [S6] `.github/workflows/ci.yml` 수정 — 단일 `build-and-test` job을 역할별 job으로 분리하고 변경 분류기 및 gate를 추가:
  - `changes` job (ubuntu-latest, 항상 실행): `classify-changes.sh` 호출, 7개 output 설정
  - `script-quality` job (조건부 macOS): `scripts_changed` 시 실행 (T016에서 상세 구현)
  - `swift-lint` job (조건부 macOS, `continue-on-error: true`): `swift_changed` 시 실행
  - `app-build` job (조건부 macOS): `swift_changed || project_config_changed` 시 실행
  - `unit-tests` job (조건부 macOS): `swift_changed || tests_changed || project_config_changed` 시 실행
  - `ui-tests` job (조건부 macOS): `ui_changed` 시 실행
  - `gate` job (ubuntu-latest, `if: always()`): `gate-evaluate.sh` 호출
  - 기존 `concurrency`, `permissions: contents: read`, job별 `timeout-minutes` 유지
  - 제3자 Action은 full commit SHA로 고정

### 정리와 단계 검증

- [x] T004 [no-write] `/bin/sh tools/ci/tests/test-classify-changes.sh`와 `tools/script-verification/bin/run.sh`로 분류 회귀·ShellCheck·shfmt 검사를 실행한다
- [x] T005 [no-write] `/bin/sh tools/ci/tests/test-gate-evaluate.sh`와 `tools/script-verification/bin/run.sh`로 gate 회귀·ShellCheck·shfmt 검사를 실행한다
- [x] T006 [no-write] 기존 `tools/script-tests/bin/run.sh`를 실행해 셸 regression test를 통과하는지 확인한다

**승인 게이트**: T001~T006의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 다음
단계를 명시적으로 승인하기 전에는 단계 B 파일을 변경하지 않는다.

---

## 작업 패키지 B: 프리커밋 확장

**목표**: 프리커밋에 `staged-sanity`(공백 오류, conflict marker, 금지 산출물),
`script-verification`(staged 셸 정적 검증) 단계를 추가하고 기존 dispatcher를 확장한다.

**소유 경로**: `tools/githooks/pre-commit`, `tools/githooks/pre-commit.d/`

**관련 변경 시나리오**: S3, S4

**독립 검증**: staged 파일에 공백 오류, conflict marker, ShellCheck 위반이 있을 때
프리커밋이 차단하고, 관련 파일이 없을 때 빠르게 성공하며, p95 30초 이내인지 확인한다.

### 준비와 기반

- [ ] T007 [S4] `tools/githooks/pre-commit.d/staged-sanity.sh` 신규 생성 — staged diff 기본 검사 POSIX sh 스크립트. `git diff --cached --check` 실행, `<<<<<<<` conflict marker 검사, `DerivedData/` `*.xcodeproj/` `*.xcworkspace/` staged 여부 검사. staged 파일이 없으면 즉시 성공 종료

### 구현

- [ ] T008 [P] [S3] `tools/githooks/pre-commit.d/script-verification.sh` 신규 생성 — staged `.sh` 파일 목록을 추출하고, 대상이 없으면 즉시 성공 종료, 대상이 있으면 `tools/script-verification` 인프라를 호출해 staged 대상만 ShellCheck/shfmt 검사. 실패 시 대상 파일과 조치 방법을 출력
- [ ] T009 [S3] [S4] `tools/githooks/pre-commit` 수정 — 허용 목록(38~44행 case문)에 `staged-sanity`와 `script-verification`을 추가하고, 고정 실행 순서(52행 for문)를 `staged-sanity → script-verification → script-tests → swift-format → build → compile → test`로 변경
- [ ] T010 [S3] [S4] `tools/githooks/pre-commit.d/enabled` 수정 — `script-tests` 앞에 `staged-sanity`와 `script-verification`을 활성화 추가

### 정리와 단계 검증

- [ ] T011 [no-write] 신규 스크립트에 대해 ShellCheck/shfmt 검사를 실행한다
- [ ] T012 [no-write] 기존 `tools/script-tests/bin/run.sh`를 실행해 셸 regression test를 통과하는지 확인한다
- [ ] T013 [no-write] 로컬에서 staged 공백 오류/conflict marker/ShellCheck 위반 파일로 프리커밋을 테스트해 차단이 동작하는지 확인한다

**승인 게이트**: T007~T013의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 다음
단계를 명시적으로 승인하기 전에는 단계 C 파일을 변경하지 않는다.

---

## 작업 패키지 C: Swift lint 배치화

**목표**: Swift-Style wrapper의 파일별 개별 도구 호출을 NUL 구분 batch 전달로
변경해 lint 실행시간을 단축한다.

**소유 경로**: `tools/githooks/swift-format/`

**관련 변경 시나리오**: S5

**독립 검증**: 다양한 파일 수(1개, ≤100개, >100개)에서 batch 분할이 올바르고 공백
경로, 삭제 파일 제외, Derived 제외가 정상 처리되며, staged 모드의 backup/rollback
계약이 유지되는지 확인한다.

### 구현

- [ ] T014 [S5] `tools/githooks/swift-format/core/style-adapter.sh` 수정 — `style_adapter_format_batch()` 함수 추가. NUL 구분 파일 목록을 `GIT_IT_LINT_BATCH_SIZE` (기본 100) 단위로 분할해 도구를 호출. 기존 `style_adapter_format_one()` 유지 (staged 모드 호환). Derived/`.build` 제외 로직 유지
- [ ] T015 [S5] `tools/githooks/swift-format/bin/run.sh` 수정 — `lint` 모드에서 `xargs -0 -n 1 style_adapter_format_one` 대신 batch adapter 호출. `staged` 모드는 기존 파일별 호출과 backup/rollback 계약 유지. `format` 모드도 batch 전환

### 정리와 단계 검증

- [ ] T016 [no-write] 수정된 스크립트에 대해 ShellCheck/shfmt 검사를 실행한다
- [ ] T017 [no-write] 기존 `tools/script-tests/bin/run.sh`를 실행해 셸 regression test를 통과하는지 확인한다
- [ ] T018 [no-write] 다양한 파일 수와 경로 조건에서 batch lint가 기존 lint와 동일한 결과를 생성하는지 확인한다

**승인 게이트**: T014~T018의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 다음
단계를 명시적으로 승인하기 전에는 단계 D 파일을 변경하지 않는다.

---

## 작업 패키지 D: Xcode 빌드·테스트 구조 개편

**목표**: `-jobs 1` 하드코딩을 환경변수로 제어하고, CI 전용 aggregate unit test
scheme을 추가하며, UI test를 별도 CI job으로 분리한다.

**소유 경로**: `tools/githooks/project-build/core/xcodebuild.sh`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`,
`.github/workflows/ci.yml`

**관련 변경 시나리오**: S6, S7, S8, S9

**독립 검증**: `GIT_IT_XCODE_JOBS`로 빌드 병렬도가 제어되고, aggregate scheme이
UI test를 제외한 모든 unit test target을 포함하며, CI에서 build-for-testing →
test-without-building 흐름이 동작하는지 확인한다.

### 준비와 기반

- [ ] T019 [S9] `tools/githooks/project-build/core/xcodebuild.sh` 수정 — 62행의 `-jobs 1`을 `-jobs "${GIT_IT_XCODE_JOBS:-1}"`로 변경. 함수 시작부에 `GIT_IT_XCODE_JOBS` 값 검증 추가: 양의 정수(1~32)만 허용, 잘못된 값 시 `오류[project-build.invalid-jobs]` 메시지와 함께 종료 코드 2 반환

### 구현

- [ ] T020 [S6] [S7] [S8] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift` 수정 — CI 전용 aggregate scheme 추가:
  - `UIComponentUITests`를 제외한 모든 unit test target(`GitItTests`, `CompositionAdepterTests`, `FeatureTests`, `DomainAuthenticationTests`, `DomainLearningProjectTests`, `DataAuthenticationTests`, `DataLearningProjectTests`, `InfrastructureAuthenticationTests`, `InfrastructureNetworkClientTests`, `InfrastructureCacheTests`, `DesignSystemTests`, `UIComponentTests`) 12개를 포함하는 aggregate unit test scheme 생성
  - 모든 build target도 포함해 `build-for-testing` 가능하도록 구성
  - UI test 전용 scheme 분리 (`UIComponentUITests` + `UIComponentLayoutHarness`)
  - 전체 testable target 목록을 추출할 수 있는 구조로 구성해 누락 검사 지원
- [ ] T021 [S6] [S7] [S8] `.github/workflows/ci.yml` 수정 — `app-build`, `unit-tests`, `ui-tests` job 상세 구현:
  - `app-build`: 일반 Swift 변경 시 대표 앱 scheme(`App`)만 빌드, `project_config_changed` 시 전체 shared scheme 빌드 검증
  - `unit-tests`: `tuist install` → `tuist generate` → aggregate scheme으로 `build-for-testing` → `test-without-building`. 실패 시 `.xcresult` artifact 업로드. `GIT_IT_XCODE_JOBS=4` 설정
  - `ui-tests`: `ui_changed` 조건. UI test scheme으로 별도 실행. unit test와 다른 timeout. 실패 시 `.xcresult` 및 simulator 로그 업로드

### 정리와 단계 검증

- [ ] T022 [no-write] 수정된 `xcodebuild.sh`에 대해 ShellCheck/shfmt 검사를 실행한다
- [ ] T023 [no-write] `GIT_IT_XCODE_JOBS=4`와 `GIT_IT_XCODE_JOBS=abc`로 로컬 빌드를 테스트해 유효/무효 값 검증이 동작하는지 확인한다
- [ ] T024 [no-write] `tuist generate`를 실행해 aggregate scheme이 올바르게 생성되는지 확인한다
- [ ] T025 [no-write] 기존 `tools/script-tests/bin/run.sh`를 실행해 셸 regression test를 통과하는지 확인한다

**승인 게이트**: T019~T025의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 다음
단계를 명시적으로 승인하기 전에는 단계 E 파일을 변경하지 않는다.

---

## 작업 패키지 E: 캐시 분리 및 관측성

**목표**: CI 캐시를 목적별로 3분할하고, 각 실행의 `$GITHUB_STEP_SUMMARY`에 분류·
타이밍·캐시·테스트 결과를 기록한다.

**소유 경로**: `.github/workflows/ci.yml`

**관련 변경 시나리오**: S10

**독립 검증**: Tuist 버전 변경 시 해당 캐시만 miss이고, summary에 모든 필수 정보가
표시되며, machine-readable timing 데이터를 수집할 수 있는지 확인한다.

### 구현

- [ ] T026 [S10] `.github/workflows/ci.yml` 수정 — 캐시 분리:
  - Tuist/SwiftPM 의존성 캐시: `~/.tuist/Cache`, `sources/Tuist/.build`, `.build`. key에 OS, arch, Xcode 버전(`DEVELOPER_DIR`에서 추출), Tuist 버전, `Package.resolved`, `Package.swift`, `Workspace.swift`, `**/Project.swift` hash 포함
  - Swift-Style 도구 캐시: `tools/swift-style/.build`. key에 OS, arch, Swift-Style `Package.resolved`, `Package.swift` hash 포함
  - mise/Tuist 실행 도구 캐시: `~/.local/share/mise`. key에 OS, arch, Tuist 버전 포함
  - 각 캐시의 hit/miss를 `$GITHUB_STEP_SUMMARY`에 기록
- [ ] T027 [S10] `.github/workflows/ci.yml` 수정 — 관측성 summary:
  - 각 job에 step 시작/종료 시각 기록과 소요시간 계산
  - `gate` job의 summary에 변경 분류 결과, 실행·생략·실패 job, job별 소요시간, 대상 Swift 파일 수와 lint 위반 수, 테스트 결과 요약, 캐시 hit/miss, artifact 위치를 종합 표시
  - machine-readable JSON timing artifact 출력 (p50/p95 계산용)

### 정리와 단계 검증

- [ ] T028 [no-write] CI 실행 후 summary에 모든 필수 정보가 표시되는지 확인한다

**승인 게이트**: T026~T028의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 다음
단계를 명시적으로 승인하기 전에는 단계 F 파일을 변경하지 않는다.

---

## 작업 패키지 F: 셸 검증 CI 연결

**목표**: CI의 `script-quality` job에서 기존 `tools/script-verification` 인프라를
호출해 checksum 고정 ShellCheck/shfmt 정적 검사와 회귀 테스트를 모두 실행한다.

**소유 경로**: `.github/workflows/ci.yml`

**관련 변경 시나리오**: S3

**독립 검증**: ShellCheck 위반이 있는 셸 파일 PR에서 `script-quality` job이 실패하고
gate가 실패하는지, 정상 PR에서 성공하는지 확인한다.

### 구현

- [ ] T029 [S3] `.github/workflows/ci.yml` 수정 — `script-quality` job 상세 구현:
  - 조건: `scripts_changed == 'true'`
  - checkout 후 `tools/script-verification/bin/prepare-tools.sh`로 ShellCheck/shfmt 설치
  - 도구 artifact 캐시 (`tools/script-verification/.build/`). key에 OS, arch, `tools.lock` hash 포함
  - `tools/script-verification/bin/run.sh`로 정적 검사 + 회귀 테스트 실행
  - `tools/script-tests/bin/run.sh`로 기존 셸 regression test 실행
  - 정적 검증 또는 regression test 실패 시 job 실패 (gate에 반영)
  - `$GITHUB_STEP_SUMMARY`에 검사 결과 요약 출력

### 정리와 단계 검증

- [ ] T030 [no-write] CI workflow 구문 검증 (YAML 유효성)
- [ ] T031 [no-write] 기존 `tools/script-tests/bin/run.sh`를 실행해 셸 regression test를 통과하는지 확인한다

**승인 게이트**: T029~T031의 변경 파일과 검증 결과를 보고한 뒤 중단한다.

---

## 전체 완료 검증

**선행 조건**: 작업 패키지 A~F의 모든 구현·검증·결과 보고가 완료되어야 한다.

- [ ] T032 [no-write] 전체 `tools/script-verification/bin/run.sh`를 실행해 모든 셸 스크립트의 ShellCheck/shfmt 검사를 통과하는지 확인한다
- [ ] T033 [no-write] 전체 `tools/script-tests/bin/run.sh`를 실행해 모든 셸 regression test를 통과하는지 확인한다
- [ ] T034 [no-write] 문서 전용 PR을 생성해 macOS job이 생략되고 `CI / gate`가 성공하는지 확인한다 (S1 수용 기준)
- [ ] T035 [no-write] 셸 파일 변경 PR을 생성해 `script-quality` job이 실행되고 Swift 빌드 job은 생략되는지 확인한다 (S3 수용 기준)
- [ ] T036 [no-write] Swift 코드 변경 PR을 생성해 변경 파일 batch lint, app build, aggregate unit test가 실행되고 UI test는 생략되는지 확인한다 (S6 수용 기준)
- [ ] T037 [no-write] lint 위반만 있는 PR에서 `CI / gate`가 성공하는지 확인한다 (S5 수용 기준)
- [ ] T038 [no-write] UI 변경 PR에서 `ui-tests` job이 별도로 실행되는지 확인한다 (S8 수용 기준)
- [ ] T039 [no-write] 혼합 변경 PR에서 관련 job의 합집합이 실행되는지 확인한다 (S2 수용 기준)
- [ ] T040 [no-write] 프리커밋에서 staged Swift 포맷 오류가 재-stage 안내와 함께 차단되고, lint 위반만으로는 commit이 차단되지 않는지 확인한다 (S4 수용 기준)

## 의존성과 실행 순서

### 단계 순서와 승인 게이트

- A(변경 분류 및 gate) → B(프리커밋 확장) → C(Swift lint 배치화) → D(Xcode 빌드·테스트 구조 개편) → E(캐시 분리 및 관측성) → F(셸 검증 CI 연결) → 전체 완료 검증
- 한 번에 한 단계만 구현한다. 현재 단계의 모든 작업과 검증이 끝나기 전에는 다음 단계
  작업을 시작하지 않는다.
- 현재 단계의 변경 파일과 검증 결과를 보고하고 명시적 사용자 승인을 받은 뒤 다음 단계로
  진행한다.

### 변경 시나리오 추적성

| 시나리오 | 설명 | 관련 단계 |
|:---:|------|:---:|
| S1 | 문서 전용 PR fast path | A |
| S2 | 변경 유형별 조건부 CI job | A |
| S3 | 셸 정적 검증 | B, F |
| S4 | 프리커밋 staged 검사 | B |
| S5 | Swift lint 배치 실행 | A, C |
| S6 | Aggregate unit test | D |
| S7 | App build 분리 | D |
| S8 | UI test 분리 | D |
| S9 | Xcode 병렬도 제어 | D |
| S10 | 캐시 분리 및 관측성 | E |

### 단계 내부 병렬 실행

**단계 A 내부**:
- T001과 T002는 서로 다른 파일을 생성하므로 병렬 가능 ([P])
- T003은 T001, T002에 의존

**단계 B 내부**:
- T007과 T008은 서로 다른 파일을 생성하므로 병렬 가능 ([P])
- T009는 T007, T008에 의존

**단계 C 내부**:
- T014와 T015는 같은 모듈의 서로 다른 파일이므로 T014 선행

**단계 D 내부**:
- T019와 T020은 서로 다른 파일을 수정하므로 병렬 가능 ([P])
- T021은 T019, T020에 의존

## 구현 전략

1. 첫 미완료 단계(A)를 선택한다.
2. 해당 단계의 준비·구현·정리·검증을 모두 완료한다.
3. 변경 파일과 실제 검증 결과를 보고하고 다음 단계 승인을 요청한 뒤 중단한다.
4. 명시적 승인 후 다음 단계에서 같은 절차를 반복한다.
5. 마지막 단계(F) 완료 뒤에만 전체 읽기 전용 검증(T032~T040)을 실행한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 파일 변경 작업은 정확한 경로를 포함한다.
- `.github/workflows/ci.yml`은 여러 단계에서 수정되지만, 각 단계는 해당 단계의 관심사만 변경한다.
- `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`는 단계 D에서만 수정한다.
- 본 기능은 iOS 앱 패키지 소스를 변경하지 않으므로 Constitution 원칙 7의 패키지 순서를 적용하지 않는다.
