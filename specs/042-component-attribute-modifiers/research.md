# 조사: UI 컴포넌트 초기화 계약 재구성

**명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

이 문서는 계획 단계의 기준선 실측과 설계 결정을 기록한다. 경로는 저장소 루트 기준이며, 컴포넌트
파일은 `sources/Projects/UI/Component/` 아래 상대경로로 줄여 적는다.

## 1. 기준선 실측

### 1.1 측정 방법

- 기준 commit: `fc9dcee`(기능 브랜치 분기 시점). 작업 트리의 무관한 변경은 측정에 영향을 주지 않는다.
- `sources/Projects/**/*.swift`에서 `Derived/`와 `Project.swift`를 뺀 모든 파일을 훑었다.
  `(?<![\w.])Name(<[^>\n]*>)?\s*(\(|\{)` 정규식에 괄호 균형 파서를 더해 인자를 읽었다.
  trailing closure 호출(`ScreenContainer {`)도 센다. 선언 줄, `-> Name {`·`: Name {`, 한정 호출
  (`SwiftUI.TextField(`)은 제외했다.
- 위치 구분: **F** = `Feature/**` 비테스트, **A** = `App/**`, **U** = `UI/**` 비테스트(컴포넌트
  본문과 `#Preview` 포함), **T** = 테스트 경로.
- 결과: App과 Composition에는 컴포넌트 호출부가 없다(App은 `UIComponent`를 import하지 않는다).
  테스트 호출부는 모두 `sources/Projects/UI/Tests/`에 있다. `Feature/Tests`에는 컴포넌트 생성
  호출이 없다. 다만 `HomeProjectCard.Variant`를 참조하는 Feature 테스트 1개가 있다(§1.4).

### 1.2 시각 속성 대상(FR-002 확정)

명세 FR-002 목록을 실측으로 확인했고, FR-001 기준에 맞는 누락 1건을 추가한다.

| 컴포넌트 | 속성 → 계약 종류 | 현재 기본값 | 명시 호출 / 전체 | 기본값과 같은 명시 |
| --- | --- | --- | --- | --- |
| `StyledText` | `style: TextStyleToken` → 텍스트 스타일 | 없음 | 170 / 170 | – |
| | `color: ColorToken` → 전경색 | `.grey100` | 96 / 170 | 5 |
| | `alignment: TextAlignment` → **계약 없음**(명확화: SwiftUI 수정자로 이관) | `.leading` | 55 / 170, 모두 `.center` | 0 |
| `ActionButton` | `style` → 스타일, `size` → 크기 | `.primary`, `.large` | 10·4 / 17 | 1·0 |
| `TagBadge` | `style` → 스타일, `size` → 크기 | `.neutral`, `.regular` | 9·3 / 12 | 1·0 |
| `IconGlassButton` | `style` → 스타일, `size` → 크기 | `.neutral`, `.small` | 4·16 / 21 | 0·1 |
| `LabeledCard` | `style` → 스타일 | 없음 | 10 / 10 | – |
| `IconPlainButton` | `tintColor` → 전경색, `backgroundColor` → 배경색 | `.white`, `.clear` | 1·1 / 4 | 0·0 |
| `LabeledProgressBar` | `valueColor` → 전경색 | `.grey400` | 1 / 2 | 0 |
| `SelectionCard` | `style: SelectionCardStyle` → 스타일 | `.detailed` | 1 / 6 | 0 |
| `SelectionCardList` | `style: SelectionCardStyle` → 스타일 | `.detailed` | 2 / 8 | 0 |
| `HomeProjectCard` | `variant: Variant` → 스타일 | 없음 | 6 / 6 | – |
| `ScreenContainer` | `background` → 배경색 | `.grey700` | 1 / 36 | 0 |
| `OverlayContainer` | `screenBackground` → 배경색(`Background == EmptyView` 생성 경로) | `.grey700` | 1 / 19 | 0 |
| **`ContinuousProgressBar`(추가)** | `height: Height` → 크기 | `.row` | 실측 대상 6곳 중 명시 호출 수는 전환 시 재확인 | – |

- **추가 근거**: `ContinuousProgressBar.Height`는 UI 패키지가 정의한 enum이다. 표시 내용·상태·동작은
  바꾸지 않고 막대 높이만 정하므로 FR-001의 시각 속성이다. 역할은 크기다.
- **제외 1 — `ActionMenu.Item.role`**: 색으로만 표현되지만 `normal`·`destructive`라는 **동작의
  의미**다. 접근성 의미와 호출부 판단(파괴적 작업 여부)을 함께 전달하므로 시각 속성이 아니다.
  초기화 인자로 유지한다.
- **제외 2 — `IconPlainButton.iconSize`·`size`**: `CGFloat` 수치라 명세 FR-003에 따라 제외한다.
- **Feature 래퍼 `FeedbackActionButton`**(`Feature/Shared/Views/FeedbackActionButton.swift`):
  `ActionButton`의 두 생성 경로와 `style`·`size` 기본값을 그대로 복제한 공개 Feature View다. 호출부는
  31곳이고, `style: .primary`처럼 기본값과 같은 값을 명시한 곳이 19곳이다. UIComponent가 아니므로
  FR-002 대상은 아니다. 다만 안쪽 `ActionButton`의 초기화 인자가 사라지면 래퍼가 값을 넘길 경로가
  없어진다. 그래서 같은 스타일·크기 계약을 채택해 `ActionButton`과 같은 선언 방식을 제공한다(§4.4).

### 1.3 표시 값 모델 대상(FR-015 확정)

명확화의 분류 기준(표시 값 = 화면에 보이는 내용, 진행률·수치 포함, `isRequired` 포함,
`accessibilityLabel`·식별자 제외)으로 판정했다. 괄호 안은 모델로 옮기는 필드다.

