# 계약: 디자인 토큰 카탈로그

**소유 target**: `DesignSystem` · **소비자**: `UIComponent`, `Feature`

토큰 카탈로그는 UI 계층이 외부에 노출하는 값 계약이다. 이름은 규격 문서가 확정한 고정
명칭이므로 원문을 보존한다(Constitution 원칙 10의 외부 고정 명칭 규정).

## 카탈로그 불변식

- 각 카테고리는 `all` 배열로 전체 목록을 노출하며 빈 배열이 아니다.
- `DesignTokenSet.current.validate()`는 위반 목록을 반환하고, 규격을 지키면 빈 배열이다.
- 토큰 이름은 카테고리 안에서 유일하다.
- 역할 토큰이 참조하는 원시 토큰은 반드시 원시 카테고리의 `all`에 존재한다.

## 신설 — `BorderToken` (6)

| 이름 | 굵기 | 참조 색 | 용도 |
| --- | --- | --- | --- |
| `default` | 1 | `grey500` | 학습세트 항목, 모달 표면, 텍스트 필드 기본 |
| `focus` | 1 | `blue100` | 선택된 항목·카드, 활성 입력, 북마크 채움 |
| `highlight` | 1 | `blue200` | 토글 활성 표면 |
| `error` | 1 | `error` | 입력 오류 |
| `tabBar` | 1 | `blue300Alpha24` | 하단 탭바 알약 테두리 |
| `loadingTrack` | 4 | `grey400` | 로딩 스피너 트랙 |

## 신설 — `OpacityToken` (6)

| 이름 | 값 | 용도 |
| --- | --- | --- |
| `subtleSurface` | 5% | 글래스 버튼 배경, 선택 항목 오버레이 |
| `tabSurface` | 10% | 탭바 알약 표면 |
| `track` | 15% | 진행률 바 트랙 |
| `border` | 24% | 탭바 알약 테두리 |
| `disabled` | 30% | 비활성 라벨, placeholder |
| `scrim` | 70% | 모달 딤 |

## 신설 — `EffectToken` (2)

| 이름 | 종류 | 레이어 |
| --- | --- | --- |
| `sheetElevation` | dropShadow | `black45` (0,4) blur 6 → `black35` (0,4) blur 34 |
| `cardElevation` | dropShadow | `black25` (4,4) blur 15 spread 10 |

레이어는 가까운 것부터 순서대로 담는다. SwiftUI radius 환산(Figma blur의 1/2)과 spread 흡수는
적용 확장의 책임이며 토큰 값은 규격 원본을 보존한다.

## 추가 — `ColorToken` (+5)

`black25` · `black35` · `black45` · `blue300Alpha10`(rgba 126,148,187,0.10) ·
`blue300Alpha24`(rgba 126,148,187,0.24)

## 추가 — `SemanticColorToken` (+5)

| 이름 | 참조 | 용도 |
| --- | --- | --- |
| `tabBarSurface` | `blue300Alpha10` | 하단 탭바 알약 표면 |
| `tabBarBorder` | `blue300Alpha24` | 하단 탭바 알약 테두리 |
| `selectedSurface` | `white5` | 선택된 리스트 항목 오버레이 |
| `grabber` | `grey500` | 시트 상단 그래버 |
| `disabledText` | `white30` | 비활성 라벨 |

## 추가 — 간격·반경·크기

- `LayoutToken`: `cardHorizontalPadding` 18 · `cardTopPadding` 14 · `iconSpacing` 6 ·
  `tightSpacing` 4
- `CornerRadiusToken`: `pill` 999 — 숫자를 직접 쓰지 않고 알약 도형으로 표현한다
- `ControlSizeToken`: `minimumTouch` 44

## 정리 — `GradientToken`

`GradientToken.all`은 규격 목록 5종(`gradient1` · `gradient2` · `gradient3` · `topEdgeScrim` ·
`bottomEdgeScrim`)과 이미 일치한다. 값 변경이 필요 없다.

남은 항목은 `gradient4` 하나다. public으로 정의되어 있으나 `all`에 포함되지 않고
`sources/Projects` 전체 사용처가 0건이므로 제거 대상이며, 삭제는 되돌리기 어려우므로 실행 전에
확인을 받는다.

`topToBottomStart` · `topToBottomEnd`는 `private static let`으로 선언된 `UnitPointRatio` 방향
상수(x 0.5, y 0 / x 0.5, y 1)이지 토큰이 아니다. 공개 계약이 아니므로 규격 대조 대상이 아니고
이름을 바꾸지 않는다. `reference-swift/GradientToken.swift`도 같은 두 상수를
`private static let`으로 두고 이름만 `topStart` · `bottomEnd`로 쓴다 — 값이 같고 둘 다
`private`이라 렌더링 결과가 같으므로 이름을 맞추지 않는다. 규격 토큰 목록에는 두 이름 모두
없다.

## 범위 밖 — 타이포와 폰트

`TextStyleToken`(13종)과 `FontFamilyToken`(2종)은 이 계약의 변경 대상이 아니다. 타이포 적용
규칙과 폰트 설정은 현행 구현을 유지한다(spec 명확화 세션 2차). 두 토큰은
`DesignTokenSet.validate()`의 검사 대상에는 포함되지만 값과 구성을 바꾸지 않는다.

규격과 어긋나는 것으로 확인된 두 지점(숫자가 라틴 폰트로 렌더되지 않음, 번들하지 않는 폰트
자산 잔존)은 spec의 "알려진 차이"에 기록되어 있으며 이 기능의 성공 기준에서 제외한다.

## 호환성

이 계약은 기존 공개 계약을 바꾼다 — `TextField` 재작도와 골격 컴포넌트(`ScreenEdgeScrim` ·
`TabShell` · `SheetSurface`)의 인자 변경이 그 예다. `GradientToken`의 이름 변경은 없다.
deprecated 별칭을 남기지 않으며, 깨진 호출부는 같은 변경 단위에서 복구한다(spec FR-040).
