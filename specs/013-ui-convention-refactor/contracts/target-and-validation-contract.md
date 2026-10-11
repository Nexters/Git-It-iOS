# Target 및 검증 계약

## UIComponent target

- source root는 `sources/Projects/UI/Component/`를 유지한다.
- `Components/Review/*.swift` 3개를 제거해 production glob에서 제외한다.
- 프로젝트 내부 의존성은 DesignSystem만 허용하며 외부 Lottie 의존은 animation 구현에
  한정한다.
- `ComposableArchitecture`, Feature, Domain, Data, Infrastructure, Composition import와
  target dependency는 0건이어야 한다.

## FeatureReview target

| 항목 | 계약 |
| --- | --- |
| target | `FeatureReview` |
| sourceDirectory | `Review` |
| physical path | `sources/Projects/Feature/Review/` |
| product | framework |
| project target dependencies | 없음 |
| shared scheme | 기존 `Feature` scheme Build Action |
| App dependency | 0건 |
| existing Feature dependency | 0건 |
| test target | 생성하지 않음 |

Review 소스는 `LayoutReviewCatalogList.swift`, `LayoutReviewChrome.swift`,
`LayoutReviewDetail.swift` 세 파일이다. 직접 표시 값과 callback을 사용하고 접근성
label·value·trait modifier를 포함하지 않는다.

## 순차 이전 계약

1. UI 단계에서 기존 Review 파일을 삭제한다.
2. UI 구현·검증 결과를 보고하고 사용자 승인을 받는다.
3. Feature 단계에서 Review 파일과 `FeatureReview` target을 생성한다.
4. Feature 및 전체 저장소 검증 결과를 보고하고 최종 승인을 받는다.

한 번의 `git mv` 또는 같은 구현 단계에서 UI 삭제와 Feature 생성을 함께 수행하지 않는다.

## 테스트 계층

| 계층 | 검증 책임 | 검증하지 않는 것 |
| --- | --- | --- |
| Swift Testing | 직접 생성, 값 clamp, token/상태 결정, ID 선택 파생, 공개 보조 타입 | 실제 XCUI tap과 pixel geometry |
| UIComponentLayoutHarness | 결정적 scenario와 화면에 보이는 상태 marker 제공 | 제품 기능·Feature 상태 |
| XCTest UI automation | tap/callback/Binding, disabled 입력 차단, frame와 pixel geometry | 접근성 label/value/trait 의미 |
| Tuist/build runner | target graph, shared scheme build, compile/link, test 실행 | 테스트 본문 미진입 환경 실패를 제품 실패로 판정 |

## Harness selector 예외

- `.accessibilityIdentifier`는 `UIComponentLayoutHarness` source에만 둘 수 있다.
- identifier는 XCUI test selector이며 제품 accessibility label/value/trait 계약이 아니다.
- production UIComponent와 FeatureReview에는 identifier를 추가하지 않는다.
- 테스트는 label/value/trait와 accessibility 전용 Dynamic Type 시나리오를 assertion하지
  않는다.

## 필수 scenario

### action-button

- primary tap count `0 → 1`
- disabled tap count 불변
- destructive가 error token을 사용
- default/pressed/disabled/destructive 표현 결정
- large/medium/small surface와 44pt hit area 유지

### selection-card-list

- 초기 `nil`
- card tap으로 해당 ID 선택
- 외부 binding 변경 반영
- 재정렬 후 같은 ID 유지
- 선택 border와 기존 card/list geometry 유지

### catalog

- 기존 ActionMenu, progress, ProjectRow, SheetSurface, scrim, icon, badge layout 계약
- wrapper 제거 뒤 직접 입력으로 동일 geometry 유지

## 결과 보고

- `build` 성공과 `compile` 성공, test body 실행 성공을 각각 구분한다.
- Simulator bootstrap이나 destination 실패로 test body가 실행되지 않았으면 테스트 통과로
  기록하지 않는다.
- `FeatureReview` 독립 build는 테스트가 없는 scheme compile이 아니라 `Feature` shared
  scheme의 Build Action 결과로 입증한다.