| 역할 폴더 | 컴포넌트·중첩 값 타입 | 표시 값 | 호출부(F/U/T) |
| --- | --- | --- | --- |
| CollectionItems | `ChoiceResultRow` | `text`, `explanation` | 0/2/3 |
| | `HomeProjectCard` | `title`, `technologies`, `progress`, `currentSetLabel`, `setTitle` | 1/3/2 |
| | `LearningSetRow` | `label`, `title`, `questionCount`, `completedCount` | 1/2/1 |
| | `ProjectRow` | `name`, `supportingText`, `progress`, `currentSet`, `setTitle` | 1/2/0 |
| | `SavedQuestionCard` | `metadata`, `prompt`, `actionTitle` | 1/2/0 |
| | `SelectionCard`(두 생성 경로) | `title`, `supportingText`, `badgeText` | 0/6/0 |
| Controls | `ChoiceAnswerOption` | `letter`, `text` | 1/4/1 |
| | `LabeledTextField` | `label`, `placeholder`, `supportingText` | 1/3/0 |
| | `PolicyAgreementRow` | `title`, `isRequired` | 1/3/2 |
| | `ScreenControlBar` | `leading`, `trailing`(`Control?`) | 14/3/2 |
| | `TextField` | `placeholder`, `errorMessage` | 0/3/3 |
| | `SelectionCardList.Item` | `title`, `supportingText`, `illust` | 5/3/8 |
| Displays | `LabeledCard` | `label`, `text` | 3/4/3 |
| | `RubricView` | `criteria`, `overallFeedback` | 0/1/0 |
| | `ScreenHeaderTitle` | `title`, `subtitle` | 10/3/0 |
| Indicators | `EmptyState` | `title`, `message` | 3/1/0 |
| | `LabeledProgressBar` | `label`, `progress`, `valueText` | 1/1/0 |
| | `PageIndicator` | `currentPage`, `totalPages` | 1/3/1 |
| | `ProgressSegments` | `completed`, `total` | 0/4/0 |
| Overlays | `ConfirmationSheet` | `imageURL`, `title`, `message`, `confirmTitle`, `cancelTitle` | 2/1/0 |
| | `WebSheet` | `title`, `url` | 2/1/0 |

표시 값이 1개 이하라 모델 대상이 아닌 공개 타입은 다음과 같다.
- 표시 값 1개: `ActionButton`, `Chip`, `IconGlassButton`, `IconPlainButton`, `SelectableSettingRow`,
  `SelectionCardList`, `SettingRow`, `OnboardingMockup`, `ResourceAnimation`, `ResourceImage`,
  `StyledText`, `TagBadge`, `WebContentView`, `ContinuousProgressBar`, `ActionMenu`, `ActionMenu.Item`,
  `ScreenControlBar.Control`
- 표시 값 0개: `AppleSignInButton`, `BookmarkButton`, `LaunchLogo`, `SplashView`, `ModalOverlay`,
  `PushedScreenOverlay`, `ScreenEdgeScrim`, `SheetSurface`, `BottomActionBar`, `FlowNavigationStack`,
  `OverlayContainer`, `ScreenContainer`, `TabShell`

`ActionMenu.Item`의 `id`와 `SelectionCardList.Item`의 `id`는 식별자라서 세지 않는다.
`ScreenControlBar.Control`의 `label`은 접근성 문구라서 세지 않는다.

**판정 주의**: `PageIndicator.currentPage`와 `ProgressSegments.completed`는 화면 진행에 따라
바뀌지만 컴포넌트가 소유하거나 상호작용으로 바꾸지 않는다. 명확화 기준의 "진행률·수치"에 해당하므로
표시 값이다. `ScreenControlBar`의 `leading`·`trailing`은 아이콘으로 보이는 제어 항목이므로 표시
값이다. 호출부 14곳 중 대부분은 `leading`만 명시한다.

### 1.4 컴포넌트 안에서 다른 컴포넌트를 만드는 곳

전환할 때 안쪽 호출도 함께 바꿔야 하는 곳이다(명세 예외·경계 사례의 전달 규칙).

- `SelectionCardList` → `SelectionCard` ×2: 부모 스타일을 자식에 전달한다.
- `ConfirmationSheet` → `SheetSurface`, `ActionButton` ×2(`.destructive`, `.text`), `StyledText` ×2
- `WebSheet` → `SheetSurface`, `IconGlassButton`, `WebContentView`, `StyledText`
- `ProjectRow` → `ContinuousProgressBar`, `TagBadge`(`.muted`·`.compact`), `IconGlassButton`
  (`.destructive`·`.medium`), `IconPlainButton`, `StyledText` ×3
- `ScreenControlBar` → `IconGlassButton` ×2(`size: .medium`)
- `LabeledProgressBar` → `ContinuousProgressBar`(`.detail`), `StyledText` ×2
- `LearningSetRow` → `ProgressSegments`, `StyledText` ×2
- `SelectionCard` → `TagBadge`(`.selected`), `StyledText` ×2
- `HomeProjectCard` → `StyledText` ×4
- `StyledText`를 1~3회 쓰는 컴포넌트: `ActionMenu`, `AppleSignInButton`, `Chip`,
  `SelectableSettingRow`, `TextField`, `PolicyAgreementRow`, `SettingRow`, `ChoiceAnswerOption`,
  `ChoiceResultRow`, `EmptyState`, `LabeledCard`, `LabeledTextField`, `RubricView`,
  `ScreenHeaderTitle`, `SavedQuestionCard`
- Feature 참조: `Feature/Home/ViewModels/HomeProjectDisplay.swift`와 그 테스트
  `Feature/Tests/Home/Home/ViewModels/HomeProjectDisplayTests.swift`가 `HomeProjectCard.Variant`를
  참조한다. `HomeProjectDisplay`는 `HomeProjectSectionState`를 거쳐 Feature State에 담긴다.

### 1.5 기존 테스트

