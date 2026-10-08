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

## TS-20260822-003: `ScrollView` 안의 고정 폭 `HStack`이 화면 폭을 넘으면 전체 콘텐츠가 중앙 정렬·클리핑된다

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `/speckit-implement` — UI 패키지(T144) 완료 뒤 사용자의 시뮬레이터 UI 확인 중 발견
**관련 항목**: `specs/014-all-usecases-implementation/tasks.md`의 T144,
`sources/Projects/UI/ComponentPreviewApp/LayoutContractCatalog.swift`,
`sources/Projects/UI/Component/Components/Composite/LearningSetRow.swift`,
`sources/Projects/UI/Component/Components/Composite/EssayAnswerInput.swift`

### 증상

시뮬레이터에서 `UIComponentPreviewApp`(`LayoutContractCatalog`)을 실행하면 제목
"Figma 레이아웃 계약"을 포함한 화면 전체 콘텐츠가 좌우로 잘려 보였다(예: "Figma 레이아웃
계약"이 "웃 계약"으로, "Large"가 "ge"로 보임). `EssayAnswerInput`을 최근에 수정했다는
정황 때문에 처음에는 그 컴포넌트의 `TextEditor` 높이 문제로 추정했다.

### 영향

`EssayAnswerInput`의 `TextEditor`에 `.scrollDisabled(true)`·`maxHeight` 상한을
추가하고, `LayoutContractCatalog`의 최상위 `VStack`/`ScrollView`에
`.frame(maxWidth: .infinity, alignment: .leading)`를 추가하고,
`.dynamicTypeSize(.large)`로 강제 고정하는 등 여러 차례 수정을 시도했으나 스크린샷상
증상이 전혀 변하지 않아 원인 진단이 상당히 지연되었다. 잘못된 가설(TextEditor 높이,
ScrollView 폭 제약 없음, Dynamic Type)로 여러 차례 재빌드·재설치·재스크린샷을 반복했다.

### 근거

- `NSLog`로 `GeometryReader`의 `proxy.frame(in: .global)`을 로깅한 결과, 제목
  `Text`의 global x-origin이 iPhone 17 Pro 시뮬레이터(폭 402pt)에서 `-125.0`,
  iPhone 17 Pro Max 시뮬레이터(폭 440pt)에서 `-106.0`으로 측정되었다. 두 값 모두
  `(availableWidth - 652) / 2`와 정확히 일치해, 콘텐츠의 실제 intrinsic 폭이
  652pt로 고정돼 있고 `ScrollView`가 이를 가운데 정렬하고 있음을 확인했다.
- `LayoutContractCatalog.swift`의 `learningSetRowContracts`(당시 `private var
  learningSetRowContracts: some View`)가 `LearningSetRow`(각 320pt,
  `LearningSetRow.swift`의 `Constant.width`) 두 개를 `HStack(spacing:
  LayoutToken.gutter.cgFloatValue)`(12pt)에 배치해 320+320+12=652pt였다.
- `body`를 이진 탐색(제목만 남기고 전부 제거 → 정상 렌더링 확인 → 절반씩 복원)한 결과,
  `learningSetRowContracts`를 추가하는 시점에만 증상이 재현되고 그 전 모든 섹션(action
  button, project row, sheet surface, glass container, text field, setting row,
  question contracts 포함)은 단독으로 정상 렌더링되었다(스크린샷으로 확인).
- `xcrun simctl` 직접 빌드·설치·스크린샷으로 재현했으며, `.frame(maxWidth: .infinity,
  alignment: .leading)`·`.dynamicTypeSize(.large)` 강제 적용 뒤에도 title의 global
  x-origin이 동일하게 `-125.0`으로 남아 있어 이 두 수정이 근본 원인을 해결하지 못했음을
  직접 확인했다.

### 원인

`ScrollView`(세로)는 자신의 콘텐츠가 자신의 폭보다 넓을 때 내부 `VStack(alignment:
.leading)`의 정렬을 따르지 않고 콘텐츠 전체를 가로로 가운데 정렬한다. 화면 폭
402~440pt보다 넓은 652pt 콘텐츠(두 `LearningSetRow`를 감싼 일반 `HStack`)가 최상위
`VStack`에 포함되면서, 최상위 `VStack`의 intrinsic 폭이 652pt가 되어 `ScrollView`
전체가 가운데 정렬됐고, 그 결과 제목을 포함한 모든 형제 섹션이 좌우로 잘려 보였다.
`EssayAnswerInput`은 이 증상과 무관했다.

### 조치

`learningSetRowContracts`를 `ScrollView(.horizontal, showsIndicators: false)`로
감싸 두 `LearningSetRow`가 자체적으로 가로 스크롤되도록 하여, 최상위 `VStack`의
intrinsic 폭 계산에 더 이상 영향을 주지 않게 했다(`LayoutContractCatalog.swift`).
`EssayAnswerInput`의 `.scrollDisabled(true)`·`maxHeight` 상한(240pt)은 근본 원인은
아니었지만 `TextEditor`가 콘텐츠 크기에 맞춰 자동 조정되고 무한 확장을 방지하는
정당한 개선이라 되돌리지 않고 유지했다.

### 검증

- `xcrun simctl` 직접 빌드·설치 후 스크린샷: 수정 전에는 제목부터 모든 섹션이 좌우로
  잘려 보였고, `learningSetRowContracts`를 가로 `ScrollView`로 감싼 뒤에는 제목부터
  `questionContracts`(`EssayAnswerInput` 포함)까지 화면 폭 안에서 정상 렌더링됨을
  확인했다.
- `xcodebuild -workspace GitIt.xcworkspace -scheme UI -destination 'platform=iOS
  Simulator,id=<UDID>' build test`: **BUILD SUCCEEDED / TEST SUCCEEDED**(8개 Suite
  31개 테스트 통과, `LearningSetRow 계약` 포함).

### 재발 방지

- 이후 세션에서 SwiftUI 레이아웃이 예상과 다르게 잘리거나 밀리는 증상을 진단할 때는,
  최근에 수정한 컴포넌트를 먼저 의심하기 전에 `body`를 이진 탐색(섹션을 절반씩
  제거·복원)해 증상이 재현되는 최소 범위를 먼저 좁힌다.
- 세로 `ScrollView` 안에 고정 폭 자식들을 담은 `HStack`을 배치할 때는, 그 자식들의
  합산 폭이 대상 화면 폭을 넘을 수 있는지(특히 고정 `frame(width:)`를 가진 컴포넌트
  두 개 이상을 나란히 배치하는 경우) 미리 계산하고, 넘을 수 있으면 처음부터
  `ScrollView(.horizontal)`로 감싼다.
- `GeometryReader`의 `proxy.frame(in: .global)`을 `NSLog`로 로깅하는 방법이 시뮬레이터
  환경에서 SwiftUI 레이아웃 오프셋의 실제 수치 원인(중앙 정렬 폭 불일치 등)을 확인하는
  데 유효했다.

### 연결

없음

## TS-20260823-001: Feature scheme의 `test-without-building`이 시뮬레이터에서 테스트 진입 전 SIGSEGV로 크래시한다

**기록일**: 2026-08-23
**상태**: 환경 제약
**발생 단계**: `/speckit-implement` — Feature 패키지(T154~T186) 구현·검증 중 T186(`build`·`compile`·`test`)에서 발견
**관련 항목**: `specs/014-all-usecases-implementation/tasks.md`의 T186,
`sources/Projects/Feature/**`(U01~U08 8개 TCA Feature 전체)

### 증상

Feature shared scheme으로 `xcodebuild ... -scheme Feature ... test`(test-without-building)를
실행하면 실제 테스트 코드가 실행되기 전에 `xctest` 프로세스가
`EXC_BAD_ACCESS(SIGSEGV)`로 크래시한다. 크래시 스택은 `realizeAllClasses →
swift_getSingletonMetadata` 프레임을 포함하며 시스템 프레임워크 `LocalStatusKit`이
관여한다.

### 영향

T186의 "build·compile·test 실행하고 결과를 기록한다" 중 `test` 항목이 완전히
검증되지 않은 채로 남는다. Feature 패키지의 실제 프로덕션 코드·테스트 코드 자체의
결함인지, 로컬 빌드 환경의 문제인지 이 세션 안에서는 확정하지 못했다. `build`와
`build-for-testing`(compile)은 Feature scheme을 포함해 8개 scheme 전부 성공했고,
Feature를 제외한 나머지 7개 scheme(Domain/Infrastructure/Data/Composition/UI/
UIUITests/AppTests)은 `test`까지 전부 정상 통과해, 이 크래시가 Feature 패키지 범위에만
재현된다.

### 근거

- `xcodebuild -workspace GitIt.xcworkspace -scheme Feature -destination 'platform=iOS
  Simulator,...' test`: 반복 실행 시 매번 `EXC_BAD_ACCESS(SIGSEGV)`,
  `realizeAllClasses → swift_getSingletonMetadata` 프레임, `LocalStatusKit` 관여를
  동일하게 재현.
- `project_build_runner test`(8개 scheme 전체 실행): `성공=7 실패=1`(Feature만 실패,
  나머지 7개는 전부 성공).
- Xcode 26.5.2 / iOS 26.5 시뮬레이터 환경에서 관찰.

### 원인

확정하지 못함. Feature target이 이 저장소에서 `ComposableArchitecture` 매크로
확장이 가장 많고(`@Reducer`/`@ObservableState`/`@CasePathable`/`@ViewAction`을 U01~U08
8개 Feature 전체에 적용) `UIComponent`·Lottie를 통째로 링크하는 target이라는 점이
관련 있을 것으로 추정하나, 매크로 확장 규모·링크 그래프 크기·`LocalStatusKit`(시스템
프레임워크) 중 무엇이 실제 트리거인지는 확인하지 못했다. 제품 코드(Reducer/View/Test
자체의 논리 결함)가 원인이라는 근거는 발견하지 못했다.

### 조치

다음을 시도했으나 모두 동일하게 재현되어 크래시를 해소하지 못했다.

- DerivedData 삭제 후 재빌드
- 단일 `@Suite`만 선택해 실행(테스트 범위 축소)
- 시뮬레이터 erase 후 재생성
- `CoreSimulatorService` 재시작
- 동일 조건 5회 재시도

사용자 승인 하에 이 문제를 환경 제약으로 기록하고, Feature 패키지의 `build`·
`build-for-testing` 성공과 코드 리뷰 가능한 상태를 근거로 T186 승인 게이트를 통과해
App 패키지(작업 패키지 7) 착수를 진행했다.

### 검증

- `xcodebuild ... -scheme Feature ... build`: **BUILD SUCCEEDED**
- `xcodebuild ... -scheme Feature ... build-for-testing`(compile): **성공**
- `xcodebuild ... -scheme Feature ... test`: **미해결** — 반복 재현되는 SIGSEGV로 실행 불가
- `project_build_runner test`(8개 scheme 전체): 성공=7 실패=1(Feature만 실패)

### 재발 방지

- 이후 세션(App 패키지 이후 전체 완료 검증 T201 등)에서 Feature scheme의 `test`를
  다시 시도할 때는, 먼저 Xcode를 재설치하거나 다른 macOS/Xcode 버전 환경에서
  재현 여부를 확인해 이 문제가 로컬 환경 고유 문제인지 이 저장소의 구성 문제인지
  구분한다.
- 재현되지 않는 환경을 찾으면 그 환경의 Xcode/iOS 시뮬레이터 버전을 이 항목에 후속
  기록으로 남겨 원인 범위를 좁힌다.
- 재현되면 Feature target만 별도로 `@Reducer` 매크로 적용 범위를 줄인 최소 재현
  target을 만들어 이분 탐색하는 방법을 다음 시도로 고려한다.

### 연결

없음

## TS-20260823-002: `SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor` target에서 `@Reducer` 타입과 `StoreOf<>` 프로퍼티가 다른 파일에 있으면 circular reference 컴파일 오류가 난다

**기록일**: 2026-08-23
**상태**: 해결
**발생 단계**: `/speckit-implement` — App 패키지(T190~T192) 구현 중 `RootFeature`/`RootView` 빌드에서 발견
**관련 항목**: `specs/014-all-usecases-implementation/tasks.md`의 T190, T191,
`sources/Projects/App/Sources/RootFeature.swift`, `sources/Projects/App/Sources/RootView.swift`

### 증상

App target은 `SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor`로 설정돼 있다. `@Reducer`
매크로가 적용된 `RootFeature` 타입 선언은 `RootFeature.swift`에 있고, 이를 사용하는
`StoreOf<RootFeature>` 프로퍼티는 `RootView.swift`(다른 파일)에 선언했는데,
`xcodebuild -scheme App build` 시 circular reference 컴파일 오류가 발생했다.

### 영향

`RootFeature`/`RootView`를 계획대로 분리된 두 파일(T190, T191)에 작성한 상태로는
App target이 빌드되지 않아 진행이 중단됐다.

### 근거

- `xcodebuild -workspace GitIt.xcworkspace -scheme App -destination 'platform=iOS
  Simulator,...' build`: `RootFeature`와 `StoreOf<RootFeature>` 선언이 서로 다른
  파일에 있는 상태에서 circular reference 오류로 최초 빌드 실패.
- 같은 조건에서 `RootFeature` 타입 선언에 `nonisolated`를 추가한 뒤 재빌드하면 **BUILD
  SUCCEEDED**로 통과함을 확인.

### 원인

`SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor`가 target 전역 기본 격리를 `MainActor`로
만든 상태에서, `@Reducer` 매크로가 생성하는 확장 코드와 `StoreOf<RootFeature>` 프로퍼티
선언이 서로 다른 파일에 위치하면 두 선언 사이의 격리 추론이 순환 참조로 해석되는
것으로 보인다(Swift 매크로 확장과 MainActor 기본 격리 상호작용에 대한 정확한 컴파일러
내부 동작까지는 확인하지 못함, 증상과 해결 조치만 확정).

### 조치

`RootFeature` `@Reducer` 타입 선언 자체에 `nonisolated`를 직접 붙였다
(`sources/Projects/App/Sources/RootFeature.swift`). 이후 `RootView.swift`의
`StoreOf<RootFeature>` 프로퍼티 선언과의 circular reference가 해소됐다.

### 검증

- `xcodebuild -workspace GitIt.xcworkspace -scheme App -destination 'platform=iOS
  Simulator,...' build`: 수정 전 circular reference 오류로 실패 → `nonisolated` 추가
  뒤 **BUILD SUCCEEDED**로 통과.

### 재발 방지

- 이 저장소처럼 target에 `SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor`가 설정된 상태에서
  `@Reducer` 타입과 그 타입을 사용하는 `StoreOf<>` 프로퍼티를 서로 다른 파일에 나눠
  작성할 때 circular reference 오류가 나면, 우선 해당 `@Reducer` 타입 선언에
  `nonisolated`를 붙여 재현 여부를 확인한다.
- 근본적인 컴파일러 동작 원인은 아직 확정하지 못했으므로, 동일 증상이 다른 Feature나
  App 파일에서 재발하면 이 항목을 참조하는 후속 항목으로 원인 조사를 이어간다.

### 연결

없음
