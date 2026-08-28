# 구현 계획: UI 패키지 컨벤션 리팩터링

**Git-flow 유형**: `feature`

**브랜치**: `feature/ui-convention-refactor`

**날짜**: 2026-08-22 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/013-ui-convention-refactor/spec.md`의 기능 명세

## 요약

UIComponent production 컴포넌트의 표시 상태 `ViewModel` wrapper를 제거하고 표시 값,
SwiftUI `Binding`, 콜백과 시각 변형을 직접 받는 공개 계약으로 정렬한다. Figma의
`사용한 컴포넌트`는 지원 변형·상태 의미, `Design system`은 토큰의 정본으로 사용하되
현재 크기·간격·배치를 유지한다. 접근성 label·value·trait 구현과 관련 검증은 제거하고,
입력·상태 결정은 Swift Testing, 실제 탭·Binding 전달과 geometry는 전용 layout harness의
UI 자동화로 검증한다. Review 전용 View 3개는 UI에서 제거한 뒤 사용자 승인을 거쳐
Feature 패키지의 제품 앱 비연결 임시 `FeatureReview` target에 추가한다.

## 기술 맥락

**언어/버전**: Swift 5 language mode, Swift tools 6.0

**주요 의존성**: SwiftUI, DesignSystem, UIComponent, Lottie; 기존 Feature target의 TCA는
유지하되 임시 `FeatureReview` target은 SwiftUI 외 의존성을 선언하지 않는다.

**저장소**: N/A — 영속 데이터나 외부 저장소 변경 없음

**테스트**: Swift Testing 단위 계약 테스트, XCTest UI 자동화,
`UIComponentLayoutHarness`, 저장소 project build runner

**대상 플랫폼**: iOS 26.0 이상, iOS Simulator

**프로젝트 유형**: Tuist 기반 멀티 패키지 iOS 모바일 앱

**성능 목표**: 기존 렌더링과 입력 반응을 유지하며 새 비동기 작업·I/O를 추가하지 않는다.

**제약 조건**: 기존 geometry 유지, UIComponent의 Feature/TCA 의존 0건, production
접근성 modifier 및 접근성 의미 검증 0건, 실제 터치 영역 44pt 이상, 제품 App에서
`FeatureReview` 의존 0건

**규모/범위**: UIComponent production Swift 파일 25개 전수 검토, 표시 wrapper가 있는
22개 파일의 공개 계약 정렬, Review 파일 3개 이전, UI unit/UI test와 harness 갱신,
Feature Tuist 선언 2곳 갱신

## 헌법 점검

*게이트: 0단계 조사 전에 통과했으며 1단계 설계 후 다시 점검한다.*

| 원칙 | 판정 | 계획 근거 |
| --- | --- | --- |
| 명시적인 경계 | 통과 | UIComponent는 DesignSystem만 사용하고 Feature·TCA 타입을 노출하지 않는다. `FeatureReview`는 App과 기존 `Feature` target에서 참조하지 않는다. |
| 상태와 데이터 안전성 | 통과 | 변경 가능한 선택값은 외부 `Binding`이 소유하고 컴포넌트는 상태를 복제하지 않는다. |
| 검증 가능한 변경 | 통과 | 직접 입력·상태 결정, 실제 상호작용, geometry, target graph를 서로 분리해 자동 검증한다. |
| 스킬별 수정 경로 | 통과 | 계획 단계에서는 이 기능의 plan/research/data-model/quickstart/contracts만 수정한다. 구현 파일은 아래 경계에 경로로만 기록한다. |
| 한국어 산출물 | 통과 | 자연어 산출물은 한국어로 작성하고 코드·경로·명령 식별자는 원문을 유지한다. |
| 패키지 단위 진행 | 통과 | 적용 패키지는 `UI → Feature`이며 UI 완료·검증·보고·승인 전 Feature 파일을 변경하지 않는다. |
| Git-flow | 통과 | 사용자 지시에 따라 `feature/ui-convention-refactor` 브랜치를 생성했고 실제 이름을 기록한다. |
| 책임 기반 네이밍 | 통과 | target은 `FeatureReview`, 역할 폴더는 `Review`, 항목 식별자는 `ID` 표기를 사용한다. |

### 한시적 규칙 예외

`FeatureReview`는 사용자 기능을 소유해야 한다는 Feature production target 규칙의 한시적
예외다. 이유는 제품 UI가 아닌 Review View를 UIComponent production target에서 격리해
독립 빌드하기 위해서다. 영향은 Feature 프로젝트에 비제품 framework target 하나가
추가되는 것으로 제한하며 App과 기존 Feature target의 의존은 금지한다. 영구 Feature
구조로 일반화하지 않고 PR에 이유·영향·검증 범위와 임시 target임을 기록한다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/013-ui-convention-refactor/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── target-and-validation-contract.md
│   └── ui-component-public-contracts.md
└── tasks.md             # /speckit-tasks 산출물
```

### 구현 대상 구조

```text
sources/
├── Projects/
│   ├── UI/
│   │   ├── Component/Components/{Leaf,Composite}/
│   │   ├── ComponentLayoutHarness/
│   │   └── Tests/Component/{Unit,UI}/
│   └── Feature/
│       └── Review/                       # FeatureReview sourceDirectory
└── Tuist/ProjectDescriptionHelpers/
    ├── ProjectName.swift                 # Feature scheme Build Action
    └── Projects/FeatureModuleName.swift  # FeatureReview target
```

