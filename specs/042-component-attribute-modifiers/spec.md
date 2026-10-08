# 기능 명세: UI 컴포넌트 초기화 계약 재구성 — 시각 속성 메서드와 표시 값 모델

**Git-flow 유형**: `feature`

**기능 브랜치**: `feature/component-attribute-modifiers`

**브랜치 상태**: `생성`

**생성일**: 2026-09-21

**상태**: 초안

**입력**: 사용자 설명: "UI 컴포넌트의 시각 변형 속성을 Self 반환 메서드로 선언하도록 변경한다. ActionButton, StyledText, TagBadge, IconGlassButton, LabeledCard, IconPlainButton, LabeledProgressBar, SelectionCard, SelectionCardList, HomeProjectCard, ScreenContainer, OverlayContainer처럼 Style·Size·Color·Alignment·Variant·배경 ColorToken 같은 내부 정의 시각 변형 속성을 가진 View에 대해, 속성 종류별 Protocol을 정의하고 자기 타입을 그대로 반환하는 메서드(SwiftUI Text.font처럼)로 속성값을 선언하도록 수정한다. 결정 사항: (1) 대상은 시각 변형만이며 title·isSelected·isEnabled·action 같은 표시 값·상태·콜백은 init에 남긴다. 현재 기본값이 없는 시각 속성(예: StyledText의 TextStyleToken style)은 기본값을 새로 정한다. (2) init의 시각 속성 인자는 완전히 제거하고 호출부(약 260곳, StyledText 170곳)를 모두 메서드 체이닝으로 전환한다. (3) 현재 docs/conventions/view/component-init.md의 "시각 변형은 Style·Size enum을 초기화 인자로 받는다" 규칙을 새 방식으로 개정한다. 렌더링 결과(레이아웃·토큰·색)는 바뀌지 않아야 한다."

**선행 기능**: [039 UIComponent 정적 팩토리 제거](../039-ui-component-factory-removal/spec.md)가 확정한
"시각 변형은 초기화 인자로 받는다" 규칙을 이 기능이 개정한다. 039의 "공개 생성 경로는 초기화 메서드
하나" 원칙은 유지한다.

## 명확화

### 세션 2026-09-21

- 질문: `ColorToken` 색 속성의 계약 종류를 무엇으로 나누는가? → 답변: 역할별 두 계약으로 나눈다.
  전경색(`StyledText` 글자색, `IconPlainButton` 틴트, `LabeledProgressBar` 값 색)과 배경색
  (`IconPlainButton` 배경, `ScreenContainer`·`OverlayContainer` 배경).
- 질문: 대상 컴포넌트 하나만 가진 속성 종류(텍스트 스타일, 정렬, 변형)에도 계약을 두는가? → 답변:
  모두 계약을 두되, `HomeProjectCard.Variant`는 별도 종류로 두지 않고 스타일 계약에 합친다.
- 질문: 기본값이 없던 시각 속성의 기본값은 어떤 기준으로 고르는가? → 답변: 디자인 시스템의 중립·기본
  값(본문 텍스트 스타일, 각 enum의 기본 케이스)을 기본값으로 삼는다.
- 질문: SwiftUI 타입인 `StyledText`의 정렬(`TextAlignment`)도 자체 계약으로 두는가? → 답변: 두지
  않는다. `alignment` 저장 속성을 없애고 호출부는 SwiftUI `.multilineTextAlignment(_:)`로 선언한다.
- 질문: 초기화 인자를 하나의 모델로 묶는 기준은 무엇인가? → 답변: 상태가 아니라 **표시 값**이 2개
  이상인 컴포넌트는 표시 값을 하나의 모델로 정의해 초기화 인자로 받는다. 상태·`Binding`·콜백·자식
  View는 모델에 넣지 않고 개별 인자로 남는다.
- 질문: 표시 값 모델 규칙을 어떤 컴포넌트에 적용하는가? → 답변: `UIComponent`의 모든 공개 View
  컴포넌트에 적용하고, 공개 중첩 값 타입(`SelectionCardList.Item`, `ActionMenu.Item`,
  `ScreenControlBar.Control` 등)의 초기화 인자도 같은 규칙으로 정리한다.
- 질문: 표시 값·상태·동작 설정을 어떻게 구분하는가? → 답변: 표시 값은 화면에 보이는 내용(텍스트·
  수치·진행률·이미지·아이콘, `placeholder`·`errorMessage`·`supportingText`, `isRequired`처럼 고정
  표기를 정하는 값)이다. `accessibilityLabel`처럼 화면에 보이지 않는 문구는 표시 값에서 빼고 개별
  인자로 둔다. 상태는 상호작용·판정으로 바뀌는 값(`isSelected`·`isEnabled`·`isError`·`judgement`·
  `state`·`isExpanded`)이고, 동작 설정(`keyboardType`·`isLooping`·`speed`·`contentMode`·`expansion`
  등)은 개별 인자로 남는다.