- `UIComponentTests`(`sources/Projects/UI/Tests/Component/Unit/**`) 21개 파일과 `DesignSystemTests`
  2개 파일이 있다. 모두 Swift Testing과 `@testable import`를 쓴다.
- 기존 테스트가 쓰는 검증 방식은 둘이다. 하나는 `Style`·`Size`의 토큰 대응 단언이고, 다른 하나는
  `Mirror`로 `_` 접두 저장 프로퍼티(상태 보관)가 없음을 확인하는 단언이다.
- 초기화 인자가 바뀌면 T 열의 호출부를 함께 고친다. 토큰 대응 단언은 그대로 둔다(FR-013).

## 2. 계약 구현 방식

- **결정**: 시각 속성 종류마다 `View`를 정제하는 공개 프로토콜을 하나씩 두고, 요구사항은
  `Self`를 반환하는 메서드 하나다. 각 컴포넌트는 시각 속성을 `private var` 저장 프로퍼티(기본값
  포함)로 두고, 메서드를 `var copy = self; copy.<속성> = 값; return copy`로 직접 구현한다.
  스타일·크기 계약은 컴포넌트마다 다른 타입을 받도록 `associatedtype`을 가진다. 토큰형 계약(텍스트
  스타일·전경색·배경색)은 DesignSystem 토큰 타입을 고정으로 받는다.
- **근거**:
  - 메서드 요구사항만 두면 공개 표면에 쓰기 가능한 프로퍼티가 생기지 않는다. 그래서 FR-008의
    "두 번째 선언 경로 없음"을 지킨다.
  - 반환 타입이 `Self`라서 여러 속성을 이어 붙일 수 있다(FR-006). 일반 수정자 뒤에서는 호출할 수
    없어 컴파일 오류가 난다(명세 예외·경계 사례).
  - 받지 않는 속성 종류의 메서드는 존재하지 않으므로 컴파일 오류가 난다(FR-011).
  - 저장 프로퍼티 `style`과 메서드 `style(_:)`를 한 타입에 두는 형태를 iOS 26 simulator SDK·Swift 6
    `swiftc -typecheck`로 확인했다. 모호성 오류 없이 통과했다. 프로퍼티 이름은 역할 이름을 그대로 쓴다.
  - 프로토콜이 `View`를 정제하므로 메서드는 `View`와 같은 main actor 격리를 따른다. 호출부는 모두
    View 문맥이라 영향이 없다.
- **검토한 대안**:
  - 요구사항을 `var style: Style { get set }`으로 두고 기본 구현으로 메서드를 제공하는 방식.
    공개 프로토콜의 요구사항은 공개 setter를 강제한다. 그러면 `component.style = ...`라는 두 번째
    경로가 생겨 FR-008을 위반하므로 기각했다.
  - `WritableKeyPath`를 정적 요구사항으로 노출하는 방식. 공개 key path로 외부에서 쓸 수 있으므로
    같은 이유로 기각했다.
  - Environment 값이나 `ViewModifier`로 전달하는 방식. 반환 타입이 컴포넌트가 아니어서 속성을
    받지 않는 컴포넌트에도 호출이 허용된다. 그러면 런타임에 무시되어 FR-011을 위반하므로 기각했다.

## 3. 계약과 메서드 이름

| 계약(프로토콜) | 메서드 | 받는 값 | 채택 컴포넌트 |
| --- | --- | --- | --- |
| `StyleConfigurable` | `style(_:)` | `associatedtype Style` | `ActionButton`, `TagBadge`, `IconGlassButton`, `LabeledCard`, `SelectionCard`, `SelectionCardList`, `HomeProjectCard`, `FeedbackActionButton`(Feature) |
| `SizeConfigurable` | `size(_:)` | `associatedtype Size` | `ActionButton`, `TagBadge`, `IconGlassButton`, `ContinuousProgressBar`, `FeedbackActionButton`(Feature) |
| `TextStyleConfigurable` | `textStyle(_:)` | `TextStyleToken` | `StyledText` |
| `ForegroundColorConfigurable` | `foregroundColorToken(_:)` | `ColorToken` | `StyledText`, `IconPlainButton`, `LabeledProgressBar` |
| `BackgroundColorConfigurable` | `backgroundColorToken(_:)` | `ColorToken` | `IconPlainButton`, `ScreenContainer`, `OverlayContainer` |

- **이름 근거**:
  - 계약 이름은 채택 컴포넌트가 제공하는 능력("이 속성을 설정할 수 있다")을 표현한다
    ([naming/protocol-contract.md](../../docs/conventions/naming/protocol-contract.md)).
  - 메서드 이름은 SwiftUI `Text.font(_:)`처럼 속성 이름 자체를 쓴다.
- **FR-010(SwiftUI 수정자와의 충돌) 판정**:
  - SwiftUI `View`에는 `style`, `size`, `textStyle` 인스턴스 메서드가 없다. 비슷한 것은 접두어가
    붙은 `buttonStyle`, `controlSize` 같은 이름뿐이다.
  - `foregroundColor(_:)`는 SwiftUI `View`·`Text`에 있다. 그래서 전경색 메서드는 기본 이름이 겹치지
    않도록 `foregroundColorToken(_:)`으로 정했다.
  - `background(_:)`·`backgroundStyle(_:)`과 구분하기 위해 배경색 메서드도 `backgroundColorToken(_:)`으로
    짝을 맞췄다.
  - DesignSystem의 `designSystemForeground(_:)`·`designSystemBackground(_:)`와도 이름이 다르다.
- **검토한 대안**:
  - `color(_:)`: `StyledText`에는 자연스럽다. 하지만 `IconPlainButton`에서는 틴트인지 배경인지
    드러나지 않아 역할별 두 계약(명확화)과 맞지 않으므로 기각했다.
  - `foregroundColor(token:)`: 인자 이름으로는 구분되지만 기본 이름이 SwiftUI의 deprecated 수정자와
    같다. 자동 완성과 읽기에서 혼동되므로 기각했다.
  - `HomeProjectCard`에 `variant(_:)`를 두는 방안: 명확화에서 스타일 계약에 합치기로 했으므로
    기각했다.

