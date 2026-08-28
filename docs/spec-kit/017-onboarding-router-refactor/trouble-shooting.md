# 017-onboarding-router-refactor 문제 해결 기록

**대상 기능**: `017-onboarding-router-refactor`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260828-001: /speckit-plan에서 실제 코드를 읽지 않고 Composition 패키지 영향을 잘못 추정함

**기록일**: 2026-08-28
**상태**: 해결
**발생 단계**: `/speckit-plan` (Phase 0/1 설계, `plan.md`·`research.md` 초안 작성)
**관련 항목**: `plan.md`(요약, 기술 맥락, 헌법 점검의 "패키지 진행" 절, 프로젝트 구조),
`research.md` 4절, `tasks.md`

### 증상

`/speckit-plan` 초안에서 "Composition 패키지도 `AppEntryFeature`·
`OnboardingRouterFeature`의 새 initializer 시그니처에 맞춰 배선을 갱신해야 한다"고
판단해 패키지 진행 순서를 `Feature → Composition → App`으로 기록했다. 이후
`tasks.md` 생성 직전 실제 소스를 읽자 이 판단이 틀렸음이 드러났다.

### 영향

`tasks.md`에 존재하지 않는 "Composition 패키지 단계"가 그대로 생성됐다면, 구현 단계
(`/speckit-implement`)에서 변경할 필요가 없는
`sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`를 불필요하게
수정하거나, 승인 게이트를 하나 더 거치며 작업 순서가 늘어날 위험이 있었다.

### 근거

- `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift` 전체를
  Read한 결과, 이 타입은 Feature 타입을 전혀 import·참조하지 않고
  `restoreSession`·`fetchMemberProfile`·`signIn`·`signOut`·`completeCuration`·
  `policyConsent` 등 개별 UseCase 프로퍼티만 평평하게(flat) 공개 노출하는 순수
  Composition 조립 구조였다.
- `sources/Projects/App/GitIt/GitItApp.swift:32-48`에서 실제로
  `AppRootFeature(restoreSession: ..., signIn: composition.signIn, ...)`처럼
  `composition`의 개별 프로퍼티를 어떤 Feature initializer 인자에 배정할지 결정하는
  코드는 App 패키지에 있었다.

### 원인