- 질문: 표시 값 모델은 Feature의 어디에서 만드는가? → 답변: Feature View가 컴포넌트 호출 지점에서
  State·업무 모델 값을 표시 값 모델로 매핑해 만든다. Feature State와 Reducer는 표시 값 모델 타입을
  보유하지 않는다.
- 질문: 문서에 반영할 때 기존 "표시 상태를 묶는 `ViewModel`·`State`·wrapper 금지" 규칙은 어떻게
  다루는가? → 답변: 금지 문장을 모든 문서에서 삭제하고, FR-015의 표시 값 모델 규칙만 새로 서술한다.
- 질문: 시각 속성 메서드 전환과 표시 값 모델 전환을 한 기능에서 다루는가? → 답변: 한 기능으로
  유지한다. 제목과 시나리오를 두 전환 모두를 다루도록 넓히고, 표시 값 모델을 별도 시나리오(P1)로 둔다.
- 질문: 컴포넌트가 상호작용으로 스스로 바꾸는 상태는 어떻게 받는가? → 답변: 값 인자와 짝이 되는
  변경 콜백 대신 SwiftUI `Binding` 하나로 받고, 짝이던 변경 콜백은 제거한다. `isEnabled`·`judgement`·
  `isDeleting`·`isError`처럼 컴포넌트가 바꾸지 않는 읽기 전용 상태는 값 인자로 남는다.
- 질문: 상태 `Binding` 전환도 이 기능에서 다루는가? → 답변: 042에 포함한다. 시각 속성·표시 값 모델과
  같은 호출부를 바꾸므로 호출부를 한 번만 고친다.
- 질문: Feature는 상태 `Binding`을 어떻게 만드는가? → 답변: 화면 View가 호출 지점에서
  `Binding(get: { store.… }, set: { … send(.기존 View Action) })`을 만든다. setter는 기존 View Action을
  보내며 `BindableAction`·`BindingReducer`를 도입하지 않는다. Action·Reducer·Reducer 테스트는 바뀌지
  않는다.
- 질문: 상태를 스스로 바꾸지 않는 `ChoiceAnswerOption`·`SelectionCard`·`PushedScreenOverlay`는
  어떻게 두는가? → 답변: 값 인자로 유지한다(`ChoiceAnswerOption`의 `state`·`onTap`,
  `SelectionCard.isSelected`, `PushedScreenOverlay.isPresented`). `ChoiceAnswerOption.ExpansionControl`의
  `toggleable(isExpanded:onToggleExpand:)`만 `toggleable(isExpanded: Binding<Bool>)`로 바꾼다.
- 질문: 목록 단위 선택 상태(`SelectionCardList`)는 어떤 형태로 받는가? → 답변:
  `SelectionCardList(items:selection:)`로 `selection: Binding<String?>` 하나를 받는다. `Item.isSelected`와
  `onSelect`는 제거하고 `Item`은 `init(id:displayModel:)`만 남긴다. 선택 항목이 없으면 `nil`이다.
- 질문: 상태 `Binding` 인자는 기본값을 갖는가? → 답변: 갖지 않는다. 기본값 없는 필수 인자로 두고
  기존 `Bool` 기본값(`= false`·`= true`)은 없앤다. 프리뷰·테스트만 `.constant(...)`를 넘긴다
  (`docs/conventions/view-declarations/binding.md`의 `.constant` 기본값 금지 규칙).

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - 시각 속성을 Self 반환 메서드로 선언 (우선순위: P1)

개발자가 UI 컴포넌트를 쓸 때 무엇을 보여 주고 어떻게 동작하는지는 초기화 메서드로, 어떻게 보이는지는
컴포넌트 뒤에 이어 붙이는 메서드로 선언한다. 지금은 `StyledText(text:style:color:alignment:)`처럼
표시 값과 시각 속성이 한 초기화 인자 목록에 섞여 있어, 시각 속성이 늘어날수록 초기화 인자가
길어지고 기본값을 가진 인자와 필수 인자의 구분이 흐려진다. 변경 뒤에는
`StyledText(text: "제목").textStyle(.subtitle1).color(.grey400)`처럼 SwiftUI `Text.font(_:)`와
같은 방식으로 시각 속성을 선언하며, 메서드는 컴포넌트 자신의 타입을 그대로 돌려주므로 여러 시각
속성을 이어서 선언할 수 있다. (메서드 이름은 예시이며 계획 단계에서 확정한다.)

**주요 행위자**: 개발자(UI 컴포넌트를 쓰는 Feature·App 코드 작성자, UI 컴포넌트 작성자)

**우선순위 이유**: 이 기능의 목적 자체다. 시나리오 2·3은 이 계약이 정해져야 진행할 수 있다.

**독립 테스트**: 대상 컴포넌트 하나를 전환하고 그 호출부를 모두 옮긴 뒤 build·compile·test가
통과하고, 그 컴포넌트의 프리뷰가 전환 전과 같은 화면을 그리는지 확인한다. 컴포넌트 단위로
독립 검증할 수 있다.

**수용 시나리오**:

