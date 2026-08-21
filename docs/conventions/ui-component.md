# Git It iOS UIComponent 컨벤션

**상태**: 초안

**작성일**: 2026-08-21

**최종 수정일**: 2026-08-22

## 목적

이 문서는 `UIComponent`의 재사용 가능한 표현 계약을 정의하고 컴포넌트의 분류, 공개
입력, 파일·선언·자산 구성과 검증 방식을 통일합니다. UI 패키지의 책임과 의존 방향은
[UI 패키지 규칙](../package-rules/ui.md)이 소유하고, 컴포넌트 구현 방식은 이 문서가
소유합니다.

## 1. 적용 범위

- `sources/Projects/UI/Component/Components/Leaf/**`의 말단 컴포넌트
- `sources/Projects/UI/Component/Components/Composite/**`의 조합 컴포넌트
- `sources/Projects/UI/Component/Components/Review/**`의 검토·디버그 전용 컴포넌트
- `sources/Projects/UI/Component/Resources/**`의 이미지·애니메이션·일러스트레이션 자산
- `UIComponentLayoutHarness`와 UI 자동화 target의 컴포넌트 레이아웃 검증

DesignSystem 토큰의 정의, Feature 화면 상태와 화면 흐름은 이 문서의 범위가 아닙니다.

## 2. 공개 계약

- 컴포넌트는 화면과 Feature 구현에서 독립적으로 해석 가능한 표현 계약이어야 합니다.
- 읽기 전용 표시 값은 초기화 인자, 외부 변경을 관찰해야 하는 값은 SwiftUI `Binding`,
  일회성 사용자 입력은 콜백으로 받습니다.
- Feature의 `State`, `Action`, 업무 모델과 TCA의 `Store`, `Reducer`, `Effect`를 공개
  API나 구현에 사용하지 않습니다.
- 표시 상태를 묶기 위한 `ViewModel`, `State` 또는 동등한 wrapper 타입을 정의하지
  않습니다.
- 외부 라이브러리가 필요하면 구현에 필요한 범위로 격리하고 외부 타입을 Feature에
  공개하지 않습니다.
- 컴포넌트의 공개 이름은 [네이밍 컨벤션](./naming.md)을 따르며 시각 의미와 재사용
  책임을 드러냅니다.

## 3. 컴포넌트 경계

### 3.1 말단 컴포넌트

말단 컴포넌트는 렌더링 트리에 프로젝트가 소유한 다른 `View` 컴포넌트를 포함하지 않는
최하위 단위입니다. 크기나 구현 라인 수가 아니라 의존 구조로 판단합니다.

말단 컴포넌트는 다음 요소를 사용할 수 있습니다.

- 플랫폼이 제공하는 기본 `View`, `Shape`와 modifier
- DesignSystem이 제공하는 토큰과 토큰 적용 API
- 같은 컴포넌트의 `body`, private 연산 프로퍼티 또는 private 메서드로 분해한 렌더링 조각

다음 조건 중 하나라도 해당하면 말단 컴포넌트가 아닙니다.

- 프로젝트가 소유한 다른 컴포넌트 타입을 생성해 렌더링합니다.
- 제네릭 `Content` 또는 `@ViewBuilder`로 임의의 자식 View를 입력받습니다.
- 같은 파일의 별도 View 타입에 렌더링 책임을 위임합니다.

### 3.2 조합 컴포넌트

조합 컴포넌트는 말단 컴포넌트 또는 `@ViewBuilder`로 받은 자식을 조립해 하나의 독립된
표현 계약을 제공합니다. 조합 자체가 Feature 상태를 해석하거나 화면 목적지를 결정하지
않습니다.

### 3.3 검토·디버그 전용 컴포넌트

