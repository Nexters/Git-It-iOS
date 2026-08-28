# UI 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

**최종 수정일**: 2026-08-21

## 설명

UI는 시각 언어와 화면에서 독립된 재사용 UI 구성요소를 담당하는 표현 경계입니다.
DesignSystem은 디자인 토큰과 적용 API를, UIComponent는 Feature 구현 타입과 분리된 표시
값·SwiftUI `Binding`·콜백 기반 컴포넌트를 제공합니다.

이 문서는 UI 패키지가 소유하는 책임과 허용 의존성을 정의합니다. 컴포넌트의 역할 분류,
공개 입력과 자산 구성은 [UIComponent 컨벤션](../conventions/ui-component.md), 폴더와
파일 배치는 [디렉터리·파일 컨벤션](../conventions/directory-file.md), 공통 SwiftUI 구현
방식은 [View 컨벤션](../conventions/view.md)을 따릅니다.

## 적용 범위

- `DesignSystem`: 토큰, Typography, 색상·효과·레이아웃 적용 API와 폰트 등록
- `UIComponent`: 화면에서 독립적으로 해석 가능한 역할별 재사용 컴포넌트와 해당 자산
- `UIComponentLayoutHarness`와 UI 자동화 target: 제품 API가 아닌 레이아웃 계약 검토

Feature 화면 상태, 화면 흐름과 Feature 전용 조립은 UI의 범위가 아닙니다.

## 공개 계약

- 공개 이름은 [네이밍 컨벤션](../conventions/naming.md)을 따르며 시각 의미와 재사용
  책임을 드러냅니다.
- production target은 공통 디자인 규칙 또는 화면에서 독립된 재사용 UI 구성요소를
  제공해야 합니다.
- 공개 API는 사용처 수와 관계없이 Feature 구현에서 독립된 표현 계약으로 설계합니다.
- 공개 API와 구현은 `ComposableArchitecture`에 의존하지 않으며 TCA의 Store, Reducer,
  Effect와 Action 타입을 사용하지 않습니다.
- Feature State, Action, 업무 모델 또는 내부 구현 이름을 공개 API에 노출하지 않습니다.

## Target 책임과 의존 방향

### DesignSystem

- 원시·의미 디자인 토큰, 폰트와 토큰 적용 API를 소유합니다.
- UIComponent나 Feature 화면에 의존하지 않습니다.
- 여러 컴포넌트나 화면이 공유하는 시각 값을 토큰으로 승격하고 유효성 검증을 제공합니다.
- 원시 값, 의미 토큰과 적용 API 사이의 변환을 target 안에서 완료합니다.

### UIComponent

- DesignSystem을 사용해 역할별 재사용 컴포넌트와 컴포넌트 자산을 제공합니다.
- Feature, Domain, Data, Infrastructure 또는 Composition 타입을 참조하지 않습니다.
- 읽기 값은 초기화 인자, 변경 값은 Binding, 일회성 입력은 콜백으로 받습니다.
- 컴포넌트의 상세 구현은 [UIComponent 컨벤션](../conventions/ui-component.md)을
  따릅니다.

### 검토·테스트 Target

`UIComponentPreview`는 모든 public component의 variant·size·state와 환경 fixture를
local data로 탐색하는 실행 환경입니다. UI 자동화 target은 Preview route, 레이아웃,
상호작용과 접근성 계약을 판정합니다. 두 target 모두 제품 API를 제공하거나 production
target의 의존 대상이 되어서는 안 됩니다.

표현 API의 사용 방향은 `Feature → UIComponent → DesignSystem`입니다. 컴파일 의존성은
아키텍처의 `Feature → UI` 범위를 넘지 않아야 합니다.

## 구현 컨벤션

- 컴포넌트 역할 분류, 재사용 판단, 자산 구성과 검증은
  [UIComponent 컨벤션](../conventions/ui-component.md)을 따릅니다.
- 소스 루트, 폴더 뎁스와 파일 분할은
  [디렉터리·파일 컨벤션](../conventions/directory-file.md)을 따릅니다.
- 공개 생성 경로, 디자인 토큰, 내부 선언, 접근성과 프리뷰는
  [View 컨벤션](../conventions/view.md)을 따릅니다.
- 테스트 이름, Test Double, 파일과 target 구성은
  [테스트 컨벤션](../conventions/test.md)을 따릅니다.
- Figma 노드와 코드 컴포넌트의 대응은
  [컴포넌트 인덱스](../../.agents/skills/implement-figma-ui/references/component-index.md)에서
  추적합니다.

## 제약조건

- 프로젝트 내부의 다른 패키지에 의존해서는 안 됩니다.
- `ComposableArchitecture`에 의존하거나 UI target dependency로 선언해서는 안 됩니다.
- 특정 Feature의 화면, Action, State 또는 화면 흐름을 소유해서는 안 됩니다.
- Domain 모델이나 비즈니스 규칙을 참조해서는 안 됩니다.
- Data DTO, 서버 API, 네트워크, 저장소 또는 Composition 로직을 참조해서는 안 됩니다.
- 외형만 같고 공개 입력의 의미가 다른 UI를 하나의 컴포넌트로 통합해서는 안 됩니다.
- 표시 상태를 묶는 ViewModel, State 또는 동등한 wrapper 타입을 정의해서는 안 됩니다.
- DesignSystem 밖에 공통 시각 어휘를 정의해서는 안 됩니다.
- 검토 전용 UI를 `UIComponent`가 소유해서는 안 됩니다. `UIComponentPreviewApp`
  target에 둡니다.
- production target이 UIComponentLayoutHarness 또는 UI 자동화 target에 의존해서는 안
  됩니다.