1. **전제** 대상 컴포넌트가 시각 속성을 초기화 인자로 받고 있고, **실행** 그 속성을 Self 반환
   메서드로 옮기면, **결과** 초기화 메서드에는 표시 값·상태·콜백만 남고 시각 속성은 메서드로만
   선언할 수 있다.
2. **전제** 시각 속성 메서드를 호출하지 않은 컴포넌트가 있고, **실행** 화면을 그리면, **결과**
   그 속성은 컴포넌트가 정한 기본값으로 그려진다.
3. **전제** 한 컴포넌트에 시각 속성 메서드를 여러 개 이어 붙이고, **실행** 화면을 그리면, **결과**
   각 메서드로 선언한 값이 모두 반영되고 호출 순서와 무관하게 같은 결과가 나온다.
4. **전제** 같은 속성 메서드를 두 번 호출하고, **실행** 화면을 그리면, **결과** 마지막에 선언한
   값이 적용된다.

---

### 시나리오 2 - 속성 종류별 공통 계약 (우선순위: P1)

UI 컴포넌트 작성자가 새 컴포넌트에 `Style`·`Size` 같은 시각 속성을 둘 때, 속성 종류마다 정해진
공통 계약을 채택해 같은 이름과 같은 형태의 메서드를 제공한다. 컴포넌트마다 메서드 이름과 형태를
따로 정하지 않으므로, 개발자는 컴포넌트가 달라도 "스타일은 이 메서드, 크기는 이 메서드"로 같은
방식으로 선언한다.

**주요 행위자**: UI 컴포넌트 작성자, 개발자

**우선순위 이유**: 사용자가 요청한 "속성 종류별 Protocol"이 이 시나리오다. 계약 없이 메서드만
추가하면 컴포넌트마다 이름과 형태가 달라질 수 있다.

**독립 테스트**: 같은 종류의 시각 속성을 가진 컴포넌트들이 같은 계약을 채택하고, 같은 이름의
메서드로 선언되는지 코드 리뷰와 컴파일로 확인한다. 계약 하나를 채택한 컴포넌트만으로도
검증할 수 있다.

**수용 시나리오**:

1. **전제** 스타일 속성을 가진 컴포넌트가 여럿 있고, **실행** 각 컴포넌트에서 스타일을 선언하면,
   **결과** 모든 컴포넌트가 같은 이름의 메서드를 쓰며 각자 자기 스타일 타입만 받는다.
2. **전제** 한 컴포넌트가 스타일과 크기 두 속성을 갖고, **실행** 두 계약을 채택하면, **결과** 두
   메서드를 모두 제공하고 서로 간섭하지 않는다.
3. **전제** 컴포넌트가 받지 않는 종류의 속성이 있고, **실행** 그 속성 메서드를 호출하면, **결과**
   컴파일 오류가 난다(런타임에 무시되지 않는다).

---

### 시나리오 3 - 호출부 전환과 컨벤션 개정 (우선순위: P2)

개발자가 Feature·App·UI 프리뷰 어디에서든 새 방식 하나로만 시각 속성과 표시 값을 전달한다. 초기화
인자에서 시각 속성을 완전히 제거하고 표시 값을 모델로 묶으므로 이전 방식과 새 방식이 공존하지 않는다.
동시에 컨벤션·패키지 규칙 문서(FR-016)가 두 규칙을 규정해, 이후 추가되는 컴포넌트도 같은 방식을
따른다.

**주요 행위자**: 개발자, 리뷰어

**우선순위 이유**: 제거와 호출부 전환이 끝나야 "선언 경로 하나"가 성립한다. 컨벤션 개정이 없으면
039의 규칙과 실제 코드가 어긋난다.

**독립 테스트**: 대상 컴포넌트의 초기화 인자에 시각 속성과 개별 표시 값 인자(FR-015 대상)가 남아
있지 않은지 조회하고, 전체 build·compile·test가 통과하는지 확인한다. 개정된 문서만 읽고 새
컴포넌트의 시각 속성 선언 방식과 표시 값 모델 적용 여부를 판정할 수 있는지 검토한다.

**수용 시나리오**:

1. **전제** 전환이 끝났고, **실행** 대상 컴포넌트의 공개 초기화 메서드를 조회하면, **결과** 시각
   속성 인자가 하나도 없다.
2. **전제** 컨벤션이 개정됐고, **실행** 리뷰어가 시각 속성을 초기화 인자로 받는 새 컴포넌트를 보면,
   **결과** 컨벤션 문서의 규칙으로 기준 이탈을 지적할 수 있다.
3. **전제** 문서 개정이 끝났고, **실행** FR-016 대상 문서를 조회하면, **결과** 표시 상태 wrapper
   금지 문장과 명세 규칙에 어긋나는 서술이 없다.

---

### 시나리오 4 - 표시 값을 하나의 모델로 전달 (우선순위: P1)

