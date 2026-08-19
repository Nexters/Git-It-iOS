# 참조 화면 레이아웃·상호작용 계약

**화면**: `screen.project.list` · **Figma 상태 노드**: `1542:19495`, `1621:30331`,
`1597:19052`, `1621:23431`, `1621:30561`, `1621:24059`

**구현 위치**: `sources/Projects/Feature/Presentation/Screens/LearningProjectList/LearningProjectListView.swift`

**계획 상태**: `구현 대상` — 006의 Feature·App 단계에서 구현하고 검증한다. 현재 완료 여부는
이 계약에 복제하지 않으며 `tasks.md`의 완료 표시와 실제 빌드·테스트 결과로 판정한다.

## 선택 근거

프로젝트 목록 화면은 목록·빈 상태·메뉴·삭제 모드·확인 시트를 모두 가지며,
`ScreenHeader`, `ProjectRow`, `EmptyState`, `SheetSurface`, `BottomActionBar`,
`ActionButton`, `IconGlassButton`, `TagBadge`를 함께 사용한다. 또한
`FetchLearningProjects`와 `DeleteLearningProject` 계약으로 생성자 주입과 Mock 상태 전이를
검증할 수 있어 후속 화면의 본보기로 적합하다.

## 상태

| 상태 ID | Figma 노드 | 근거 수준 | 표시 조건 | 계획 상태 | 검증 수준 |
| --- | --- | --- | --- | --- | --- |
| `project.list.loaded` | `1542:19495` | A | 조회 성공, 항목 1개 이상 | 구현 대상 | launch + Figma 정밀 판정 |
| `project.list.menu` | `1621:30331` | A | 상단 메뉴 버튼 선택 | 구현 대상 | launch + Figma 정밀 판정 |
| `project.list.empty` | `1597:19052` | A | 조회 성공, 항목 0개 | 구현 대상 | launch + Figma 정밀 판정 |
| `project.list.deleting` | `1621:23431`, `1621:30561` | A | 삭제 모드 진입 | 구현 대상 | launch + Figma 정밀 판정 |
| `project.list.confirmingDeletion` | `1621:24059` | A | 삭제할 항목 선택 | 구현 대상 | launch + Figma 정밀 판정 |
| `project.list.loading` | 직접 대응 프레임 없음 | 운영 | 최초 조회 중 | 구현 대상 | launch + 최소 렌더링 |
| `project.list.failed` | 직접 대응 프레임 없음 | 운영 | 조회 실패 | 구현 대상 | launch + 최소 렌더링·재시도 전이 |

앞의 5개는 Figma 디자인 상태이고 뒤의 2개는 앱 운영 상태다. 운영 상태는 Figma 정밀
레이아웃·색 판정에서 제외하지만 launch scenario와 명시된 동작 검증에서 제외하지 않는다.

## 확정 레이아웃

| 계약 ID | 대상 | 값 | 근거 | 자동 검증 ID |
| --- | --- | --- | --- | --- |
| `project.screen.width` | 기준 화면 폭 | 360pt | A | `project.screen` |
| `project.content.horizontalInset` | 목록 좌우 | 20pt | A | `project.list` |
| `project.content.topInset` | 첫 행 위 | 8pt | A | `project.list` |
| `project.content.rowSpacing` | 행 사이 | 8pt | A | `project.row.*` |
| `project.row.width` | `ProjectRow` | 320pt | A | `project.row.*` |
| `project.row.defaultHeight` | 일반 행 | 150pt | A | `project.row.default` |
| `project.row.deleteHeight` | 삭제 행 | 94pt | A | `project.row.delete` |
| `project.row.insets` | 내부 | 위 16·좌우 18·아래 18pt | A | `project.row.*` |
| `project.row.thumbnail` | 썸네일 | 60×60pt | A | `project.row.thumbnail` |
| `project.row.thumbnailSpacing` | 썸네일과 텍스트 | 14pt | A | `project.row.header` |
| `project.row.sectionSpacing` | 헤더와 진행 영역 | 12pt | A | `project.row.default` |
| `project.row.progressHeight` | 진행 바 | 6pt | A | `project.row.progress` |
| `project.row.progressDetailsSpacing` | 진행 바와 세트 정보 | 12pt | A | `project.row.progressArea` |
| `project.row.detailSpacing` | 태그와 제목 | 8pt | A | `project.row.details` |
| `project.menu.size` | 펼친 메뉴 | 181×126pt | A | `project.menu` |
| `project.menu.position` | 화면 좌상단 기준 | x=160, y=91pt | A | `project.menu` |
| `project.menu.insets` | 메뉴 내부 | 위 8·좌우 14·아래 9pt | A | `project.menu` |
| `project.sheet.frame` | 삭제 확인 시트 | 360×475pt, y=325pt | A | `project.delete.sheet` |
| `project.sheet.grabber` | grabber | 58×4pt, 위 5pt | A | `project.delete.grabber` |

