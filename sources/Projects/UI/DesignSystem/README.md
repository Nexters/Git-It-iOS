# DesignSystem

Git-It의 프레임워크 비의존 디자인 토큰 값 모델과 SwiftUI 적용 계층을 제공하는 대상입니다.
`UIComponent`를 포함해 `UI` 패키지 밖의 다른 프로젝트 내부 패키지에는 의존하지 않습니다.

## 토큰 카테고리

`Token/`은 SwiftUI를 import하지 않는 순수 Swift 값 타입입니다.

| 카테고리 | 파일 | 원천 |
| --- | --- | --- |
| 색상 | `ColorToken.swift` | `specs/002-design-token-system` FR-005~FR-007 (24종) |
| 그라데이션 | `GradientToken.swift` | 같은 명세 FR-008·FR-008a (3종) |
| 글꼴 패밀리 | `FontFamilyToken.swift` | 같은 명세 FR-010 |
| 텍스트 스타일 | `TextStyleToken.swift` | 같은 명세 FR-009 (10종) |
| 레이아웃 | `LayoutToken.swift` | 같은 명세 FR-013 (`Margin`, `Gutter`) |
| 불투명도 | `OpacityToken.swift` | `specs/003-common-ui-components` FR-007 (Figma 확인 대기, 현재 비어 있음) |
| 모서리 | `CornerRadiusToken.swift` | 같은 명세 FR-007 (Figma 확인 대기, 현재 비어 있음) |
| 선 | `BorderToken.swift` | 같은 명세 FR-007 (Figma 확인 대기, 현재 비어 있음) |
| 효과 | `EffectToken.swift` | 같은 명세 FR-007 (Figma 확인 대기, 현재 비어 있음) |
| 제어 크기 | `ControlSizeToken.swift` | 같은 명세 FR-007 (Figma 확인 대기, 현재 비어 있음) |

`DesignTokenSet.active`가 위 10개 카테고리를 취합한 유일한 활성 집합입니다.
`DesignTokenSet.validate()`로 화면 렌더링 없이 이름 유일성·값 범위·참조 무결성을 검사할
수 있습니다.

## 적용 계층

`Application/`은 SwiftUI 뷰 모디파이어로 토큰을 화면에 연결합니다. 값 모델(`Token/`)은
이 계층을 참조하지 않으며, 의존 방향은 항상 `Token/ ← Application/ ← UIComponent`입니다.

| 모디파이어 | 대상 |
| --- | --- |
| `Text.designSystemStyled(_:style:)` | `TextStyleToken` — 글꼴·굵기·크기·자간을 한 번에 적용, 문자 단위 한글/영문 글꼴 전환 |
| `View.designSystemLineSpacing(_:)` | `TextStyleToken` — 행간 백분율을 SwiftUI 줄 간격으로 변환하는 유일한 지점 |
| `View.designSystemForeground(_:)` / `designSystemBackground(_:)` | `ColorToken` |
| `View.designSystemBackground(_:)` (`GradientToken` 오버로드) | `GradientToken` |
| `LayoutToken.cgFloatValue`, `View.designSystemScreenMargin(_:)` | `LayoutToken` |
| `View.designSystemCornerRadius(_:)` | `CornerRadiusToken` |
| `View.designSystemBorder(_:)` | `BorderToken` |
| `View.designSystemEffect(_:)` | `EffectToken` |
| `View.designSystemControlSize(_:)` | `ControlSizeToken` |

`Font/`에 번들된 Noto Sans KR·Plus Jakarta Sans 정적 TTF(Regular/Medium/Bold)는
`FontRegistration.registerBundledFonts`가 프로세스 스코프에 1회 등록하며,
`Text.designSystemStyled(_:style:)`가 렌더링 전 이를 트리거합니다.

## 소비 규칙

- 사용처는 원시 색상 값·글꼴 이름·수치를 직접 기재하지 않고 토큰 이름으로만 참조합니다.
- 활성 집합은 `DesignTokenSet.active` 하나뿐이며, 임의의 팔레트를 주입할 수 없습니다.
- 신규 토큰(불투명도·모서리·선·효과·제어 크기)은 Figma 확인 전까지 비어 있습니다. 값이
  채워지기 전에는 해당 적용 모디파이어를 호출하는 소비 코드를 추가하지 마세요.