개발자가 표시 값을 여러 개 받는 컴포넌트를 쓸 때, 표시 값을 개별 인자로 나열하지 않고 컴포넌트가
정의한 표시 값 모델 하나로 전달한다. 지금은 `ConfirmationSheet(imageURL:title:message:confirmTitle:
cancelTitle:...)`처럼 표시 값·상태·콜백이 한 인자 목록에 섞여 있다. 변경 뒤에는 무엇을 보여 주는지는
모델 하나로, 상태·동작 설정·콜백·자식 View는 개별 인자로 전달해 초기화 인자의 역할이 드러난다.
Feature에서는 View가 호출 지점에서 State 값을 모델로 매핑한다.

**주요 행위자**: 개발자(Feature·App 코드 작성자, UI 컴포넌트 작성자), 리뷰어

**우선순위 이유**: 시각 속성 메서드 전환과 같은 호출부를 바꾸므로 함께 진행해야 호출부를 두 번
고치지 않는다. 문서 개정(FR-016)의 핵심 규칙이기도 하다.

**독립 테스트**: 표시 값이 2개 이상인 컴포넌트 하나를 모델 방식으로 전환하고 그 호출부를 모두 옮긴 뒤
build·compile·test가 통과하고 프리뷰가 전환 전과 같은 화면을 그리는지 확인한다. 컴포넌트 단위로
독립 검증할 수 있다.

**수용 시나리오**:

1. **전제** 표시 값을 2개 이상 받는 컴포넌트가 있고, **실행** 전환 뒤 공개 초기화 메서드를 조회하면,
   **결과** 표시 값은 모델 인자 하나로만 받고 상태·동작 설정·`accessibilityLabel`·`Binding`·콜백·
   자식 View는 개별 인자로 남아 있다.
2. **전제** 표시 값이 1개 이하인 컴포넌트가 있고, **실행** 전환 뒤 초기화 메서드를 조회하면, **결과**
   표시 값 모델이 없고 표시 값은 개별 인자로 받는다.
3. **전제** Feature 화면이 모델 방식 컴포넌트를 쓰고, **실행** Feature State와 Reducer를 조회하면,
   **결과** 표시 값 모델 타입을 참조하지 않고 View의 호출 지점에서만 모델을 만든다.
4. **전제** 컴포넌트가 상호작용으로 스스로 바꾸는 상태를 갖고, **실행** 전환 뒤 공개 초기화 메서드를
   조회하면, **결과** 그 상태는 `Binding` 인자 하나로 받고 같은 상태를 바꾸는 변경 콜백이 없다.

---

### 예외·경계 사례

- 시각 속성 메서드를 `padding`·`frame` 같은 SwiftUI 일반 수정자 **뒤에** 호출하면, 결과 타입이
  더 이상 컴포넌트가 아니므로 컴파일 오류가 난다. `Text.font(_:)`와 같은 제약이며, 시각 속성
  메서드는 일반 수정자보다 먼저 호출해야 한다. 이 제약을 컨벤션에 명시한다.
- 새 메서드 이름이 SwiftUI `View`의 기존 수정자 이름(`background`, `tint`, `foregroundStyle` 등)과
  같으면 호출부에서 어느 쪽이 선택되는지 모호해지거나 의도와 다른 수정자가 적용될 수 있다. 이름이
  겹쳐 해석이 달라지는 경우가 없어야 한다.
- 지금 기본값이 없는 필수 시각 속성(`StyledText`의 텍스트 스타일, `LabeledCard`의 스타일,
  `HomeProjectCard`의 스타일)은 기본값을 새로 갖는다. 전환 전 명시했던 값은 전환 뒤에도 모든
  호출부에서 같은 값으로 그려져야 한다.
- `StyledText`가 `alignment`를 저장하지 않으므로, 정렬을 선언하지 않은 호출부는 SwiftUI 기본값
  `.leading`(또는 상위 View가 준 `multilineTextAlignment` 환경값)으로 그려진다. 전환 전 `.leading`이
  아닌 정렬을 명시했던 호출부는 `.multilineTextAlignment(_:)`로 같은 값을 선언해야 하며, 상위 환경값이
  바뀐 정렬을 적용해 렌더링이 달라지는 호출부가 없어야 한다.
- `ActionButton(styledText:)`처럼 다른 시각 속성 컴포넌트를 인자로 받는 경우, 안쪽 컴포넌트의
  시각 속성은 안쪽 컴포넌트에 선언한 값이 유지된다.
- 컴포넌트 내부에서 자식 컴포넌트를 만들 때(예: `SelectionCardList`가 `SelectionCard`에 스타일을
  넘기는 경우) 부모에 선언한 시각 속성이 자식에 그대로 전달된다.
- 여러 컴포넌트가 같은 이름의 속성 enum을 각자 중첩 타입으로 갖는다(`ActionButton.Style`,
  `TagBadge.Style`). 공통 계약은 컴포넌트마다 다른 속성 타입을 허용해야 한다.