## 4. 기본값과 개별 결정

### 4.1 기본값이 없던 속성(FR-007)

명확화 기준은 "디자인 시스템의 중립·기본 값"이며 호출부 최빈값은 기준이 아니다.

| 속성 | 기본값 | 근거 |
| --- | --- | --- |
| `StyledText` 텍스트 스타일 | `.body1` | 본문 계열(`body1` 16pt, `body2` 14pt, `body3` 12pt)의 기준 단계다. `ActionButton`의 제목도 `.body1`로 그린다. 최빈값 `.body2`(46곳)는 기준이 아니다 |
| `LabeledCard` 스타일 | `.neutral` | 두 케이스 중 강조가 없는 중립 케이스다. 선언 순서상 첫 케이스는 `.accent`지만 "중립" 기준을 우선한다 |
| `HomeProjectCard` 스타일 | `.purple` | `init(index:)`가 인덱스 0에 부여하는 케이스이자 선언 순서상 첫 케이스다 |

기존 기본값(`ActionButton` `.primary`·`.large` 등)은 그대로 둔다. 전환할 때 기본값과 같은 값을 명시한
호출부는 메서드를 생략한다(FR-009). 해당하는 곳은 `StyledText` 전경색 `.grey100` 5곳,
`ActionButton.style` 1곳, `TagBadge.style` 1곳, `IconGlassButton.size` 1곳, `FeedbackActionButton.style`
19곳과 `size` 1곳이다. 새 기본값 `.body1`과 같은 `StyledText` 20곳, `LabeledCard` `.neutral` 5곳,
`HomeProjectCard` `.purple` 3곳도 생략할 수 있다.

### 4.2 `StyledText` 정렬

명확화대로 `alignment` 저장 프로퍼티와 초기화 인자를 없앤다. 이를 명시했던 55곳은 모두 `.center`다.
이 호출부는 `.multilineTextAlignment(.center)`를 붙여 같은 값을 선언한다.

`.leading`을 명시한 호출부는 0곳이다. 그래서 전환 전에 정렬 값을 넘기지 않던 호출부(115곳)만 검토
대상이다. 이 호출부는 전환 뒤 상위 View의 `multilineTextAlignment` 환경값을 받게 된다. 상위에
`.multilineTextAlignment`가 걸린 컨테이너 안의 `StyledText`는 렌더링이 달라질 수 있으므로 U1에서
전수 조회한다. 해당 호출부에는 `.multilineTextAlignment(.leading)`을 명시해 전환 전과 같게 둔다.

### 4.3 `HomeProjectCard.Variant` → `Style` 이름 변경

스타일 계약의 `associatedtype Style`은 `Variant`로도 추론된다. 그래도 [view-declarations/style.md]
(../../docs/conventions/view-declarations/style.md)의 "시각 변형 enum은 `Style`" 어휘와 FR-002의
"스타일(현재 `Variant`)"에 맞춰 `HomeProjectCard.Style`로 이름을 바꾼다.

[naming/rename.md](../../docs/conventions/naming/rename.md)에 따라 순수 이름 변경을 설계 변경과 다른
단위(U4)로 분리한다. 영향 파일은 다음과 같다.
- `HomeProjectCard.swift`
- `Feature/Home/ViewModels/HomeProjectDisplay.swift`
- `Feature/Tests/Home/Home/ViewModels/HomeProjectDisplayTests.swift`
- `UI/Tests/Component/Unit/CollectionItems/HomeProjectCardTests.swift`

### 4.4 `FeedbackActionButton`

Feature 공개 View지만 `ActionButton` 계약을 그대로 감싼다. 그래서 `StyleConfigurable`·`SizeConfigurable`을
채택한다. `associatedtype`은 `ActionButton.Style`·`ActionButton.Size`로 둔다.

초기화 인자에서 `style`·`size`를 없애고, 저장한 값을 `body`에서 안쪽 `ActionButton`에 메서드로
전달한다. 이렇게 하면 Feature 호출부 31곳도 UI 컴포넌트와 같은 선언 방식이 된다.

이 결정은 새 규칙을 Feature View에 넓히는 것이 아니다. 래퍼가 감싼 컴포넌트의 공개 계약을 그대로
따르게 하는 것이다. 컨벤션 문서 개정 범위는 UIComponent로 유지한다.

### 4.5 `OverlayContainer`의 생성 경로

배경 View를 받는 기본 생성 경로와 `Background == EmptyView`일 때 `screenBackground: ColorToken`을 받는
생성 경로가 있다. 배경색 계약은 `EmptyView` 조건부 확장에서만 채택할 수 없다. 그래서 채택 형태를
다음처럼 정한다.
- 저장 프로퍼티 `screenBackground`는 두 경로 모두의 기본값(`.grey700`)을 갖는다.
- `backgroundColorToken(_:)`은 타입 전체에서 제공한다.
- 두 번째 생성 경로에서는 `screenBackground` 인자만 제거한다.

현재 구현을 대조한 결과, 배경 View를 받는 기본 경로도 비공개 공통 초기화 메서드에
`screenBackground: .grey700`을 넘긴다. 그래서 두 경로 모두 `body`의
`.background(Color(designSystem: screenBackground))`로 같은 화면 배경을 그린다. 전환 뒤에는
비공개 공통 초기화 메서드에서도 `screenBackground` 인자를 없애고 저장 프로퍼티 기본값으로 대신한다.
그래서 렌더링은 바뀌지 않는다.

### 4.6 `SelectionCard`의 경로별 기본 스타일

`SelectionCard`의 두 생성 경로는 스타일 기본값이 다르다.
- 썸네일 경로의 기본값은 `.detailed`다.
- `Thumbnail == EmptyView` 경로는 스타일 인자가 없고, 안에서 `.compact`로 고정한다.

