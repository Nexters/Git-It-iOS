# 구현 계획: GitHub CI 및 프리커밋 검증 개선

**Git-flow 유형**: `feature`

**브랜치**: `feature/ci-refactor`

**날짜**: 2026-08-20 | **명세**: [spec.md](file:///Users/jerry/Desktop/Git-It-iOS/specs/009-ci-precommit-optimization/spec.md)

**입력**: `/specs/009-ci-precommit-optimization/spec.md`의 기능 명세

## 요약

현재 CI는 PR 변경 범위와 무관하게 전체 Swift lint, 전체 shared scheme 빌드, 전체
테스트를 직렬 실행한다. 프리커밋은 `script-tests`만 활성화되어 있어 공백 오류, conflict
marker, staged Swift 포맷 위반, staged 셸 정적 검증을 커밋 전에 잡지 못한다.

본 계획은 다음 접근 방식으로 개선한다:

1. **변경 분류기**: ubuntu runner에서 PR diff를 분석해 후속 job의 실행 조건을 결정
2. **단일 CI gate**: 항상 실행되며 차단 job의 성공/실패/skipped를 종합
3. **프리커밋 확장**: `staged-sanity`, `script-verification`, `swift-format` 단계 추가
4. **Swift lint 배치화**: `xargs -0 -n 1`을 batch 전달로 변경
5. **Aggregate unit test**: CI 전용 scheme으로 build-for-testing/test-without-building 통합
6. **UI test 분리**: unit test와 별도 job에서 조건부 실행
7. **Xcode 병렬도**: 환경변수 `GIT_IT_XCODE_JOBS`로 제어
8. **캐시 분리**: Tuist/SwiftPM, Swift-Style, mise 3개 독립 캐시
9. **관측성**: step summary에 분류·타이밍·캐시·테스트 결과 기록

## 기술 맥락

**언어/버전**: Swift 5.0+ (iOS 26.0), POSIX sh (셸 스크립트)

**주요 의존성**: Tuist 4.202.2, Swift-Style (서브모듈), ShellCheck 0.11.0, shfmt 3.13.1, TCA

**저장소**: N/A (로컬 Tuist 프로젝트)

**테스트**: Swift Testing (기본), XCTest (UI test), 셸 regression test

**대상 플랫폼**: iOS 26.0+ (Simulator), GitHub Actions macOS-26 / ubuntu-latest

**프로젝트 유형**: iOS 모바일 앱 (Tuist 멀티 패키지)

**성능 목표**: 문서 PR p50≤2분, Swift PR p50≤12분, 프리커밋 p95≤30초

**제약 조건**: `continue-on-error: true` 유지 (lint 비차단), `contents: read` 최소 권한

**규모/범위**: 7개 패키지 scheme, 12개 unit test target, 1개 UI test target

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

**원칙 1 — 명시적인 경계**: CI workflow와 셸 스크립트의 모듈 책임이 명확하다. 변경
분류기, gate, 프리커밋 단계는 각각 독립된 스크립트/job으로 구현된다.
✅ 통과

**원칙 3 — 검증 가능한 변경**: 각 구현 단계별 빌드/테스트/회귀 테스트 검증 계획이
있다. `--no-verify` 금지 정책을 유지하고 CI가 최종 검증 권한을 가진다.
✅ 통과

**원칙 4 — 스킬별 수정 경로**: 이 계획은 `plan.md`, `research.md`, `quickstart.md`만
수정한다. 구현 파일 경로는 `tasks.md`에 기록한다.
✅ 통과

**원칙 7 — 패키지 단위 구현 진행**: 이 기능은 iOS 앱 패키지(App, Domain, Data 등)의
소스를 변경하지 않는다. 변경 대상은 CI workflow(`.github/`), 셸 스크립트(`tools/`),
Tuist helper(`sources/Tuist/`)이다. Constitution 원칙 7의 패키지 순서는 iOS 앱 소스
코드 패키지에 적용되며, 본 기능은 CI/도구/프로젝트 설정 계층만 변경하므로 아래 구현
경계에서 별도 정의한다.
✅ 통과 (적용 대상 패키지 없음 — 별도 단계 정의)

**브랜치 네임스페이스**: `feature/ci-refactor` — 일반 기능 변경이므로
`feature` 네임스페이스 사용.
✅ 통과

**허용 수정 경로**: 계획 단계에서 `plan.md`, `research.md`, `quickstart.md`만 수정.
✅ 통과

**세션 지식 기록**: 실제 문제 미발생. 기록 조건 미충족.
✅ 해당 없음

**Git 실행 직렬화**: 계획 단계에서 Git 변경 체인 미실행.
✅ 해당 없음

**책임 기반 네이밍**: 새 스크립트, 환경변수, job 이름은 실제 책임을 반영한다.
`staged-sanity`(staged diff 기본 검사), `script-verification`(셸 정적 검증),
`GIT_IT_XCODE_JOBS`(Xcode 병렬도 제어), `CI / gate`(단일 병합 조건).
✅ 통과

**패키지 진행**: 본 기능의 변경은 iOS 앱 패키지 소스가 아닌 CI/도구 계층이므로 아래
구현 경계를 별도 정의한다.
✅ 통과

---

### 1단계 설계 후 헌법 재점검

**원칙 1**: 새 스크립트(`staged-sanity.sh`, `script-verification.sh`,
`classify-changes.sh`)는 각각 단일 책임을 가진다. CI job(`changes`, `script-quality`,
`swift-lint`, `app-build`, `unit-tests`, `ui-tests`, `gate`)도 역할별로 분리된다.
✅ 통과

**원칙 3**: 검증 계획이 있다 — 셸 스크립트는 ShellCheck/shfmt, 회귀 테스트를 통과해야
한다. CI workflow 변경은 테스트 PR로 검증한다.
✅ 통과

## 프로젝트 구조

### 문서(이 기능)

```text
specs/009-ci-precommit-optimization/
├── spec.md
├── plan.md              # 이 파일
├── research.md          # 0단계 조사 결과
├── quickstart.md        # 검증 가이드
└── checklists/
    └── requirements.md
```

### 소스 코드(저장소 루트)

```text
.github/
└── workflows/
    └── ci.yml                          # CI workflow 전면 개편

tools/
├── ci/                                 # [신규] CI 전용 기능 모듈
│   ├── bin/
│   │   ├── classify-changes.sh         # 변경 분류 공개 진입점
│   │   └── gate-evaluate.sh            # gate 평가 공개 진입점
│   ├── core/
│   │   ├── change-policy.sh            # 경로 분류 순수 정책
│   │   └── gate-policy.sh              # job 결과 순수 정책
│   └── tests/
│       ├── test-classify-changes.sh     # NUL-safe 분류 회귀
│       └── test-gate-evaluate.sh        # gate 조합 회귀
├── githooks/
│   ├── pre-commit                      # dispatcher 허용 목록 확장
│   ├── pre-commit.d/
│   │   ├── enabled                     # 단계 활성화 목록 갱신
│   │   ├── staged-sanity.sh            # [신규] staged diff 기본 검사
│   │   └── script-verification.sh      # [신규] staged 셸 정적 검증
│   ├── swift-format/
│   │   ├── bin/run.sh                  # batch 실행 지원 추가
│   │   └── core/style-adapter.sh       # batch adapter 추가
│   └── project-build/
│       └── core/xcodebuild.sh          # -jobs 환경변수 제어
├── repository-paths/
│   └── repository-paths.json           # CI 스크립트 경로 추가 (필요 시)
├── script-tests/                       # 기존 유지 + 신규 regression test 추가
└── script-verification/                # CI 모듈 정적 검사 대상으로 확장

sources/
└── Tuist/
    └── ProjectDescriptionHelpers/
        └── ProjectName.swift           # CI 전용 aggregate scheme 추가
```

**구조 결정**: 기존 `tools/` 하위 모듈 구조를 유지하면서 CI 전용 스크립트를
`tools/ci/`에 추가한다. CI workflow에서 셸 스크립트를 호출하는 패턴은 기존
`repository-paths` 경로 관리를 따른다. Tuist helper 확장으로 CI 전용 aggregate
scheme을 생성한다.

## 구현 경계

본 기능은 iOS 앱 패키지 소스를 변경하지 않으므로 Constitution 원칙 7의 패키지 순서
대신 아래 단계별 경계를 적용한다. 각 단계는 독립적으로 롤백 가능하다.

### 단계 A: 변경 분류 및 gate 도입

**대상 파일**:
- `[신규] tools/ci/bin/classify-changes.sh`
- `[신규] tools/ci/bin/gate-evaluate.sh`
- `[신규] tools/ci/core/change-policy.sh`
- `[신규] tools/ci/core/gate-policy.sh`
- `[신규] tools/ci/tests/test-classify-changes.sh`
- `[신규] tools/ci/tests/test-gate-evaluate.sh`
- `[수정] .github/workflows/ci.yml`
- `[수정] tools/script-verification/config/verification.conf`

**검증**: classify 스크립트 단위 테스트(regression), 테스트 PR로 job 분기 확인,
gate 로직의 성공/실패/skipped 조합 테스트

**승인 게이트**: 변경 분류와 gate가 올바르게 동작함을 확인한 뒤 다음 단계 진행

---

### 단계 B: 프리커밋 확장

**대상 파일**:
- `[수정] tools/githooks/pre-commit` — 허용 목록에 `staged-sanity`, `script-verification` 추가
- `[신규] tools/githooks/pre-commit.d/staged-sanity.sh`
- `[신규] tools/githooks/pre-commit.d/script-verification.sh`
- `[수정] tools/githooks/pre-commit.d/enabled` — 새 단계 활성화

**검증**: 각 단계별 정상/오류 케이스 로컬 테스트, 기존 `script-tests` regression 통과,
p95 30초 이내 확인

**승인 게이트**: 프리커밋이 새 단계를 포함해 올바르게 동작함을 확인한 뒤 다음 단계 진행

---

### 단계 C: Swift lint 배치화

**대상 파일**:
- `[수정] tools/githooks/swift-format/bin/run.sh` — batch 실행 지원
- `[수정] tools/githooks/swift-format/core/style-adapter.sh` — batch adapter 추가
- `[수정] .github/workflows/ci.yml` — 변경 파일 lint, summary 추가

**검증**: batch runner 단위 테스트(1개, 100개 이하, 100개 초과 파일), 공백 경로,
삭제 파일 제외, Derived 제외, rollback 계약 유지, 기존 regression test 통과

**승인 게이트**: batch lint가 기존 lint와 동일한 결과를 제공하고 실행시간이 단축됨을
확인한 뒤 다음 단계 진행

---

### 단계 D: Xcode 빌드·테스트 구조 개편

**대상 파일**:
- `[수정] tools/githooks/project-build/core/xcodebuild.sh` — `-jobs` 환경변수 제어
- `[수정] sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift` — CI aggregate scheme 추가
- `[수정] .github/workflows/ci.yml` — app-build, unit-tests, ui-tests job 분리

**검증**: `GIT_IT_XCODE_JOBS` 유효/무효 값 테스트, aggregate scheme으로 build-for-testing
→ test-without-building 성공, UI test 분리 확인, `.xcresult` 업로드, test target
누락 검사

**승인 게이트**: aggregate test가 모든 기존 unit test를 포함하고 UI test가 별도 job으로
분리됨을 확인한 뒤 다음 단계 진행

---

### 단계 E: 캐시 분리 및 관측성

**대상 파일**:
- `[수정] .github/workflows/ci.yml` — 캐시 3분할, summary 추가, timing artifact

**검증**: 캐시 key 변경 시 올바른 캐시만 무효화, summary에 모든 필수 정보 표시,
machine-readable timing 출력 확인

**승인 게이트**: 20회 이상 benchmark 후 성능 목표 달성 여부 확인

---

### 단계 F: 셸 검증 CI 연결

**대상 파일**:
- `[수정] .github/workflows/ci.yml` — `script-quality` job 추가
- `[수정] tools/repository-paths/repository-paths.json` — CI 스크립트 경로 추가 (필요 시)

**검증**: ShellCheck 위반 PR에서 `script-quality` 실패, 정상 PR에서 성공, 도구 캐시
hit 확인

**승인 게이트**: `script-quality` job이 정적 검증과 회귀 테스트를 모두 실행하고 gate에
올바르게 반영됨을 확인

---

## 파일별 변경 요약

### [신규] `tools/ci/bin/classify-changes.sh`
- PR base↔head diff를 분석해 7개 분류 플래그를 `$GITHUB_OUTPUT`에 출력
- 분류 규칙을 코드 내 연관 배열 또는 case문으로 관리
- `$GITHUB_STEP_SUMMARY`에 분류 결과 테이블 출력
- base SHA fetch 실패 시 종료 코드 1

### [신규] `tools/ci/bin/gate-evaluate.sh`
- 차단 job 결과를 인자로 받아 최종 pass/fail 결정
- `skipped` → pass, `success` → pass, `failure`/`cancelled` → fail
- `swift-lint` 결과는 평가에서 제외
- `$GITHUB_STEP_SUMMARY`에 실행·생략·실패 job 테이블 출력

### [수정] `.github/workflows/ci.yml`
- `changes` job 추가 (ubuntu-latest)
- 기존 `script-tests` → `script-quality`로 확장 (ShellCheck/shfmt 추가)
- `lint` → `swift-lint`로 이름 변경, 변경 파일 lint, batch 실행, summary
- `build-and-test` → `app-build` + `unit-tests` + `ui-tests`로 분리
- `gate` job 추가 (ubuntu-latest, `if: always()`)
- 캐시 3분할, timeout 조정, concurrency 유지

### [신규] `tools/githooks/pre-commit.d/staged-sanity.sh`
- `git diff --cached --check` 실행
- `<<<<<<<` conflict marker 검사
- `DerivedData/`, `*.xcodeproj/`, `*.xcworkspace/` staged 검사

### [신규] `tools/githooks/pre-commit.d/script-verification.sh`
- staged `.sh` 파일 목록 추출
- 대상이 없으면 즉시 성공 종료
- 기존 `tools/script-verification` 인프라를 호출해 staged 대상만 검사

### [수정] `tools/githooks/pre-commit`
- 허용 목록에 `staged-sanity`, `script-verification` 추가
- 고정 실행 순서: `staged-sanity` → `script-verification` → `script-tests` →
  `swift-format` → `build` → `compile` → `test`

### [수정] `tools/githooks/pre-commit.d/enabled`
- `staged-sanity`, `script-verification` 활성화 추가

### [수정] `tools/githooks/swift-format/bin/run.sh`
- `xargs -0 -n 1 style_adapter_format_one` → batch 모드 분기
- lint 모드에서 batch 크기 `GIT_IT_LINT_BATCH_SIZE` (기본 100) 적용
- staged 모드의 backup/rollback 계약 유지

### [수정] `tools/githooks/swift-format/core/style-adapter.sh`
- `style_adapter_format_batch()` 함수 추가
- 기존 `style_adapter_format_one()` 유지 (staged 모드용)

### [수정] `tools/githooks/project-build/core/xcodebuild.sh`
- `-jobs 1` → `-jobs "${GIT_IT_XCODE_JOBS:-1}"`
- 값 검증: 양의 정수만 허용, 잘못된 값 시 명확한 오류

### [수정] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`
- CI 전용 aggregate unit test scheme 추가: `UIComponentUITests`를 제외한 모든 unit
  test target 포함
- test target 누락 검사 지원을 위한 전체 testable target 목록 노출

### [추가 대상 파일 (필요 시)]
- `tools/repository-paths/repository-paths.json` — CI 스크립트 경로 키 추가
- `tools/script-tests/` — 신규 스크립트의 regression test 추가
