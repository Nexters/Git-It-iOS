# 빠른 시작 검증 가이드: GitHub CI 및 프리커밋 검증 개선

## 사전 요구사항

- macOS (Apple Silicon 또는 Intel)
- Xcode 26 이상 (Command Line Tools 포함)
- Git
- `make init` 완료 (Tuist 설치, workspace 생성, Git 훅 설치)

---

## 검증 시나리오 1: 프리커밋 staged-sanity 검사

### 목표
staged 파일에 공백 오류나 conflict marker가 있으면 커밋이 차단되는지 확인한다.

### 실행

```sh
# 기존 파일을 덮어쓰지 않도록 고유한 임시 fixture를 생성해 stage
test_file=$(mktemp "$PWD/.staged-sanity-fixture.XXXXXX.md")
printf 'test line with trailing whitespace   \n' > "$test_file"
git add -- "$test_file"
git commit -m "[Test] whitespace test"
# 기대: staged-sanity 단계가 실패하고 오류 위치를 출력
```

### 기대 결과
- `staged-sanity` 단계에서 `git diff --cached --check`가 실패
- 오류 메시지에 파일 이름과 줄 번호가 표시됨
- commit이 차단됨

```sh
git restore --staged -- "$test_file"
rm -- "$test_file"
```

---

## 검증 시나리오 2: 프리커밋 script-verification 검사

### 목표
staged 셸 파일에 ShellCheck 위반이 있으면 커밋이 차단되는지 확인한다.

### 실행

```sh
# 기존 파일과 충돌하지 않는 ShellCheck 위반 fixture 생성
test_script=$(mktemp "$PWD/tools/test-script.XXXXXX.sh")
printf '%s\n' '#!/bin/sh' 'echo $UNDEFINED_VAR' > "$test_script"
chmod +x "$test_script"
git add -- "$test_script"
git commit -m "[Test] shellcheck test"
# 기대: script-verification 단계가 실패
```

### 기대 결과
- ShellCheck가 `SC2086` (미인용 변수) 위반을 보고
- commit이 차단됨

```sh
git restore --staged -- "$test_script"
rm -- "$test_script"
```

---

## 검증 시나리오 3: Swift 포맷 검증

### 목표
staged Swift 파일의 포맷이 변경되면 재-stage 안내와 함께 커밋이 중단되는지 확인한다.

### 실행

```sh
# pre-commit.d/enabled에 swift-format이 활성화된 상태에서
# 포맷 위반이 있는 Swift 파일을 stage하고 commit 시도
git commit -m "[Test] format test"
# 기대: formatter가 파일을 변경하면 재-stage 안내 출력
```

### 기대 결과
- `오류[swift-format.restage-required]` 메시지 출력
- 재-stage 후 commit 성공

---

## 검증 시나리오 4: CI 변경 분류 확인

### 목표
PR의 변경 파일 분류가 올바르게 동작하는지 확인한다.

### 실행

```sh
# develop 브랜치에서 feature 브랜치 생성
git checkout -b feature/test-ci-classify

# 문서만 변경
echo "test" >> README.md
git add README.md && git commit -m "[Docs] test doc change"
git push origin feature/test-ci-classify
# PR 생성 후 CI 확인
```

### 기대 결과
- `changes` job 로그에 `docs_only=true` 출력
- `app-build`, `unit-tests`, `ui-tests`, `swift-lint` job이 `skipped`
- `CI / gate`가 성공

---

## 검증 시나리오 5: Aggregate Unit Test 확인

### 목표
aggregate scheme으로 build-for-testing → test-without-building 흐름이 동작하는지 확인한다.

### 실행

```sh
# 로컬에서 aggregate scheme 실행
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
# aggregate compile (build-for-testing)
"$project_build_runner" compile
# aggregate test (test-without-building)
"$project_build_runner" test
```

### 기대 결과
- compile 단계에서 모든 unit test target이 빌드됨
- test 단계에서 빌드 없이 테스트가 실행됨
- UI test(`UIComponentUITests`)는 제외됨

---

## 검증 시나리오 6: CI Gate 동작 확인

### 목표
lint만 실패하고 나머지 차단 검사가 성공하면 `CI / gate`가 성공하는지 확인한다.

### 실행

```sh
# lint 위반이 있는 Swift 파일을 PR에 포함
# (다른 빌드/테스트는 모두 통과하는 상태)
```

### 기대 결과
- `swift-lint` job이 `failure` 상태이지만 `continue-on-error: true`로 비차단
- `CI / gate`의 summary에 lint 실패가 기록되지만 gate는 `success`
- PR이 병합 가능 상태

---

## 검증 시나리오 7: Xcode 병렬도 제어

### 목표
`GIT_IT_XCODE_JOBS` 환경변수가 `xcodebuild -jobs` 값을 제어하는지 확인한다.

### 실행

```sh
# 병렬도 4로 빌드
GIT_IT_XCODE_JOBS=4 "$project_build_runner" build

# 잘못된 값으로 빌드 시도
GIT_IT_XCODE_JOBS=abc "$project_build_runner" build
# 기대: 명확한 오류 메시지 출력
```

### 기대 결과
- `GIT_IT_XCODE_JOBS=4` → `-jobs 4`로 xcodebuild 실행
- `GIT_IT_XCODE_JOBS=abc` → 검증 실패 메시지 출력, 실행 중단

---

## 검증 시나리오 8: 캐시 분리 확인

### 목표
CI에서 캐시 key가 목적별로 분리되어 있고 summary에 hit/miss가 표시되는지 확인한다.

### 실행

```sh
# PR CI 실행 후 Actions 로그의 Step Summary 확인
```

### 기대 결과
- Summary에 3개 캐시(Tuist/SwiftPM, Swift-Style, mise) 각각의 hit/miss 표시
- Tuist 버전 변경 시 해당 캐시만 miss