**구조 결정**: 기존 UI/Feature 프로젝트와 패키지별 shared scheme을 유지한다. 새 scheme이나
빈 test target을 만들지 않고 `FeatureReview`를 기존 `Feature` scheme의 Build Action에만
추가한다. `sources/Projects/UI/Project.swift`, `sources/Projects/Feature/Project.swift`,
`UIModuleName.swift`, App target 선언은 변경하지 않는다.

## 설계 결정

- 공개 계약 상세는 [UIComponent 공개 계약](./contracts/ui-component-public-contracts.md)을
  따른다. `ViewModel`·`State` wrapper 대신 직접 표시 값, `Binding`, 콜백을 사용한다.
- `ActionButton`은 `StyledText` 자식 조합을 DesignSystem `Text` 적용 API로 바꿔 Leaf에
  유지한다. `Pressing`은 내부 `ButtonStyle`, `Disabled`는 `isEnabled`, `Error`는
  `destructive` 변형으로 처리한다.
- `SelectionCardList`는 `Binding<Item.ID?>`, `TabShell`은 `Binding<Item>`을 받아 외부 상태를
  갱신하며 내부 `@State`나 `.constant` 복제를 사용하지 않는다.
- 기존 DesignSystem 토큰으로 현재 역할을 표현할 수 있으므로 새 토큰은 계획하지 않는다.
  구현 중 둘 이상의 컴포넌트가 공유하는 새 역할 근거가 확인될 때만 UI 단계에서 추가한다.
- production과 Review의 접근성 label·value·trait 및 관련 assertion을 제거한다. harness의
  `.accessibilityIdentifier`는 접근성 의미 계약이 아닌 비제품 UI test selector로만
  허용하며 label·value·trait를 검증하지 않는다.
- Figma와 현재 geometry가 다르면 현재 layout contract가 우선한다. Figma는 지원 변형과
  상태 의미, 토큰 대조에만 사용한다.

## 패키지별 구현 경계와 승인 게이트

### 1. UI 패키지

**구현 경로**:

- `sources/Projects/UI/Component/Components/Leaf/*.swift`
- `sources/Projects/UI/Component/Components/Composite/*.swift`
- `sources/Projects/UI/Component/Components/Review/*.swift` 삭제
- `sources/Projects/UI/ComponentLayoutHarness/*.swift`
- `sources/Projects/UI/Tests/Component/Unit/*.swift`
- `sources/Projects/UI/Tests/Component/UI/LayoutContractUITests.swift`
- 조건부로 기존 역할 토큰만으로 표현할 수 없다는 공유 근거가 생긴 경우
  `sources/Projects/UI/DesignSystem/**`와 `sources/Projects/UI/Tests/DesignSystem/**`

**검증**:

- 공개 wrapper, 금지 import, production 접근성 modifier와 접근성 assertion의 0건 검사
- `UI` scheme의 build-for-testing/test-without-building
- `UIUITests` scheme의 build-for-testing/test-without-building
- 입력·상호작용·기존 geometry 및 Figma 상태 매핑 계약 검증

**게이트**: UI 변경과 검증 결과를 사용자에게 보고하고 명시적 승인을 받기 전에는
`sources/Projects/Feature/**`, `FeatureModuleName.swift`, `ProjectName.swift`를 변경하지 않는다.

### 2. Feature 패키지

**구현 경로**:

- `sources/Projects/Feature/Review/LayoutReviewCatalogList.swift`
- `sources/Projects/Feature/Review/LayoutReviewChrome.swift`
- `sources/Projects/Feature/Review/LayoutReviewDetail.swift`
- `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`
- `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 Feature scheme branch

Review 파일은 UI 단계에서 제거한 기존 tracked source를 기준으로 직접 입력 계약과
접근성 제거를 적용해 생성한다. `ProjectName.swift`는 여러 패키지가 공유하는 파일이지만
이번 변경은 Feature scheme branch만 수정하므로 Feature 단계에 단독 배정한다.

**검증**:

- `make tuist`
- `Feature` scheme Build Action에서 `Feature`와 `FeatureReview`가 함께 빌드되는지 확인
- App과 기존 Feature target의 `FeatureReview` 의존 0건 확인
- 저장소 전체 `build`, `compile`, `test`를 순차 실행하고 build/compile/test 결과를 구분

**게이트**: Feature 변경과 전체 검증 결과를 보고하고 사용자의 최종 승인을 받아 구현을
완료한다.

### 제외 패키지

`Domain`, `Data`, `Infrastructure`, `Composition`, `App`은 소스·테스트·구성 변경 대상이
아니다. 전체 검증에서 실패가 관찰되면 원인을 분류하되 이 계획의 범위를 임의로 넓히지
않는다.

## 1단계 설계 후 헌법 재점검

- 모든 설계 산출물에 미해결 명확화 표식이 남아 있지 않다.
- UI와 Feature의 변경 파일이 분리되고 공용 구성 변경은 Feature 단계에 배정됐다.
- Review 이전을 단일 `git mv`로 처리하지 않아 UI→Feature 승인 경계를 넘지 않는다.
- 제품 App의 의존 방향, UI의 금지 의존성, 외부 상태 소유권을 유지한다.
- 한시적 `FeatureReview` 예외 외에 정당화되지 않은 Constitution·아키텍처 위반이 없다.

## 복잡성 추적

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
| --- | --- | --- |
| Feature에 사용자 기능이 아닌 임시 `FeatureReview` framework target 추가 | Review View를 UIComponent production에서 제거하면서 독립 빌드 대상으로 보존해야 한다. | UI에 유지하면 명세 FR-004를 위반하고, App에 연결한 실행 target은 제품 경로 제외 요구를 위반한다. |