`SelectionCardList`는 `style.showsThumbnail`에 따라 경로를 고른다. 그래서 목록 스타일 `.compact`는
EmptyView 경로의 `.compact`로 그려진다.

전환 뒤 이 동작을 다음처럼 유지한다.
- 저장 프로퍼티 기본값은 `.detailed`로 둔다.
- EmptyView 경로의 초기화 메서드가 저장 프로퍼티를 `.compact`로 설정한다. 이는 인자가 아니라 경로의
  고정값이라 FR-008의 두 번째 선언 경로가 아니다.
- 두 경로 모두 `style(_:)`로 바꿀 수 있다. `SelectionCardList`의 썸네일 경로는 `.style(style)`로 부모
  스타일을 전달한다.

## 5. 표시 값 모델 설계

- **결정**: 모델 대상 타입마다 공개 중첩 타입 `DisplayModel`을 둔다.
  - `public struct DisplayModel: Sendable, Equatable`이며, 필드는 §1.3의 표시 값이다.
  - 명시적 `public init`을 두고 기존 초기화 인자의 기본값(`supportingText: String? = nil` 등)을
    그대로 옮긴다.
  - 컴포넌트 초기화 메서드는 첫 인자로 `displayModel: DisplayModel`을 받는다. 상태·동작 설정·
    접근성 문구·`Binding`·콜백·자식 View는 그 뒤에 개별 인자로 남는다.
  - `DisplayModel`은 소유 컴포넌트 파일 안의 `extension {컴포넌트}`에 둔다.
- **이름 근거**:
  - 명세 용어 "표시 값 모델"을 그대로 옮겼다. 소유 컴포넌트 이름이 문맥을 주므로 컴포넌트 이름을
    반복하지 않는다([view-declarations/internal-declarations.md](../../docs/conventions/view-declarations/internal-declarations.md)).
  - `Content`는 기각했다. 자식 View 제네릭 파라미터(`SettingRow<Content>`, `ModalOverlay<Content>`)의
    관례 이름과 충돌한다.
  - `Model`은 기각했다. 무엇의 모델인지 드러나지 않는다.
  - `Presentation`은 기각했다. Overlay 컴포넌트에서 sheet presentation과 혼동된다.
- **위치 근거**: [view/access-level.md](../../docs/conventions/view/access-level.md)는 "공개 계약에
  필요한 비상태 보조 타입"을 `public`으로 허용한다. [view-declarations/internal-declarations.md]
  (../../docs/conventions/view-declarations/internal-declarations.md)는 View가 소유한 선언을 같은
  파일에 둔다. [file-vocabulary/one-type-per-file.md](../../docs/conventions/file-vocabulary/one-type-per-file.md)는
  최상위 타입만 세므로 위반이 아니다. 기존 `+Item.swift`·`+Control.swift` 분할 선례는 따르지 않는다.
  모델은 컴포넌트의 입력 계약이라 컴포넌트와 함께 읽혀야 하기 때문이다.
- **`SelectionCardList.Item`**: `Item(id:displayModel:isSelected:)`로 바꾸고,
  `SelectionCardList.Item.DisplayModel`은 `+Item.swift` 파일 안에 둔다. 필드는 `title`,
  `supportingText`, `illust`다. `SelectionCard.DisplayModel`(`title`, `supportingText`, `badgeText`)과
  필드가 달라 재사용하지 않는다.
- **`SelectionCard`의 두 생성 경로**: 썸네일이 있는 경로와 `Thumbnail == EmptyView` 경로 모두
  `displayModel:`을 받는다. `SelectionCardList`는 `Item.DisplayModel`에서 `SelectionCard.DisplayModel`을
  만들어 넘긴다.
- **Feature 매핑**(명확화): Feature View가 컴포넌트 호출 지점에서 모델을 만든다. 예를 들어
  `HomeScreen+ProjectSection.swift`가 `HomeProjectDisplay`에서 `HomeProjectCard.DisplayModel`을 만든다.
  Feature State·Reducer와 State에 담기는 `ViewModels/` 타입(`HomeProjectDisplay`,
  `HomeProjectSectionState`)은 `DisplayModel`을 보유하지 않는다.

## 6. 계약 프로토콜의 위치와 추상화 컨벤션

- **결정**: 다섯 계약을 `sources/Projects/UI/Component/Contracts/`에 파일 하나씩 둔다.
- **근거**:
  - 계약은 특정 역할 폴더의 컴포넌트가 아니라 여러 역할 폴더가 함께 채택하는 선언이다.
  - `Contracts/`는 형태 어휘 표에 이미 있는 이름이다(Domain·Data의 "계약 프로토콜"). 새 어휘를
    만들지 않는다.
  - 다만 현재 [ui-component/folder-file.md](../../docs/conventions/ui-component/folder-file.md)는
    `UI/Component/` 1뎁스를 역할 폴더와 `Resources/`로 한정한다. 그래서
    [file-vocabulary/shape-vocabulary.md](../../docs/conventions/file-vocabulary/shape-vocabulary.md)의
    `UI/Component/` 행과 함께 같은 PR에서 갱신한다(FR-016, [shape-rules.md](../../docs/conventions/directory-file/shape-rules.md)).
- **추상화 컨벤션 판정**:
  - [abstraction/protocol-criteria.md](../../docs/conventions/abstraction/protocol-criteria.md)의 근거 A
    (패키지 경계 역전)와 B(프로덕션 구현 교체)에는 해당하지 않는다.
  - 스타일·크기 계약은 `associatedtype`을 가진다. 하지만 제네릭 제약으로 쓰는 곳이 없어 §1의 적용
    제외("제네릭 제약을 표현하기 위한 프로토콜")에도 온전히 들어가지 않는다.
  - 명세 FR-004가 요구하는 "공개 API 형태를 통일하는 계약"이므로, 명세 FR-016에 따라 추상화
    컨벤션을 개정한다. [abstraction.md](../../docs/conventions/abstraction.md) §1의 적용 제외에 "여러
    컴포넌트가 같은 이름·형태의 공개 메서드를 제공하도록 강제하는 UI 시각 속성 계약"을 추가한다.
  - [abstraction/structure-baseline.md](../../docs/conventions/abstraction/structure-baseline.md)의
    수치와 목록(§3.2 제네릭 제약 옆의 새 분류)을 갱신한다.
