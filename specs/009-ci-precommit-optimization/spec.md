# 기능 명세: GitHub CI 및 프리커밋 검증 개선

**Git-flow 유형**: `feature`

**기능 브랜치**: `feature/ci-refactor`

**생성일**: 2026-08-20

**상태**: 초안

**입력**: 사용자 설명: "Git-It-iOS 프로젝트의 GitHub Actions CI 실행시간을 단축하고, 로컬 프리커밋 단계에서 발견 가능한 오류를 앞당겨 검출하기 위한 작업 범위와 동작 계약 정의 (문서 ID: CI-OPT-001)"

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - 문서 전용 PR의 빠른 CI 완료 (우선순위: P1)

PR이 Markdown, 문서 이미지, `specs/`, `docs/` 등 문서 파일만 변경한 경우, macOS runner에서 Swift lint, 앱 빌드, 단위 테스트, UI 테스트를 실행하지 않고 변경 분류와 기본 문서 검사만 수행한 뒤 `CI / gate`를 성공으로 완료한다. 이를 통해 문서 기여의 CI 대기시간을 p50 2분 이하로 단축한다.

**주요 행위자**: 개발자 (PR 작성자), CI 시스템

**우선순위 이유**: 현재 모든 PR이 전체 macOS 빌드·테스트를 실행하므로 문서 전용 변경에서도 불필요한 macOS runner 시간이 소모된다. 변경 분류와 gate 도입이 전체 작업의 기반이 되므로 최우선이다.

**독립 테스트**: 문서 파일만 변경한 테스트 PR을 생성해 macOS job이 생략되고 `CI / gate`가 성공하는지 확인한다.

**수용 시나리오**:

1. **전제** PR이 `README.md`만 수정함, **실행** PR CI가 실행됨, **결과** `changes` job이 `docs_only=true`를 출력하고, `app-build`, `unit-tests`, `ui-tests`, `swift-lint` job이 실행되지 않으며, `CI / gate`가 성공함
2. **전제** PR이 `specs/001-apple-social-login/spec.md`만 수정함, **실행** PR CI가 실행됨, **결과** macOS job이 모두 생략되고 `CI / gate`가 성공함
3. **전제** PR이 `README.md`와 `sources/Projects/App/Sources/AppDelegate.swift`를 함께 수정함, **실행** 변경 분류기가 실행됨, **결과** `docs_only=false`, `swift_changed=true`로 설정되어 Swift 관련 차단 검사가 정상 실행됨

---

### 시나리오 2 - 변경 유형별 조건부 CI job 실행 (우선순위: P1)

변경 분류기가 PR의 base SHA와 head SHA 사이 파일을 분석해 `docs_only`, `scripts_changed`, `swift_changed`, `ui_changed`, `project_config_changed`, `workflow_changed`, `tests_changed` 플래그를 출력하고, 후속 job은 이 플래그에 따라 실행 여부를 결정한다. 항상 실행되는 `CI / gate` job이 모든 차단 job의 결과를 종합해 최종 성공/실패를 판정한다.

**주요 행위자**: CI 시스템, 개발자 (PR 작성자 및 리뷰어)

**우선순위 이유**: 변경 분류와 gate는 모든 후속 시나리오의 전제 조건이다. 이것이 없으면 조건부 실행과 비차단 lint 정책을 구현할 수 없다.

**독립 테스트**: 각 변경 유형별 테스트 PR을 생성해 해당 job만 실행되는지, `CI / gate`가 올바르게 성공/실패하는지 확인한다.

**수용 시나리오**:

1. **전제** 변경 분류 스크립트가 CI workflow에 추가됨, **실행** 임의의 PR에서 CI가 실행됨, **결과** `changes` job이 모든 분류 플래그를 `$GITHUB_OUTPUT`에 출력하고 `$GITHUB_STEP_SUMMARY`에 분류 결과 테이블을 표시함
2. **전제** 셸 파일만 변경한 PR에서 CI가 실행됨, **실행** `changes` job이 `scripts_changed=true`, `swift_changed=false`를 출력함, **결과** `script-quality` job만 실행되고 `app-build`, `unit-tests` job은 생략됨
3. **전제** 모든 차단 job이 성공하고 `swift-lint`만 실패함, **실행** `CI / gate`가 평가됨, **결과** gate가 성공함
4. **전제** `unit-tests` job이 실패함, **실행** `CI / gate`가 평가됨, **결과** gate가 실패함
5. **전제** `app-build` job이 조건에 의해 `skipped`됨, **실행** `CI / gate`가 평가됨, **결과** `skipped`를 정상으로 처리하고 gate가 성공함

