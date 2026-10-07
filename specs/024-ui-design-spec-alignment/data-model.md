# 데이터 모델: UI 패키지 디자인 규격 정렬

**기능 브랜치**: `feature/ui-design-spec-alignment`

**날짜**: 2026-09-02

**명세**: [spec.md](./spec.md) · **조사**: [research.md](./research.md)

이 기능의 "데이터"는 저장소에 보관하는 레코드가 아니라 UI 계층이 소유하는 값 모델이다.
아래 엔터티는 모두 `DesignSystem` 또는 `UIComponent` target의 공개 타입이며 영속성이 없다.

## 1. 토큰 카테고리

이름과 값을 갖는 디자인 값의 묶음. 11종이며 각각 `all` 배열로 전체 목록을 노출한다.
`DesignTokenSet`이 이를 취합해 일괄 검증한다. 기기와 무관한 고정 값만 담는다.

| 카테고리 | 항목 수 | 현재 | 속성 | 변경 |
| --- | --- | --- | --- | --- |
| `ColorToken` | 35 | 30 | `name`, 색 성분, 알파 | 5종 추가 |
| `SemanticColorToken` | 16 | 11 | `name`, 참조하는 `ColorToken`, 역할 설명 | 5종 추가 |
| `TextStyleToken` | 13 | 13 | `name`, 크기, 굵기, 행간 비율, 자간 | **변경 없음** |
| `FontFamilyToken` | 2 | 2 | `name`, PostScript 이름 접두어 | **변경 없음** |
| `CornerRadiusToken` | 7 | 6 | `name`, 반경 | `pill`(999) 추가 |
| `LayoutToken` | 7 | 3 | `name`, 간격 | 4종 추가 |
| `BorderToken` | 6 | **0** | `name`, `width`, 참조하는 `ColorToken` | 6종 신설 |
| `OpacityToken` | 6 | **0** | `name`, `percent` | 6종 신설 |
| `EffectToken` | 2 | **0** | `name`, `kind`, `layers` | 2종 신설 |
| `GradientToken` | 5 | 6 (`all` 5 + 밖 1) | `name`, 방향, 정지점 | `gradient4` 제거(승인 필요) |
| `ControlSizeToken` | 2 | 1 | `name`, 표면 크기, 최소 터치 | `minimumTouch` 추가 |

`TextStyleToken`과 `FontFamilyToken`은 타이포 적용·폰트 설정을 현행 유지하기로 한 결정에
따라 값과 구성을 바꾸지 않는다(spec 명확화 세션 2차). 검증 규칙의 대상에는 포함되지만
값 변경 작업은 없다.

### 검증 규칙

`DesignTokenSet.validate()`가 화면 렌더링 없이 다음을 검사하고 위반 목록을 반환한다.
위반이 없으면 빈 배열이다.

- **이름 중복**: 한 카테고리 안에서 `name`이 유일하다.
- **값 범위**: 알파와 `OpacityToken.percent`는 0 이상 100 이하, 반경·간격·굵기는 0 이상.
- **참조 무결성**: `SemanticColorToken`·`BorderToken`·`EffectToken.Layer`가 참조하는
  `ColorToken`이 `ColorToken.all`에 존재한다.

### 관계

원시 값과 역할 값으로 나뉘고 역할 값이 원시 값을 참조한다. 참조는 단방향이며 순환하지 않는다.

```text
ColorToken ──┬── SemanticColorToken
             ├── BorderToken
             └── EffectToken.Layer
LayoutToken ──── LayoutMetrics (계산 입력)
```

## 2. `EffectToken` — 다중 레이어 구조

그림자가 레이어 여러 개로 구성되므로 단일 offset·blur가 아니라 배열을 갖는다.

| 필드 | 형태 | 설명 |
| --- | --- | --- |
| `name` | 문자열 | 토큰 이름 |
| `kind` | 열거 | `dropShadow` · `innerShadow` |
| `layers` | `Layer` 배열 | 가까운 레이어부터 순서대로 |

`Layer`는 참조 색 토큰, offset(x·y), blur, spread를 갖는다. 규격이 정의한 두 토큰은 다음과
같다.

- `sheetElevation` — 레이어 2개. `black45` (0, 4) blur 6 · `black35` (0, 4) blur 34
- `cardElevation` — 레이어 1개. `black25` (4, 4) blur 15 spread 10

SwiftUI의 `shadow(radius:)`는 Figma blur의 절반이고 spread에 대응이 없어 radius로 흡수한다.
이 환산은 적용 확장이 수행하며 토큰 값은 규격 원본을 그대로 보존한다.

