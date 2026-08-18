# 005-figma-layout-audit 문제 해결 기록

**대상 기능**: `005-figma-layout-audit`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260819-001: Figma MCP 호출 한도 도달

**기록일**: 2026-08-19
**상태**: 환경 제약
**발생 단계**: Figma 레이아웃 상수 조사
**관련 항목**: `spec.md`, `contracts/ui-layout-constants.md`, T004·T005

### 증상

Figma `get_metadata` 호출이 Starter plan의 MCP 호출 한도 오류로 실패해 구조화된 노드 메타데이터를 가져오지 못했다.

### 영향

전체 컴포넌트 트리를 자동 수집할 수 없었고, Figma 직접 근거 수준 `A`는 브라우저에서 100% 배율로 확인한 Action button과 Liquid Glass Icon button 크기로 제한됐다.

### 근거

- `get_metadata`: Starter plan MCP call limit 오류를 반환했다.
- Figma 브라우저 100% 배율 확인: Action button LG 54pt·SM 40pt, Liquid Glass Icon button MD 40pt·SM 36pt를 관찰했다.

### 원인

현재 Figma 계정 플랜의 MCP 호출 한도에 도달한 외부 환경 제약이다.

### 조치

로그인 없이 열리는 Figma 브라우저 화면을 확대해 직접 확인하고, 직접 확인하지 못한 기존 구현값은 근거 수준 `C`로 분리했다.

### 검증

- `contracts/ui-layout-constants.md` 수동 대조: `A`와 `C` 근거가 분리되어 있으며 `C` 값은 Figma 확정값으로 서술하지 않았다.

### 재발 방지

MCP 한도 오류가 발생하면 구조화된 전체 점검을 완료했다고 보고하지 않고, 브라우저 직접 확인 범위와 저장소 기준선을 별도 근거 수준으로 기록한다.

### 연결

없음

## TS-20260819-002: Tuist scheme 인자 순서 오류

**기록일**: 2026-08-19
**상태**: 해결
**발생 단계**: T001·T002 UI 테스트 기반 생성
**관련 항목**: `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`

### 증상

첫 `make tuist` 실행에서 `Scheme` 생성자의 `testAction` 인자 위치가 API 선언 순서와 맞지 않아 manifest 컴파일이 실패했다.

### 영향

workspace 생성과 Red 테스트 실행이 중단됐다.

### 근거

- `make tuist`: `testAction`을 `runAction` 뒤에 전달한 manifest 오류를 출력했다.

### 원인

새 `UIComponentLayout` scheme 선언에서 현재 Tuist `Scheme` 생성자의 인자 순서를 잘못 적용했다.

### 조치

`testAction`을 `runAction`보다 앞에 배치하도록 scheme 선언을 교정했다.

### 검증

- `make tuist`: workspace 생성 성공.
- `xcodebuild -list -json -workspace sources/GitIt.xcworkspace`: `UIComponentLayout`, `UIComponent`, `DesignSystem` scheme 확인.

### 재발 방지

Tuist helper를 추가할 때 저장소의 기존 `Scheme` 생성 예시와 현재 컴파일러 진단의 인자 순서를 먼저 대조한다.

### 연결

없음

## TS-20260819-003: 기본 iPhone 17 Pro Simulator 데이터 누락

**기록일**: 2026-08-19
**상태**: 해결
**발생 단계**: T007 UI 테스트 Red 실행
**관련 항목**: `UIComponentLayout`, T015·T017

### 증상

이름 기반 `iPhone 17 Pro` destination이 가리킨 기기의 `data` 디렉터리가 없어 UI 테스트 runner가 앱을 실행하지 못했다.

### 영향

첫 UI 테스트 실패가 레이아웃 단언 실패인지 환경 실패인지 구분할 수 없었다.

### 근거

- `xcresulttool get test-results summary`: `Unable to boot device because it cannot be located on disk`와 누락된 Simulator data 경로를 보고했다.
- `xcrun simctl list devices available`: 별도의 부팅된 `default` Simulator UUID를 확인했다.

### 원인

Xcode가 이름 기반 destination으로 선택한 Simulator 레코드와 실제 디스크 데이터가 불일치했다.

### 조치

현재 부팅된 `default` Simulator의 UUID를 destination으로 명시해 Red와 Green 테스트를 재실행했다.

### 검증

- `xcodebuild test -workspace sources/GitIt.xcworkspace -scheme UIComponentLayout -destination 'platform=iOS Simulator,id=<booted-device>'`: Red 단언 실패 확인 후 최종 성공.
- 공용 runner `test`: 9개 testable scheme 성공.

### 재발 방지

이름 기반 destination이 launch 전에 실패하면 `simctl list devices available`로 실제 부팅 가능 기기를 확인하고 UUID로 재실행해 제품 실패와 분리한다.

### 연결

없음

## TS-20260819-004: 외곽 frame이 버튼 접근성 프레임을 확장하지 않음

**기록일**: 2026-08-19
**상태**: 해결
**발생 단계**: T008·T009 Green 구현
**관련 항목**: `ActionButton.swift`, `IconGlassButton.swift`, `LayoutContractUITests.swift`

### 증상

`Button` 바깥에 44pt `.frame`을 적용한 첫 Green 구현에서도 XCUITest가 작은 Action button 높이 40pt와 IconGlassButton MD 너비 40pt를 관찰했다.