---

### 시나리오 3 - 셸 파일의 실제 정적 검증 (우선순위: P1)

CI의 `script-quality` job이 기존 회귀 테스트에 더해 저장소 셸 파일에 대한 실제 ShellCheck와 shfmt 검사를 실행한다. 프리커밋에서도 staged 셸 파일에 대해 동일한 정적 검증을 수행한다.

**주요 행위자**: 개발자 (셸 스크립트 작성자)

**우선순위 이유**: 현재 CI는 회귀 테스트만 실행하고 실제 정적 검증을 수행하지 않아 ShellCheck/shfmt 위반이 병합될 수 있다. 프리커밋에서도 셸 검증이 없어 커밋 후에야 문제를 발견한다.

**독립 테스트**: ShellCheck 위반이 있는 셸 파일을 PR에 포함해 `script-quality` job이 실패하는지 확인하고, 로컬에서 staged 셸 파일에 shfmt 위반을 넣어 프리커밋이 차단하는지 확인한다.

**수용 시나리오**:

1. **전제** ShellCheck 위반이 있는 `.sh` 파일이 PR에 포함됨, **실행** `script-quality` job이 실행됨, **결과** ShellCheck가 위반을 보고하고 job이 실패하며 `CI / gate`가 실패함
2. **전제** staged 셸 파일에 shfmt 위반이 있음, **실행** `git commit`을 실행함, **결과** 프리커밋 `script-verification` 단계가 실패하고 대상 파일과 조치 방법을 출력하며 commit이 차단됨
3. **전제** CI `script-quality` job이 실행됨, **실행** 저장소의 고정 도구 준비 스크립트로 ShellCheck/shfmt를 설치함, **결과** `brew install` 없이 checksum 고정 바이너리를 사용하며 캐시가 활용됨

---

### 시나리오 4 - 프리커밋 staged 검사 확장 (우선순위: P1)

프리커밋이 기존 `script-tests`에 더해 `staged-sanity`(공백 오류, conflict marker, 금지 산출물), `script-verification`(staged 셸 정적 검증), `swift-format`(staged Swift 포맷 검사)를 수행한다. Swift lint 위반은 commit을 차단하지 않는다.

**주요 행위자**: 개발자 (커밋 수행자)

**우선순위 이유**: 현재 프리커밋이 `script-tests`만 수행해 공백 오류, conflict marker, 포맷 위반 등 단순 오류를 커밋 전에 잡지 못한다. 빠른 로컬 피드백은 CI 실행 전 품질을 높인다.

**독립 테스트**: 각 유형의 오류가 있는 파일을 staging하고 commit을 시도해 해당 단계에서 차단되는지 확인한다.

**수용 시나리오**:

1. **전제** staged 파일에 trailing whitespace가 있음, **실행** `git commit`을 실행함, **결과** `staged-sanity` 단계가 실패하고 오류 위치를 출력함
2. **전제** staged 파일에 `<<<<<<<` conflict marker가 있음, **실행** `git commit`을 실행함, **결과** `staged-sanity` 단계가 실패함
3. **전제** staged Swift 파일이 formatter에 의해 변경됨, **실행** `git commit`을 실행함, **결과** commit이 중단되고 변경 파일을 다시 stage하라는 안내가 출력됨
4. **전제** staged Swift 파일에 lint 위반만 있고 포맷은 정상임, **실행** `git commit`을 실행함, **결과** lint 위반이 표시되지만 commit은 성공함
5. **전제** staged 파일이 없음, **실행** `git commit`을 실행함, **결과** 각 단계가 관련 파일 없음으로 빠르게 성공하고 p95 실행시간이 30초 이내임
6. **전제** 프리커밋 dispatcher에 알 수 없는 단계 이름이 입력됨, **실행** dispatcher가 실행됨, **결과** 오류가 출력되고 실행이 중단됨

---

### 시나리오 5 - Swift lint 변경 파일 배치 실행 (우선순위: P2)

Swift-Style wrapper가 파일마다 도구를 재실행하는 대신, NUL 구분 파일 목록을 배치 단위(기본 100개)로 하나의 invocation에 전달한다. CI에서는 PR 변경 파일만 기본 대상으로 하되 프로젝트 설정 변경 시 전체 lint로 승격한다.

**주요 행위자**: CI 시스템, 개발자