- 중첩 값 타입의 식별자(`SelectionCardList.Item.id`, `ActionMenu.Item.id`)는 화면에 보이지 않으므로
  표시 값이 아니며 개별 인자로 남는다. 식별자를 빼고 센 표시 값이 2개 이상일 때만 모델 대상이다.
- 상태 `Binding`의 setter가 기존 View Action을 보내므로 탭·토글 뒤 화면에 보이는 값은 Store 상태가
  바뀐 뒤에 갱신된다. 서버 정본을 바꾸는 상태(북마크 등)는 Reducer가 기존처럼 처리하며, 요청이 실패해
  Store 값이 바뀌지 않으면 컴포넌트도 전환 전과 같은 값을 그린다.
- 표시 값이 옵셔널이거나 기본값을 가진 경우(`supportingText: String? = nil`)에도 표시 값 개수에
  포함한다. 전환 뒤 그 값을 생략했던 호출부의 렌더링은 전환 전과 같아야 한다.

## 요구사항 *(필수)*

### 기능 요구사항

- **FR-001**: 대상은 UI 패키지 `UIComponent`의 공개 컴포넌트가 가진 **시각 속성**이다. 시각 속성은
  UI 패키지가 정의한 enum·토큰 타입(`Style`, `Size`, `Variant`, `SelectionCardStyle`, `ColorToken`,
  `TextStyleToken`)의 값으로, 표시 내용·상태·동작은 바꾸지 않고 모양만 정하는
  값이다.
- **FR-002**: 대상 컴포넌트와 속성은 다음과 같다. 계획 단계의 기준선 실측으로 누락이 확인되면
  FR-001 기준에 맞는 항목을 추가한다.
  - `StyledText`: 텍스트 스타일, 전경색(글자색)
  - `ActionButton`: 스타일, 크기
  - `TagBadge`: 스타일, 크기
  - `IconGlassButton`: 스타일, 크기
  - `LabeledCard`: 스타일
  - `IconPlainButton`: 전경색(틴트), 배경색
  - `LabeledProgressBar`: 전경색(값 색)
  - `SelectionCard`, `SelectionCardList`: 스타일
  - `HomeProjectCard`: 스타일(현재 `Variant`)
  - `ScreenContainer`, `OverlayContainer`: 배경색
- **FR-003**: 제목·텍스트·이미지 같은 표시 값, `isSelected`·`isEnabled`·`isSaved` 같은 상태,
  `Binding`, 콜백, 자식 View(`content`·`footer`)는 시각 속성이 아니며 초기화 인자에 남는다. 표시
  값이 2개 이상이면 FR-015에 따라 표시 값 모델 하나로 받고, 컴포넌트가 스스로 바꾸는 상태는
  FR-017에 따라 `Binding`으로 받는다.
  `IconPlainButton`의 `size`·`iconSize`처럼 UI 패키지 enum·토큰이 아닌 수치와
  `ScreenEdgeScrim`의 `edge`·`height`처럼 배치를 정하는 필수 값도 이번 범위에서 제외한다.
  SwiftUI가 수정자로 이미 제공하는 속성(`StyledText`의 `TextAlignment` 정렬)은 계약을 두지 않는다.
  `StyledText`는 `alignment` 저장 속성과 초기화 인자를 없애고, 호출부는 SwiftUI
  `.multilineTextAlignment(_:)`로 정렬을 선언한다.
- **FR-004**: 시각 속성 종류마다 공통 계약을 하나씩 두고, 그 속성을 가진 컴포넌트는 해당 계약을
  채택한다. 계약은 컴포넌트마다 다른 속성 타입(예: `ActionButton.Style`과 `TagBadge.Style`)을
  허용한다. 속성 종류는 값의 타입이 아니라 **역할**로 나눈다. `ColorToken` 색 속성은 전경색
  (`StyledText` 글자색, `IconPlainButton` 틴트, `LabeledProgressBar` 값 색)과 배경색
  (`IconPlainButton` 배경, `ScreenContainer`·`OverlayContainer` 배경) 두 계약으로 나누며, 한
  컴포넌트가 두 색 계약을 함께 채택할 수 있다. 대상 컴포넌트 하나만 가진 종류(텍스트 스타일)도
  계약을 둔다. `HomeProjectCard.Variant`는 별도 종류가 아니라 스타일 계약으로 선언한다.
- **FR-005**: 각 계약은 속성값 하나를 받아 **컴포넌트 자신의 타입**을 반환하는 메서드를 제공한다.
  반환값은 그 속성만 바뀌고 나머지 표시 값·상태·콜백·시각 속성은 호출 전과 같다.
- **FR-006**: 시각 속성 메서드는 여러 개를 이어 붙일 수 있고, 서로 다른 속성의 호출 순서는 결과에
  영향을 주지 않는다. 같은 속성을 여러 번 선언하면 마지막 값이 적용된다.
