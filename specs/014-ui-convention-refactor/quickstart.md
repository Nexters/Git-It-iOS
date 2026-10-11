# 빠른 시작: UI 패키지 컨벤션 정본화 검증

## 목적

이 문서는 [UIComponent 공개 계약](./contracts/ui-component-public-contract.md)과 [Preview 및 검증 계약](./contracts/preview-and-validation-contract.md)의 구현 결과를 UI 패키지 승인 게이트에서 검증하는 실행 안내다.

## 사전 조건

- 저장소 루트: `/Users/jerry/Desktop/codex/Git-It-iOS`
- Xcode와 Tuist가 설치돼 있다.
- 기본 `iPhone 17 Pro` Simulator를 사용할 수 있거나 `GIT_IT_TEST_DESTINATION`을 지정한다.
- 같은 checkout에서 실행 중인 commit/pre-commit/staged formatter 변경 체인이 없다.

## 1. 프로젝트 생성

```sh
make tuist
```

기대 결과:

- `UIComponentPreview`가 app target으로 생성된다.
- `UI`와 `UIUITests` shared scheme이 Preview를 build/run target으로 사용한다.
- `UIComponentUITests`가 Preview를 target application으로 사용한다.
- generated `.xcodeproj` 또는 `.xcscheme`을 직접 수정하지 않는다.

## 2. 구현 전 Red 계약 확인

직접 입력과 Preview 계약 테스트를 먼저 작성한 직후 `make tuist`로 test source를 반영하고 다음을 실행한다.

```sh
red_ui_runner=$(
  ./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER
)

"$red_ui_runner" compile-unit
"$red_ui_runner" test-unit
"$red_ui_runner" compile-ui
"$red_ui_runner" test-ui
```

기대 결과:

- 새 직접 입력 API 또는 Preview route가 아직 없다는 예상 원인으로 실패한다.
- Simulator·destination 또는 무관한 기존 실패이면 Red 계약 성공으로 판정하지 않는다.

## 3. 정적 경계·consumer 검사

```sh
rg -n '\b(ViewModel|viewModel:)\b' \
  sources/Projects/UI/Component/Components/Leaf \
  sources/Projects/UI/Component/Components/Composite

rg -n 'ComposableArchitecture|import (App|Composition|Feature|Domain|Data|Infrastructure)' \
  sources/Projects/UI/Component \
  sources/Projects/UI/ComponentPreview

rg -n 'UIComponentLayoutHarness|ComponentLayoutHarness|LayoutContractCatalog' \
  sources/Projects/UI \
  sources/Tuist/ProjectDescriptionHelpers \
  docs/package-rules/ui.md \
  docs/conventions/ui-component.md

rg -n '\b(ViewModel|viewModel:)\b|UIComponentLayoutHarness' \
  sources/Projects/Feature \
  sources/Projects/App \
  docs/package-rules/ui.md \
  docs/conventions/ui-component.md
```

기대 결과는 모두 0건이다. historical `specs/**`, changelog와 trouble-shooting 기록은 legacy 이름 검사 대상에서 제외한다.

## 4. UI unit/UI 및 lint 검증

```sh
ui_plan_runner=$(
  ./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER
)

"$ui_plan_runner" compile-unit
"$ui_plan_runner" test-unit
"$ui_plan_runner" compile-ui
"$ui_plan_runner" test-ui

ui_lint_runner=$(
  ./tools/repository-paths/bin/repository-paths.sh GIT_IT_SWIFT_FORMAT_RUNNER
)
"$ui_lint_runner" lint
```

기대 결과:

- direct initializer, default, variant/state, callback, accessibility와 public API coverage unit test가 통과한다.
- 기존 geometry, 44pt interaction, 최대 Dynamic Type와 접근성 UI test가 통과한다.
- catalog 23개 route, light/dark, 긴 텍스트, Reduce Motion와 fallback scenario가 통과한다.
- 변경 Swift 파일의 lint가 통과한다.
- build-for-testing과 test body 실행 결과를 구분할 수 있다.

## 5. Preview 수동 확인

`UI` scheme의 run target으로 `UIComponentPreview`를 실행한다.

기대 결과:

- public component 23개를 Leaf/Composite별로 탐색할 수 있다.
- 각 공개 variant·size·주요 state와 환경 fixture를 네트워크 없이 재현할 수 있다.
- Preview 안에는 assertion이나 pass/fail 결과 UI가 없다.

## 6. 전체 compile boundary 최종 검증

UI 구현과 UI 범위 검증·결과 보고·사용자 승인이 끝난 뒤 실행한다.

```sh
"$ui_plan_runner" build
"$ui_plan_runner" compile
"$ui_plan_runner" test
```

기대 결과:

- 모든 shared scheme production build가 성공한다.
- 모든 test scheme build-for-testing이 성공한다.
- unit/UI test body가 성공한다.
- Feature/App source를 수정하지 않고도 UI public API 변경의 compile 전이가 성공한다.

## 7. UI 패키지 승인 보고

다음을 사용자에게 구분해 보고한 뒤 UI 단계 완료 승인을 받는다.

- 변경한 production component, Preview, tests, Tuist helper와 UI 문서
- ViewModel·legacy 이름·금지 dependency·source inclusion 정적 검사 결과
- `build`, `compile`, `test` 각각의 실제 결과
- Preview catalog 등록률과 환경 scenario 결과
- 미실행 또는 환경 문제로 판정하지 못한 범위

UI 외 패키지 수정이 새로 필요해지면 승인 전에 구현을 중단하고 계획·작업의 적용 패키지 경계를 갱신한다.