**우선순위 이유**: 현재 `xargs -n 1` 구조로 파일마다 SwiftPM 기반 도구를 재실행해 lint 시간이 선형 증가한다. 배치 실행으로 p50 2분 이하 목표를 달성한다.

**독립 테스트**: 100개 이상의 Swift 파일 변경 PR에서 batch 분할과 실행시간을 측정한다.

**수용 시나리오**:

1. **전제** PR에서 50개의 Swift 파일이 변경됨, **실행** `swift-lint` job이 실행됨, **결과** 변경 파일 50개가 하나의 batch로 lint 도구에 전달되고 summary에 대상 파일 수, 위반 수, 실행시간이 표시됨
2. **전제** PR에서 150개의 Swift 파일이 변경됨, **실행** `swift-lint` job이 실행됨, **결과** 100개, 50개 두 batch로 분할 실행됨
3. **전제** 공백이 포함된 파일 경로가 대상에 포함됨, **실행** batch runner가 실행됨, **결과** NUL 구분으로 올바르게 처리됨
4. **전제** `Derived/` 또는 `.build/` 내 Swift 파일이 존재함, **실행** batch runner가 실행됨, **결과** 해당 파일이 제외됨
5. **전제** lint 위반이 발견됨, **실행** lint job이 완료됨, **결과** `continue-on-error: true`에 의해 job은 비차단이고 `CI / gate`는 성공함

---

### 시나리오 6 - CI 전용 aggregate unit test (우선순위: P2)

여러 testable scheme을 개별 `xcodebuild`로 반복하는 대신, UI test를 제외한 모든 unit test target을 포함하는 aggregate scheme 또는 test plan으로 `build-for-testing`을 한 번 실행하고, 같은 산출물로 `test-without-building`을 실행한다.

**주요 행위자**: CI 시스템, 개발자

**우선순위 이유**: 현재 scheme마다 별도 `xcodebuild`를 직렬 실행해 중복 빌드와 긴 실행시간이 발생한다. 빌드 산출물 재사용으로 일반 Swift PR의 CI p50을 12분 이하로 단축한다.

**독립 테스트**: aggregate scheme으로 `build-for-testing` → `test-without-building` 순서로 실행해 모든 unit test가 통과하는지 확인한다.

**수용 시나리오**:

1. **전제** CI 전용 aggregate unit test scheme이 존재함, **실행** `unit-tests` job이 실행됨, **결과** `build-for-testing`이 한 번 실행되고 같은 산출물로 `test-without-building`이 실행됨
2. **전제** 기존 unit test target 5개가 모두 aggregate에 포함됨, **실행** 테스트가 실행됨, **결과** 5개 target 모두 실행되고 결과가 `.xcresult`에 보존됨
3. **전제** 신규 test target이 추가되었으나 aggregate에 누락됨, **실행** 누락 검사가 실행됨, **결과** 차단 실패로 처리됨
4. **전제** unit test가 실패함, **실행** job이 완료됨, **결과** `.xcresult`가 artifact로 업로드됨

---

### 시나리오 7 - app build와 전체 shared scheme build 분리 (우선순위: P2)

일반 Swift PR에서는 대표 앱 scheme만 빌드하고, 프로젝트 설정 변경 시에만 전체 shared scheme을 빌드한다.

**주요 행위자**: CI 시스템

**우선순위 이유**: 모든 PR에서 전체 shared scheme을 반복 빌드하면 불필요한 시간이 소모된다. 일반 변경은 대표 앱 scheme으로 빌드 가능성을 확인하면 충분하다.

**독립 테스트**: 일반 Swift PR과 `Project.swift` 변경 PR에서 각각 빌드 범위가 달라지는지 확인한다.

**수용 시나리오**:

1. **전제** Swift 파일만 변경된 PR에서 CI가 실행됨, **실행** `app-build` job이 실행됨, **결과** 대표 앱 scheme만 빌드되고 전체 shared scheme 반복 빌드는 실행되지 않음
2. **전제** `Project.swift`가 변경된 PR에서 CI가 실행됨, **실행** `app-build` job이 실행됨, **결과** 전체 shared scheme 빌드 검증이 실행됨

---

### 시나리오 8 - UI test 분리 (우선순위: P2)

UI test를 unit test와 별도 job에서 실행한다. UI 관련 파일 또는 UI test 변경 시에만 실행하며, 별도 timeout과 artifact를 관리한다.

**주요 행위자**: CI 시스템, 개발자

**우선순위 이유**: UI test가 unit test와 같은 직렬 흐름에 포함되어 전체 CI 완료시간을 크게 늘리고, unit test 결과 확인을 지연시킨다.

