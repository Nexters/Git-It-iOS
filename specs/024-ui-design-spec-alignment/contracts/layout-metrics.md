# 계약: 런타임 레이아웃 변수

**소유 target**: `DesignSystem` (값) · `UIComponent` (Environment 주입)

## 원칙

1. Figma 정본 캔버스 360 × 800은 크기 기준이 아니다. 정본에서는 구성 순서·간격·컴포넌트
   높이·색만 가져온다.
2. 가로는 늘리고 세로는 고정한다. 화면이 넓어지면 콘텐츠 폭만 늘고, 세로 간격과 컴포넌트
   높이는 화면 높이와 무관하게 규격 값을 유지한다. 남는 높이는 스크롤 여유다.
3. 변하는 값은 계산식과 범위로 함께 정의한다. 구현은 계산식을 쓰고 검수는 범위를 본다.
4. 고정 폭은 종횡비가 의미를 갖는 요소에 쓰며, 규격이 직접 확정한 `TabShell` 298만 별도
   예외로 둔다.

## 입력 계약

`LayoutMetrics`는 네 값만 입력으로 받는다. 그 밖의 값을 기기에서 직접 읽지 않는다.

```text
screenWidth · screenHeight · safeAreaTop · safeAreaBottom
```

지원 범위는 375 – 440 × 667 – 956, safe area 상단 20 – 68 · 하단 0 – 34다. 범위 밖 입력도
계산은 동작하지만 규격이 보장하지 않는다.

## 파생 계약

| 이름 | 계산식 | 보장 범위 |
| --- | --- | --- |
| `contentWidth` | `screenWidth − margin × 2` | 335 – 400 |
| `gridColumn2` | `(contentWidth − gutter) / 2` | 161.5 – 194 |
| `gridColumn3` | `(contentWidth − gutter × 2) / 3` | 103.67 – 125.33 |
| `topScrimHeight(headerStyle:)` | `safeAreaTop + headerHeight` | 70 – 188 |
| `bottomScrimHeight(hasTabBar:)` | `safeAreaBottom + (탭바 ? 93 : 0)` | 0 – 127 |
| `contentBudget(headerStyle:)` | `screenHeight − safeAreaTop − safeAreaBottom − headerHeight − tabBarClearance(92)` | 435 – 718 |
| `tabBarBottomInset` | `max(safeAreaBottom, 24)` | 24 – 34 |
| `sheetMaximumHeight` | `screenHeight − safeAreaTop − 16` | 631 – 878 |

`headerHeight`는 헤더 종류가 정한다: plain 50 · inlineTitle 64 · inlineUser 98 ·
largeTitle 120.

## 금지 값

다음 정본 고정값은 컴포넌트의 레이아웃 차원으로 나타날 수 없다. 같은 숫자가 토큰 값이나
지원 기기 테스트 입력처럼 다른 의미로 쓰이는 경우는 위반이 아니다. 정적 검사가 문맥을
구분해 판정한다.

| 값 | 정본에서의 의미 | 대체 |
| --- | --- | --- |
| 103 | 상단 스크림 높이(53 + 50) | `topScrimHeight(headerStyle:)` |
| 154 | 2열 카드 폭 | `gridColumn2` |
| 34 · 127 | 하단 스크림 높이 | `bottomScrimHeight(hasTabBar:)` |
| 53 | 상단 safe area | 시스템 값 |

## 골격 계층 계약

Responsive Layout Spec의 계층 표를 따른다. 참조 구현과 충돌하면 이 표가 우선한다(research
R-06).

| 컴포넌트 | 정렬 | 크기 | 비고 |
| --- | --- | --- | --- |
| `ScreenBackground` | fill | `screenWidth` × `screenHeight` | `screenBackground` |
| `ScrollContent` | fill | `contentWidth` × 콘텐츠 | 위 정렬. 하단 인셋은 탭바 인셋 |
| `ScreenHeader` | top, safe area 아래 | `screenWidth` × 50/64/98/120 | 스크롤과 무관하게 고정 |
| `ScreenEdgeScrim.top` | top | `screenWidth` × `topScrimHeight` | 히트 테스트 꺼짐 |
| `ScreenEdgeScrim.bottom` | bottom | `screenWidth` × `bottomScrimHeight` | 히트 테스트 꺼짐 |
| `TabShell` | bottom | 폭 298(인자로 변경 가능) × 68 + `tabBarBottomInset` | 가로 중앙 |
| `SheetSurface` | bottom | `screenWidth` × 콘텐츠, 상한 `sheetMaximumHeight` | 비율 detent 금지. 상단 두 모서리만 16 |
| `ModalOverlay` | fill | `screenWidth` × `screenHeight` | safe area 무시. scrim 70% |

## 확정 사항

정본에 근거가 없어 Responsive Layout Spec §07이 확정한 3건을 그대로 따른다.

- **탭바 알약 폭**: 298 고정, 가로 중앙. 탭 5개 × 44 히트 영역 = 220이 들어가므로 안전하다.
  폭은 인자로 두어 채움으로 바꿀 수 있게 한다.
- **`TextField` 높이**: 52. 등록 화면 정본의 56이 아니라 규격 재작도 값을 쓴다.
- **시트 최대 높이**: `screenHeight − safeAreaTop − 16`. 넘으면 시트 안에서 스크롤한다.