## 3. `LayoutMetrics` — 런타임 레이아웃 변수

기기에서 읽은 값으로부터 파생값을 계산하는 값 타입. 토큰과 달리 런타임에 결정된다.
`DesignSystem` target에 두고 SwiftUI에 의존하지 않는다(R-01·R-02).

### 입력 (4)

| 필드 | 범위 | 출처 |
| --- | --- | --- |
| `screenWidth` | 375 – 440 | 기기 |
| `screenHeight` | 667 – 956 | 기기 |
| `safeAreaTop` | 20 – 68 | 기기 |
| `safeAreaBottom` | 0 – 34 | 기기 |

지원 범위 밖의 입력도 계산은 동작하되 규격이 보장하는 범위는 위와 같다.

### 파생값 (8)

| 필드 | 계산식 | 범위 |
| --- | --- | --- |
| `contentWidth` | `screenWidth − LayoutToken.margin × 2` | 335 – 400 |
| `gridColumn2` | `(contentWidth − gutter) / 2` | 161.5 – 194 |
| `gridColumn3` | `(contentWidth − gutter × 2) / 3` | 103.67 – 125.33 |
| `topScrimHeight(headerStyle:)` | `safeAreaTop + headerHeight` | 70 – 188 |
| `bottomScrimHeight(hasTabBar:)` | `safeAreaBottom + (탭바 ? 93 : 0)` | 0 – 127 |
| `contentBudget(headerStyle:)` | `screenHeight − safeAreaTop − safeAreaBottom − headerHeight − tabBarClearance(92)` | 435 – 718 |
| `tabBarBottomInset` | `max(safeAreaBottom, 24)` | 24 – 34 |
| `sheetMaximumHeight` | `screenHeight − safeAreaTop − 16` | 631 – 878 (비율 detent 금지) |

`headerHeight`는 기기가 아니라 헤더 종류가 정한다: plain 50 · inlineTitle 64 · inlineUser 98
· largeTitle 120. 따라서 헤더에 의존하는 세 값은 프로퍼티가 아니라 헤더 종류를 받는 함수다.

**검증 대상은 13종이다.** 입력 4 + 파생 8 = 12종을 `LayoutMetrics`가 소유하고, 규격
`METRICS` 11종 중 `headerHeight`는 `LayoutMetrics.HeaderStyle`이 소유한다. 규격 11종에
Responsive Layout Spec §07이 확정한 `tabBarBottomInset`·`sheetMaximumHeight`를 더한 값이
13종이며 SC-004의 판정 집합과 일치한다.

### 전달 경로

`ScreenContainer`가 화면 폭·높이·safe area를 읽어 `LayoutMetrics`를 만들고 Environment 키
하나로 하위에 전달한다. 골격 컴포넌트(`ScreenEdgeScrim`·`TabShell`·`SheetSurface`)가 이를
읽는다. 주입 지점은 화면당 한 곳이다.

## 4. 크기 결정 방식 (`SizingMode`)

컴포넌트가 폭을 정하는 방식 4종. 컴포넌트마다 하나를 갖는다.

| 값 | 의미 | 적용 |
| --- | --- | --- |
| `fill` | 부모 폭을 채움 | 버튼·행·카드·텍스트 등 대부분 |
| `grid` | 열 수로 나눔 | `HomeProjectCard`(2열), 마이 통계 카드(3열) |
| `hug` | 내용에 맞춤. 상한은 부모 폭 | `Chip`, `TagBadge` |
| `fixed` | 규격 값 고정 | 종횡비 요소(썸네일·Lottie·가로 스크롤 카드)와 `TabShell` 298 |

`fixed`는 예외이며 정적 검사의 허용 목록에 등록된 곳에서만 쓸 수 있다(R-09).

## 5. 컴포넌트

값과 콜백만 받아 그리는 재사용 표현 단위. 상태·네비게이션·데이터 조회·햅틱·화면 여백을
소유하지 않는다. 역할 폴더 하나에 속하고 `SizingMode` 하나를 갖는다.

### 신설 4종

| 컴포넌트 | 역할 폴더 | 받는 값 | 소유하지 않는 것 |
| --- | --- | --- | --- |
| `Chip` | `Controls` | 라벨, 선택 여부, 탭 콜백 | 선택 상태 — 목록이 소유 |
| `PressOverlayStyle` | `Controls` | 없음 (버튼 스타일) | 눌림 외 모든 상태 |
| `BookmarkButton` | `Controls` | 저장 여부, 접근성 라벨(필수), 탭 콜백 | 저장 상태 |
| `ChoiceResultRow` | `CollectionItems` | 정답·오답, 접힘·펼침, 본문, 탭 콜백 | 펼침 상태 — 패널이 소유 |