**독립 테스트**: UI 컴포넌트 변경 PR에서 `ui-tests` job이 별도로 실행되고 unit test와 독립적으로 결과를 보고하는지 확인한다.

**수용 시나리오**:

1. **전제** UI component가 변경된 PR에서 CI가 실행됨, **실행** `ui-tests` job이 실행됨, **결과** unit test와 별도로 실행되고 실패 시 simulator 로그와 `.xcresult`가 업로드됨
2. **전제** UI 관련 파일이 변경되지 않은 일반 Swift PR, **실행** CI가 실행됨, **결과** `ui-tests` job이 생략됨
3. **전제** UI test가 실패함, **실행** `CI / gate`가 평가됨, **결과** gate가 실패함

---

### 시나리오 9 - Xcode 병렬도 환경변수 제어 (우선순위: P3)

`xcodebuild -jobs 1` 하드코딩을 제거하고 `GIT_IT_XCODE_JOBS` 환경변수로 병렬도를 제어한다. CI 기본값은 `4`, 로컬 미지정 시 안정성을 위한 기본값을 사용한다.

**주요 행위자**: 개발자, CI 관리자

**우선순위 이유**: 하드코딩된 `-jobs 1`이 빌드 시간을 불필요하게 늘린다. 환경변수로 제어하면 runner 환경에 따라 유연하게 조절하고 문제 발생 시 즉시 롤백할 수 있다.

**독립 테스트**: 환경변수 값을 변경하며 빌드 실행시간과 안정성을 측정한다.

**수용 시나리오**:

1. **전제** `GIT_IT_XCODE_JOBS=4`가 CI에 설정됨, **실행** `xcodebuild`가 실행됨, **결과** `-jobs 4`로 실행됨
2. **전제** `GIT_IT_XCODE_JOBS`가 미설정됨, **실행** 로컬에서 `xcodebuild`가 실행됨, **결과** 문서화된 기본값으로 실행됨
3. **전제** `GIT_IT_XCODE_JOBS=abc`가 설정됨, **실행** 빌드 스크립트가 실행됨, **결과** 명확한 오류 메시지가 출력되고 실행이 중단됨

---

### 시나리오 10 - 캐시 분리 및 관측성 (우선순위: P3)

캐시를 목적별(Tuist/SwiftPM 의존성, Swift-Style 도구, mise/Tuist 실행 도구)로 분리하고 key에 OS, architecture, Xcode 버전, Tuist 버전, manifest hash를 포함한다. 각 CI 실행의 `$GITHUB_STEP_SUMMARY`에 변경 분류, 실행/생략 job, 소요시간, 캐시 상태, 테스트 결과를 기록한다.

**주요 행위자**: CI 관리자, 개발자

**우선순위 이유**: 현재 캐시 key가 불명확하고 하나의 archive에 여러 목적의 디렉터리를 묶어 캐시 효율이 떨어진다. 관측성 정보는 성능 목표 달성 여부를 측정하고 병목을 식별하는 데 필수적이다.

**독립 테스트**: Xcode 버전 변경 후 캐시가 무효화되는지, summary에 모든 필수 정보가 표시되는지 확인한다.

**수용 시나리오**:

1. **전제** Tuist 버전이 변경됨, **실행** CI가 실행됨, **결과** Tuist 관련 캐시가 miss이고 Swift-Style 도구 캐시는 hit임
2. **전제** CI 실행이 완료됨, **실행** `$GITHUB_STEP_SUMMARY`를 확인함, **결과** 변경 분류 결과, 실행·생략된 job, step별 소요시간, 캐시 hit/miss, 테스트 결과 요약이 모두 표시됨
3. **전제** 최소 20회 CI가 실행됨, **실행** machine-readable timing 데이터를 수집함, **결과** 변경 유형별 p50, p95를 계산할 수 있음

---

### 예외·경계 사례

- 변경 분류기에서 base SHA fetch가 실패하면 어떻게 처리하는가? → 차단 실패로 처리하고 모든 job 실행을 안전 측으로 승격하지 않는다.
- 같은 PR에 새 commit이 push되면 이전 CI 실행은 어떻게 처리하는가? → 기존 concurrency 정책에 따라 이전 실행을 취소한다.
- 프리커밋에서 signal 중단이 발생하면 임시 파일은 어떻게 처리하는가? → trap handler로 정리한다.
- 변경 파일에 삭제된 파일이 포함되면 lint 대상에서 어떻게 처리하는가? → 존재하지 않는 파일은 대상에서 제외한다.
- 프리커밋 p95가 30초를 초과하면 어떻게 대응하는가? → 느린 regression test를 pre-push 또는 CI로 이동한다.
- aggregate test plan에 신규 test target이 누락되면 어떻게 탐지하는가? → 생성된 testable target 목록과 aggregate 목록을 자동 대조해 누락 시 차단 실패로 처리한다.
- 경로 필터로 workflow 전체가 생략되는 상황이 발생하면 어떻게 방지하는가? → `CI / gate`를 `if: always()`로 설정해 항상 실행한다.

