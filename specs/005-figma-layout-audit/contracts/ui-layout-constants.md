# UI 레이아웃 상수 계약 체크리스트

## 근거 수준

- `A`: Figma `사용한 컴포넌트`를 100% 확대해 직접 확인한 값
- `B`: 저장소 문서가 Figma 실측이라고 명시한 값
- `C`: 현재 구현에만 존재하는 회귀 기준선. Figma 확정값으로 보고하지 않음

고정값 기본 허용 오차는 `±0.5pt`다. `C` 항목은 값 보존 테스트는 할 수 있지만, Figma와의 일치 판정에는 사용하지 않는다.

## 공용 토큰

| 상태 | 계약 ID | 값 | 근거 | 소스 |
| --- | --- | --- | --- | --- |
| [ ] | `layout.margin` | 20pt | B | `DesignSystem/Token/LayoutToken.swift`, DesignSystem README |
| [ ] | `layout.gutter` | 12pt | B | `DesignSystem/Token/LayoutToken.swift`, DesignSystem README |
| [ ] | `corner.micro` | 3pt | B | `DesignSystem/Token/CornerRadiusToken.swift`, DesignSystem README |
| [ ] | `corner.compact` | 6pt | B | 같은 경로 |
| [ ] | `corner.small` | 8pt | B | 같은 경로 |
| [ ] | `corner.medium` | 10pt | B | 같은 경로 |
| [ ] | `corner.large` | 12pt | B | 같은 경로 |
| [ ] | `corner.extraLarge` | 16pt | B | 같은 경로 |
| [ ] | `touch.minimum` | 44pt × 44pt 이상 | 프로젝트 접근성 규칙 | `docs/conventions/view.md` |

## 컨트롤

| 상태 | 계약 ID | 대상 | 목표 | 근거 | UI 테스트 식별자 |
| --- | --- | --- | --- | --- | --- |
| [ ] | `action.large.height` | `ActionButton` LG, 모든 스타일·상태 | 54pt | A·B | `action.large.*` |
| [ ] | `action.small.height` | `ActionButton` SM, 모든 스타일·상태 | 40pt | A | `action.small.*` |
| [ ] | `action.state.stable` | 같은 크기의 Default·Disabled·Error | 외곽 높이 동일 | A | `action.*.*` |
| [ ] | `action.radius` | 채워진 `ActionButton` | 12pt | B | 이미지/렌더 보조 검증 |
| [ ] | `iconGlass.medium.surface` | `IconGlassButton` MD | 40pt × 40pt | A | `iconGlass.medium.*.surface` |
| [ ] | `iconGlass.small.surface` | `IconGlassButton` SM | 36pt × 36pt | A | `iconGlass.small.*.surface` |
| [ ] | `iconGlass.touch` | 모든 `IconGlassButton` | 44pt × 44pt 이상 | 접근성 규칙 | `iconGlass.*.*` |
| [ ] | `tag.padding` | `TagBadge` | 좌우 10pt, 위 3pt, 아래 4pt | C | `tag.*` |
| [ ] | `tag.radius` | `TagBadge` | 6pt | C | 렌더 보조 검증 |

## 화면 골격

| 상태 | 계약 ID | 대상 | 목표 | 근거 | UI 테스트 식별자 |
| --- | --- | --- | --- | --- | --- |
| [ ] | `header.default.row` | `ScreenHeader` Default·Inline Title·Large Title | 컨트롤 행 40pt | C | `header.*` |
| [ ] | `header.user.row` | `ScreenHeader` Inline User | 컨트롤 행 66pt, 위 22pt | C | `header.inlineUser` |
| [ ] | `header.large.spacing` | `ScreenHeader` Large Title | 제목 간격 16pt, 아래 10pt | C | `header.largeTitle` |
| [ ] | `header.avatar` | Inline User 아바타 | 40pt × 40pt, 텍스트 간격 11pt | C | `header.inlineUser.avatar` |
| [ ] | `bottomAction.insets` | `BottomActionBar` | 좌우 20pt, 위 4pt, 아래 24pt | C | `bottomAction.default` |
| [ ] | `sheet.grabber` | `SheetSurface` | 48pt × 4pt | C | `sheet.default.grabber` |
| [ ] | `sheet.insets` | `SheetSurface` | grabber 위 8pt·아래 22pt, 콘텐츠 아래 24pt | C | `sheet.default` |
| [ ] | `sheet.radius` | `SheetSurface` 상단 모서리 | 16pt | B | 렌더 보조 검증 |
| [ ] | `tab.adaptive` | `TabShell` | 시스템 `TabView` 높이 적응, 아이콘 아래 4pt | 플랫폼·C | `tab.default` |

## 카드와 리스트

| 상태 | 계약 ID | 대상 | 목표 | 근거 | UI 테스트 식별자 |
| --- | --- | --- | --- | --- | --- |
| [ ] | `homeCard.frame` | `HomeProjectCard` 모든 색상 변형 | 154pt × 192pt | C | `homeCard.*` |
| [ ] | `homeCard.title` | 카드 헤더 | 제목 폭 94pt, 제목 간격 6pt | C | `homeCard.*.title` |
| [ ] | `homeCard.insets` | 카드 내부 | 좌 14pt·우 10pt·위 18pt·아래 18pt | C | `homeCard.*` |
| [ ] | `homeCard.progress` | 카드 진행 바 | 높이 5pt | C | `homeCard.*.progress` |
| [ ] | `projectRow.thumbnail` | `ProjectRow` | 60pt × 60pt, 옆 간격 14pt | C | `projectRow.*.thumbnail` |
| [ ] | `projectRow.insets` | `ProjectRow` | 전체 16pt, 최소 높이 92pt | C | `projectRow.*` |
| [ ] | `selectionCard.thumbnail` | `SelectionCard` | 52pt × 52pt, 옆 간격 16pt | C | `selectionCard.*.thumbnail` |
| [ ] | `selectionCard.frame` | `SelectionCard` | 전체 14pt, 최소 높이 80pt, 테두리 1pt | C | `selectionCard.*` |
| [ ] | `selectionList.spacing` | `SelectionCardList` | 항목 간 8pt | C | `selectionList.default` |

## 제외 항목

| 항목 | 제외 이유 |
| --- | --- |
| `StyledText`, `ResourceImage`, `ProgressSegments`, `SavedQuestionCard`, `ScreenContainer`, `OnboardingMockup` | 저장소 체크리스트에서 Figma 직접 대응이 없다고 명시 |
| 전체 `TabView` 높이와 안전 영역 | iOS 시스템과 기기 환경이 소유하는 적응형 값 |
| 미구현 `Dropdown menu`, `Text field`, `Modal`, 문항 컴포넌트 등 | 이번 기능은 현재 코드 대응이 있는 컴포넌트 점검만 포함 |

## 완료 조건

- `A`·`B` 항목은 모두 자동화 또는 렌더 보조 검증과 연결하고 통과 상태로 표시한다.
- `C` 항목은 기준선 테스트와 근거 수준을 유지하며 Figma 확정값으로 승격하지 않는다.
- 불일치 항목은 수정 전 실패와 수정 후 성공 결과를 남긴다.