레이아웃 카탈로그나 TestFlight 검토 제어처럼 제품 화면에서 사용하지 않는 컴포넌트는
`Components/Review/`에 둡니다. 제품 컴포넌트가 Review 컴포넌트에 의존해서는 안 되며,
세부 기준은 [View 컨벤션](./view.md#21-검토디버그-전용-컴포넌트)을 따릅니다.

## 4. 재사용 판단

재사용 가능성은 사용처의 수나 외형의 유사성이 아니라 공개 입력의 의미적 통일성으로
판단합니다. 다음 질문에 모두 같은 답을 할 수 있을 때 하나의 컴포넌트를 재사용합니다.

1. 각 초기화 인자와 `Binding`은 같은 사용자 인지 역할을 표현하는가?
2. 같은 상태 값은 모든 사용처에서 같은 상태와 표현 규칙을 의미하는가?
3. nil, 빈 값과 범위 밖 값 같은 경계값을 같은 방식으로 해석하는가?
4. 특정 Feature 모델을 다른 의미로 치환하거나 범용 이름 뒤에 숨기지 않는가?

현재 사용처가 하나라는 사실만으로 재사용 가능성을 인정하거나 부정하지 않습니다.
화면 문맥이 달라도 입력과 상태 의미가 같으면 같은 계약을 사용할 수 있고, 외형이 같아도
의미가 다르면 별도 컴포넌트로 유지합니다.

## 5. 파일·선언·자산 구성

### 5.1 파일과 폴더

- 말단 컴포넌트는 `Components/Leaf/`, 조합 컴포넌트는
  `Components/Composite/`, 검토 전용 컴포넌트는 `Components/Review/`에 둡니다.
- 각 폴더에는 컴포넌트마다 하위 폴더를 만들지 않고 Swift 파일을 바로 둡니다.
- 각 Swift 파일은 주된 최상위 `struct`, `enum`, `class`, `actor` 또는 `protocol`을
  하나만 정의하며 파일 이름은 타입 이름과 일치시킵니다.
- 프리뷰 전용 타입이나 중첩할 수 없는 보조 타입은 같은 폴더에 소유 컴포넌트 이름을
  앞에 붙인 파일로 둡니다.
- 컴포넌트 파일과 타입 이름은 표현 대상을 사용하고 `View` 접미어를 붙이지 않습니다.

### 5.2 중첩 선언

- `Style`, `Constant`, `Item`, `Control`처럼 컴포넌트가 소유하는 보조 타입은 원칙적으로
  컴포넌트 View 내부에 중첩하고 같은 파일에 둡니다.
- 소유 컴포넌트가 문맥을 제공하므로 `ActionButtonStyle` 대신
  `ActionButton.Style`, `SelectionCardListItem` 대신 `SelectionCardList.Item`을
  사용합니다.
- 변형에 따라 갈리는 표현 값은 `Style`이 소유하고 컴포넌트는 결과만 읽습니다.
- 중첩할 수 없는 경우는 [View 컨벤션](./view.md#54-중첩할-수-없는-경우)을 따릅니다.

### 5.3 자산

- 이미지, Lottie 애니메이션과 일러스트레이션처럼 컴포넌트가 렌더링하는 자산은
  `Component/Resources/`가 소유합니다.
- Feature는 자산 이름이나 bundle 탐색을 직접 해석하지 않고 UIComponent의 표현 API를
  사용합니다.
- 폰트와 토큰 카탈로그는 `DesignSystem/`이 소유하며 UIComponent 자산과 섞지 않습니다.

## 6. 상태와 생성 경로

- 표시 값은 private 불변 저장 프로퍼티로, 변경 가능한 외부 상태는 `@Binding`으로
  보존합니다.
- 컴포넌트 입력을 `@State`나 별도 참조 타입에 복제하지 않습니다.
- 상위 소유자에게 입력을 전달하는 콜백은 초기화 인자로 받고 private 저장 프로퍼티로
  보존합니다.
- 공개 생성 경로는 표시 값·`Binding`·콜백을 직접 받는 초기화 메서드와 시각 변형별
  `public static func` 팩토리로 제한합니다.
- 팩토리 기준, 접근 수준, `Constant`와 `Style`의 세부 구현은
  [View 컨벤션](./view.md)을 따릅니다.

```swift
public struct SelectionToggle: View {
    public init(isSelected: Binding<Bool>) {
        self._isSelected = isSelected
    }

    public var body: some View {
        Toggle("선택", isOn: $isSelected)
    }

    @Binding private var isSelected: Bool
}
```

## 7. 분리 절차

1. 화면과 사용처에서 독립적으로 이름 붙일 수 있는 표현 책임을 찾습니다.
2. 후보들의 외형이 아니라 입력 필드, 상태와 경계값을 비교합니다.
3. 의미가 모두 일치할 때만 하나의 초기화 인자·`Binding`·콜백 계약을 정의합니다.
4. Feature의 State, Action 또는 업무 모델 없이 계약을 정의합니다.
5. 다른 프로젝트 UI 컴포넌트를 렌더링하지 않는 후보만 말단으로 분류합니다.
6. 보조 타입은 컴포넌트 내부에 중첩하고 표시 상태 wrapper는 추가하지 않습니다.
7. 분리 전후의 표시 상태와 사용자 입력 전달이 보존되는지 검증합니다.

## 8. 검증

- 공개 입력·`Binding`, 상태별 표현과 레이아웃 계약을 단위 테스트 또는
  `UIComponentLayoutHarness`의 UI 자동화 테스트로 검증합니다.
- UI production target의 Tuist dependency와 Swift import에
  `ComposableArchitecture`가 없는지 확인합니다.
- 컴포넌트 분리 전후의 표시 상태와 사용자 입력 전달을 확인합니다.
- 테스트 이름, Test Double, 파일과 target 구성은 [테스트 컨벤션](./test.md)을 따릅니다.

## 9. 검토 체크리스트

- [ ] 화면과 Feature 상태에서 독립적으로 설명할 수 있는 표현 계약인가?
- [ ] 읽기 값·변경 값·일회성 입력이 초기화 값·Binding·콜백으로 구분되는가?
- [ ] Feature, Domain 또는 TCA 타입이 공개 API와 구현에 없는가?
- [ ] 외형이 아니라 입력·상태·경계값의 의미로 재사용을 판단했는가?
- [ ] 말단·조합·Review 폴더가 실제 의존 구조와 일치하는가?
- [ ] 보조 선언이 View에 중첩되고 표시 상태 wrapper가 없는가?
- [ ] 자산과 DesignSystem 토큰의 소유 경계가 분리되는가?
- [ ] 레이아웃과 사용자 입력 전달을 독립적으로 검증했는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [UI 패키지 규칙](../package-rules/ui.md)
- [View 컨벤션](./view.md)
- [네이밍 컨벤션](./naming.md)
- [테스트 컨벤션](./test.md)
- [UI 컴포넌트 체크리스트](../ui-component-checklist.md)

## 문서 변경 기준

UIComponent의 공개 입력 형태, 말단·조합 분류, 파일·선언·자산 배치 또는 레이아웃 검증
방식이 바뀔 때 수정합니다. Figma 항목과 구현 현황만 바뀌면 이 문서가 아니라
[UI 컴포넌트 체크리스트](../ui-component-checklist.md)를 수정합니다.