## 요구사항 *(필수)*

### 기능 요구사항

- **FR-001**: CI는 모든 PR에서 가장 먼저 변경 분류 job을 실행해야 한다. 분류기는 `docs_only`, `scripts_changed`, `swift_changed`, `ui_changed`, `project_config_changed`, `workflow_changed`, `tests_changed` 출력을 제공하고 결과를 `$GITHUB_STEP_SUMMARY`에 표시해야 한다.
- **FR-002**: 각 CI job은 변경 분류기의 output을 기준으로 실행 여부를 결정해야 한다. `CI / gate`는 `if: always()`로 항상 실행되고, 조건부 job의 `skipped`는 정상으로, 실행된 차단 job의 `failure`/`cancelled`는 gate 실패로 처리해야 한다. Swift lint 결과는 gate 실패 조건에 포함하지 않는다.
- **FR-003**: CI의 `script-quality` job은 checksum 고정 ShellCheck/shfmt 준비, 저장소 셸 파일 정적 검사, 기존 script regression test를 모두 실행해야 한다. 정적 검증 또는 regression test 중 하나라도 실패하면 job이 실패해야 한다.
- **FR-004**: Swift lint job은 `continue-on-error: true`를 유지하고, PR에서는 변경 Swift 파일만 기본 대상으로 하되 프로젝트 설정 변경 시 전체 lint로 승격할 수 있어야 한다. lint 결과는 `CI / gate`의 실패 조건에 포함하지 않는다.
- **FR-005**: Swift-Style wrapper는 파일마다 도구를 재실행하지 않고, NUL 구분 파일 목록을 기본 100개 단위 batch로 전달해야 한다. batch 크기는 구성 가능하고, `Derived`/`.build` 등 생성 산출물은 제외하며, 공백/특수문자 경로를 정상 처리해야 한다.
- **FR-006**: 프리커밋은 `staged-sanity`(git diff --cached --check, conflict marker, 금지 산출물), `script-verification`(staged 셸 ShellCheck/shfmt), `swift-format`(staged 포맷 검사), `script-tests`(기존 회귀 테스트) 순서로 실행하고, 전체 Xcode build/test는 수행하지 않아야 한다.
- **FR-007**: 프리커밋 dispatcher는 `staged-sanity`, `script-verification`, `swift-format`, `script-tests` 단계를 지원하고, 알 수 없는 단계는 오류로 처리하며, 실행 순서를 코드에 명시적으로 고정하고, 관련 staged 파일이 없으면 빠르게 성공해야 한다.
- **FR-008**: CI 전용 aggregate unit test 진입점이 UI test를 제외한 모든 unit test target을 포함하고, `build-for-testing`을 한 번 실행한 뒤 `test-without-building`으로 테스트해야 한다. 신규 test target 누락을 자동 검출하는 검사가 있어야 한다.
- **FR-009**: 일반 Swift PR에서는 대표 앱 scheme으로 빌드 가능성을 확인하고, 프로젝트 설정 변경 시에만 전체 shared scheme build를 실행해야 한다.
- **FR-010**: UI test는 unit test와 별도 job에서 실행해야 한다. UI 관련 변경 시 실행되고, 실패 시 simulator 로그와 `.xcresult`를 업로드해야 한다.
- **FR-011**: `xcodebuild -jobs 1` 하드코딩을 제거하고 `GIT_IT_XCODE_JOBS` 환경변수로 제어해야 한다. CI 기본값 `4`, 허용 값 검증, 잘못된 값에 대한 명확한 오류를 제공해야 한다.
- **FR-012**: 캐시를 Tuist/SwiftPM 의존성, Swift-Style 도구, mise/Tuist 실행 도구로 분리하고, key에 runner OS, architecture, Xcode 버전, Tuist 버전, 관련 manifest hash를 포함해야 한다.
- **FR-013**: 항상 실행되는 `CI / gate` job이 변경 분류기, script quality, app build, unit tests, UI tests의 결과를 평가하고, Swift lint 결과는 gate 실패 조건에서 제외해야 한다. gate summary에 실행·생략·실패 job을 구분해 표시해야 한다.
- **FR-014**: 각 CI 실행은 `$GITHUB_STEP_SUMMARY`에 변경 분류 결과, 실행·생략 job, 소요시간, 대상 파일 수와 lint 위반 수, 테스트 결과, 캐시 상태, artifact 위치를 기록해야 한다. machine-readable timing 형식을 제공해야 한다.
- **FR-015**: 기존 concurrency 정책(동일 PR 이전 실행 취소), `contents: read` 최소 권한, job별 timeout, 도구 버전의 명시적 고정, 제3자 Action의 full commit SHA 고정을 유지해야 한다.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: 문서 전용 PR의 CI workflow p50이 2분 이하, p95가 4분 이하이다 (최소 20회 실행 기준).
- **SC-002**: 일반 Swift PR의 CI workflow p50이 12분 이하, p95가 18분 이하이다 (최소 20회 실행 기준).
- **SC-003**: 프리커밋 p95 실행시간이 30초 이하이다 (staged 파일 기반 빠른 검사 범위).
- **SC-004**: 변경 파일 Swift lint p50이 2분 이하, p95가 4분 이하이다 (배치 실행 기준).
- **SC-005**: Swift lint 실패만으로 `CI / gate`가 실패하는 사례가 0건이다.
- **SC-006**: 변경 분류로 인해 필요한 검사가 잘못 생략되는 사례가 0건이다 (분류 regression test 통과).
- **SC-007**: 기존 unit test 및 UI test의 검증 범위가 축소되지 않는다 (aggregate 누락 자동 검출 통과).
- **SC-008**: 동일 commit SHA에 대해 반복 실행 시 도구 버전과 실행 조건이 일관된다.
- **SC-009**: 최소 20회 benchmark에서 성능 목표를 충족하거나, 미달 사유와 후속 조치가 문서화된다.

