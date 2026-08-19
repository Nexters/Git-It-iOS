# 빠른 시작: 최종 UXUI 기반과 참조 화면 검증

## 사전 조건

- 저장소 루트 `/Users/jerry/Desktop/Git-It-iOS`에서 실행한다.
- `make tuist`로 최신 workspace와 scheme을 생성한다.
- 기본 destination은 `platform=iOS Simulator,name=iPhone 17 Pro`다. 다른 시뮬레이터는
  `GIT_IT_TEST_DESTINATION`으로 지정한다.
- 목표값과 근거는 먼저 다음 계약에서 확인한다.
  - [화면 목록과 그룹 분할](./contracts/screen-inventory.md)
  - [디자인 토큰 정합](./contracts/design-token-alignment.md)
  - [공용 컴포넌트 교정](./contracts/component-correction.md)
  - [참조 화면 레이아웃·상호작용](./contracts/reference-screen-layout.md)
  - [Use Case 계약](./contracts/use-case-contracts.md)
- 계약 문서의 `계획 상태`는 구현 책임과 검증 대상을 뜻한다. 현재 완료 여부는 `tasks.md`의
  완료 표시와 이 문서의 실제 빌드·테스트 결과로 판정한다.

## 패키지 승인 순서

구현은 `Domain → Composition → UI → Feature → App` 순서로 진행한다. 각 단계는 구현,
해당 패키지 검증, 결과 보고, 사용자 승인을 마친 뒤에만 다음 단계 파일을 변경한다.
Data와 Infrastructure는 이 기능에 적용되지 않는다.

## 공통 준비

```sh
make tuist

project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

## 1. Domain 검증

```sh
"$project_build_runner" build DomainLearningProject
"$project_build_runner" test DomainLearningProject
```

기대 결과:

- `LearningProjectID`, 목록 모델과 두 Use Case Protocol이 빌드된다.
- 입력 경계값과 모델 불변조건 테스트가 통과한다.
- Domain production·test target에 Feature 상태 검증용 Mock이 정의되지 않는다.

## 2. Composition 검증

```sh
"$project_build_runner" build Composition
"$project_build_runner" test Composition
```

기대 결과:

- 표본 구현이 고정 프로젝트 목록과 삭제 결과를 반환하고, harness용 조회 동작
  `projects`·`failure`·`pending`을 재현한다.
- 조립 지점이 두 Use Case Protocol의 실행 객체를 제공한다.
- 구현 선택이 `Composition/Composition/AppComposition.swift` 한 파일에 모여 있다.
- Composition production target에 Mock 정의나 테스트 전용 모듈 의존성이 없다.

## 3. UI 검증

```sh
"$project_build_runner" test DesignSystem
"$project_build_runner" test UIComponent
"$project_build_runner" test UIComponentLayout
```

기대 결과:

- Figma 색 변수 25개와 `ColorToken`의 이름·값·불투명도가 전부 일치한다.
- 참조 화면이 사용하는 `subtitle1`, `subtitle2`, `subtitle3`, `body1`, `body2`, `caption1`이
  Figma 텍스트 스타일과 대응하고 기존 `TextStyleTokenTests`가 크기·굵기·행간을 검증한다.
- [교정 계약](./contracts/component-correction.md)의 갱신 항목이 `±0.5pt` 안에 들어온다.
- 모든 조작 컨트롤의 터치 영역이 44×44pt 이상이다.
- 기준선을 갱신하지 않은 기존 DesignSystem·UIComponent 검증이 동일하게 통과한다.

## 4. Feature 검증

```sh
"$project_build_runner" build Feature
"$project_build_runner" test Feature
```

기대 결과:

- `FetchLearningProjects` Mock 결과에 따라 loaded·empty·failed로 전이한다.
- failed 상태의 재시도 조작이 loading 전이와 `FetchLearningProjects` 재호출을 일으킨다.
- 메뉴 열기, 삭제 모드, 확인 시트, 삭제 성공·실패 전이가 계약과 일치한다.
- `DeleteLearningProject` 호출 식별자와 호출 횟수를 확인한다.
- 두 Mock 정의와 참조가 `FeatureTests/LearningProjectList/**` 안에만 있다.
- Mock을 다른 Protocol 구현으로 바꿔도 Feature와 화면 코드를 수정하지 않는다.

## 5. App과 참조 화면 검증

```sh
"$project_build_runner" build GitIt
"$project_build_runner" test GitItTests
"$project_build_runner" test ScreenLayout
```

기대 결과:

- 앱 실행 후 `screen.project.list`에 도달한다.
- Figma 디자인 상태 `loaded`·`empty`·`menu`·`deleting`·`confirmingDeletion`이 각각 독립
  launch scenario로 표시되고 확정 레이아웃과 색이
  [참조 화면 계약](./contracts/reference-screen-layout.md)에 맞는다.
- 운영 상태 `loading`·`failed`가 각각 독립 launch scenario로 최소 렌더링되고, `failed`의
  재시도 조작이 조회 재호출과 상태 전이를 일으킨다. 두 상태에는 Figma 정밀 판정을 요구하지
  않는다.
- 최대 Dynamic Type에서 텍스트 잘림과 겹침이 없다.
- Typography 렌더 판정은 glyph 픽셀을 비교하지 않고 최대 Dynamic Type의 잘림·겹침만
  확인한다. Figma 스타일↔`TextStyleToken` 대응은 정적 계약과 UI 패키지 단위 테스트가
  담당한다.
- 앱과 `ScreenLayoutHarness`의 production 의존성·링크 산출물에 Mock 심볼이나 별도 Mock
  모듈이 없다.
- `AppComposition.live()`의 구현 선택을 대체해도 App·Feature 파일 변경 없이 같은 화면이
  실행된다.

scheme별 실행이 runner에서 지원되지 않으면 생성된 workspace를 직접 사용한다.

```sh
xcodebuild test \
  -workspace sources/GitIt.xcworkspace \
  -scheme ScreenLayout \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## 검출력 확인

production 소스를 바꾸거나 원복하지 않는다. `ScreenLayout` 판정 helper의 단위 테스트에
다음 잘못된 측정값을 각각 주입한다.

1. 참조 화면의 목록 좌우 여백 계약값 20pt에 대해 측정값 21pt를 전달한다.
2. 진행 바 채움 `blue200`의 기대 RGBA와 다른 측정 RGBA를 전달한다.

helper는 화면 이름, 계약 ID, 기대값과 실제값을 포함한 실패 진단을 반환해야 한다. 정상
측정값을 전달한 짝 테스트는 성공해야 하며 검출력 확인 때문에 추적 파일이 바뀌지 않는다.

## 전체 회귀 검증

패키지별 승인을 모두 마친 뒤 순서대로 실행한다.

```sh
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

실제 실행 결과만 완료 보고와 PR에 기록한다. 빌드·테스트를 실행하지 않은 계획 단계에서는
통과했다고 기록하지 않는다.