- **FR-007**: 모든 시각 속성은 기본값을 가진다. 기존 기본값은 그대로 유지하고, 기본값이 없던 속성
  (`StyledText` 텍스트 스타일, `LabeledCard` 스타일, `HomeProjectCard` 스타일)은 디자인 시스템의
  중립·기본 값(텍스트는 본문 스타일, enum은 기본 케이스)을 기본값으로 삼는다. 호출부 최빈값은
  기본값 선택 기준이 아니다. 구체 값은 계획 단계에서 이 기준으로 확정하고 근거를 기록한다.
- **FR-008**: 대상 컴포넌트의 공개 초기화 메서드에서 시각 속성 인자를 모두 제거한다. 같은 속성을
  선언하는 두 번째 경로(초기화 인자, 정적 팩토리, 별도 래퍼)를 남기지 않는다.
- **FR-009**: Feature·App·UI(프리뷰 포함)·테스트의 모든 호출부를 새 방식으로 전환한다. 전환 뒤 각
  호출부가 그리는 시각 속성 값은 전환 전과 같아야 한다. 전환 전에 기본값과 같은 값을 명시했던
  호출부는 메서드를 생략할 수 있다.
- **FR-010**: 새 메서드 이름은 SwiftUI `View` 수정자와 이름이 같아 호출 해석이 모호해지거나 의도와
  다른 수정자가 선택되는 일이 없어야 한다.
- **FR-011**: 메서드가 받지 않는 속성 종류를 선언하려 하면 컴파일 오류가 나야 한다.
- **FR-012**: `docs/conventions/view/component-init.md`의 "시각 변형은 `Style`·`Size` 같은 enum을
  초기화 인자로 받아 선택한다" 규칙을 새 방식으로 개정한다. 초기화 메서드가 표시 값·상태·콜백만
  받는다는 경계, 표시 값이 2개 이상이면 표시 값 모델 하나로 받는다는 규칙(FR-015), 속성 종류별
  계약 채택, 기본값 필수, 일반 수정자보다 먼저 호출한다는 제약을 규정한다.
- **FR-016**: 이 명세가 정한 규칙(FR-003·FR-004·FR-007·FR-012·FR-015·FR-017)을 이 규칙과 어긋나거나 이를
  전제하는 모든 프로젝트 문서에 반영한다. 명세 작성 시점 조회 기준 대상과 반영 내용은 다음과 같으며,
  계획 단계에서 전수 조회로 누락을 보완한다.
  - `docs/conventions/view/component-init.md`: FR-012 개정. "여러 인자가 함께 변경된다는 이유만으로
    상태 wrapper를 추가하지 않는다" 문장과 `SelectionToggle(state:)` 금지 예시를 삭제하고, 시각 속성
    메서드·표시 값 모델 예시로 바꾼다. Feature 모델 직접 전달(`ProjectRow(project:)`) 금지는 유지한다.
  - `docs/conventions/view/display-value-binding-callback.md`: 표시 상태 wrapper 금지 문장을 삭제하고
    표시 값 모델 규칙, 표시 값·상태·동작 설정·화면에 보이지 않는 문구의 구분(FR-015)과 컴포넌트가
    스스로 바꾸는 상태는 변경 콜백 대신 기본값 없는 `Binding`으로 받는다는 규칙(FR-017)을 서술한다.
  - `docs/package-rules/feature.md`에는 화면 View가 상태 `Binding`을 `Binding(get:set:)`으로 만들고
    setter가 기존 View Action을 보낸다는 규칙(FR-017)도 추가한다.
  - `docs/conventions/view.md`: 공개 생성 경로 요약과 체크리스트의 wrapper 금지 항목을 삭제하고, 시각
    속성 메서드·표시 값 모델 항목으로 바꾼다.
  - `docs/package-rules/ui.md`: "표시 상태를 묶는 ViewModel, State 또는 동등한 wrapper 타입을
    정의해서는 안 됩니다" 제약을 삭제하고 표시 값 모델 규칙을 가리킨다.
  - `docs/conventions/ui-component/public-contract.md`: "표시 상태 wrapper 금지" 언급을 삭제한다.
  - `docs/conventions/view-declarations/style.md`, `docs/conventions/view-declarations.md`,
    `docs/conventions/view-declarations/internal-declarations.md`: `Style`을 초기화 인자로 받는다는
    서술을 시각 속성 메서드 선언으로 바꾸고, 표시 값 모델을 View 내부 선언 목록에 추가한다.
  - `docs/package-rules/feature.md`: Feature View가 표시 값 모델을 호출 지점에서 매핑해 만들고
    State·Reducer는 이를 보유하지 않는다는 규칙을 추가한다.
  - `.agents/skills/implement-figma-ui/references/component-index.md`: 초기화 인자로 설명한 시각
    속성·표시 값 서술을 새 공개 계약에 맞춘다.
  - 화면 ViewModel 금지(`docs/package-rules/feature.md`)와 Feature 업무 모델을 UIComponent 공개
    API에 노출하지 않는다는 제약은 표시 값 모델과 별개이므로 유지한다.
- **FR-013**: 렌더링 결과(레이아웃·토큰·색·글꼴)는 바뀌지 않는다. 시각 속성의 값 대응(예: 스타일별
  배경 토큰)은 각 컴포넌트의 속성 타입이 계속 소유한다.