- **검토한 대안**:
  - DesignSystem `Extensions/`에 두는 방안은 기각했다. DesignSystem은 토큰과 토큰 적용 API를
    소유하며, 컴포넌트 선언 계약은 UIComponent의 공개 계약이다([package-rules/ui.md](../../docs/package-rules/ui.md)).
  - 역할 폴더 중 하나에 두는 방안도 기각했다. 여러 역할이 채택하므로 특정 역할의 소유로 볼 수 없다.

## 7. 문서 개정 범위 전수 조회(FR-016 보완)

명세 FR-016 목록에 없던 문서 중 명세 규칙과 어긋나거나 이를 전제하는 문서를 찾았다. 다음을 추가로
개정한다.

| 문서 | 어긋나는 서술 | 개정 내용 |
| --- | --- | --- |
| [docs/conventions/view-declarations/binding.md](../../docs/conventions/view-declarations/binding.md) | "별도 상태 wrapper에 외부 값을 복제하지 않습니다" | 명확화(wrapper 금지 문장 삭제)에 따라 삭제한다. `Binding` 보존 규칙은 유지한다 |
| [docs/conventions/view/preview.md](../../docs/conventions/view/preview.md) | 변경 없음(모든 시각 변형 나열 규칙 유지) | 컴포넌트 프리뷰가 시각 속성 메서드로 변형을 나열한다는 예시만 보강한다 |
| [docs/conventions/ui-component/folder-file.md](../../docs/conventions/ui-component/folder-file.md) | 1뎁스는 역할 폴더와 `Resources/`뿐 | `Contracts/`를 추가한다 |
| [docs/conventions/file-vocabulary/shape-vocabulary.md](../../docs/conventions/file-vocabulary/shape-vocabulary.md) | `UI/Component/` 행에 `Contracts/` 없음 | 행을 추가한다 |
| [docs/conventions/abstraction.md](../../docs/conventions/abstraction.md) | 적용 제외에 API 형태 계약이 없음 | §6 판정대로 추가한다 |
| [docs/conventions/abstraction/structure-baseline.md](../../docs/conventions/abstraction/structure-baseline.md) | 프로토콜 수와 목록 | 수치를 다시 재고 계약 5개를 새 분류로 등재한다 |
| [docs/conventions/view-declarations/internal-declarations.md](../../docs/conventions/view-declarations/internal-declarations.md) | "표시 값과 `Binding`은 별도 타입으로 감싸지 않고 컴포넌트 저장 프로퍼티에 직접 둡니다" | 표시 값 모델(`DisplayModel`) 규칙으로 바꾸고 선언 표에 `DisplayModel` 행을 추가한다 |

명세 FR-016이 이미 나열한 문서(`component-init.md`, `display-value-binding-callback.md`, `view.md`,
`package-rules/ui.md`, `public-contract.md`, `view-declarations.md`, `view-declarations/style.md`,
`package-rules/feature.md`, `component-index.md`)는 그대로 개정 대상이다.

조회했지만 개정하지 않는 문서는 다음과 같다.
- [docs/conventions/view/screen-init.md](../../docs/conventions/view/screen-init.md): 화면의 생성 경로만
  다룬다.
- [docs/conventions/test.md](../../docs/conventions/test.md): 프레임워크·이름 규칙에 변화가 없다.
- [docs/architecture.md](../../docs/architecture.md): 의존 방향에 변화가 없다.

## 8. 검증 방식

- **SC-007(계약 단위 테스트)**: 계약마다 채택 컴포넌트 하나 이상을 대상으로 `Mirror`로 저장
  프로퍼티를 읽는다. 메서드가 그 속성만 바꾸고 표시 값·다른 시각 속성은 유지하는지 단언한다. 기본값과
  마지막 선언 우선(FR-006)도 같은 파일에서 검증한다. 위치는
  `sources/Projects/UI/Tests/Component/Unit/Contracts/`다(production 형태 폴더 미러링,
  [test/test-folder-target.md](../../docs/conventions/test/test-folder-target.md)).
- **SC-001·SC-008(초기화 인자 형태)**: [quickstart.md](./quickstart.md)의 조회 명령으로 두 가지를
  확인한다. 대상 컴포넌트의 `public init`에 시각 속성 인자와 개별 표시 값 인자가 없는지, Feature
  State·Reducer 파일에 `DisplayModel` 참조가 없는지다.
- **SC-004(렌더링 동일성)**: 자동 스냅샷 도구가 없다(명세 가정). 호출부 diff 리뷰에서 전환 전후 값
  대응표(§1.2 명시 호출)를 대조하고, 대상 컴포넌트와 사용 화면의 프리뷰를 확인한다.
- **SC-003**: 단위마다 `compile`, 테스트를 고친 단위는 `test`까지 실행한다. 마지막 단위에서
  `build`·`compile`·`test`를 모두 실행한다.

## 9. 상태 `Binding` 전환(FR-017, 명확화 2026-09-21 추가)

### 9.1 대상 실측

- 측정 기준: U1 commit `b4b1a79` 이후 작업 트리. UIComponent의 모든 `public init`에서 `Bool` 상태 인자와
  `on…` 콜백 인자를 추출했다. 그다음 컴포넌트 본문이 그 콜백을 어떤 사용자 상호작용에 연결하는지
  대조했다.
