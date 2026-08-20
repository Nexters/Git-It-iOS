# 공용 컴포넌트 교정 계약

**대상 기능**: `006-final-uxui-screens` · **조사일**: 2026-08-19

이 문서는 FR-011, FR-029, SC-006, SC-021의 기준선 변경 계약이다. 근거 수준은
`research.md`의 정의를 따르며, 고정값 허용 오차는 `±0.5pt`다.

## 기준선 갱신 항목

| 계약 ID | 대상 | 이전값 | Figma 확정값 | 근거 노드 | 구현 영향 |
| --- | --- | --- | --- | --- | --- |
| `sheet.grabber` | `SheetSurface` | 48×4pt | 58×4pt | `Sheet Modal` `786:37977` | grabber 폭 교정 |
| `sheet.grabberArea` | `SheetSurface` | 위 8pt·아래 22pt | 위 5pt·전체 16pt | `Sheet Modal` `786:37977` | grabber 영역 구조 교정 |
| `projectRow.insets` | `ProjectRow` | 전체 16pt | 위 16pt·좌우 18pt·아래 18pt | `ProjectList` `1621:23606` | 방향별 padding 교정 |
| `action.small.surface` | `ActionButton` 크기 계단 | Small 40pt | MD 40pt·SM 36pt | `Button` `739:27351` | `Size`가 LG·MD·SM을 구분하도록 교정 |

위 네 항목만 기존 `C` 기준선 갱신 대상으로 인정한다. 구현 편의를 이유로 현재값을
목표값으로 채운 항목은 없다.

## 값은 유지하고 근거만 승격하는 항목

| 계약 ID | 값 | 이전 근거 | 새 근거 | Figma 노드 |
| --- | --- | --- | --- | --- |
| `layout.margin` | 20pt | B | A | `프로젝트` `1542:19495` 내부 컨테이너 |
| `header.default.row` | 40pt | C | A | `Toolbar - Top` `786:34960` |
| `header.large.spacing` | 제목 간격 16pt·아래 10pt | C | A | 같은 노드 |
| `bottomAction.insets` | 좌우 20pt·위 4pt·아래 24pt | C | A | `Toolbar - Bottom` `739:28772` |
| `tag.radius` | 8pt(`.small`) | C | A | `Tag` `1334:16349` |
| `tag.padding` | 좌우 10pt·위 3pt·아래 4pt | C | A | `Tag` `1334:16349` |
| `projectRow.thumbnail` | 60×60pt·옆 간격 14pt | C | A | `ProjectList` `1621:23606` |
| `action.large.height` | 54pt | A·B | A | `Button` `739:27351` |
| `action.radius` | 12pt | B | A | 같은 노드 |
| `iconGlass.medium.surface` | 40×40pt | A | A | `Button - Liquid Glass - Icon` `783:34498` |
| `iconGlass.small.surface` | 36×36pt | A | A | 같은 노드 |
| `tab.item.iconSpacing` | 아이콘 아래 4pt | C | A | `BottomNavigationBar-item` `1305:14835` |

`TagBadge.swift`의 라이브 소스는 이미 `RoundedRectangle(designSystem: .small)`을 사용하고
`CornerRadiusToken.small`은 8pt다. 따라서 과거 6pt 기준은 갱신 대상이 아니라 낡은 조사
기록이며, 구현 변경 없이 `tag.radius` 회귀 검증으로 8pt를 보존한다.

## 구조 교정

`ProjectRow`는 Figma `ProjectList`에 대응한다. `학습세트 List-item`은 320×130pt,
세그먼트 진행 표시, Grey700 배경을 갖는 별도 계약이므로 `ProjectRow`의 변형으로 합치지
않는다. 구현 단계에서 `docs/ui-component-checklist.md`의 잘못된 대응을 고치되,
새 컴포넌트 구현은 G4 후속 기능이 소유한다.

## 보류 항목

| 항목 | 사유 | 처리 |
| --- | --- | --- |
| `sheet.radius` | 이번 조사에서 상단 모서리 값을 직접 조회하지 않음 | 기존 B 기준선 16pt 유지, 갱신하지 않음 |
| `tab.adaptive` 전체 형태 | 시스템 `TabView`와 Figma 커스텀 바의 책임 경계 미확정 | 참조 화면 확정 검증에서 제외 |
| `homeCard.*`, `selectionCard.*` | 이번 참조 화면의 교정 범위 밖 | 기존 C 기준선 유지 |

## 검증

- 기준선 갱신 4개 행은 계약 ID·대상·이전값·Figma 확정값·근거 노드·구현 영향이 모두
  비어 있지 않아야 하며, Figma 근거 없이 갱신된 행은 0개여야 한다(SC-021).
- 갱신 항목은 구현 전 실패와 구현 후 성공을 같은 계약 ID로 확인한다.
- `tag.radius`는 구현 전후 모두 8pt인지 회귀 단언하고 소스 변경 작업을 만들지 않는다.
- `SheetSurface`와 `ProjectRow`의 레이아웃 수치는 `private enum Constant`에 유지하고 테스트
  전용 internal 측정 API를 만들지 않는다. `UIComponentTests`는 공개 구성·상태 계약을
  검증하며, `UIComponentLayoutHarness`와 `UIComponentUITests`가 실제 렌더 padding·크기와
  44pt 터치 영역을 검증한다.
- 갱신하지 않은 기존 `DesignSystemTests`·`UIComponentTests`는 적용 전후 동일하게
  통과해야 한다.
- 실패 메시지는 계약 ID, 기대값, 실제값을 포함한다.
