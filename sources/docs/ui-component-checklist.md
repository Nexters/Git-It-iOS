# Git It iOS UI 컴포넌트 체크리스트

**상태**: 초안

**작성일**: 2026-08-18

**원천**: Figma export `사용한 컴포넌트.svg`, `사용한 아이콘.svg`

이 문서는 디자인에서 확정된 컴포넌트·자산 목록과 `UIComponent` 구현 현황을 대응시킵니다.
어떤 컴포넌트를 만들지 판단하는 기준이 아니라 **무엇이 남았는지 추적하는 목록**입니다.

- 분리 기준과 소유 범위는 [UI 패키지 규칙](./package-rules/ui.md)
- 구현 컨벤션(공개 생성 경로, 토큰, 중첩 선언, 접근성, 프리뷰)은
  [View 컨벤션](./view-conventions.md)
- 토큰 카테고리는 [DesignSystem README](../Projects/UI/DesignSystem/README.md)

체크 표시는 **해당 Figma 변형이 코드로 표현 가능한 상태**를 뜻합니다. 시각 세부 조정이
남아 있어도 계약이 존재하면 체크하고, 미대응 변형은 비고에 남깁니다.

## 1. 컨트롤

| Figma 컴포넌트 | 변형 | 구현 | 상태 | 비고 |
| --- | --- | --- | --- | --- |
| `Button` | Size LG·MD·SM × Style Primary·Secondary·Primary Text·Text × State Default·Pressing·Disabled·Error | `Leaf/ActionButton` | [x] | Style 4종·Disabled 대응. Size 분기와 Pressing·Error 상태 미대응 |
| `Button - Liquid Glass - Icon` | Size MD·SM × Style 4종 × State 4종 | `Leaf/IconButton` | [x] | `.glass` 버튼 스타일 + tint 4종. Size 분기와 Pressing·Error 상태 미대응 |
| `Button - Liquid Glass - Group` | Only Icon, Various | `Composite/ScreenHeader` 컨트롤 행 | [x] | 독립 컴포넌트가 아니라 헤더의 leading·trailing 슬롯으로 표현 |
| `Tag` | Accent, Normal | `Leaf/TagBadge` | [x] | `neutral`·`accent`·`selected` 3종 |
| `Dropdown menu` | 단일 | — | [ ] | 미구현 |
| `Text field` | Default, Active, Filled, Error | — | [ ] | 미구현 |
| `Check List` | 단일 | — | [ ] | 미구현. `Sheet Modal` 안에서만 사용 |

## 2. 화면 골격

| Figma 컴포넌트 | 변형 | 구현 | 상태 | 비고 |
| --- | --- | --- | --- | --- |
| `Toolbar - Top` | Default, Large Title, Inline User, Inline Title | `Composite/ScreenHeader` | [x] | `Style` 4종이 Figma 변형과 1:1 대응 |
| `Toolbar - Bottom` | Vertical, Horizen | `Composite/BottomActionBar` | [x] | 배치는 호출부가 `@ViewBuilder`로 결정 |
| `Sheet Modal` | 단일 | `Composite/SheetSurface` | [x] | Grabber + 상단 모서리 표면. Overlay(scrim)는 호출부 책임 |
| `BottomNavigationBar`, `BottomNavigationBar-item` | selected, default | `Composite/TabShell`, `TabShellItem` | [x] | 탭 목록은 `TabShellItem` 준수 타입이 소유 |
| `Modal` | Default, Progress, Text Field | — | [ ] | 미구현. `Text field`·`Progress Bar` 선행 필요 |
| `top dim`, `bottom dim` | Default, 문제풀이용 | — | [ ] | 미구현 |
| — | — | `Composite/ScreenContainer` | [x] | Figma에 대응 컴포넌트가 없는 화면 배경·색 구성표 소유자 |

## 3. 진행 표시

| Figma 컴포넌트 | 변형 | 구현 | 상태 | 비고 |
| --- | --- | --- | --- | --- |
| `bar` | 0%, 30%, 50%, 80%, 100% | — | [ ] | 미구현. 현재는 `ProjectRow`·`HomeProjectCard`가 각각 그림 |
| `Progress Bar` | label Set + Bar | — | [ ] | 미구현. 라벨을 포함한 조합 |
| — | — | `Leaf/ProgressSegments` | [x] | 문항 단위 세그먼트 표시. Figma `bar`(연속형)와 다른 계약 |

## 4. 카드와 리스트

