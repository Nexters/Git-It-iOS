# 014-all-usecases-implementation 문제 해결 기록

**대상 기능**: `014-all-usecases-implementation`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260822-001: GIT_IT_PROJECT_BUILD_RUNNER가 패키지 단위 검증을 지원하지 않음

**기록일**: 2026-08-22
**상태**: 환경 제약
**발생 단계**: `/speckit-implement` — Domain 패키지 구현 완료 후 패키지 검증
**관련 항목**: `specs/014-all-usecases-implementation/tasks.md`의 T087(Domain 패키지 검증), `quickstart.md` 패키지별 검증 절차

### 증상

`tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER`가 가리키는
`tools/githooks/project-build/bin/run.sh`의 `build`/`compile`/`test` 액션은 모두
`project_build_scope`를 `all` 또는 `testable`(전체 test target)로 고정한다. 특정 패키지
하나(예: `Domain`)만 선택해 빌드·테스트하는 옵션이 없다.

### 영향

Constitution 원칙 7(패키지 단위 구현 진행)과 `tasks.md`는 각 패키지 완료 시 그 패키지만
독립적으로 빌드·테스트해 결과를 보고하도록 요구한다. 그러나 Domain만 완료되고
Composition·Data·Feature·App이 아직 이전 Domain 변경(예: `ProjectRegistrationReceipt`
rename, `LoginSessionRepository` 신규 메서드)에 맞춰 갱신되지 않은 시점에는
`GIT_IT_PROJECT_BUILD_RUNNER build`(scope=all)가 반드시 컴파일 실패한다. 즉 공식 빌드
러너로는 패키지 단위 승인 게이트를 검증할 수 없다.

### 근거

- `tools/githooks/project-build/bin/run.sh:39-56`: `case "$project_build_operation"`에서
  `build`→`project_build_scope=all`, `compile|test`→`project_build_scope=testable`로
  고정되어 있고 패키지·scheme을 선택하는 인자가 없음을 직접 읽어 확인했다.
- `tools/githooks/project-build/bin/run.sh` 인자 없이 실행: `오류[common.invalid-input]:
  ACTION 한 개가 필요합니다`만 반환하고 scheme 선택 옵션은 제공하지 않음을 확인했다.
- 우회 검증: `cd sources && xcodebuild -workspace GitIt.xcworkspace -scheme Domain
  -destination 'platform=iOS Simulator,id=FF975095-E0FC-434D-89E9-E3EBA19EB913' test`
  실행 결과 `** TEST SUCCEEDED **`, `DomainAuthenticationTests` 32개·
  `DomainLearningProjectTests` 47개·`DomainMemberTests` 11개 총 90개 테스트 통과를
  확인했다(로그: `/tmp/domain-test-run6.log`, 이 로그는 세션 로컬 임시 파일이며 저장소에
  포함되지 않는다).

### 원인

공식 빌드 러너 스크립트(`tools/githooks/project-build/bin/run.sh`)가 pre-commit 등 전체
저장소 검증 용도로 설계되어 있고, Spec Kit의 패키지 단계별 점진적 승인 게이트라는
사용 사례를 고려하지 않았다.

### 조치

이번 세션에서는 Domain 패키지 검증(T087)에 `GIT_IT_PROJECT_BUILD_RUNNER` 대신
`xcodebuild -workspace GitIt.xcworkspace -scheme Domain -destination
'platform=iOS Simulator,id=<사용 가능한 시뮬레이터 UDID>' build`와 `test`를 직접 호출해
대체했다. 시뮬레이터는 `xcodebuild -showdestinations`로 확인한 로컬 사용 가능
디바이스(`default-1`, UDID `FF975095-E0FC-434D-89E9-E3EBA19EB913`)를 사용했다
(`iPhone 17 Pro`가 이 macOS 환경에 설치돼 있지 않아 `GIT_IT_TEST_DESTINATION` 기본값도
사용할 수 없었다).

### 검증

- `xcodebuild ... -scheme Domain ... build`: 성공(`** BUILD SUCCEEDED **`)
- `xcodebuild ... -scheme Domain ... test`: 성공(`** TEST SUCCEEDED **`, 90/90 테스트 통과)
- `GIT_IT_PROJECT_BUILD_RUNNER build`(scope=all): 미실행 — Composition 이하 패키지가
  아직 Domain 변경에 맞춰 갱신되지 않아 실행 시 실패가 예상되므로 해당 패키지들의 구현이
  끝난 뒤(App 패키지 완료 후)에만 실행하기로 결정했다.

### 재발 방지