### 영향

시각 표면은 맞았지만 실제 버튼 접근성 프레임이 44pt 최소 터치 계약을 충족하지 못했다.

### 근거

- `LayoutContractUITests.testSmallActionButtonPreservesMinimumTouchTarget`: 기대 44pt, 실제 40pt.
- `LayoutContractUITests.testIconGlassButtonsMeetMinimumTouchTarget`: 기대 44pt 이상, MD 실제 너비 40pt.

### 원인

SwiftUI의 버튼 의미 요소는 버튼 바깥 레이아웃 프레임이 아니라 label 영역을 접근성 프레임으로 노출했다.

### 조치

44pt 터치 프레임을 Button label 내부로 옮겼다. Liquid Glass는 44pt label 안의 40pt·36pt 표면에 `glassEffect(...interactive(), in: .circle)`를 적용해 시각 크기와 터치 크기를 분리했다.

### 검증

- `UIComponent` 단위 테스트: 크기 계약 테스트 성공.
- `UIComponentLayout` UI 테스트: 큰 Action button 54pt, 작은 Action button 44pt 터치 프레임, 두 Glass button 최소 44pt 단언 성공.

### 재발 방지

SwiftUI control의 최소 터치 영역은 control 바깥 frame이 아니라 label 내부 content shape와 frame으로 구성하고 XCUITest의 실제 접근성 프레임으로 확인한다.

### 연결

없음

## TS-20260819-005: sandbox에서 공용 project runner가 Xcode workspace를 오판

**기록일**: 2026-08-19
**상태**: 해결
**발생 단계**: T017 전체 완료 검증
**관련 항목**: 공용 project build runner

### 증상

sandbox 안에서 공용 runner의 `build`를 실행하자 CoreSimulator와 Xcode 사용자 캐시 접근이 거부되고, 모든 scheme이 같은 `is not a workspace file` 오류로 실패했다.

### 영향

코드 회귀와 실행 환경 권한 실패가 혼동될 수 있었고 전체 검증이 중단됐다.

### 근거

- `./tools/githooks/project-build/bin/run.sh build`: 12개 scheme 모두 실패하며 `CoreSimulatorService connection became invalid`, 로그 접근 `Operation not permitted`를 함께 출력했다.

### 원인

runner가 사용하는 Xcode 하위 프로세스가 sandbox 밖의 Simulator 서비스와 사용자 캐시에 접근하지 못했다.

### 조치

동일 runner 명령을 권한 확장으로 재실행하고, compile·test에는 유효한 Simulator UUID를 `GIT_IT_TEST_DESTINATION`으로 지정했다.

### 검증

- 공용 runner `build`: 12/12 성공.
- 공용 runner `compile`: 9/9 성공.
- 공용 runner `test`: 9/9 성공.

### 재발 방지

모든 scheme이 동일한 workspace 오류와 Simulator 권한 오류를 동시에 내면 manifest 문제로 수정하기 전에 같은 명령을 허용된 Xcode 환경에서 재검증한다.

### 연결

TS-20260819-003

## TS-20260819-006: 사후 포맷 훅의 IUO 린트 실패

**기록일**: 2026-08-19
**상태**: 해결
**발생 단계**: `speckit-implement` 필수 사후 훅
**관련 항목**: T006, `sources/Projects/UI/UIComponentUITests/LayoutContractUITests.swift`

### 증상

전체 Swift 소스를 대상으로 실행한 `swift-format` 사후 훅이 `LayoutContractUITests.swift`의 `XCUIApplication!` 선언을 `implicitly_unwrapped_optional` 위반으로 보고하고 종료 코드 1로 실패했다.

### 영향

UI 패키지 구현과 테스트 작업은 완료 표시되어 있었지만 필수 사후 훅을 통과하지 못해 기능 완료를 보고할 수 없었다.

### 근거

- `tools/githooks/swift-format/bin/run.sh format`: `LayoutContractUITests.swift:51:22`에서 `Implicitly Unwrapped Optional Violation` 1건을 보고했다.
- 같은 전체 실행에서 나머지 Swift 파일은 위반 없이 검사를 마쳤다.

### 원인

각 테스트의 `setUpWithError()`에서 다시 생성하는 `XCUIApplication` 저장 프로퍼티를 초기값 없이 IUO로 선언해 프로젝트 SwiftLint 정책을 위반했다.

### 조치

저장 프로퍼티를 `private var app = XCUIApplication()`으로 초기화하고 기존 `setUpWithError()`의 테스트별 재생성·실행 흐름은 유지했다.

### 검증

- `tools/githooks/swift-format/bin/run.sh format sources/Projects/UI/UIComponentUITests/LayoutContractUITests.swift`: 포맷 완료, SwiftLint 위반 0건.
- `xcodebuild test -workspace sources/GitIt.xcworkspace -scheme UIComponentLayout -destination 'platform=iOS Simulator,id=<booted-device>'`: 4개 테스트, 실패 0건.

### 재발 방지

XCTest 생명주기에서 테스트용 객체를 재할당하더라도 IUO 대신 선언 시 유효한 기본값을 제공하고, 사후 훅 전에 신규 테스트 파일의 SwiftLint를 실행한다.

### 연결

TS-20260819-003
