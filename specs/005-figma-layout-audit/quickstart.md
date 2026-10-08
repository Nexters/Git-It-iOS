# 빠른 시작: UI 레이아웃 검증

## 사전 조건

- 저장소 루트에서 `make tuist`를 실행해 최신 workspace를 생성한다.
- 기본 시뮬레이터는 `iPhone 17 Pro`다. 다른 destination을 쓰면 `GIT_IT_TEST_DESTINATION`을 지정한다.
- 목표값과 근거 수준은 [UI 레이아웃 상수 계약 체크리스트](./contracts/ui-layout-constants.md)를 먼저 확인한다.

## TDD 검증 순서

1. UI 테스트 타깃과 크기 계약 테스트를 추가한다.
2. 구현을 바꾸기 전에 `UIComponentLayout` UI 테스트를 실행한다.
3. `action.small.height`, `iconGlass.medium.surface`, `iconGlass.touch`의 실패 진단에서 기대값과 실제값을 보존한다.
4. 해당 컴포넌트의 크기 변형과 터치 영역을 교정한다.
5. 같은 UI 테스트를 다시 실행해 통과를 확인한다.
6. 기존 UI 패키지 테스트와 전체 빌드를 실행한다.

## 실행 명령

```sh
make tuist

project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build UIComponent
"$project_build_runner" test UIComponentLayout
"$project_build_runner" test DesignSystem
```

scheme별 test 실행이 runner에서 지원되지 않으면 다음과 같이 생성된 workspace의 scheme을 직접 실행한다.

```sh
xcodebuild test \
  -workspace sources/GitIt.xcworkspace \
  -scheme UIComponentLayout \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## 기대 결과

- UI 테스트는 계약 ID, 기대값과 실제값을 포함해 실패하거나 통과한다.
- 최종 상태에서 Figma 근거 수준 `A`·`B`인 모든 항목이 허용 오차 안에 들어온다.
- `IconGlassButton`의 작은 시각 표면은 유지되면서 실제 접근성 프레임은 최소 44pt다.
- Dynamic Type과 시스템 탭 영역은 고정 프레임 때문에 잘리거나 화면 경계를 침범하지 않는다.
- 기존 `DesignSystemTests`와 `UIComponentTests`에 회귀가 없다.