- **FR-014**: UI 공개 API 제거와 Feature·App 호출부 전환은 함께 바뀌어야 compile되므로 같은
  브랜치에서 진행하며, 컴포넌트 단위로 나눠 검증할 수 있어야 한다.
- **FR-015**: 적용 범위는 FR-002와 별개로 `UIComponent`의 모든 공개 View 컴포넌트와 그 공개 중첩
  값 타입(`SelectionCardList.Item`, `ActionMenu.Item`, `ScreenControlBar.Control` 등)이다. 목록은
  계획 단계의 기준선 실측으로 확정한다.
  표시 값을 2개 이상 받는 컴포넌트·중첩 값 타입은 표시 값을 하나의 모델로 정의하고, 초기화
  메서드는 개별 표시 값 인자 대신 그 모델 하나를 받는다. 인자는 다음처럼 구분한다.
  - **표시 값**(모델에 넣음): 화면에 보이는 내용. 텍스트·수치·진행률·이미지·아이콘,
    `placeholder`·`errorMessage`·`supportingText`, `isRequired`처럼 고정 표기를 정하는 값.
  - **상태**(개별 인자): 상호작용·판정으로 바뀌는 값. `isSelected`·`isEnabled`·`isError`·
    `judgement`·`state`·`isExpanded` 등. 컴포넌트가 스스로 바꾸는 상태는 FR-017에 따라
    `Binding`으로, 읽기 전용 상태는 값으로 받는다.
  - **동작 설정**(개별 인자): `keyboardType`·`textInputAutocapitalization`·`autocorrectionDisabled`·
    `isLooping`·`speed`·`contentMode`·`expansion` 등.
  - **화면에 보이지 않는 문구**(개별 인자): `accessibilityLabel` 등.
  - `Binding`·`FocusState`, 콜백, 자식 View도 모델에 넣지 않고 개별 인자로 남는다.
  Feature에서는 View가 컴포넌트 호출 지점에서 State·업무 모델 값을 표시 값 모델로 매핑해 만든다.
  Feature State·Reducer는 표시 값 모델 타입을 보유하거나 만들지 않으며, 이번 전환으로 Reducer와
  Reducer 테스트는 바뀌지 않는다. 표시 값이 1개 이하인 컴포넌트·중첩 값 타입은 모델을 두지 않는다. 호출부 전환은 FR-009·
  FR-014와 같은 방식(모든 호출부 전환, 컴포넌트 단위 검증)을 따른다.

- **FR-017**: 컴포넌트가 상호작용(탭·토글·펼침·닫기)으로 스스로 바꾸는 상태는 값 인자와 변경
  콜백의 짝 대신 SwiftUI `Binding` 하나로 받는다. 짝이던 변경 콜백(`onTap`·`onToggle`·
  `onBookmarkTap`·`onDismiss` 등 그 상태를 바꾸는 용도의 콜백)은 제거한다. 상태 변경과 무관한
  콜백(`onOpenLink`·`onActionTap` 등)은 남는다. 컴포넌트가 바꾸지 않는 읽기 전용 상태(`isEnabled`·
  `judgement`·`isDeleting`·`isError` 등)는 값 인자로 남는다. 판정 결과를 포함하거나 부모가 소유하는
  상태(`ChoiceAnswerOption.state`, `SelectionCard.isSelected`)와 컴포넌트가 닫지 않는 표시 여부
  (`PushedScreenOverlay.isPresented`)도 값 인자다. 공개 중첩 값 타입 안의 상태·콜백 짝
  (`ChoiceAnswerOption.ExpansionControl.toggleable`)에도 같은 규칙을 적용한다. 목록 단위 선택은
  목록이 선택 `Binding` 하나를 받는다(`SelectionCardList`의 `selection: Binding<String?>`, 항목의
  `isSelected`와 `onSelect` 제거). 상태 `Binding` 인자는 기본값 없는 필수 인자이며, 전환 전 `Bool`
  기본값은 없앤다. 기존 `TabShell(selected:)`가 이 규칙의 선례다. 대상 목록은 계획 단계의 기준선 실측으로 확정한다. Feature에서는 화면 View가 호출 지점에서
  `Binding(get:set:)`을 만들고, setter는 제거된 콜백이 보내던 기존 View Action을 보낸다.
  `BindableAction`·`BindingReducer`는 도입하지 않으며 Action·Reducer·Reducer 테스트는 바뀌지 않는다.

### 핵심 엔터티

- **시각 속성 계약**: 한 종류의 시각 속성(스타일, 크기, 전경색, 배경색 등)을 선언하는 공통 규약.
  종류는 값의 타입이 아니라 역할로 구분한다. 속성 타입과
  "자기 타입을 반환하는 선언 메서드"를 정의하며, 컴포넌트가 채택한다.
- **시각 속성 값**: 컴포넌트가 소유한 enum·토큰 값. 기본값을 가지며, 값별 렌더링 대응은 속성
  타입이 소유한다.
