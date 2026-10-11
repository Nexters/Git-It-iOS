# 018-home-screen 문제 해결 기록

**대상 기능**: `018-home-screen`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260830-001: Feature 패키지 test-without-building이 xctest 부트스트랩 SIGSEGV(LocalStatusKit)로 재차단됨

**기록일**: 2026-08-30
**상태**: 환경 제약
**발생 단계**: `/speckit-implement`, T029(Feature 패키지 `[no-write]` build-for-testing·test-without-building 검증) 실행 중
**관련 항목**: T029, `feature/onboarding-login-tutorial-app-integration`의 TS-20260826-012·
TS-20260827-001·TS-20260827-002·TS-20260828-005, `feature/onboarding-router-refactor`의
TS-20260828-002·TS-20260828-003·TS-20260828-005·TS-20260828-006

### 증상

`make tuist` 후 `project_build_runner compile`(7/7 성공, `Feature` 포함)까지는 정상이었다.
이후 `xcodebuild test-without-building -workspace sources/GitIt.xcworkspace -scheme Feature
-destination 'platform=iOS Simulator,name=iPhone 17 Pro'
-derivedDataPath sources/DerivedData/PreCommit/TestSchemes/Feature`를 3회 재시도(최초 실행,
`DerivedData` 삭제 후 `project_build_runner compile`로 재빌드하고 재실행, `xcrun simctl erase`
+ 재부팅 후 재실행)했으나 매번 동일하게 실패했다.

```text
Testing failed:
	xctest (nnnnn) encountered an error (Early unexpected exit, operation never finished
	bootstrapping - no restart will be attempted. (Underlying Error: The test runner crashed
	while preparing to run tests: xctest at <external symbol>))
```

`project_build_runner test`(전체 7개 공유 scheme 실행)에서도 `AppTests`와 `Feature`만 동일
패턴으로 실패했고(`UI`·`Composition`·`Infrastructure`·`Data`·`Domain`은 성공), 이후
`project_build_runner test-unit`(통합 `AllTests` scheme) 실행에서는 하위 모든 xctest 프로세스가
연쇄로 크래시했다.

### 영향

T029(Feature 패키지 `test-without-building` 검증)를 이 세션에서 완료로 확정할 수 없다.
`build-for-testing`(`compile`)은 3회 모두 100% 성공했으므로 프로덕션·테스트 컴파일 자체는
정상이며, 검증 공백은 `test` 실행 단계로 한정된다. `/speckit-implement`는 T029를 미완료로
보존하고 App 실행 단위로 진행하지 않은 채 사용자 보고를 위해 중단했다.

### 근거

- `~/Library/Logs/DiagnosticReports/xctest-2026-08-30-104533.ips`,
  `xctest-2026-08-30-110025.ips`를 Python으로 JSON 파싱한 결과, crashed thread 프레임이
  기존 기록과 100% 동일했다: `computeMetadataBoundsFromSuperclass`(libswiftCore.dylib) ←
  `_swift_relocateClassMetadata` ← `swift_getSingletonMetadata` ←
  `<deduplicated_symbol>`(이미지: `LocalStatusKit`) ← `realizeAllClasses()`(libobjc.A.dylib) ←
  `objc_copyClassList` ← `+[XCTestCase(RuntimeUtilities) _allSubclasses]`/`allSubclasses` ←
  `+[XCTestSuite suitesForBundlesIncludingEmptySuites:]` ← ... ← `_XCTestMain`.
- `exception`은 `EXC_BAD_ACCESS`/`SIGSEGV`, `subtype`은
  `KERN_INVALID_ADDRESS at 0x000000000bad4007` — 016의 TS-20260826-012·TS-20260828-005와
  017의 TS-20260828-005가 특정한 시그니처와 프레임 단위로 동일하다.
- `rm -rf sources/DerivedData/PreCommit/TestSchemes/Feature`
  `sources/DerivedData/PreCommit/TestSchemes/AppTests` 후
  `project_build_runner compile` 재실행(성공) → `xcodebuild test-without-building -scheme
  Feature` 재실행: 동일 크래시 재현(완화 안 됨).
