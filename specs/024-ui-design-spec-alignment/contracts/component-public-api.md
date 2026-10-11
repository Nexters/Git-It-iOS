# 계약: 컴포넌트 공개 API

**소유 target**: `UIComponent` · **소비자**: `Feature`

## 공통 계약

모든 컴포넌트는 다음을 지킨다. 위반은 정적 검사가 판정한다.

- 표시 상태를 스스로 보관하지 않는다. 값과 콜백으로만 받는다.
- 화면 좌우 여백(`LayoutToken.margin`)을 붙이지 않는다. `ScreenContainer`가 한 번 붙인다.
- 햅틱을 발생시키지 않는다. 판정·완료·삭제 세 지점 모두 Screen이 붙인다.
- 데이터를 조회하지 않고 네비게이션하지 않는다.
- 규격이 토큰 또는 레이아웃 변수로 정의한 수치를 직접 적지 않는다.
- `SizingMode` 하나를 갖는다. `fixed`는 허용 목록 등록분만 가능하다.
- 조작 가능하면 44 × 44 이상의 터치 영역을 확보한다. 표면 크기는 규격 값을 유지하고 히트
  영역만 넓힌다.
- 프로덕션 구현이 SwiftUI `Button`을 사용하면 `PressOverlayStyle`로 눌림 표현을
  `white30` 오버레이 하나로 통일한다.

## 신설 컴포넌트

### `Controls/Chip`

선택을 소유하지 않는 필터 칩. 선택은 이를 담는 목록이 갖는다.

| 입력 | 필수 | 설명 |
| --- | --- | --- |
| 라벨 | 예 | Body 2, 1줄 고정. 줄바꿈·말줄임 없음 |
| 선택 여부 | 예 | 값으로 받음 |
| 탭 콜백 | 예 | 같은 칩을 다시 눌러도 해제되지 않음 — 토글이 아님 |

표현: 비선택은 `raisedBackground` 배경 + `blue100` 라벨, 선택은 `brandAccent` 배경 +
`grey700` 라벨. 반경 `CornerRadiusToken.small`(8). 높이 36. `SizingMode.hug`.

접근성: 선택 특성을 노출한다.

### `Controls/PressOverlayStyle`

버튼 계열 공용 누름 표현. 눌림 시 `white30` 오버레이 하나만 적용하며 배경색을 새로 만들지
않는다. `Component/` 프로덕션 코드의 SwiftUI `Button` 사용처 전부가 이 스타일을 쓴다.

### `Controls/BookmarkButton`

| 입력 | 필수 | 설명 |
| --- | --- | --- |
| 저장 여부 | 예 | 값으로 받음 |
| 접근성 라벨 | **예** | 아이콘 이름이 아니라 동작 이름("저장하기") |
| 탭 콜백 | 예 | |

접근성 라벨을 선택 인자로 두지 않는다. 생략할 수 없어야 한다(spec FR-033).

### `CollectionItems/ChoiceResultRow`

채점 결과 행. 펼침 상태를 소유하지 않는다 — 이를 담는 패널이 `expanded` 집합으로 갖는다.

| 입력 | 필수 | 설명 |
| --- | --- | --- |
| 판정 | 예 | 정답 · 오답 |
| 펼침 여부 | 예 | 값으로 받음 |
| 본문·해설 | 예 | |
| 탭 콜백 | 예 | 펼침 토글 요청. 햅틱 없음 |

표현: `cardBackground` 기본, 판정 시 `correct`/`incorrect` 배경 + `grey100` 본문.
접힘 높이 **59** · 펼침 높이 **111**. 두 값은 UIUX Guide 상태 매트릭스와 Design System Spec의
`ChoiceResultRow` 스펙 카드가 함께 확정한 세로 규격 값이며, FR-018에 따라 화면 높이와 무관하게
유지한다. 가로는 `SizingMode.fill`이다 — 스펙 카드의 `320 × 111` 중 320은 정본 캔버스 360에서
좌우 여백 20을 뺀 값이므로 고정 폭으로 옮기지 않는다(P4 · FR-017).

접근성: 색만으로 판정을 전달하지 않는다. 접근성 라벨에 "정답"·"오답"을 접미로 붙인다.

## 변경 컴포넌트

### `Controls/TextField`

높이 52 · 반경 8 · 내부 좌우 16으로 재작도한다. Material 잔여 형태(반경 4/4/0/0, 하단 active
indicator, 라벨 축소)를 제거한다.

| 상태 | 테두리 | 부가 |
| --- | --- | --- |
| 기본 | `BorderToken.default` | |
| 활성 | `BorderToken.focus` | |
| 입력됨 | `mutedText` 1pt | |
| 오류 | `BorderToken.error` | Caption 1 오류문 |

### 골격 컴포넌트

`ScreenContainer` · `ScreenHeader` · `ScreenEdgeScrim` · `TabShell` · `SheetSurface` ·
`ModalOverlay`는 [layout-metrics.md](./layout-metrics.md)의 골격 계층 계약을 따른다.
`ScreenContainer`는 추가로 `LayoutMetrics`를 만들어 Environment로 주입하는 유일한 지점이다.