- 후속 패키지 단계(Infrastructure, Data, Composition, UI, Feature, App)의 각 승인 게이트
  시점에도 동일하게 `xcodebuild -workspace GitIt.xcworkspace -scheme <Package>
  -destination 'platform=iOS Simulator,id=<UDID>'`로 그 패키지만 직접 검증한다.
  `-destination`의 UDID는 매 세션 `xcodebuild -showdestinations -scheme <Package>`로 확인해
  하드코딩하지 않는다.
- 모든 적용 대상 패키지(App까지)가 완료된 뒤에만 `GIT_IT_PROJECT_BUILD_RUNNER`의
  `build`/`compile`/`test`(scope=all)를 실행해 전체 워크스페이스 최종 검증을 수행한다.
- `GIT_IT_PROJECT_BUILD_RUNNER`에 scheme 선택 옵션을 추가하는 것이 근본 해결책이 될 수
  있으나, 이는 `tools/githooks/project-build`의 책임 스킬(`write-project-scripts`) 범위이며
  이 기록만으로 그 스크립트를 수정하지 않는다.

### 연결

없음

## TS-20260822-002: Swift Testing `#require` 중첩 호출이 매크로 재귀 확장 컴파일 오류를 낸다

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `/speckit-implement` — Data 패키지(T104, T105) 신규 테스트 작성 후 패키지 검증
**관련 항목**: `specs/014-all-usecases-implementation/tasks.md`의 T104, T105,
`sources/Projects/Data/Tests/LearningProject/Remotes/HTTPAnswerRemoteTests.swift`,
`sources/Projects/Data/Tests/LearningProject/Remotes/HTTPBookmarkRemoteTests.swift`

### 증상

`xcodebuild -workspace GitIt.xcworkspace -scheme Data -destination
'platform=iOS Simulator,id=<UDID>' test` 실행 시 `HTTPAnswerRemoteTests.swift`,
`HTTPBookmarkRemoteTests.swift`에서 `error: recursive expansion of macro
'require(_:_:sourceLocation:)'`가 발생해 `DataLearningProjectTests` target 컴파일이
실패했다(테스트 실행 전 build 단계 실패, `Testing cancelled because the build failed.`).

### 영향

두 테스트 파일이 포함된 `DataLearningProjectTests` target 전체가 컴파일되지 않아 Data
패키지 검증(T109)을 진행할 수 없었다. 원인이 테스트 로직 결함이 아니라 매크로 문법
제약이라는 점을 먼저 확인하지 않으면 응답 DTO나 request 조립 코드를 잘못 의심할 여지가
있었다.

### 근거

- xcodebuild 원문 오류: `@__swiftmacro_...requirefMf1_.swift:1:61: error: recursive
  expansion of macro 'require(_:_:sourceLocation:)'`이 `HTTPAnswerRemoteTests.swift:32:24`의
  `#require(JSONSerialization.jsonObject(with: try #require(request.body)) as? [String: Int])`
  표현식을 가리켰다.
- 같은 패턴(`#require(... try #require(...) ...)`)이 `HTTPBookmarkRemoteTests.swift`의
  `bookmarked` 본문 검증에도 있어 동일 오류가 함께 발생했다.

### 원인

Swift Testing의 `#require`는 매크로이며, 인자 표현식 안에 또 다른 `#require` 호출을
중첩하면 매크로 확장기가 그 중첩 호출을 재귀적으로 다시 확장하려 시도해 컴파일 타임에
멈춘다. 런타임 assertion 실패가 아니라 매크로 확장 단계의 구조적 제약이다.

### 조치

두 파일 모두에서 중첩 호출을 제거하고, 내부 `#require(request.body)` 결과를 별도
`let bodyData = try #require(request.body)`로 먼저 추출한 뒤 그 값을 외부
`#require(JSONSerialization.jsonObject(with: bodyData) as? T)`에 전달하도록 두 단계로
분리했다.

### 검증

- `xcodebuild -workspace GitIt.xcworkspace -scheme Data -destination
  'platform=iOS Simulator,id=FF975095-E0FC-434D-89E9-E3EBA19EB913' test`: 성공
  (`** TEST SUCCEEDED **`, `DataLearningProjectTests` 56개 포함 전체 통과)
- `xcodebuild ... -scheme Data ... build`: 성공(`** BUILD SUCCEEDED **`)

### 재발 방지

- 이후 세션에서 `#require`/`#expect` 계열 매크로를 조합할 때는 매크로 호출을 중첩하지
  않고, 중간 결과를 먼저 별도 `let`으로 바인딩한 뒤 다음 매크로에 전달한다.

### 연결

없음