- 판정 기준(명세 FR-017): 컴포넌트가 상호작용으로 스스로 바꾸는 상태이고, 그 상태를 바꾸는 용도의
  콜백과 짝을 이룬다.

| 컴포넌트·타입 | 현재 | 전환 후 | 쓰기 시점과 값 | 호출부(F/U/T) |
| --- | --- | --- | --- | --- |
| `Chip` | `isSelected: Bool`, `onTap` | `isSelected: Binding<Bool>` | 탭 → `toggle()` | 2/3/3 |
| `SelectableSettingRow` | `isSelected: Bool = false`, `onTap` | `isSelected: Binding<Bool>` | 탭 → `toggle()` | 0/2/0 |
| `PolicyAgreementRow` | `isSelected: Bool = false`, `onToggle` | `isSelected: Binding<Bool>`(`onOpenLink` 유지) | 체크 영역 탭 → `toggle()` | 1/3/2 |
| `ChoiceResultRow` | `isExpanded: Bool`, `onTap` | `isExpanded: Binding<Bool>` | 행 탭 → `toggle()` | 0/2/3 |
| `SavedQuestionCard` | `isBookmarked: Bool = true`, `onBookmarkTap` | `isBookmarked: Binding<Bool>`(`onActionTap` 유지) | 북마크 탭 → `toggle()` | 1/2/0 |
| `BookmarkButton` | `isSaved: Bool`, `onTap` | `isSaved: Binding<Bool>` | 탭 → `toggle()` | 1/2/3 |
| `ModalOverlay` | `isPresented: Bool`, `onDismiss = { }` | `isPresented: Binding<Bool>` | scrim 탭 → `false` | 7/2/0 |
| `SelectionCardList` | `Item.isSelected: Bool = false`, `onSelect: (String) -> Void` | `selection: Binding<String?>` | 카드 탭 → 그 항목 `id` | 5/1/2 |
| `ChoiceAnswerOption.ExpansionControl` | `toggleable(isExpanded: Bool, onToggleExpand:)` | `toggleable(isExpanded: Binding<Bool>)` | 펼침 버튼·접근성 동작 → `toggle()` | 1/2/0 |

- **값으로 남는 상태**: `isEnabled`(`ActionButton`), `isDeleting`(`ProjectRow`), `isLearningEnabled`
  (`HomeProjectCard`), `isError`(`LabeledTextField`), `judgement`(`ChoiceResultRow`), `state`·`onTap`
  (`ChoiceAnswerOption`), `isSelected`(`SelectionCard`), `isPresented`(`PushedScreenOverlay`)는 컴포넌트가
  바꾸지 않는다. 그래서 값 인자로 둔다(명확화).
- **동작 설정으로 남는 값**: `isSecure`(`TextField`), `isLooping`(`ResourceAnimation`), `isScrollable`
  (`SheetSurface`), `isRequired`(`PolicyAgreementRow`, 표시 값)는 상태가 아니다.
- **남는 콜백**: `WebSheet.onDismiss`는 짝이 되는 표시 상태 인자가 없다. 표시 여부는 부모가
  `ModalOverlay`의 `Binding`으로 정한다. 그래서 그대로 둔다. `ConfirmationSheet`의 `onConfirmTap`·
  `onCancelTap`, `SavedQuestionCard.onActionTap`, `PolicyAgreementRow.onOpenLink`,
  `HomeProjectCard.onSelect`·`onStart`, `ProjectRow.onAccessoryTap`은 상태 변경 용도가 아닌 동작
  콜백이다.
- **선례**: `TabShell(selected: Binding<Item>)`, `TextField(text: Binding<String>)`는 이미 기본값 없는
  `@Binding private var`로 저장한다.

### 9.2 컴포넌트 쪽 결정

- **결정**: 상태 `Binding`은 기본값 없는 필수 초기화 인자로 받는다. `_isSelected = isSelected`처럼
  `@Binding private var`에 저장한다. 상호작용에서 `wrappedValue`를 쓰며, 쓰는 값은 §9.1 표와 같다.
- **근거**:
  - [view-declarations/binding.md](../../docs/conventions/view-declarations/binding.md)가 외부 상태를
    `@State`로 복제하지 않고 `Binding`의 `.constant` 기본값을 금지한다. 선례 `TabShell`·`TextField`와
    같은 저장 방식이다.
  - Bool 상태는 `toggle()`로 쓴다. 전환 전 콜백은 값 없이 "탭됨"만 알렸다. Feature setter가 새 값을
    쓰지 않고 기존 View Action을 보내므로(§9.3), 쓰는 값이 달라도 Feature 동작은 같다.
  - `ModalOverlay`는 scrim 탭이 닫기 하나뿐이라 `false`만 쓴다.
- **검토한 대안**:
  - 선택형 컴포넌트(`Chip`, `SelectableSettingRow`)에서 `true`만 쓰는 방식. 이미 선택된 항목을 다시
    탭해도 setter가 호출되지 않을 수 있다. 전환 전에는 매번 `onTap`이 불렸으므로 기각했다.
  - `Binding` 기본값 `.constant(false)`. 명세 명확화와 binding.md가 금지하므로 기각했다.

### 9.3 Feature 쪽 결정

- **결정**: 화면 View(또는 SubViews)의 호출 지점이나 `private var …Binding: Binding<…>` 계산
  프로퍼티에서 `Binding(get:set:)`을 만든다.
  - getter는 전환 전 값 인자에 넘기던 식을 그대로 쓴다.
  - setter는 제거된 콜백이 보내던 View Action을 그대로 보낸다.
  - 예: `BookmarkButton`은 `set: { _ in send(.bookmarkToggleTapped) }`, `ModalOverlay`는
    `set: { isPresented in if !isPresented { send(.deletionCancelled) } }`,
    `SelectionCardList`는 `set: { identifier in … send(.levelSelected(level)) }`.