- **표시 값 모델**: 표시 값이 2개 이상인 컴포넌트가 초기화 인자로 받는 값 하나. 그 컴포넌트의
  표시 값만 담고 상태·동작 설정·화면에 보이지 않는 문구(`accessibilityLabel`)·`Binding`·콜백·
  자식 View·시각 속성은 담지 않는다.
- **상태 `Binding`**: 컴포넌트가 상호작용으로 바꾸는 상태 하나를 읽고 쓰는 SwiftUI `Binding`.
  표시 값 모델에 넣지 않고 개별 인자로 받으며, 같은 상태를 바꾸는 별도 콜백을 함께 두지 않는다.
- **대상 컴포넌트**: FR-002의 UI 공개 컴포넌트. 초기화 메서드와 채택한 시각 속성 계약으로 공개
  계약이 구성된다.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: FR-002의 모든 대상 컴포넌트에서 공개 초기화 메서드의 시각 속성 인자가 0개다.
- **SC-002**: 같은 종류의 시각 속성은 모든 대상 컴포넌트에서 같은 이름의 메서드 하나로 선언된다.
  속성 종류별로 메서드 이름이 1개다.
- **SC-003**: 전환 전후 `build`, `compile`, `test` 결과가 모두 통과한다.
- **SC-004**: 대상 컴포넌트와 이를 쓰는 화면의 프리뷰가 전환 전후 같은 레이아웃·토큰·색으로
  그려진다. 호출부 diff 리뷰에서 시각 속성 값이 바뀐 호출부가 0곳이다.
- **SC-005**: 시각 속성 메서드 이름 중 SwiftUI `View` 수정자와 같아서 해석이 달라지는 경우가
  0건이다.
- **SC-006**: 개정된 컨벤션 문서만 읽고 새 컴포넌트의 시각 속성 선언 방식과 기본값·호출 순서
  제약, 표시 값 모델 적용 여부와 인자 구분(표시 값·상태·동작 설정), 상태를 `Binding`으로 받을지
  값으로 받을지를 판정할 수 있다. 컨벤션 문서에서 "시각 변형을 초기화 인자로 받는다"는 문장이 0곳이다.
  FR-016 대상 문서에서 "표시 상태를 묶는 `ViewModel`·`State`·wrapper 금지" 문장이 0곳이고, 명세 규칙과
  어긋나는 서술이 0곳이다.
- **SC-007**: 각 시각 속성 계약에 대해, 메서드가 해당 속성만 바꾸고 다른 값은 유지함을 확인하는
  단위 테스트가 있다.
- **SC-008**: FR-015 대상 컴포넌트·중첩 값 타입의 공개 초기화 메서드에서 개별 표시 값 인자가 0개이고, 표시 값은
  모델 인자 하나로만 전달된다. 모델에 상태·동작 설정·`accessibilityLabel`·`Binding`·콜백·자식
  View 필드가 0개다. Feature State·Reducer에서 표시 값 모델 타입을 참조하는 곳이 0곳이다.
- **SC-009**: FR-017 대상 컴포넌트의 공개 초기화 메서드에서 스스로 바꾸는 상태는 `Binding` 인자이고,
  그 상태를 바꾸는 용도의 콜백 인자가 0개다. 상태 `Binding` 인자의 기본값이 0개다. 읽기 전용 상태는
  값 인자로 남아 있다.

## 가정

- 대상은 UI 패키지의 공개 컴포넌트다. Feature 화면 안의 비공개 서브뷰는 이번 범위가 아니다.
- 예외로, UI 컴포넌트를 감싸 그 시각 속성을 그대로 전달하는 Feature 래퍼(예:
  `FeedbackActionButton`)는 감싼 컴포넌트와 같은 시각 속성 계약을 채택한다. 그래야 FR-008의
  "두 번째 선언 경로 없음"을 호출부 전체에서 지킬 수 있다. 컨벤션 개정(FR-016) 범위는 UIComponent로
  한정하며, 이 래퍼 규칙은 계획의 조사 문서에 근거를 남긴다.
- 기능 브랜치는 `develop`이 아니라 현재 작업 기준(041 완료 시점, `fc9dcee`)에서 분기했다.
  `develop`에는 039·041의 UI·Feature 변경이 아직 없어 대상 코드가 다르기 때문이다.
- 호출부 수는 명세 작성 시점 조회 기준 약 260곳(`StyledText` 약 170곳)이며, 표시 값 모델
  전환(FR-015) 대상 호출부는 포함하지 않았다. 계획 단계에서 두 전환의 기준선을 실측해 정정한다.
- 메서드 이름, 계약 이름, 기본값 구체 값, 계약의 구현 방식, 표시 값 모델의 이름·위치는 계획
  단계에서 정한다.
- 스냅샷 테스트 같은 자동 시각 비교 도구는 없으므로 렌더링 동일성은 프리뷰 확인과 호출부 diff
  리뷰로 검증한다.
