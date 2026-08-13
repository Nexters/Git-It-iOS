# 데이터 모델: 디자인 토큰 시스템

**입력**: [spec.md 핵심 엔터티](./spec.md#핵심-엔터티), [research.md](./research.md)

모든 타입은 `sources/Projects/UI/DesignSystem/Token/`에 위치하며 `Foundation`만
import합니다(`SwiftUI` import 금지, FR-001·FR-017). 이름 뒤 괄호는 Swift 타입/케이스
이름이며, 디자인 문서 표기는 `displayName`으로 별도 보관합니다(research.md §3).

## RGBAComponents

색상 원시 값. 다른 엔터티가 값으로 포함합니다.

| 필드 | 타입 | 설명 |
|---|---|---|
| `red`, `green`, `blue` | `Double`(0...1) | sRGB 컴포넌트 |
| `alpha` | `Double`(0...1) | 불투명도. 기본 1.0 |

**검증 규칙**: 네 값 모두 0...1 범위(`FR-006` 불투명도 토큰 포함).

## ColorToken

| 필드 | 타입 | 설명 |
|---|---|---|
| `name` (case) | `ColorToken.Name` | Swift 식별자(예: `.blue500`, `.white15`) |
| `displayName` | `String` | 디자인 문서 표기(예: `"Blue500"`, `"white 15"`) |
| `group` | `ColorToken.Group` | `.blue` `.purple` `.grey` `.opacity` `.state` |
| `value` | `RGBAComponents` | 색상 값 |

**관계**: `GradientToken`의 정지점(stop)이 색상 값으로 참조. `TextStyleToken`은 참조하지
않음(텍스트 색은 적용 시점에 별도 `ColorToken`으로 지정, FR-014).

**검증 규칙(FR-005~FR-007)**: `Name`의 모든 케이스가 정확히 24개(Blue 5·Purple 5·Grey
7·Opacity 4·State 3)이고, 각 값이 명세 표에 명시된 hex/불투명도와 일치해야 한다(SC-001,
SC-005).

**엔터티 정체성**: 서로 다른 `Name` 케이스가 동일한 `value`를 가질 수 있다(예: `grey100`
`#FFFFFF`와 `white70`의 불투명도 없는 `#FFFFFF` 성분은 다르지만, 이름이 다르면 값이
같아도 별개 토큰으로 취급한다). 식별의 기준은 항상 `name`이며 `value`가 아니다.

## GradientToken

| 필드 | 타입 | 설명 |
|---|---|---|
| `name` (case) | `GradientToken.Name` | `.gradient1` `.gradient2` `.gradient3` |
| `displayName` | `String` | `"Gradient 1"` 등 |
| `kind` | `GradientToken.Kind` | 이번 범위에서는 `.linear` 고정(FR-008) |
| `start`, `end` | `UnitPointRatio`(`x: Double`, `y: Double`, 0...1) | 방향 좌표비율(FR-008a) |
| `stops` | `[GradientStop]` | 정지점 목록(위치 오름차순) |

### GradientStop

| 필드 | 타입 | 설명 |
|---|---|---|
| `position` | `Double`(0...1) | 정지점 위치(0%, 100%) |
| `color` | `RGBAComponents` | 정지점 색상 |

**검증 규칙**: `stops.count == 2`, 첫 정지점 `position == 0`, 마지막 `position == 1`
(FR-008). `start`·`end` 기본값은 세 토큰 모두 `(0.5, 0)` → `(0.5, 1)`(FR-008a).

## FontFamilyToken

| 필드 | 타입 | 설명 |
|---|---|---|
| `name` (case) | `FontFamilyToken.Name` | `.notoSans` `.plusJakartaSans` |
| `postScriptName` | `String` | 실제 글꼴 리소스 이름 |
| `scriptScope` | `FontFamilyToken.ScriptScope` | `.korean`(한글), `.english`(영문 알파벳). 기본 문자에는 적용 계층이 `Noto Sans`를 선택(FR-010) |

**관계**: `TextStyleToken.fontFamilyPair`가 두 케이스를 고정 쌍으로 참조. 개별
`TextStyleToken`이 하나만 선택하지 않는다(문자 단위 판별은 적용 시점 책임, FR-010·
research.md §7).

## TextStyleToken

| 필드 | 타입 | 설명 |
|---|---|---|
| `name` (case) | `TextStyleToken.Name` | `.headline1` … `.caption2`(10종) |
| `displayName` | `String` | `"Headline 1"` 등 |
| `fontFamilyPair` | `(hangul: FontFamilyToken.Name, latin: FontFamilyToken.Name)` | 항상 `(.notoSans, .plusJakartaSans)` 고정 |
| `weight` | `TextStyleToken.Weight` | `.bold` `.medium` `.regular` |
| `sizeInPoints` | `Double` | pt 단위(FR-009) |
| `lineHeightPercent` | `Double` | 백분율의 소수 표현(150% → `1.5`). 실제 행 높이로의 변환은 보유하지 않음(FR-011) |
| `letterSpacingPercent` | `Double` | 모든 스타일에서 `0`(FR-009) |
| `paragraphSpacing` | `Double` | 모든 스타일에서 `0` |
| `paragraphIndent` | `Double` | 모든 스타일에서 `0` |

**검증 규칙(FR-009)**: 10개 케이스 전량 존재, 각 `weight`·`sizeInPoints`·
`lineHeightPercent`가 명세 표와 일치(SC-001, SC-005). `lineHeightPercent`는 저장만 하고
pt 변환 로직을 포함하지 않는다(FR-011 위반 방지).

## LayoutToken

| 필드 | 타입 | 설명 |
|---|---|---|
| `name` (case) | `LayoutToken.Name` | `.margin` `.gutter` |
| `value` | `Double` | `margin = 20`, `gutter = 12`(FR-013) |

## DesignTokenSet

토큰 전체를 하나로 묶는 교체 단위(FR-020, FR-022).

| 필드 | 타입 | 설명 |
|---|---|---|
| `colors` | `[ColorToken.Name: ColorToken]` | 24개 전량 |
| `gradients` | `[GradientToken.Name: GradientToken]` | 3개 전량 |
| `fontFamilies` | `[FontFamilyToken.Name: FontFamilyToken]` | 2개 전량 |
| `textStyles` | `[TextStyleToken.Name: TextStyleToken]` | 10개 전량 |
| `layouts` | `[LayoutToken.Name: LayoutToken]` | 2개 전량 |

**정적 접근점**: `DesignTokenSet.current: DesignTokenSet` 하나만 공개 API로 노출한다.
사용처는 이 상수를 거치지 않고 각 토큰 `Name` 케이스로 직접 참조한다(적용 수단이 내부적
으로 `DesignTokenSet.current`를 조회, FR-020 "사용처의 토큰 참조 방식은 동일하게
유지").

**불변 규칙**: 인스턴스는 하나만 존재(전역 `var`가 아닌 `let` 상수). 런타임에 다른
`DesignTokenSet`으로 교체하는 API를 제공하지 않는다(FR-022 "실행 중 사용처가 집합을
선택하도록 해서는 안 된다").

## 존재하지 않는 토큰 참조 처리 (FR-004)

모든 `Name` 타입은 `CaseIterable`을 준수하는 Swift `enum`으로 정의한다. 문자열 키가 아닌
enum 케이스로 참조하므로 존재하지 않는 이름은 애초에 컴파일되지 않는다(빌드 시점 검출,
FR-004·FR-019). `DesignTokenSet`의 각 딕셔너리는 `Name.allCases`를 순회해 빠짐없이
채워지는지 사용자 스토리 3의 테스트가 검증한다(SC-001, SC-007).