| Figma 컴포넌트 | 변형 | 구현 | 상태 | 비고 |
| --- | --- | --- | --- | --- |
| `Card` | Purple, Blue, Navy | `Composite/HomeProjectCard` | [x] | `Variant` purple·lightBlue·darkBlue |
| `학습세트 List-item` | Default, Variant2 | `Composite/ProjectRow` | [x] | Variant2를 `isDeleting`으로 표현 |
| `select card` | off, on | `Composite/SelectionCard` | [x] | `isSelected`로 테두리·trait 분기 |
| `select card list` | Default, 1~5 | `Composite/SelectionCardList` | [x] | 선택 개수 변형은 항목 상태로 표현 |
| `오픈소스 추천` | 단일 | — | [ ] | 미구현 |
| — | — | `Composite/SavedQuestionCard` | [x] | 저장한 문제 카드. Figma 대응 컴포넌트 미확인 |

## 5. 문항

| Figma 컴포넌트 | 변형 | 구현 | 상태 | 비고 |
| --- | --- | --- | --- | --- |
| `객관식문항-문제 풀이` | Default, Click | — | [ ] | 미구현 |
| `객관식문항-답안` | Answer Correct·Incorrect × State Default·Click | — | [ ] | 미구현. `ColorToken.correct`·`incorrect` 토큰은 준비됨 |
| `객관식 문항 인터랙션 쇼케이스` | — | — | [ ] | 미구현. 검토용 조합이므로 `Components/Review/` 대상 |

## 6. 자산과 아이콘

| Figma 자산 | 형식 | 구현 | 상태 | 비고 |
| --- | --- | --- | --- | --- |
| 리스트 썸네일 Default | PNG | `ResourceImage.Asset.selectionCardThumbnail` | [x] | |
| 리스트 썸네일 `Illust_Levels_*` | Beginner, Junior, Mid, Senior | — | [ ] | 미구현. 4단계 레벨 일러스트 |
| 리스트 썸네일 `Illust_Knowledge_*` | Basic, Intermediate, Advanced | — | [ ] | 미구현. 3단계 지식 일러스트 |
| Empty 일러스트 | PNG | `ResourceImage.Asset.emptyState` + `Composite/EmptyState` | [x] | |
| 리스트 썸네일 삭제 아이콘 | Trash | `IconButton.destructive` | [x] | SF Symbol `trash`로 대체 |
| 로딩 애니메이션 | JSON(Lottie) | — | [ ] | 미구현. Lottie 의존성 도입 여부 미결정 |
| 알림 애니메이션 | JSON(Lottie) | — | [ ] | 미구현. 같은 의존성 결정에 묶임 |

`ResourceImage.Asset`이 소유한 그 밖의 자산 — `profile`, `creationLoading`,
`learningComplete`, `projectAndroid`, `projectDetail`, `projectNexters` — 은 화면 조립
단계에서 사용하며 Figma 컴포넌트 목록에는 개별 항목으로 나타나지 않습니다.

## 7. Figma 대응이 없는 구현

디자인 컴포넌트가 아니라 코드 쪽 필요로 존재하는 선언입니다.

| 구현 | 역할 |
| --- | --- |
| `Leaf/StyledText` | Typography 팩토리. 모든 문자열이 통과하는 단일 경로 |
| `Leaf/ResourceImage` | 자산 이름 문자열과 리소스 번들을 감싸는 이미지 계약 |
| `Composite/OnboardingMockup` | 온보딩 화면 안에서 앱 화면을 축소해 보여주는 목업 |
| `Review/LayoutReviewCatalogList` | TestFlight 레이아웃 검토 화면 목록 |
| `Review/LayoutReviewChrome` | 검토 화면의 상태 전환 제어 |
| `Review/LayoutReviewDetail` | 검토 대상 화면과 제어의 합성 |

## 8. 남은 작업 요약

- [ ] `Text field` — `Modal`과 문항 화면의 선행 조건
- [ ] `bar` / `Progress Bar` — 연속형 진행 표시를 컴포넌트로 승격
- [ ] `객관식문항-문제 풀이`, `객관식문항-답안`
- [ ] `Modal` 3변형
- [ ] `Dropdown menu`
- [ ] `Check List`
- [ ] `오픈소스 추천`
- [ ] `top dim` / `bottom dim`
- [ ] 레벨·지식 단계 썸네일 일러스트 자산
- [ ] Lottie 애니메이션 2종과 의존성 결정
- [ ] `ActionButton`·`IconButton`의 Size 분기와 Pressing·Error 상태

## 문서 변경 기준

Figma 컴포넌트 목록이 갱신되거나 위 항목의 구현 상태가 바뀔 때 수정합니다. 구현 컨벤션이
바뀌면 이 문서가 아니라 [View 컨벤션](./view-conventions.md)을 수정합니다.