### 이동 2종

| 타입 | 현재 | 이동 후 | 사유 |
| --- | --- | --- | --- |
| `QuestionPrompt` | `UI/Component/Displays/` | `Feature/Quiz/Views/` | 규격이 Sub View로 분류 |
| `EssayAnswerInput` | `UI/Component/Controls/` | `Feature/Quiz/Views/` (`AnswerEditor`) | 상태(`text`·`isFocused`)를 소유 |

두 타입 모두 UI 패키지 밖 사용처가 0건이라 이동이 호출부를 깨지 않는다(R-07).

### 판정 대상 15종

`SelectionCardStyle` · `AccountActionRow` · `LabeledTextField` · `SelectableSettingRow` ·
`LaunchLogo` · `OnboardingMockup` · `RubricView` · `SplashView` · `WebContentView` ·
`WebSheet` · `TabShellPreviewItem` · `ScreenContainer` · `StyledText` · `EmptyState` ·
`PolicyAgreementRow`

각각 유지·이동·삭제로 판정하고 근거를 PR 본문에 남긴다. 판정은 명세 작성 시점이 아니라
**구현 중 사용처 조사로** 수행한다. 기본값은 유지이며, 삭제는 사용처가 없음을 확인하고
사용자 승인을 받은 경우로 한정한다 — 삭제는 되돌리기 어려우므로 Constitution 원칙 7의
명시적 승인 대상이다.

## 6. 역할 폴더

컴포넌트가 화면에서 맡는 역할에 따른 분류 6종. 공개 계약으로 판정하며 판정 순서가 곧
우선순위다. 기준은 [UIComponent 컨벤션](../../docs/conventions/ui-component.md)이 소유한다.

| 순서 | 폴더 | 현재 개수 | 테스트 |
| --- | --- | --- | --- |
| 1 | `Scaffolds` | 4 | **0** → 필요 |
| 2 | `Overlays` | 6 | 2 |
| 3 | `Controls` | 13 | 5 |
| 4 | `CollectionItems` | 7 | 2 |
| 5 | `Indicators` | 5 | 2 |
| 6 | `Displays` | 9 | **0** → 필요 |

## 7. 계층

`Screen` · `Sub View` · `Component` 3단계. 무엇을 소유하는가로 나뉜다. 이 기능의 대상은
`Component` 계층과 그 계층이 지켜야 할 경계이며, `Screen`·`Sub View`의 구현은 범위 밖이다.

| 계층 | 소유 | 받는 것 | 금지 |
| --- | --- | --- | --- |
| Screen | 화면 골격, 네비게이션, 데이터 로딩, 탭 선택, 햅틱, 화면 여백 | 라우팅 파라미터 | 다른 Screen을 직접 그리기 |
| Sub View | 자기 영역의 상태와 레이아웃 | 표시할 데이터와 콜백 | 화면 여백 |
| Component | 없음 | 값과 콜백 전부 | 데이터 조회, 네비게이션, 자체 상태, 햅틱, 화면 여백 |

## 8. 정적 검사 규칙

`tools/design-rules`가 소유하는 금지 패턴. 규칙마다 대상 경로와 허용 예외 목록을 갖는다.

| 규칙 | 금지 패턴 | 허용 예외 |
| --- | --- | --- |
| 고정 폭 | `.frame(width:` | `config/allowed-fixed-width` 등록분 |
| 정본 레이아웃 차원 | 컴포넌트의 폭·높이·safe area에 쓰인 103·154·34·127·53 | `#Preview` 제외, 승인된 154 고정 폭 |
| 하드코딩 수치 | 토큰으로 대체 가능한 수치 리터럴 | `+Constant.swift` 파일 |
| 상태 보관 | 컴포넌트의 `@State` | 없음 |
| 화면 여백 | 컴포넌트의 `LayoutToken.margin` 또는 `designSystemScreenMargin(` 사용 | `ScreenContainer` |
| 햅틱 | 컴포넌트의 햅틱 호출 | 없음 |
| 세로 채움 | 컴포넌트의 `.frame(maxHeight: .infinity)` | `config/allowed-vertical-fill` 등록분 |
| Dynamic Type | `dynamicTypeSize` · `ScaledMetric` · `relativeTo:` · `UIFontMetrics` | 없음 |