모든 고정값 허용 오차는 `±0.5pt`다. Status Bar, Home Indicator, 안전 영역과 시스템 키보드
영역은 플랫폼 소유 값이므로 고정 프레임 판정에서 제외한다.

## 색 적용

| 계약 ID | 대상 | 토큰 | 값 | 근거 |
| --- | --- | --- | --- | --- |
| `project.color.background` | 화면 | `SemanticColorToken.screenBackground` | `#141414` | A |
| `project.color.row` | 목록 행 | `SemanticColorToken.cardBackground` | `#242425` | A |
| `project.color.progressTrack` | 진행 트랙 | 신규 의미 토큰 → `grey500` | `#3B3B3B` | A |
| `project.color.progressFill` | 진행 채움 | 신규 의미 토큰 → `blue200` | `#8BB5EF` | A |
| `project.color.secondaryText` | 부제 | `grey400` | `#919191` | A |
| `project.color.detailText` | 세트 제목 | `grey300` | `#BCBCBC` | A |
| `project.color.sheet` | 삭제 확인 시트 | `cardBackground` | `#242425` | A |
| `project.color.overlay` | 시트 배경 오버레이 | `scrim` | `#000000`, 70% | A |

화면과 컴포넌트 코드에는 `Color(red:)`, hex 문자열 또는 숫자 RGB 값을 직접 쓰지 않는다.

## Typography 적용

참조 화면이 실제 사용하는 텍스트 역할만 Figma 로컬 스타일과 `TextStyleToken`에 대응한다.
아래 여섯 토큰은 [디자인 토큰 정합 계약](./design-token-alignment.md)의 일치 항목이며,
`Caption 2`와 `ENG/Subtitle 3` 불일치는 참조 화면에서 사용하지 않으므로 이 표에 포함하지 않는다.

| 화면 역할 | 사용 위치 | Figma 스타일 | `TextStyleToken` | 검증 |
| --- | --- | --- | --- | --- |
| 화면 제목·빈 상태 제목 | `ScreenHeader`, `EmptyState` | `Subtitle 1` | `subtitle1` | 토큰 값 단위 테스트 + 사용처 정적 검토 |
| 실패·삭제 확인 제목 | `LearningProjectListView`, `SheetSurface` | `Subtitle 2` | `subtitle2` | 토큰 값 단위 테스트 + 사용처 정적 검토 |
| 프로젝트 이름 | `ProjectRow` | `Subtitle 3` | `subtitle3` | 토큰 값 단위 테스트 + 사용처 정적 검토 |
| 버튼 제목 | `ActionButton` | `Body 1` | `body1` | 토큰 값 단위 테스트 + 사용처 정적 검토 |
| 설명·세트 제목·태그·메뉴 | `LearningProjectListView`, `EmptyState`, `ProjectRow`, `TagBadge`, `ActionMenu` | `Body 2` | `body2` | 토큰 값 단위 테스트 + 사용처 정적 검토 |
| 프로젝트 보조 정보 | `ProjectRow` | `Caption 1` | `caption1` | 토큰 값 단위 테스트 + 사용처 정적 검토 |

UI 렌더 검증은 glyph 픽셀을 비교하지 않는다. 최대 Dynamic Type에서 텍스트가 잘리거나
겹치지 않는지 판정하고, 정적 계약과 단위 테스트가 Figma 스타일↔토큰 대응을 소유한다.

## edge dim 그라데이션

참조 화면 상태 노드 6개를 다시 조회한 결과 모두 `top dim`의 `문제풀이용` 변형과
`bottom dim`을 사용한다.