- `xcrun simctl shutdown 580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F` →
  `xcrun simctl erase 580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F` →
  `xcrun simctl boot 580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F` 후 재실행: 동일 크래시 재현
  (완화 안 됨).
- `xcrun simctl list runtimes`: 이 머신에는 여전히 iOS 18.0과 iOS 26.5(23F77)만 설치돼
  있음을 확인(017의 TS-20260828-006이 임시 설치했던 iOS 26.4는 이 세션에는 없음).

### 원인

기존에 특정된 원인과 동일. 이 머신의 Xcode 26.6(빌드 17F113)에 포함된 iOS 26.5 Simulator
런타임(빌드 23F77)의 Apple 내부 전용 프레임워크 `LocalStatusKit`의 resilient class metadata
계산 결함(또는 이 OS/Xcode 빌드 조합 자체의 결함)으로, XCTest의 test discovery
(`objc_copyClassList` 기반 강제 클래스 realize)가 SIGSEGV로 죽는다. GitIt 프로젝트
코드·의존성과 무관하며 `ComposableArchitecture`를 import하는 scheme(`Feature`·`AppTests`,
이를 포함하는 통합 `test-unit`의 `AllTests`)에서 재현된다. 이번 세션이 새로 시도한
`DerivedData` 삭제와 시뮬레이터 완전 `erase`+재부팅 두 완화 경로 모두 재현을 막지 못해,
017의 TS-20260828-005·006이 이미 결론지은 "이 머신에 설치된 런타임만으로는 근본 우회
불가능"이라는 결론을 다시 확인했을 뿐이다.

### 조치

프로젝트 설정이나 `deploymentTargets`를 바꾸는 우회는 시도하지 않았다(017의
TS-20260828-005·006이 이미 실효성 없음을 확인한 경로와 동일). `/speckit-implement`는 T029를
미완료로 보존하고 checkbox·stage·commit을 수행하지 않은 채 사용자에게 보고하기 위해
중단했다.

### 검증

- `xcodebuild -scheme Feature build-for-testing`(`project_build_runner compile`): 3회 모두
  성공.
- `xcodebuild -scheme Feature test-without-building`: 3회 모두 동일 크래시로 실패.
- `project_build_runner test`(7개 공유 scheme): `Feature`·`AppTests`만 실패, 나머지 5개
  성공.
- `project_build_runner test-unit`(통합 `AllTests`): 전체 실패, 연쇄 크래시.

### 재발 방지

017의 TS-20260828-005·006이 남긴 권고(Xcode 또는 iOS 26.5 Simulator 런타임을 이 결함이
없는 다른 빌드로 교체, Apple Feedback으로 `LocalStatusKit` 크래시 보고, SDK-런타임 버전이
일치하는 새 iOS 26.5.x 패치 런타임 확인)가 여전히 유효하며 이번 세션에서 추가로 좁히지
못했다. 다음 세션이 `Feature`·`App` 패키지 test 검증에서 이 crash를 다시 만나면 이 항목과
016·017의 연결 항목을 먼저 참조해 코드 결함으로 오판하지 않는다.

### 연결

`feature/onboarding-login-tutorial-app-integration`의 TS-20260826-012, TS-20260827-001,
TS-20260827-002, TS-20260828-005. `feature/onboarding-router-refactor`의 TS-20260828-002,
TS-20260828-003, TS-20260828-005, TS-20260828-006.

## TS-20260830-002: T038~T042(Simulator·Preview 기반 시각·접근성 검증)가 이 세션 도구 범위 밖으로 확인돼 사용자 승인 예외로 미검증 처리됨

**기록일**: 2026-08-30
**상태**: 환경 제약
**발생 단계**: `/speckit-implement`, 전체 완료 검증(T038~T042, Simulator에서 MainShell·Home
Preview를 실제로 보며 탭 순서·VoiceOver·`DynamicTypeSize` 12단계·Figma `1465:19015`·
`1542:19610` 비교를 검증하는 `[no-write]` 작업) 실행 중
**관련 항목**: T038, T039, T040, T041, T042

### 증상