### `Overlays/SheetSurface`

높이는 콘텐츠를 따르고 상한은 `sheetMaximumHeight`(`screenHeight − safeAreaTop − 16`)다.
상한을 넘으면 시트 안에서 스크롤한다. 비율 detent를 쓰지 않는다.

**상태를 보관하지 않고 이 동작을 얻는 방법**을 계약으로 확정한다. `ViewThatFits(in: .vertical)`의
첫 후보를 콘텐츠 그대로, 둘째 후보를 `ScrollView { 콘텐츠 }`로 두고 전체에
`.frame(maxHeight:)`로 `sheetMaximumHeight`를 건다. 콘텐츠가 상한 안에 들어가면 첫 후보가,
넘으면 둘째 후보가 선택되므로 높이 측정을 위한 `@State`나 `PreferenceKey`가 필요 없다.

이 확정은 FR-015(콘텐츠를 따르는 높이)와 FR-026·SC-014(표시 상태 비보관, 예외 없음)를 동시에
만족시키기 위한 것이다. 현재 구현은 `@State private var contentHeight`와
`ContentHeightPreferenceKey`로 콘텐츠 높이를 재어 `ScrollView`의 세로 탐욕성을 막고 있는데,
그 측정이 유일한 `@State` 사용 이유이므로 위 구조로 바꾸면 함께 사라진다. SC-014의
"규칙 예외로 남는 컴포넌트가 없다"를 약화하지 않는다.

따라서 **`isScrollable` 인자를 제거한다.** 스크롤 여부는 호출부가 정하지 않고 콘텐츠 높이와
상한이 정한다. 호출부는 `sources/Projects/Feature/Onboarding/Screens/LegalAgreementScreen.swift`
한 곳이며 FR-040의 호출부 복구 범위에 든다.

| 입력 | 필수 | 설명 |
| --- | --- | --- |
| 콘텐츠 | 예 | `@ViewBuilder`. 높이는 콘텐츠가 정한다 |

상단 두 모서리만 반경 16을 적용하고 그래버는 `grabber` 역할 색을 쓴다. 시트는 화면 좌우
여백을 붙이지 않는다(공통 계약) — 현재 구현의 `.designSystemScreenMargin()` 호출은 제거 대상이다.

### 상태 매트릭스

UIUX Guide의 10행을 그대로 따른다. 눌림 표현은 전 항목 공통으로 `white30` 오버레이다.

| 컴포넌트 | 기본 | 선택·활성 | 비활성 | 오류 |
| --- | --- | --- | --- | --- |
| `ActionButton` primary | `brandAccent` 배경 · `grey700` 라벨 | `white30` 오버레이 | `raisedBackground` 배경 · `white30` 라벨 | `error` 배경 · `grey100` 라벨 |
| `ActionButton` secondary | `raisedBackground` 배경 · `grey100` 라벨 | `white30` 오버레이 | `raisedBackground` 배경 · `white30` 라벨 | `raisedBackground` 배경 · `error` 라벨 |
| `ActionButton` text | 배경 없음 · `grey100` 라벨 | `white30` 오버레이 | `white30` 라벨 | `error` 라벨 |
| `TextField` | `BorderToken.default` | `BorderToken.focus`(활성) / `mutedText` 1pt(입력됨) | — | `BorderToken.error` + Caption 1 오류문 |
| `Chip` | `raisedBackground` 배경 · `blue100` 라벨 | `brandAccent` 배경 · `grey700` 라벨 | — | — |
| `ChoiceAnswerOption` | `cardBackground` · 테두리 없음 | 외곽 `BorderToken.focus` | — | — |
| `ChoiceResultRow` | `cardBackground` · 접힘 59 | 펼침 111 | — | `correct`/`incorrect` 배경 + `grey100` 본문 |
| `LearningSetRow` · `SelectionCard` | `screenBackground` · `BorderToken.default` | `selectedSurface` 겹침 + `BorderToken.focus` | — | — |
| `TabShell.Item` | `mutedText` 아이콘·라벨 | `brandAccent` 아이콘·라벨 | — | — |
| `EmptyState` | 프로젝트 없음 · 저장 문제 없음 2종만 | — | — | 이 두 종만 사용. 네트워크 오류 등 별도 상태는 만들지 않는다 |

## 이동 대상

`QuestionPrompt`와 `EssayAnswerInput`은 상태를 소유하므로 Component 계약을 만족할 수 없다.
`Feature/Quiz/Views/`로 옮긴다. 두 타입이 쓰던 무상태 조각(`ProgressSegments` 등)은 UI에
컴포넌트로 남는다.

## 판정 대상 15종

규격 인덱스에 없는 기존 컴포넌트는 구현 중 사용처를 조사해 유지·이동·삭제로 판정하고 근거를
PR 본문에 적는다. 유지 판정한 컴포넌트도 위 "공통 계약"을 지켜야 한다. 삭제 판정은 실행 전에
승인을 받는다.
