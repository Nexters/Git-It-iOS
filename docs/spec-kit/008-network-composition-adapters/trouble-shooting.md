# 008-network-composition-adapters 문제 해결 기록

**대상 기능**: `008-network-composition-adapters`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260820-001: Composition 스킴에 Test Action이 없어 T010 패키지 검증이 실행조차 되지 않음

**기록일**: 2026-08-20
**상태**: 해결
**발생 단계**: speckit-implement, Composition 패키지 정리와 검증(T010)
**관련 항목**: T010, `xcodebuild test -workspace GitIt.xcworkspace -scheme Composition -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`, `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`

### 증상

T010 검증 명령을 처음 실행하자 빌드/테스트가 시작조차 되지 않고 즉시
`xcodebuild: error: Scheme Composition is not currently configured for the test action.`로
종료됐다.

### 영향

`Composition` 패키지에 새로 추가한 4개 Adapter와 4개 테스트 파일(T002~T009)의 실제
컴파일·실행 결과를 전혀 확인할 수 없는 상태였다 — 코드 결함 여부와 무관하게 검증
자체가 차단됐다.

### 근거

- `xcodebuild test -workspace GitIt.xcworkspace -scheme Composition -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` 1차 실행 로그: `xcodebuild: error: Scheme Composition is not currently configured for the test action.`
- `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.Composition` 스킴 케이스(수정 전): `[.module(name: "Composition")]` — `testTarget:` 인자가 없음. 같은 파일의 `.Domain`/`.Data` 케이스는 각각 `testTarget: "DomainAuthenticationTests"`/`testTarget: "DataAuthenticationTests"`를 명시적으로 넘긴다.
- `extension Scheme { static func module(name:testTarget:) }`(같은 파일) 정의: `testAction: testTarget.map { .targets([.testableTarget(target: .target($0))]) }` — `testTarget`이 `nil`이면 `testAction`이 `nil`이 되어 스킴에 Test Action 자체가 생성되지 않는다.
- `sources/Projects/Composition/CompositionTests/Placeholder.swift`: 008 이전까지 `CompositionTests`에는 이 placeholder 주석 파일 하나뿐이었다(실제 테스트 없음) — 이 gap이 지금까지 드러나지 않은 이유.
- `specs/008-network-composition-adapters/tasks.md` T001: `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`만 소유 경로로 명시하며 `ProjectName.swift`는 어떤 작업에도 배정되지 않았다.

### 원인

`ProjectName.swift`의 `.Composition` 스킴 정의가 애초에 `testTarget`을 넘기지 않아 Test
Action이 없는 상태였다 — 008이 작성한 Adapter/테스트 코드의 결함이 아니라, `CompositionTests`가
실제 테스트를 가져본 적이 없어 드러나지 않았던 기존 Tuist 스킴 구성 gap이다.

### 조치

이 파일이 008 `tasks.md`의 어떤 작업에도 소유 경로로 명시돼 있지 않아 speckit-implement의
"작업 목록에 없는 파일은 수정하지 말고 중단" 규칙에 따라 먼저 멈추고 `AskUserQuestion`으로
처리 방식을 물었다. 사용자가 "No preference"로 응답해 직접 수정을 선택, `.Composition`
케이스를 `[.module(name: "Composition", testTarget: "CompositionTests")]`로 변경한 뒤
`tuist generate`로 워크스페이스를 재생성했다.

### 검증

- `tuist generate --no-open`(수정 후): `✔ Success — Project generated.`
- `xcodebuild test -workspace GitIt.xcworkspace -scheme Composition -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`(재실행): `** TEST SUCCEEDED **`, `Test run with 25 tests in 4 suites passed`, 실패 0건(`ExternalRepositoryRemoteAdapter`·`ExternalRepositoryLookupAdapter`·`LearningProjectRemoteAdapter`·`LearningProjectRepositoryAdapter` 4개 Suite 전부 통과).

### 재발 방지

새 기능이 지금까지 실제 테스트가 없던 target(예: `CompositionTests`, 향후 다른 placeholder-only
target)에 처음으로 테스트를 추가할 때는, 해당 target을 가리키는 Tuist 스킴 정의
(`ProjectName.swift`의 `schemes` 분기)가 `testTarget`을 실제로 넘기고 있는지 구현 착수 전에
먼저 확인한다. 넘기지 않고 있다면 `tasks.md`에 그 파일도 소유 경로로 명시하도록 계획
단계에서 미리 반영한다.

### 연결

없음