`docs/architecture.md`의 일반 원칙("Composition은 Domain↔Data Adapter 구현과 객체
생성·수명 관리를 담당")만으로 이번 기능이 Composition에도 영향을 준다고 추정하고,
이 프로젝트의 `AppComposition` 실제 구현이 Feature-무관 flat 구조라는 사실을 소스
코드로 확인하지 않은 채 패키지 영향 범위를 판단했다.

### 조치

`AppComposition.swift`와 `GitItApp.swift`를 직접 Read해 확인한 뒤 `plan.md`의 요약,
기술 맥락, 헌법 점검의 "패키지 진행" 절, 프로젝트 구조와 `research.md` 4절을 모두
"Composition 패키지는 변경하지 않는다"로 정정했다. `tasks.md`는 애초에 `Feature → App`
2단계로만 생성했다(Composition 단계 없음).

### 검증

- 소스 코드 직접 확인(Read): `AppComposition.swift`에 Feature 타입 import·참조가
  없음, `GitItApp.swift`가 개별 UseCase를 각 Feature initializer 인자로 배정하는
  코드를 실제로 갖고 있음 — 성공(사실 확인됨).
- `tasks.md`에 Composition 패키지 단계가 생성되지 않았음을 파일 내용으로 확인 —
  성공.
- 실제 리팩토링 구현(`/speckit-implement`)은 아직 실행하지 않아, 계획대로 Composition
  파일 변경이 정말 필요 없는지는 구현 완료 시점에 다시 확인해야 한다 — 미실행.

### 재발 방지

패키지 진행 순서나 영향받는 패키지 목록을 계획에 적을 때는 아키텍처 문서의 일반
원칙만으로 추정하지 않는다. 실제로 그 패키지의 조립 파일(Composition Assembly, App의
실제 생성 호출부 등)을 Read해 어떤 파일이 어떤 타입을 import·참조하는지 확인한 뒤에만
패키지 목록을 확정한다.

### 연결

없음

## TS-20260828-002: Feature 패키지 test 실행이 xctest 부트스트랩 SIGSEGV로 차단됨(016의 TS-20260826-012 계열 재발)

**기록일**: 2026-08-28
**상태**: 환경 제약
**발생 단계**: `/speckit-implement` 작업 패키지 1(Feature) T049 `[no-write]` 검증
**관련 항목**: T049, `sources/Projects/Feature/Tests/AppEntry/Reducers/AppEntryFeatureTests.swift`,
`sources/Projects/Feature/Tests/Onboarding/Reducers/OnboardingGuideFeatureTests.swift`,
`CurationFeatureTests.swift`, `OnboardingExitFeatureTests.swift`,
`OnboardingRouterFeatureTests.swift`, `OnboardingAccessibilityTests.swift`

### 증상

`xcodebuild -workspace sources/GitIt.xcworkspace -scheme Feature ... build-for-testing`
(`project_build_runner compile`이 실행하는 것과 동일)은 매번 성공했지만
(`** TEST BUILD SUCCEEDED **`), 이어지는 `test`/`test-without-building`을 실행하면
특정 테스트가 실패하는 것이 아니라 `xctest` 프로세스 자체가 테스트 준비(bootstrap)
단계에서 죽는다.

```text
Testing failed:
	xctest (NNNN) encountered an error (Early unexpected exit, operation never finished
	bootstrapping - no restart will be attempted. (Underlying Error: The test runner
	crashed while preparing to run tests: xctest at <external symbol>))
```

### 영향

T049(Feature 패키지 `[no-write]` 검증)의 `compile`은 통과했지만 `test`는 이 크래시로
차단되어, 이번 세션에서 새로 작성한 `AppEntryFeatureTests`·`OnboardingGuideFeatureTests`·
`CurationFeatureTests`·`OnboardingExitFeatureTests`·`OnboardingRouterFeatureTests`·
`OnboardingAccessibilityTests`가 실제로 Green(통과)인지 자동화된 방법으로 확정하지
못했다. TDD Red→Green 전환의 "Green" 확인이 이 환경 문제로 미완료 상태로 남는다.

### 근거

- `~/Library/Logs/DiagnosticReports/xctest-2026-08-28-034623.ips`(및 재현마다 생성된
  동일 패턴 `.ips` 여러 건)를 파싱: crashed thread가
  `+[XCTestCase(RuntimeUtilities) allSubclasses]` → `objc_copyClassList` →
  `realizeAllClasses()` → `swift_getSingletonMetadata` →
  `_swift_relocateClassMetadata` → `computeMetadataBoundsFromSuperclass`이고 exception은
  `EXC_BAD_ACCESS`/`SIGSEGV`, `KERN_INVALID_ADDRESS at 0x0000000000bad4007`다. 즉 특정
  테스트 코드 실행 전, XCTest가 프로세스 내 모든 Objective-C 클래스를 강제로 realize하는
  시점에 크래시한다.
- 이 crash signature와 crashed thread 프레임은
  `docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md`의
  TS-20260826-012·TS-20260827-002·TS-20260827-006이 이미 기록한 것과 프레임 단위로
  동일하다 — 017에서 새로 발생한 문제가 아니라 기존에 반복 관찰된 미해결 환경 문제의
  재발이다.
- `rm -rf sources/DerivedData/PreCommit/TestSchemes/Feature` 후 clean
  `build-for-testing`으로 재빌드: `** TEST BUILD SUCCEEDED **`이지만 이어지는
  `test-without-building`은 동일하게 크래시(캐시 문제 아님).
- `xcodebuild ... -only-testing:FeatureTests/OnboardingExitFeatureTests`로 테스트
  하나만 선택해도 동일하게 크래시(특정 테스트 코드와 무관, bootstrap 단계에서 발생).
- `xcrun simctl shutdown/erase/boot 580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F` 후 재시도:
  동일하게 재현(시뮬레이터 상태 손상 문제 아님).
- `killall -9 com.apple.CoreSimulator.CoreSimulatorService` 후 재시도: 동일하게 재현.
- `xcrun simctl create`로 완전히 새로운 시뮬레이터 디바이스(iPhone 17 Pro / iOS 26.5,
  `D3FDE195-DF3D-4057-A043-ACE76B11F959`)를 만들어 재시도: 동일한 crash signature로
  재현(`Test crashed with signal segv while preparing to run tests`) — 기존 디바이스의
  개별 상태 문제가 아니라 이 세션의 Xcode(17F113)/iOS 26.5 Simulator 런타임 조합 자체의
  문제일 가능성을 강화한다. 이 임시 디바이스는 정리(삭제)했다.
- 같은 세션의 `project_build_runner compile`(전체 8개 scheme) 실행에서 Feature·
  Domain·Data·Infrastructure는 성공했고 AppTests만 실패했다(App 패키지가 아직 이번
  리팩토링을 반영하지 않아 `OnboardingFeature` 참조가 남아있는 예상된 실패로, 이 크래시와
  무관).

### 원인

확정되지 않음 — 016의 TS-20260826-012·TS-20260827-002·TS-20260827-006이 이미 근본
원인을 미확인으로 남긴 것과 동일하다. 이번 세션에서 추가로 확보한 근거(완전히 새로운
시뮬레이터 디바이스에서도 동일 재현)는 "이 기능의 코드 변경이 원인"이라는 가설과
"디바이스별 상태 손상이 원인"이라는 가설을 모두 배제하고, Xcode(17F113)/iOS 26.5
Simulator 런타임 조합 자체의 문제라는 기존 가설을 강화한다.

### 조치

이 crash를 우회하는 프로젝트 설정 변경은 시도하지 않았다(016의 선례를 따름 — 근본
원인이 불명인 상태에서 임의로 설정을 바꾸지 않는다). Feature 패키지의 실제 코드 변경
(Reducer·Screen·Preview·TestDoubles·Tests)은 그대로 유지했다. 사용자에게 test 실행이
이 환경 문제로 차단되었음을 보고하고, `compile` 성공(타입 정확성과 SC-002 관련 독립
컴파일 확인)까지만 이 세션에서 확정했다고 알릴 예정이다.

### 검증

- `xcodebuild ... -scheme Feature ... build-for-testing`: `** TEST BUILD SUCCEEDED **`
  — 성공(반복 재현).
- `xcodebuild ... -scheme Feature ... test-without-building`(여러 회, 서로 다른
  시뮬레이터 디바이스 포함): 매번 동일한 부트스트랩 SIGSEGV — 실패(미해결로 기록,
  성공 근거 없음).

### 재발 방지

016의 TS-20260826-012·TS-20260827-002·TS-20260827-006이 이미 남긴 재발 방지 절차를
그대로 따른다: Feature/App처럼 `ComposableArchitecture`를 사용하는 scheme에서 `test`
실행이 특정 테스트 실패가 아니라 bootstrap 단계 SIGSEGV로 죽으면, 먼저 이 문제가 코드
결함이 아니라 이 저장소가 반복 관찰한 환경 문제일 가능성을 가정한다. 시간이 허락하면
디바이스 교체·CoreSimulator 재시작·DerivedData 삭제를 시도할 수 있지만, 016의 기록과
이번 재현 모두 이 세 가지로는 해소되지 않았으므로 근본 해결책(Xcode/Simulator 버전
갱신 등 이 세션이 수행할 수 없는 조치)이 필요할 가능성이 높다는 것을 사용자에게 조기에
알린다.

### 연결

[[TS-20260826-012]]

## TS-20260828-003: 동일한 xctest 부트스트랩 SIGSEGV가 App 패키지 AppTests scheme에서도 재현됨(TS-20260828-002 범위 확장)

**기록일**: 2026-08-28
**상태**: 환경 제약
**발생 단계**: `/speckit-implement` 작업 패키지 2(App) T056 `[no-write]` 검증
**관련 항목**: T056, `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`,
`sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`,
`sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`, TS-20260828-002

### 증상

T050~T055(App 패키지 테스트 재작성·구현)를 마친 뒤 `project_build_runner compile`과
`test`를 8개 scheme 전체 범위로 두 차례(각 약 4분) 실행했다. `compile`은 매번
`시도=8 성공=8 실패=0`으로 전부 성공했다. 이어지는 `test`는 두 번 모두
`시도=8 성공=5 실패=3`이었고, 그중 `AppTests`와 `Feature`가 TS-20260828-002와 동일한
패턴으로 실패했다.

```text
Testing failed:
	GitIt (NNNNN) encountered an error (Early unexpected exit, operation never finished
	bootstrapping - no restart will be attempted. (Underlying Error: The test runner
	crashed while preparing to run tests: GitIt at <external symbol>))
```

`Composition`도 실패했지만 이는 이 크래시와 무관한 별개의 기존 실패
(`AppCompositionSharedLifetimeTests`·`AppCompositionTests`의 access token 공유 검증
실패)였다. `Infrastructure`·`Data`·`Domain`·`UI`·`UIUITests`는 두 실행 모두 정상
통과했다.

### 영향

`compile` 성공으로 `AppRootFeature.swift`가 `AppEntryFeature`·`OnboardingRouterFeature`를
올바른 타입으로 조합하고 `AppRootFeatureTests.swift`·`AppRootTestSupport.swift`가 새
초기화 시그니처에 맞춰 타입 정확하게 컴파일됨은 확인했다. 그러나 T050~T053에서
작성·구현한 `AppRootFeatureTests`의 대표 진입 판단 4가지(미인증→`onboarding(startingAt:
.guide)`, 인증+프로필 미완료→`onboarding(startingAt: .curation)`, 인증+프로필
완료→`mainShell`, 복원 가능한 실패 후 재시도)가 실제로 Green인지는 이 환경 문제로
자동화된 방법으로 확정하지 못했다. TDD Red→Green 전환의 "Green" 확인이 Feature
패키지(TS-20260828-002)에 이어 App 패키지에서도 동일한 사유로 미완료 상태로 남는다.

### 근거

- 두 번째 `test` 실행 로그: `AppTests` 실패 메시지가
  `GitIt (20179) encountered an error (Early unexpected exit, operation never finished
  bootstrapping ...)`로 TS-20260828-002가 기록한 `Feature` scheme의
  `xctest (NNNN) encountered an error (Early unexpected exit, operation never finished
  bootstrapping ...)`와 동일한 "부트스트랩 단계에서 프로세스 자체가 죽는다"는 신호
  패턴이다(테스트 실행 결과가 아니라 테스트 러너 준비 단계 크래시).
- 같은 실행에서 `Feature` scheme도 동일 패턴으로 실패해, 이 문제가 특정 패키지 코드
  변경이 아니라 세션 전반의 환경 문제로 재발했음을 뒷받침한다.
- `compile`은 `AppTests`를 포함해 8개 scheme 모두 두 번 다 성공했다 — 크래시가 코드의
  타입·구성 오류가 아니라 `test-without-building` 실행 단계에서만 발생한다는 점에서
  TS-20260828-002의 근거와 일치한다.
- 동일한 크래시 재현을 두 번(반복 `test` 실행) 모두 확인했다.

### 원인

확정되지 않음 — TS-20260828-002가 이미 미확인으로 남긴 것과 동일한 원인(Xcode
17F113/iOS 26.5 Simulator 런타임 조합 추정)이며, 이번 관찰은 그 문제가 `Feature`
scheme에 국한되지 않고 `ComposableArchitecture`를 사용하는 다른 scheme(`AppTests`)에도
동일하게 영향을 준다는 근거를 추가할 뿐 새로운 원인 가설을 제시하지 않는다.

### 조치

TS-20260828-002·016의 선례를 따라 이 크래시를 우회하는 프로젝트 설정 변경은 시도하지
않았다. App 패키지의 실제 코드 변경(`AppRootFeature.swift`·`AppRootView.swift`·
`AppRootFeatureTests.swift`·`AppRootTestSupport.swift`)은 그대로 유지했다. 사용자에게
`compile` 성공까지만 이 세션에서 확정했고 `test` 실행은 이 환경 문제로 차단되었음을
투명하게 보고했다.

### 검증

- `project_build_runner compile`(8개 scheme, 2회 반복): `시도=8 성공=8 실패=0` — 성공.
- `project_build_runner test`(8개 scheme, 2회 반복): `AppTests`·`Feature`가 매번 동일한
  부트스트랩 크래시로 실패 — 실패(미해결로 기록, 성공 근거 없음).

### 재발 방지

TS-20260828-002의 재발 방지 절차를 그대로 따르되, 이 문제가 `Feature` scheme에만
한정되지 않는다는 점을 추가한다: App 패키지를 포함해 `ComposableArchitecture`를 사용하는
어느 scheme에서든 `test` 실행이 특정 테스트 실패가 아니라 부트스트랩 단계에서 프로세스
자체가 죽으면(`Early unexpected exit, operation never finished bootstrapping`), 먼저 이
세션이 반복 관찰한 환경 문제(Xcode/Simulator 런타임 조합 추정)로 가정하고 코드 결함을
의심하기 전에 `compile`(빌드) 성공 여부로 타입·구성 정확성만 별도로 확인한다.

### 연결

[[TS-20260828-002]]

## TS-20260828-004: Simulator 수동 검증이 git-it.kr 네트워크 미도달로 SC-005 2~4단계를 재현하지 못함

**기록일**: 2026-08-28
**상태**: 환경 제약
**발생 단계**: `/speckit-implement` 전체 완료 검증 T058(quickstart.md "수동 확인 — 사용자
흐름 무변경(SC-005)" 절차)
**관련 항목**: T058, quickstart.md "수동 확인" 절, `sources/Projects/App/Config/debug.xcconfig`,
`sources/Projects/App/GitIt/Screens/AppRootView.swift`, `sources/Projects/App/GitIt/GitItApp.swift`,
TS-20260828-002, TS-20260828-003

### 증상

iOS Simulator(iPhone 17 Pro, `580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F`)에
`sources/DerivedData/PreCommit/Build/Products/Debug-iphonesimulator/GitIt.app`
(`com.nexters.hytime.gitit`, 같은 세션의 `project_build_runner build`로 새로 빌드됨)을
설치·실행했다. 앱 실행 직후 스플래시 없이 바로 `AppEntryScreen`의 오류 상태("세션을
확인하지 못했어요" / "네트워크 상태를 확인한 뒤 다시 시도해 주세요." / "다시 시도"
버튼)가 표시됐다. "다시 시도"를 탭해도 크래시 없이 동일한 오류 상태를 유지했다.

### 영향

`AppRootView.swift`(T054)가 `restoring` 단계 placeholder를 `AppEntryScreen(store:)`로
교체한 배선과, 재시도(`retryTapped`) 흐름이 크래시 없이 idempotent하게 동작함은 실기기
수준에서 확인했다. 그러나 quickstart.md가 요구하는 SC-005 수동 확인 절차의 2~4단계
(로그아웃 상태 실행 → 튜토리얼 → 약관 동의 → Apple 로그인 → 포지션/경력 선택 →
MainShell 진입 순서 확인, 포지션 화면 뒤로 가기 확인, 온보딩 완료 계정 재실행 시
MainShell 직행 확인)는 이 세션에서 재현하지 못했다.

### 근거

- `sources/Projects/App/Config/debug.xcconfig:10`: `GIT_IT_API_HOST = git-it.kr` — DEBUG
  빌드가 실제 운영/스테이징 호스트를 가리킨다.
- 시뮬레이터 스크린샷(2회, 최초 실행과 "다시 시도" 탭 이후): 두 번 모두 동일한
  `AppEntryScreen`의 `errorContent`("세션을 확인하지 못했어요" 등) 상태로,
  `AppEntryFeature`의 `restoreSessionFinished(.recoverableFailure)` 분기가 매번
  선택됐음을 시사한다.
- `sources/Projects/App/GitIt/GitItApp.swift`(DEBUG): 세션을 초기화하는
  `DebugSessionResettingRestoreSessionUseCase`가 실제 `composition.restoreSession`
  (네트워크 호출)을 감싸고 있어, 이 실패가 세션 상태 문제가 아니라 그 아래 네트워크
  호출 결과에서 비롯됨을 뒷받침한다.

### 원인

확정되지 않음 — 이 세션의 Simulator/도구 환경이 외부 네트워크(`git-it.kr`)에 도달하지
못하는 것으로 추정만 했다(직접적인 네트워크 진단 명령을 실행해 확정하지는 않았다).
TS-20260828-002·TS-20260828-003이 기록한 xctest 부트스트랩 SIGSEGV와는 증상·원인이
다르다(그것은 테스트 러너 프로세스 자체의 크래시이고, 이번은 실행 중인 앱이 정상
동작하며 네트워크 호출 결과만 실패로 귀결되는 차이가 있다).

### 조치

이 제약을 우회하는 프로젝트 설정 변경이나 목(mock) 서버 전환은 시도하지 않았다.
`AppEntryScreen`까지의 `restoring` 단계 렌더링과 재시도 흐름만 실기기 수준에서
확인한 상태로 남기고, SC-005 2~4단계는 미검증 범위로 사용자에게 투명하게 보고할
예정이다.

### 검증

- Simulator 스크린샷 확인(2회): `AppEntryScreen` 오류 상태 렌더링과 재시도 후에도
  크래시 없음 — 성공(이 범위만).
- SC-005 2~4단계(튜토리얼~MainShell 전체 여정) 재현: 네트워크 도달 불가로 미실행.

### 재발 방지

다음 세션에서 SC-005 전체 여정을 수동 검증하려면 먼저 이 환경이 `git-it.kr`(또는 대체
테스트 서버)에 실제로 도달 가능한지 확인한다(예: 네트워크 접근 권한을 가진 환경에서
재실행하거나, 로컬 mock 서버로 `GIT_IT_API_HOST`를 바꾼 별도 설정으로 검증). 도달
가능성을 먼저 확인하지 않으면 recoverableFailure 상태를 코드 결함으로 오판할 위험이
있다.

### 연결

[[TS-20260828-002]] [[TS-20260828-003]]

## TS-20260828-005: xctest 부트스트랩 SIGSEGV의 원인을 crash report 직접 분석으로 특정함(LocalStatusKit, 원인 미확인 상태 갱신)

**기록일**: 2026-08-28
**상태**: 환경 제약
**발생 단계**: `/speckit-implement` 전체 완료 검증 이후 사용자 요청에 따른 근본 원인
분석(부트스트랩 에러 원인 분석)
**관련 항목**: TS-20260828-002, TS-20260828-003,
`sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`

### 증상

TS-20260828-002·TS-20260828-003이 "원인 미확인"으로 남긴 xctest 부트스트랩 SIGSEGV의
crash report(`.ips`) 4건(`GitIt-2026-08-28-143322.ips`,
`xctest-2026-08-28-143404.ips`, `xctest-2026-08-28-135746.ips`,
`xctest-2026-08-28-035244.ips` — App/Feature scheme, 이번 세션과 이전 세션에 걸친
서로 다른 시각)을 `~/Library/Logs/DiagnosticReports/`에서 Python으로 JSON 파싱해
crashed thread(`faultingThread`)의 프레임과 `usedImages`를 직접 확인했다.

### 영향

원인이 GitIt 프로젝트 코드나 의존성이 아니라 Apple 내부 전용 시스템 프레임워크로
특정됨에 따라, 다음 세션이 이 크래시를 프로젝트 코드 문제로 오판해 코드를 수정하는
헛수고를 방지할 수 있다. 다만 근본 해결(Xcode/Simulator 런타임 교체)은 이 세션의 권한
밖이라는 결론은 TS-20260828-002·003과 동일하게 유지된다.

### 근거

- 4건의 crash report 모두 crashed thread 프레임 구조가 100% 동일했다:
  `computeMetadataBoundsFromSuperclass(...)`(libswiftCore.dylib) ←
  `_swift_relocateClassMetadata(...)`(libswiftCore.dylib) ←
  `swift_getSingletonMetadata`(libswiftCore.dylib) ←
  `<deduplicated_symbol>`(이미지: LocalStatusKit, imageOffset 24900) ←
  `realizeAllClasses()`(libobjc.A.dylib) ← `objc_copyClassList`(libobjc.A.dylib) ←
  `+[XCTestCase(RuntimeUtilities) _allSubclasses]`/`allSubclasses`(XCTestCore) ←
  `+[XCTestSuite suitesForBundlesIncludingEmptySuites:]` ← ... ← `_XCTestMain` ←
  (App scheme의 경우) `RunTestsFromRunLoop` ← `UIApplicationMain` ←
  `static App.main()` ← `GitItApp.$main()`.
- `usedImages`에서 크래시를 유발한 이미지를 확인한 결과 `CFBundleIdentifier`가
  `com.apple.internal.LocalStatusKit`인 Apple 내부 전용 private framework였다(경로
  `.../LocalStatusKit.framework/LocalStatusKit`, `CFBundleShortVersionString` 1.0,
  `CFBundleVersion` 1). GitIt 프로젝트나 그 어떤 서드파티 의존성(ComposableArchitecture
  등)에도 속하지 않는, iOS Simulator 런타임이 모든 앱 프로세스에 주입하는 시스템
  프레임워크다.
- `exception`은 `EXC_BAD_ACCESS`/`SIGSEGV`, `subtype`은
  `KERN_INVALID_ADDRESS at 0x000000000bad4007` — Swift 런타임이 흔히 쓰는
  poison/sentinel 값 패턴(`0xbad4007`)을 역참조했다.
- 같은 세션에서 GitIt.app을 iPhone 17 Pro Simulator에 테스트 없이 설치·실행했을 때는
  이 크래시가 재현되지 않고 `AppEntryScreen`까지 정상 렌더링·재시도 흐름을 확인했다
  (TS-20260828-004에 기록). 즉 이 크래시는 XCTest의 test discovery 단계
  (`+[XCTestCase(RuntimeUtilities) allSubclasses]`가 프로세스 내 모든 로드된
  Objective-C 클래스를 강제로 realize하기 위해 `objc_copyClassList()`를 호출하는
  지점)에서만 재현된다.
- `xcrun simctl create`로 iPhone 16 Pro/iOS 18.0 임시 디바이스
  (`02502474-6C2A-4DE2-87B0-B918206F8109`)를 만들고 부팅한 뒤
  `xcodebuild -workspace sources/GitIt.xcworkspace -scheme Feature ...
  -destination 'platform=iOS Simulator,id=02502474-...' build-for-testing`을
  실행했다. "Unable to find a destination matching the provided destination
  specifier"로 실패했고, `Feature` scheme의 "Available destinations" 목록에
  iOS 26.5 iPhone 17 Pro만 나열되고 iOS 18.0 디바이스는 나타나지 않았다.
- `sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift`와
  `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`를 grep한
  결과 모든 target의 `deploymentTargets`가 `.iOS("26.0")`으로 고정돼 있어, Xcode가
  애초에 iOS 18.0 시뮬레이터를 이 scheme의 유효한 destination에서 제외함을 확인했다.
  `xcrun simctl list runtimes`로 이 머신에는 iOS 18.0과 26.5 런타임만 설치돼 있음을
  확인했다(iOS 26.0~26.4대 런타임 없음).

### 원인

특정됨(단, 완전한 근본 원인은 Apple 내부 구현이라 이 세션에서 더 깊이 확인할 수 없음):
이 머신의 Xcode 26.6(빌드 17F113)에 포함된 iOS 26.5 Simulator 런타임(빌드 23F77)의
Apple 내부 전용 프레임워크 `LocalStatusKit`에 있는 어느 Swift 클래스의 resilient class
metadata pattern(슈퍼클래스 크기 정보)이 손상돼 있거나 이 OS/Xcode 빌드 조합 자체의
결함으로, `objc_copyClassList()`가 프로세스의 모든 클래스를 강제 realize할 때
`computeMetadataBoundsFromSuperclass`가 poison 포인터를 역참조해 SIGSEGV로 죽는다.
GitIt 프로젝트 코드·의존성과는 무관하다.

### 조치

이 프로젝트의 `deploymentTargets`(`.iOS("26.0")`)를 낮추거나 프로젝트 설정을 바꿔
다른 런타임으로 우회하는 시도는 하지 않았다(FR과 무관한 임의 설정 변경이며, 이미
설치된 런타임(iOS 18.0/26.5)만으로는 애초에 이 프로젝트의 유효한 destination이 되지
않아 실효성도 없었다). 임시로 만든 iOS 18.0 Simulator 디바이스는
`xcrun simctl delete`로 정리했다.

### 검증

- crash report 4건 프레임 비교: 모두 동일한 프레임·이미지(`LocalStatusKit`) — 성공
  (결정론적 재현 확인).
- iOS 18.0 런타임 우회 시도: `xcodebuild ... -destination
  'platform=iOS Simulator,id=02502474-...' build-for-testing` —
  "Unable to find a destination matching..."로 실패(프로젝트 `deploymentTargets`
  제약으로 애초에 시도 불가능함을 확인, 크래시 자체의 재현 여부는 미검증).

### 재발 방지

다음 세션이 이 문제를 근본적으로 해결하려면 이 세션에는 없는 권한/자원이 필요하다:
(1) Xcode 또는 iOS 26.5 Simulator 런타임을 이 결함이 없는 다른 빌드로 교체(다운로드는
네트워크·Apple ID 권한 필요), (2) Apple Feedback(Radar)으로 `LocalStatusKit` 크래시를
보고, (3) 대안으로 `xctest` 앱 호스트 경로를 거치지 않는 테스트 실행 방법(예: 순수
Swift Package 모듈이라면 `swift test` CLI로 Simulator UI 호스트를 우회)이 이 프로젝트
구조(Tuist 멀티 패키지, iOS 프레임워크 target)에 적용 가능한지 검토. 이 크래시를 다시
만나면 먼저 이 항목의 `LocalStatusKit` 프레임 시그니처와 일치하는지 확인해 이미 특정된
원인임을 재확인하고, 코드 결함으로 오판하지 않는다.

### 연결

[[TS-20260828-002]] [[TS-20260828-003]]

## TS-20260828-006: iOS 26.4 Simulator 런타임으로 교체 시도 — LocalStatusKit SIGSEGV는 사라졌으나 SDK 불일치로 다른 SIGABRT가 재현됨

**기록일**: 2026-08-28
**상태**: 환경 제약
**발생 단계**: 사용자 요청("다른빌드로 바꿔봐")에 따른 TS-20260828-005 근본 원인 검증
**관련 항목**: TS-20260828-002, TS-20260828-003, TS-20260828-005

### 증상

TS-20260828-005가 특정한 `LocalStatusKit` SIGSEGV가 iOS 26.5(빌드 23F77)에 특정된
것인지 확인하기 위해, 사용자 승인을 받아 다른 빌드의 iOS Simulator 런타임을 실제로
설치해 재현 여부를 검증했다. `xcodebuild -downloadPlatform iOS -buildVersion 26.4
-architectureVariant arm64`로 iOS 26.4 Simulator Runtime(빌드 23E244, arm64 전용
8.46GB)을 다운로드·설치했다(`xcrun simctl list runtimes`로 설치 확인, 다운로드 속도가
느려 총 소요 시간이 길었음을 사전에 안내하고 승인받은 뒤 백그라운드로 진행). 이
런타임에 임시 디바이스(`RootCauseProbe-iOS264`)를 만들어 `Feature` scheme을
`build-for-testing`(성공)한 뒤 `test-without-building`을 실행하자 EXIT=65로 실패했다.
다만 실패 메시지는 이전과 달랐다:

```text
xctest (52447) encountered an error (Early unexpected exit, operation never finished
bootstrapping - no restart will be attempted. (Underlying Error: Test crashed with
signal abrt before establishing connection.))
```

SIGSEGV가 아니라 SIGABRT였다.

### 영향

"다른 빌드로 바꾸면 해결되는지"를 실제로 검증했다는 점에서 TS-20260828-005의 가설을
강화했지만(아래 원인 참고), 이 머신에서 실제로 설치 가능한 iOS 26.4 런타임으로는 test
discovery 차단이라는 결과 자체는 해소되지 않았다. Feature 패키지 `test` 실행이 여전히
불가능한 상태는 변하지 않는다.

### 근거

- 새로 생성된 crash report(`~/Library/Logs/DiagnosticReports/xctest-2026-08-28-192843.ips`)를
  TS-20260828-005와 같은 방식(Python으로 JSON 파싱)으로 분석했다.
  `exception.type`은 `EXC_CRASH`/`SIGABRT`이고, `termination`은
  `namespace: DYLD`, `indicator: Symbol missing`,
  `reasons: ["Symbol not found: _OBJC_CLASS_$_SFAirDropTransferChange",
  "Referenced from: .../iOS 26.4.simruntime/.../System/Library/PrivateFrameworks/
  ShareSheet.framework/ShareSheet", "Expected in: /private/tmp/*/Sharing.framework/
  Sharing"]`, `details: ["(terminated at launch; ignore backtrace)"]`였다.
- 즉 테스트 바이너리가 링크한 `Sharing.framework`(point-free `Sharing` SPM 패키지,
  ComposableArchitecture 생태계 의존성)가 기대하는
  `_OBJC_CLASS_$_SFAirDropTransferChange` 심볼이 iOS 26.4의 `ShareSheet.framework`
  (private framework)에는 없어서, dyld가 launch 시점에 프로세스를 즉시 abort시켰다
  (crashed thread는 전부 `dyld`/`dyld_sim` 프레임뿐이었고 `computeMetadataBoundsFrom
  Superclass`·`LocalStatusKit` 프레임은 전혀 나타나지 않았다 — 이전 크래시와 완전히
  다른 결함임을 확인).
- `xcrun simctl list runtimes`: iOS 26.4 (23E244) 설치 확인.
- `xcodebuild ... -destination 'platform=iOS Simulator,id=<RootCauseProbe-iOS264>'
  build-for-testing`: 성공(EXIT=0) — 빌드 자체는 iOS 26.4 destination에서도 정상
  수행됨을 확인.

### 원인

확인됨(SDK/런타임 버전 불일치로 추정, Apple 내부 구현이라 완전한 근본 원인은 이
세션에서 더 확인 불가): 이 머신의 Xcode 26.6이 기본으로 사용하는 SDK는 설치된 기본
런타임과 버전이 맞는 iOS 26.5이므로, 그 SDK로 빌드된 테스트 바이너리를 그보다 오래된
iOS 26.4 Simulator 런타임에서 실행하면 private framework의 심볼 구성이 달라 launch
자체가 dyld 단계에서 실패한다("빌드에 사용한 SDK보다 오래된 런타임에서 실행"은
일반적으로 Apple이 지원하지 않는 조합). `LocalStatusKit` SIGSEGV(TS-20260828-005)는
iOS 26.4에서는 전혀 재현되지 않았다 — 이는 그 결함이 iOS 26.5(23F77) 런타임 자체에
특정된 것이라는 가설을 뒷받침한다.

### 조치

임시 디바이스(`RootCauseProbe-iOS264`와 iOS 26.4 설치 시 자동 생성된 기본
iPhone 17 Pro 디바이스)는 `xcrun simctl delete`로 정리했다. 다운로드한 iOS 26.4
런타임 자체(약 8.46GB 디스크 사용)를 삭제할지는 사용자에게 확인 후 결정한다.

### 검증

- `test-without-building`(iOS 26.4 destination): SIGABRT로 실패 — 실패
  (LocalStatusKit SIGSEGV는 재현 안 됨, 대신 다른 원인의 실패로 여전히 test
  discovery가 차단됨을 확인).

### 재발 방지

이 머신에서 이용 가능한 iOS 26.x 런타임(iOS 18.0은 이 프로젝트의
`deploymentTargets(.iOS("26.0"))` 미달로 애초에 유효한 destination이 되지 않음, iOS
26.4는 SDK/런타임 버전 불일치로 인한 다른 SIGABRT 발생, iOS 26.5는 TS-20260828-005의
`LocalStatusKit` SIGSEGV)로는 근본 우회가 불가능함이 이번 검증으로 확인됐다. 다음
세션이 이 문제를 다시 시도한다면, 새 iOS 26.5.x 패치 런타임(다운로드 카탈로그에서
확인된 후보: iOS 26.5 Release Candidate 빌드 23F73, 또는 이후 Apple이 배포할 23F77
이후 빌드)을 시도하거나, Xcode 자체를 다른 버전으로 교체(SDK와 런타임 버전을 함께
맞춰) 검증하는 것이 이번에 시도한 "런타임만 교체"보다 유효할 가능성이 높다.

### 연결

[[TS-20260828-002]] [[TS-20260828-003]] [[TS-20260828-005]]

## TS-20260829-001: 파일 이동 뒤 `tuist generate` 없이 빌드해 stale 경로로 6개 scheme이 실패함

**기록일**: 2026-08-29
**상태**: 해결
**발생 단계**: 사용자 직접 지시에 따른 `PolicyConsentUseCase` Domain 이전 리팩터링 구현
(Spec Kit 작업 목록 외 직접 요청)
**관련 항목**: `sources/Projects/Domain/Authentication/UseCases/PolicyConsent/PolicyConsentUseCase.swift`,
`sources/Projects/Domain/Authentication/UseCases/PolicyConsent/PolicyConsent.swift`,
`sources/Projects/Domain/Authentication/Contracts/PolicyConsentRepository.swift`

### 증상

`sources/Projects/Domain/Authentication/UseCases/PolicyConsentUseCase.swift`를
`UseCases/PolicyConsent/PolicyConsentUseCase.swift`로 이동하고 같은 폴더에
`PolicyConsent.swift`(신규 구현체)를 추가한 뒤 `tuist generate`를 다시 실행하지 않고
`project_build_runner build`를 실행했다. `App`·`AppTests`·`Composition`·`Feature`·
`Domain`·`AllTests` 6개 scheme이 모두 다음과 동일한 오류로 실패했다.

```text
error: Build input file cannot be found:
'/Users/.../sources/Projects/Domain/Authentication/UseCases/PolicyConsentUseCase.swift'.
Did you forget to declare this file as an output of a script phase or custom build
rule which produces it? (in target 'DomainAuthentication' from project 'Domain')
```

### 영향

`project_build_runner build` 결과가 `시도=10 성공=4 실패=6`으로 나와, 새로 작성한
`PolicyConsent`/`PolicyConsentRepositoryAdapter` 코드 자체의 컴파일 정확성 여부를 이
로그만으로는 판단할 수 없었다(원인이 코드 오류인지 프로젝트 참조 stale인지 구분 필요).

### 근거

- `./tools/githooks/project-build/bin/run.sh build` 실행 로그: 위 6개 scheme 모두
  동일한 "Build input file cannot be found" 오류로 실패, `Infrastructure`·`Data`만
  성공.
- 이동 전 경로(`UseCases/PolicyConsentUseCase.swift`)는 `git mv`로 실제 파일 시스템에서
  사라졌지만, Tuist가 이전에 생성한 `Domain.xcodeproj`의 pbxproj는 여전히 그 경로를
  build file로 참조하고 있었다.

### 원인

Tuist가 생성한 Xcode 프로젝트는 target의 `sourceDirectory` glob을 생성 시점에 한 번
평가해 개별 파일 참조로 고정한다. 파일을 이동·추가·삭제해도 `tuist generate`를 다시
실행하지 않으면 생성된 `.xcodeproj`가 디스크의 실제 상태와 어긋난다. `AGENTS.md`
셋업 절차는 최초 설치 시의 `make init`/`tuist generate`만 언급하고, 작업 도중 파일을
이동한 뒤 다시 생성해야 한다는 점은 놓치기 쉬웠다.

### 조치

`sources/`에서 `tuist generate --no-open`을 실행해 workspace와 전체 프로젝트를
재생성했다.

### 검증

- `tuist generate --no-open`: `✔ Success — Project generated.`
- 재생성 뒤 `project_build_runner build` 재실행: `시도=10 성공=10 실패=0` — 성공.

### 재발 방지

`sources/Projects/` 아래 Swift 파일을 이동·추가·삭제한 직후에는 빌드를 시도하기 전에
항상 `sources/`에서 `tuist generate`를 먼저 실행한다. "Build input file cannot be
found"류 오류가 나오면 먼저 코드 결함을 의심하기 전에 최근에 파일을 옮기거나
지웠는지, `tuist generate`를 그 뒤에 실행했는지부터 확인한다.

### 연결

없음

## TS-20260829-002: 같은 target 안에서 기존 `PolicyConsentTests` 이름과 겹쳐 신규 테스트 파일이 두 차례 컴파일 실패함

**기록일**: 2026-08-29
**상태**: 해결
**발생 단계**: 사용자 직접 지시에 따른 `PolicyConsentUseCase` Domain 이전 리팩터링 구현
(Spec Kit 작업 목록 외 직접 요청)
**관련 항목**: `sources/Projects/Domain/Tests/Authentication/UseCases/PolicyConsentUseCaseTests.swift`,
`sources/Projects/Domain/Tests/Authentication/Models/PolicyConsentTests.swift`,
TS-20260829-001

### 증상

TS-20260829-001을 해결한 뒤 다시 `project_build_runner build`를 실행하자 `AllTests`
scheme만 다음 오류로 실패했다(다른 9개 scheme은 성공).

```text
error: filename "PolicyConsentTests.swift" used twice:
'.../Domain/Tests/Authentication/Models/PolicyConsentTests.swift' and
'.../Domain/Tests/Authentication/UseCases/PolicyConsentTests.swift'
(in target 'DomainAuthenticationTests' from project 'Domain')
```

파일 이름을 `PolicyConsentUseCaseTests.swift`로 바꾸고 재빌드하자, 파일명 오류는
사라졌지만 다른 오류가 나타났다.

```text
error: invalid redeclaration of 'PolicyConsentTests'
```

### 영향

`AllTests` scheme(전체 test target을 한 번에 build-for-testing하는 CI용 aggregate
scheme)만 실패하고 개별 `Domain` scheme은 통과했다면 원인 파악이 늦어질 수 있었다 —
실제로는 `Domain` 단일 scheme도 같은 `DomainAuthenticationTests` target을 빌드하므로
동일하게 실패했다.

### 근거

- 첫 번째 오류: `project_build_runner build` 로그의 "filename ... used twice" 메시지.
- 두 번째 오류: 파일명만 `PolicyConsentUseCaseTests.swift`로 바꾼 뒤 재빌드한 로그의
  "invalid redeclaration of 'PolicyConsentTests'" 메시지 —
  `Models/PolicyConsentTests.swift:7:8`의 `struct PolicyConsentTests`(정책 문서 모델
  `PolicyConsentRecord.isConsentValid` 검증 스위트)와 새로 만든
  `UseCases/PolicyConsentUseCaseTests.swift:9:8`의 `struct PolicyConsentTests`(신규
  `PolicyConsent` UseCase 검증 스위트)가 이름만 파일 레벨에서 바뀌었을 뿐 타입 이름은
  그대로였다.

### 원인

새 Domain UseCase 테스트 파일을 만들 때 같은 컴파일 target
(`DomainAuthenticationTests`) 안에 이미 `PolicyConsentTests`라는 이름의
`@Suite struct`가 있는지 미리 확인하지 않고 같은 이름을 그대로 사용했다. Swift는 파일
경로가 달라도 같은 target 안에서는 (private/fileprivate가 아닌) 최상위 타입 이름이
유일해야 하고, 파일 이름도 private 선언을 구분하기 위해 target 전체에서 유일해야
한다. `PolicyConsent`(UseCase)와 `PolicyConsentRecord`(Model)처럼 이름이 비슷한
대상을 검증하는 테스트 스위트를 같은 target에 추가할 때 이 충돌이 특히 발생하기 쉽다.

### 조치

새 테스트 파일 이름과 그 안의 `@Suite struct` 이름을 모두
`PolicyConsentUseCaseTests`로 변경했다.

### 검증

- `tuist generate --no-open` 재실행 후 `project_build_runner build`:
  `시도=10 성공=10 실패=0` — 성공.
- `xcodebuild test-without-building ... -only-testing:DomainAuthenticationTests/PolicyConsentUseCaseTests`:
  5개 테스트 모두 통과 — 성공.

### 재발 방지

같은 target(특히 `Tests/<역할>/`) 안에 새 테스트 파일이나 `@Suite`/타입을 추가하기
전에 `grep -rn "<후보 이름>" sources/Projects/<패키지>/Tests/<역할>/`로 이미 같은
이름이 쓰이는지 먼저 확인한다.

### 연결

[[TS-20260829-001]]
