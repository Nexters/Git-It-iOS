# 빠른 시작: UI 패키지 컨벤션 리팩터링 검증

## 목적

이 문서는 [공개 계약](./contracts/ui-component-public-contracts.md),
[target 및 검증 계약](./contracts/target-and-validation-contract.md)을 구현한 뒤 패키지 승인
게이트별로 실행할 검증 절차를 설명한다. 구현 작업 목록이나 전체 테스트 코드는 포함하지
않는다.

## 사전 조건

- 저장소 루트: `/Users/jerry/Desktop/codex/Git-It-iOS`
- Xcode와 Tuist가 설치돼 있다.
- 기본 Simulator `iPhone 17 Pro`를 사용할 수 있거나 동일한 destination을
  `GIT_IT_TEST_DESTINATION`으로 지정한다.
- 같은 checkout에서 실행 중인 commit/pre-commit/staged formatter 변경 체인이 없다.

## 1. 프로젝트 재생성

```sh
make tuist
```

기대 결과:

- UI 단계에서는 기존 UI·Feature target graph가 생성된다.
- Feature 단계에서는 `Feature` shared scheme Build Action에 `Feature`와 `FeatureReview`가
  포함된다.
- 생성된 `.xcscheme`을 직접 수정하지 않는다.

## 2. UI 단계 정적 계약

```sh
rg -n '\b(ViewModel|State)\b' \
  sources/Projects/UI/Component/Components/Leaf \
  sources/Projects/UI/Component/Components/Composite

rg -n '\.accessibility[A-Za-z]*\(' \
  sources/Projects/UI/Component/Components/Leaf \
  sources/Projects/UI/Component/Components/Composite

rg -n 'ComposableArchitecture|import (Feature|Domain|Data|Infrastructure|Composition)' \
  sources/Projects/UI/Component

rg -n 'assertAccessibility|fullAccessibilityText|accessibility(Label|Value|Hint|AddTraits)' \
  sources/Projects/UI/Tests/Component
```

기대 결과는 모두 0건이다. harness의 `.accessibilityIdentifier`는 비제품 selector 예외이므로
production 검색과 분리해 위치가 harness로 제한됐는지 검토한다.

## 3. UI 패키지 build-for-testing과 테스트

```sh
ui_refactor_destination=${GIT_IT_TEST_DESTINATION:-'platform=iOS Simulator,name=iPhone 17 Pro'}

xcodebuild \
  -workspace sources/GitIt.xcworkspace \
  -scheme UI \
  -destination "$ui_refactor_destination" \
  -derivedDataPath sources/DerivedData/UIConvention \
  build-for-testing

xcodebuild \
  -workspace sources/GitIt.xcworkspace \
  -scheme UI \
  -destination "$ui_refactor_destination" \
  -derivedDataPath sources/DerivedData/UIConvention \
  test-without-building

xcodebuild \
  -workspace sources/GitIt.xcworkspace \
  -scheme UIUITests \
  -destination "$ui_refactor_destination" \
  -derivedDataPath sources/DerivedData/UIConventionUITests \
  build-for-testing

xcodebuild \
  -workspace sources/GitIt.xcworkspace \
  -scheme UIUITests \
  -destination "$ui_refactor_destination" \
  -derivedDataPath sources/DerivedData/UIConventionUITests \
  test-without-building
```

기대 결과:

- 직접 입력과 상태 결정에 대한 Swift Testing 테스트가 통과한다.
- `ActionButton` tap/disabled/destructive와 `SelectionCardList` ID Binding 시나리오가
  통과한다.
- 기존 geometry/pixel 계약이 허용된 이미지 측정 tolerance 안에서 통과한다.
- 접근성 label/value/trait 및 접근성 Dynamic Type 검증은 실행 목록에 없다.

여기까지의 변경·검증 결과를 사용자에게 보고하고 승인받기 전에는 Feature 단계 파일을
변경하지 않는다.

## 4. FeatureReview graph 검증

UI 단계 승인 후 실행한다.

```sh
rg -n 'case FeatureReview|FeatureModuleName\.FeatureReview\.rawValue' \
  sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift \
  sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift

rg -n 'FeatureReview' \
  sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift \
  sources/Projects/Feature/Presentation
```

첫 검색은 target case와 Feature scheme Build Action을 찾아야 한다. 두 번째 검색은 결과가
없어 App과 기존 Feature target에서 `FeatureReview`를 참조하지 않음을 보여야 한다.

```sh
xcodebuild \
  -workspace sources/GitIt.xcworkspace \
  -scheme Feature \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath sources/DerivedData/FeatureReview \
  build
```

기대 결과는 기존 `Feature`와 임시 `FeatureReview` target의 함께 빌드 성공이다.

## 5. 저장소 전체 최종 검증

```sh
ui_refactor_build_runner=$(
  ./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER
)

"$ui_refactor_build_runner" build
"$ui_refactor_build_runner" compile
"$ui_refactor_build_runner" test
```

필요하면 `compile-unit`, `test-unit`, `compile-ui`, `test-ui`로 실패 범위를 먼저 분리하되
최종 보고에는 위 전체 명령의 실제 결과를 남긴다.

기대 결과:

- 모든 shared scheme production build 성공
- 모든 테스트 scheme build-for-testing 성공
- test-without-building의 실제 test body 실행 성공
- App dependency graph의 `FeatureReview` 의존 0건

## 6. 결과 보고 형식

- UI 단계: 변경 파일, wrapper/accessibility 정적 검색 결과, UI unit/UI test 결과,
  미검증 범위, Feature 단계 진행 승인 요청
- Feature 단계: Review 파일·target·scheme 변경, App 비연결 근거, Feature build 결과,
  전체 build/compile/test 결과, 최종 승인 요청
- build 성공, compile 성공, test 실행 성공을 서로 대체해 기록하지 않는다.