- **근거**:
  - 명세 명확화가 `BindableAction`·`BindingReducer` 도입을 기각했다.
  - [tca/action/binding.md](../../docs/conventions/tca/action/binding.md)는 서버 정본을 바꾸는 작업
    (북마크 등)을 binding setter에서 실행하지 않는다. 대신 명시적 View Action을 거치게 한다. setter가
    기존 View Action을 보내므로 이 규칙을 지킨다.
  - 선례 `MainShellRouter.selectedTab`, `QuestionSolvingScreen.essayTextBinding`과 같은 형태다.
  - Action·Reducer·Reducer 테스트가 바뀌지 않는다(명세 FR-015·FR-017).
- **호출 지점 규칙**: 전환 전 콜백이 없던 호출부(기본값 `{ }`에 기대던 곳)는 setter가 아무 Action도
  보내지 않는다. 대상은 `ModalOverlay`의 `onDismiss` 생략 호출부다. 전환 전과 같이 scrim 탭이 아무
  일도 하지 않는다.
- **Feature `ViewModels/`·State**: `Binding`을 보유하지 않는다. View에서만 만든다(SC-008과 같은 경계).

### 9.4 기존 "상태를 스스로 보관하지 않는다" 테스트

- **실측**: `Mirror`로 `_` 접두 저장 프로퍼티가 없음을 단언하는 테스트는 5개다. 그중 대상과 겹치는
  것은 3개다.
  - `ChipTests` "선택 여부를 스스로 보관하지 않는다"
  - `BookmarkButtonTests` "저장 여부를 스스로 보관하지 않는다"
  - `ChoiceResultRowTests`의 같은 단언
  - `@Binding private var isSelected`는 `_isSelected: Binding<Bool>` 자식을 만들므로 전환 뒤 실패한다.
- **결정**: 세 테스트의 단언 의도("컴포넌트가 상태 정본을 소유하지 않는다")를 유지한다. 필터를
  `_` 접두가 아니라 `SwiftUI.State` 저장소로 바꾼다. 조건은
  `String(describing: type(of: child.value)).hasPrefix("State<")`다. 여기에 "상태를 `Binding`으로
  받는다"는 단언(`_isSelected`가 `Binding<Bool>`임)을 추가한다. 테스트 이름은 동작 문장으로 유지하되,
  `Binding` 사실을 반영하도록 바꾼다. 예: "선택 여부를 스스로 보관하지 않고 Binding으로 받는다".
- `TagBadgeContractTests`·`LabeledCardTests`의 같은 단언은 대상이 아니므로 그대로 둔다.
- **근거**: 헌법 원칙 2(변경 가능한 상태의 소유자와 수명)와 [ui-component/verification.md]
  (../../docs/conventions/ui-component/verification.md)의 "상태별 표현을 단위 테스트로 검증"을 따른다.
  `Binding`은 외부 정본의 참조라서 소유가 아니다.

### 9.5 실행 단위 배치

- 이미 모델 전환 단위에 있는 컴포넌트는 같은 단위에서 상태 `Binding`도 함께 바꾼다. 호출부를 한 번만
  고치기 위해서다.
  - U5: `SelectionCardList`(+`Item`)
  - U6: `ChoiceResultRow`, `SavedQuestionCard`
  - U7: `PolicyAgreementRow`, `ChoiceAnswerOption.ExpansionControl`
- 다른 단위에 없는 `Chip`, `SelectableSettingRow`, `BookmarkButton`, `ModalOverlay`는 새 단위 U9로
  묶는다. 이미 확정한 U5~U8의 범위를 넓히지 않도록 U9는 U8 뒤에 둔다. `SavedQuestionCard`는
  `BookmarkButton`을 쓰지 않고 자기 북마크 아이콘 버튼을 그리므로 U6에서 한 번만 바뀐다(구현 중
  확인해 정정).
- 문서 개정 단위는 U10으로 한 칸 뒤로 민다. U10에서 FR-017 규칙을 문서에 넣는다(FR-016).
- U1(`b4b1a79`)은 상태 인자를 바꾸지 않았으므로 영향이 없다. 중단된 U2의 미커밋 테스트 파일
  (`StyleConfigurableTests.swift`, `SizeConfigurableTests.swift`)은 U2 범위 그대로이며 이 전환과
  무관하다.

### 9.6 문서 개정 추가(§7 보완)

| 문서 | 개정 내용 |
| --- | --- |
| [docs/conventions/view/display-value-binding-callback.md](../../docs/conventions/view/display-value-binding-callback.md) | 컴포넌트가 스스로 바꾸는 상태는 변경 콜백 대신 기본값 없는 `Binding`으로 받는다. 읽기 전용 상태는 값, 상태 변경과 무관한 동작은 콜백으로 받는다(FR-017) |
| [docs/conventions/view/component-init.md](../../docs/conventions/view/component-init.md) | 인자 구분 예시에 상태 `Binding`을 넣는다 |
| [docs/conventions/view-declarations/binding.md](../../docs/conventions/view-declarations/binding.md) | 기존 `.constant` 기본값 금지 규칙은 유지하고, "상태 wrapper" 문장 삭제(§7)와 함께 컴포넌트가 상태를 `@Binding private var`로 보존한다는 예시를 보강한다 |
| [docs/package-rules/feature.md](../../docs/package-rules/feature.md) | 화면 View가 `Binding(get:set:)`을 만들고 setter가 기존 View Action을 보낸다. `BindableAction`을 컴포넌트 상태 연결에 쓰지 않는다 |
| [.agents/skills/implement-figma-ui/references/component-index.md](../../.agents/skills/implement-figma-ui/references/component-index.md) | 대상 컴포넌트의 상태·콜백 서술을 `Binding`으로 바꾼다 |

[docs/conventions/tca/action/binding.md](../../docs/conventions/tca/action/binding.md)는 개정하지 않는다.
이 설계가 그 규칙을 그대로 따르기 때문이다.