| 계약 ID | 대상 | 표시 크기 | 방향 | 정지점 | 근거 노드 |
| --- | --- | --- | --- | --- | --- |
| `project.edge.top` | 상단 dim | 360×103pt | 아래→위 | 0: `#141414` alpha 0, 0.25: alpha 0.5 | 변형 `1216:16440`, Rectangle `1216:16441` |
| `project.edge.bottom` | 하단 dim | 360×127pt | 위→아래 | 0.7: `#141414` alpha 0.6, 1: alpha 0 | 컴포넌트 `1216:16402`, Rectangle `1216:16399` |

상단 Rectangle의 원시 `gradientTransform`은
`[[0, -1, 1], [12.2160425, 0, -5.6080213]]`, 하단 Rectangle은
`[[0, 1, 0], [-9.6313915, 0, 5.3156958]]`다. 구현은 상단
`startPoint: .bottom`·`endPoint: .top`, 하단 `startPoint: .top`·
`endPoint: .bottom`으로 대응하고 정지점 위치를 그대로 보존한다. 하단 원본 컴포넌트의
기본 높이는 34pt지만 참조 화면 인스턴스 6개는 모두 127pt로 늘어나 있으므로 화면 계약은
127pt를 사용한다.

## 색·픽셀 판정 환경

- 토큰 단위 검증은 sRGB `RGBA`를 0...1 값으로 비교하며 채널별 허용치는 `1/255`다.
- 화면 렌더 검증은 `iPhone 17 Pro`, Dark appearance, 기본 Display Zoom에서 캡처하고 PNG를
  sRGB IEC 61966-2-1, 8-bit, 비선형 채널 값으로 정규화한다.
- 단색 면은 경계·문자·그림자에서 2pt 이상 떨어진 3×3pt 영역의 채널 중앙값을 사용하며
  기대 합성 결과와 R·G·B·A 각 `±1/255` 안에서 일치해야 한다.
- 반투명 scrim과 그라데이션은 알려진 배경 토큰 위 source-over 합성값을 계산해 같은 방식으로
  샘플링하고 렌더러 반올림을 고려해 R·G·B 각 `±2/255`, A `±1/255`를 허용한다. 안티앨리어싱
  경계, 텍스트 glyph, blur·shadow 픽셀은 판정 표본에서 제외한다.
- 불투명한 전체 화면 PNG의 alpha만으로 반투명도 값을 역산하지 않는다. alpha 자체는 토큰
  단위 검증에서 판정하고, 화면 검증은 위 합성 기대값으로 판정한다.

## 상호작용 계약

| 조작 | 이전 상태 | 다음 상태 | Use Case 호출 |
| --- | --- | --- | --- |
| 화면 진입 | idle | loading → loaded/empty/failed | `FetchLearningProjects` 1회 |
| 재시도 선택 | failed | loading → loaded/empty/failed | `FetchLearningProjects` 재호출 |
| 상단 메뉴 선택 | loaded/empty | menu | 없음 |
| 메뉴 바깥 선택 | menu | 이전 상태 | 없음 |
| 삭제 메뉴 선택 | menu | deleting | 없음 |
| 삭제 아이콘 선택 | deleting | confirmingDeletion | 없음 |
| 취소 선택 | confirmingDeletion | deleting | 없음 |
| 삭제 확인 | confirmingDeletion | deleting 또는 empty | `DeleteLearningProject` 1회 |
| 삭제 모드 종료 | deleting | loaded/empty | 없음 |
| 학습 시작 선택 | loaded | delegate 출력 | 없음 |

상호작용 컨트롤은 44×44pt 이상 터치 영역과 사용자 목적을 설명하는 VoiceOver 라벨을
가진다. 삭제 확인 버튼은 파괴적 의미를 라벨과 trait로 함께 전달한다.

## Dynamic Type

- 최대 접근성 글자 크기에서 제목·부제·세트 제목이 서로 겹치지 않는다.
- 두 줄 제한이 있는 제목은 잘리는 대신 정의된 줄 수 안에서 축약되고 접근성 값에는 전체
  문자열을 제공한다.
- 고정 높이 때문에 텍스트가 잘리는 경우 행은 세로로 확장할 수 있으며, 이때 150pt는 최소
  기준으로 해석한다. 360pt 기준 크기 검증과 최대 Dynamic Type 검증은 별도 시나리오다.

## 보류

Figma `BottomNavigationBar`와 현재 시스템 `TabView`의 형태 대응은 `research.md` R-13에
따라 보류한다. 참조 화면은 앱 루트에서 직접 도달 가능하게 하므로 이 결정이 화면 검증을
막지 않는다.