T034~T037(자동 검증)과 T043~T044(정적 검사)는 모두 완료했다. T038~T042는 두 가지 이유로
이 세션의 도구로 실행할 수 없었다. (1)
`sources/DerivedData/PreCommit/Build/Products/Debug-iphonesimulator/GitIt.app`을 iPhone 17
Pro Simulator에 설치·실행해 스크린샷을 확인한 결과, `AppRootFeature`의 실제
`restoreSession` 흐름이 네트워크·백엔드 인증 세션을 요구해 "세션을 확인하지 못했어요"
오류 화면에서 멈췄고, 이 세션에는 로그인 가능한 테스트 계정이 없어 실제 앱 경로로
MainShell·Home에 도달할 수 없었다. (2) `HomeScreenPreviews.swift`가 정의하는 결정론적
Preview 상태(Project Present/Absent/Loading/Project Failure as Empty/Profile Failure)는
Xcode의 Preview Canvas에서만 렌더링되며, 이 세션이 가진 CLI·Simulator MCP 도구로는 Xcode
Canvas를 구동하거나 그 렌더링 결과를 확인할 방법이 없었다.

### 영향

T038(MainShell 자동화·탭 순서·상태 보존), T039(project-present Home 표시 값·회전·drag),
T040(loading·빈 상태·실패 표현), T041(등록·전체 보기 intent), T042(Figma 차이 분류·
VoiceOver·`DynamicTypeSize` 12단계·터치)의 실제 Simulator·Preview 기반 수용 기준을 이
세션에서 검증하지 못했다. `tasks.md`에서 이 다섯 작업은 미완료(`[ ]`)로 남긴다.

### 근거

- `GitIt.app` 실행 스크린샷(iPhone 17 Pro Simulator, 2026-08-30 11:22 KST): "세션을
  확인하지 못했어요 / 네트워크 상태를 확인한 뒤 다시 시도해 주세요" 오류 화면.
- `xcodebuild -workspace sources/GitIt.xcworkspace -list`: 이 workspace에는 Preview를
  실행할 수 있는 UI 자동화 scheme(XCUITest host 등)이 없고 `AllTests`·`App`·`AppTests`·
  `Composition`·`Data`·`Domain`·`Feature`·`Infrastructure`·`UI` 9개 scheme만 존재함을
  확인했다.

### 원인

이 세션이 가진 도구(Bash, `xcodebuild` CLI, iOS Simulator MCP)로는 실제 백엔드 인증이
필요한 `GitIt.app`의 라이브 로그인 흐름을 우회할 수 없고, SwiftUI Preview Canvas는 Xcode
GUI 전용 렌더링 경로라 CLI·Simulator 자동화 도구의 범위 밖이다. 프로젝트 코드나 이번
기능의 결함이 아니라 이 세션의 실행 환경·권한 범위의 한계다.

### 조치

사용자에게 상황을 보고하고 세 가지 선택지(사용자가 Xcode에서 직접 검증/테스트 계정
제공/승인 예외로 미검증 처리)를 제시했다. 사용자가 "미검증으로 체크하고 다음 작업"을
명시적으로 선택해, T038~T042를 완료 처리하지 않고 미검증 상태로 `tasks.md`에 남긴 채
나머지 완료 검증과 마무리 절차로 진행하는 것을 승인했다.

### 검증

- `GitIt.app` Simulator 실행 1회 시도: 세션 확인 실패로 Home 도달 불가(재현, 재시도하지
  않음).
- Xcode Canvas 기반 Preview 실행: 미실행(이 세션 도구 범위 밖임을 scheme 목록 확인만으로
  판단).

### 재발 방지

다음 세션이 T038~T042와 같은 Simulator/Preview 기반 시각·접근성 수용 기준을 검증하려면
(1) 로그인 가능한 테스트 계정 또는 `restoreSession`을 우회하는 디버그 진입점이
필요하거나, (2) 사용자가 Xcode Canvas에서 직접 Preview를 열어 결과를 알려주는 방식이
필요하다. 이 두 전제 중 하나가 없으면 이 유형의 작업은 자동화 세션에서 반복적으로
차단될 가능성이 높다.

### 연결

없음.
