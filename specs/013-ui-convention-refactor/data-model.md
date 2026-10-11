# 데이터 모델: UI 패키지 컨벤션 리팩터링

이 기능은 영속 데이터 모델을 추가하지 않는다. 아래 모델은 UI 공개 계약, 외부 상태,
검증 장면과 target 경계를 구현·테스트에서 동일하게 해석하기 위한 설계 모델이다.

## 1. 컴포넌트 공개 계약

### 필드

- `displayValues`: View가 읽기 전용으로 렌더링하는 문자열, 숫자, asset, token과 보조 타입
- `externalBindings`: 상위 소유자가 원본을 가진 변경 가능 값
- `eventCallbacks`: 한 번의 사용자 입력을 상위에 전달하는 프레임워크 중립 closure
- `visualVariant`: 고정된 토큰 조합을 선택하는 `Style` 또는 factory
- `localConstants`: 한 View 안에서만 의미가 있는 layout·token 참조

### 검증 규칙

- `displayValues`는 init/factory 인자로 직접 전달한다.
- `externalBindings`는 기본 `.constant` 값이나 내부 `@State` 복제 없이 필수 `Binding`으로
  전달한다.
- `eventCallbacks`는 상태 wrapper에 넣지 않는다.
- `ViewModel`, `State`, `Configuration`처럼 표시 상태를 묶는 동등 wrapper를 만들지 않는다.
- `Style`, `Size`, `Variant`, `Asset`, `Item`, `Control`, `User`는 표시 상태 묶음이 아니라
  각자의 시각·식별·표현 책임을 가질 때만 유지한다.

## 2. ActionButton 표현 상태

### 필드

- `title`: 표시 문자열
- `typography`: 기존 styled label 경로가 제공하던 직접 text style·color·alignment 값
- `style`: `primary | secondary | destructive | text`
- `size`: `large | medium | small`
- `isEnabled`: 외부가 정하는 활성 여부
- `isPressed`: 내부 `ButtonStyle`이 관찰하는 일시 값
- `action`: 활성 상태 탭 콜백

### 상태 전이

```text
enabled/default --touch down--> enabled/pressed --touch up--> enabled/default + action 1회
enabled/default --isEnabled=false--> disabled
disabled --tap--> disabled + action 0회
any enabled state --style=destructive--> error visual variant
```

### 검증 규칙

- `isPressed`를 공개 State·Binding·init 인자로 노출하지 않는다.
- `destructive`는 오류 시각 변형이며 별도 오류 상태 wrapper를 만들지 않는다.
- 모든 상태에서 기존 size별 surface와 44pt 이상의 실제 터치 영역을 유지한다.

## 3. SelectionCardList 선택 모델

### Item

- `id: String`: 목록 순서와 독립적인 안정적 식별자
- `title: String`
- `supportingText: String?`
- `badgeText: String?`

### Selection

- `items: [Item]`
- `selectedID: Binding<Item.ID?>`

### 관계

- 목록은 여러 `Item`을 가진다.
- 한 시점의 선택은 `nil` 또는 정확히 하나의 `Item.ID`다.
- 각 `SelectionCard.isSelected`는 `selectedID == item.id`로 파생한다.

### 상태 전이

```text
nil --card(id) tap--> id
oldID --card(newID) tap--> newID
selectedID --items reorder--> selectedID
selectedID --external binding update--> externalID
```

### 검증 규칙

- 항목 수는 Figma 예시의 5개로 제한하지 않는다.
- index와 `Default | 1 | ... | 5` enum을 공개하지 않는다.
- 목록에 없는 외부 ID는 어떤 카드도 선택하지 않은 표현으로 수렴하되 binding 원본을
  임의로 변경하지 않는다.

## 4. TabShell 선택 모델

### 필드

- `selection: Binding<Item>`
- `content`: 선택 항목에 대한 ViewBuilder content

### 검증 규칙

- `TabView`의 selection은 외부 binding과 직접 연결한다.
- `.constant` 또는 별도 내부 선택 상태를 사용하지 않는다.
- 항목의 title·image·ID 계약은 기존 `TabShellItem`이 소유한다.

## 5. LayoutContractScenario

### 값

- `catalog`: 기존 geometry 계약 전체
- `actionButton`: 상태·tap·disabled·destructive 장면
- `selectionCardList`: ID 선택·외부 변경·재정렬 장면

### 필드

- `launchArgument`: `--contract-scenario <value>`
- `visibleStateMarkers`: callback·Binding 결과를 화면에 표시하는 test-only View
- `selectors`: harness에만 존재하는 XCUI identifier

### 검증 규칙

- 알 수 없는 scenario는 `catalog`로 수렴한다.
- marker는 접근성 label/value가 아니라 실제 보이는 텍스트·색·geometry로 상태를 표현한다.
- selector를 production UIComponent 공개 계약에 추가하지 않는다.

## 6. FeatureReview target 경계

### 필드

- `targetName`: `FeatureReview`
- `sourceDirectory`: `sources/Projects/Feature/Review/`
- `product`: framework
- `dependencies`: SwiftUI system framework 외 프로젝트 target 의존 없음
- `schemeMembership`: 기존 `Feature` shared scheme의 Build Action
- `productAppDependencyCount`: `0`
- `existingFeatureDependencyCount`: `0`

### 검증 규칙

- App target과 기존 `Feature` target은 `FeatureReview`에 의존하지 않는다.
- 별도 shared scheme과 빈 test target을 만들지 않는다.
- UI 삭제 단계의 승인 전에는 target과 Feature source를 생성하지 않는다.