## 범위

### 포함

- GitHub Actions CI workflow 구조 변경
- 변경 분류 스크립트/job 추가
- 단일 `CI / gate` job 추가
- CI에서 실제 ShellCheck/shfmt 실행 연결
- 프리커밋 dispatcher 확장 및 staged 검사 추가
- Swift lint 배치 실행 adapter
- CI 전용 aggregate unit test scheme/test plan
- app build와 전체 shared scheme build 분리
- UI test 별도 job 분리
- Xcode 병렬도 환경변수 제어
- 캐시 분리 및 key 명확화
- CI 관측성 summary 및 timing 데이터

### 제외

- Swift 스타일 lint를 병합 차단 검사로 변경
- `lint` job의 `continue-on-error: true` 제거
- SwiftLint/SwiftFormat 규칙 자체 변경
- 기존 코드베이스의 lint 위반 일괄 수정
- 제품 기능, 앱 동작, API 계약 변경
- Xcode/Tuist 메이저 버전 업그레이드
- 배포, 서명, TestFlight 또는 release workflow 변경
- GitHub-hosted runner를 self-hosted runner로 교체
- 모든 테스트를 프리커밋에서 실행

## 가정

- GitHub-hosted macOS runner의 가용 CPU/메모리가 `GIT_IT_XCODE_JOBS=4` 수준의 병렬 빌드를 안정적으로 처리한다. 문제 발생 시 `1`로 즉시 롤백한다.
- 저장소의 기존 `tools/script-verification/bin/prepare-tools.sh`가 ShellCheck/shfmt를 checksum 고정으로 설치하며 CI에서 재사용 가능하다.
- 기존 프리커밋 dispatcher 구조(`tools/githooks/pre-commit.d/enabled`)가 확장 가능하다.
- Tuist가 CI 전용 aggregate scheme 또는 Xcode test plan 생성을 지원한다.
- `git diff --diff-filter=ACMR --name-only`가 PR의 base SHA와 head SHA 사이 변경 파일을 신뢰성 있게 제공한다.
- 기존 `sources/DerivedData/PreCommit` 공유 경로가 `build-for-testing`과 `test-without-building`의 산출물 공유에 활용 가능하다.
- 프리커밋에서 Swift 포맷 검사의 backup, rollback, 재-stage 검증 계약이 기존 `swift-format` hook과 호환된다.
- 변경 분류 규칙의 경로 패턴이 저장소 디렉터리 구조와 일치하며 구조 변경 시 분류 규칙도 갱신된다.
