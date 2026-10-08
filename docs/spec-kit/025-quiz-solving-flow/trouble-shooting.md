# 025-quiz-solving-flow 문제 해결 기록

**대상 기능**: `025-quiz-solving-flow`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260903-001: FeatureTests·AppTests가 테스트 부트스트랩 중 SIGSEGV로 죽어 테스트 검증을 완료하지 못함

**기록일**: 2026-09-03
**상태**: 환경 제약
**발생 단계**: `/speckit-implement` 전체 완료 검증 (T072, T078, T079)
**관련 항목**: T072, T078, T079, `tasks.md`, 커밋 `e9b5202`·`099def6`·`ff45ce1`

### 증상

`GIT_IT_PROJECT_BUILD_RUNNER`의 `test`에서 7개 scheme 중 `Feature`와 `AppTests` 2개가
테스트 1건도 실행하지 못하고 실패한다. `build`(9/9)와 `compile`(7/7)은 모두 성공하므로
컴파일 오류가 아니다.

```text
Testing failed:
	xctest (55991) encountered an error (Early unexpected exit, operation never
	finished bootstrapping - no restart will be attempted.
	(Underlying Error: Test crashed with signal segv while preparing to run tests.))
```

크래시는 XCTest가 테스트 클래스를 수집하는 단계에서 발생한다. 스택은 다음과 같다.

```text
computeMetadataBoundsFromSuperclass  (libswiftCore.dylib)
_swift_relocateClassMetadata         (libswiftCore.dylib)
swift_getSingletonMetadata           (libswiftCore.dylib)
<deduplicated_symbol>                (LocalStatusKit)
realizeAllClasses()                  (libobjc.A.dylib)
objc_copyClassList                   (libobjc.A.dylib)
+[XCTestCase(RuntimeUtilities) _allSubclasses]  (XCTestCore)
```

`EXC_BAD_ACCESS (SIGSEGV)`, `KERN_INVALID_ADDRESS at 0x000000000bad4007`.

### 영향

T072(Feature 테스트), T078(App 테스트), T079(build·compile·test)를 완료로 표시할 수 없다.
T022~T032와 T074가 작성돼 있으나 실행으로 통과를 확인하지 못했다. T081의 Simulator 수용
검증도 별도로 미완이다. 후속 세션이 이 상태를 코드 결함으로 오인하지 않아야 한다.

### 근거

- `xcodebuild -version`: `Xcode 26.6 (Build 17F113)`
- `xcrun simctl list runtimes`: 사용 가능한 최신 iOS 런타임이 `iOS 26.5 (23F77)`이며
  `com.apple.CoreSimulator.SimRuntime.iOS-26-4`는 `Unavailable`로 표시된다. Xcode 26.6에
  대응하는 iOS 26.6 런타임이 설치돼 있지 않다.
- `~/Library/Logs/DiagnosticReports/xctest-2026-09-03-100429.ips`,
  `xctest-2026-09-03-135411.ips`: 두 리포트 모두 `FeatureTests` 번들이며 위와 동일한
  스택·시그널을 보인다. 두 시각 모두 이번 기능의 커밋(`e9b5202`, 14시대) 이전이다.
- 새 시뮬레이터(`QA-iPhone17Pro`, iOS 26.5)를 생성해 실행해도 동일하게 재현된다.
- `sources/DerivedData/PreCommit/TestSchemes/Feature`를 삭제하고 `build-for-testing`을
  다시 수행해도 동일하게 재현된다.
- **변경 전 상태에서도 재현**: 커밋 `1248554`(이번 기능의 Feature·App 변경이 전혀 없는
  시점)를 별도 worktree에 checkout하고 `tuist generate` → `build-for-testing` →
  `test-without-building`을 새 `derivedDataPath`로 수행한 결과 같은 크래시가 발생했다.
  이 실험이 이번 구현과의 인과를 배제하는 근거다.
- 신규 Feature 코드에는 `class` 선언이 0건이며, `#Preview`는 이번 변경 이전에도
  Feature 패키지 15개 파일에서 사용 중이었다.

### 원인

확정: 이번 기능의 구현 코드가 원인이 아니다. 변경 전 커밋에서 동일 재현됐다.

가설(확인 중): Xcode 26.6의 XCTest·Swift 런타임과 iOS 26.5 시뮬레이터 런타임의 버전
불일치. `objc_copyClassList`가 시스템 프레임워크 `LocalStatusKit`의 클래스를 realize할 때
상위 클래스 메타데이터를 계산하지 못해 죽는다. 시뮬레이터 상태나 stale DerivedData가
아님은 위 근거로 배제됐다.

### 조치

- 읽기 전용 정적 검증(T080)과 Reducer 주입 대조(T082)를 대신 수행해 커밋 `12a939b`에
  완료로 기록했다.
- UI 정합성은 Xcode Preview 렌더링(`s01`~`s13`)으로 대체 검토했다.
- 런타임 설치(`xcodebuild -downloadPlatform iOS`)는 수 GB 다운로드와 사용자 권한이
  필요해 미실행.

### 검증

- `"$GIT_IT_PROJECT_BUILD_RUNNER" build`: 성공 9/9 (경과 88s).
- `"$GIT_IT_PROJECT_BUILD_RUNNER" compile`: 성공 7/7 (경과 118s).
- `"$GIT_IT_PROJECT_BUILD_RUNNER" test`: 5/7 성공, `Feature`·`AppTests` 실패.
  `UI`·`Composition`·`Infrastructure`·`Data`·`Domain`은 통과.
- 커밋 `1248554` worktree 재현 실험: 동일 크래시로 실패.

### 재발 방지

`test`에서 `Feature` 또는 `AppTests`가 "crashed with signal segv while preparing to run
tests"로 실패하면 먼저 다음을 확인한다.

1. `xcodebuild -version`의 Xcode 버전과 `xcrun simctl list runtimes`의 최신 iOS 런타임
   버전이 일치하는가. 불일치하면 대응 런타임을 설치한 뒤 재시도한다.
2. 크래시 스택이 `objc_copyClassList` → `realizeAllClasses` → 시스템 프레임워크인지
   확인한다. 그렇다면 애플리케이션 코드 수정으로 해결되지 않는다.
3. 코드 인과를 배제하려면 변경 전 커밋을 별도 worktree에 checkout하고 새
   `derivedDataPath`로 같은 scheme을 실행한다.

부수적으로, `build`가 `FBLPromises.framework/Modules/module.modulemap: Permission denied`
로 실패하면 `sources/DerivedData` 아래 읽기 전용 `module.modulemap`에 `chmod u+w`를
적용한다. 이 조치로 실패 3개(`AppTests`·`Composition`·`Infrastructure`)가 해소됐다.

### 연결

없음
