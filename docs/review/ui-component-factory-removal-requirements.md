# UIComponent 팩토리 제거 요구사항

**상태**: 초안

**작성일**: 2026-09-20

**근거 시점**: branch `feature/feature-composition-refactor`, commit `e44b0fe`

**목적** — UIComponent의 정적 팩토리 메서드를 없애고, 변형 축을 `Style`·`Size` 같은 enum 파라미터로
받는 초기화 메서드 하나로 통일합니다.

**전제** — 햅틱 소유권 이전은 이 문서의 범위가 아닙니다. `ActionButton`의 탭 피드백은 이미
Feature의 `FeedbackActionButton`으로 옮겼고 UIComponent는 피드백을 발생시키지 않습니다.

## 1. 현상

UIComponent의 공개 생성 경로가 두 갈래입니다. 초기화 메서드가 `style:` 파라미터를 받는데도
같은 변형을 이름으로 고정한 정적 팩토리가 함께 공개돼 있고, 호출부는 대부분 팩토리를 씁니다.

```swift
public init(title: String, style: Style = .primary, size: Size = .large, ...)
public static func primary(_ title: String, size: Size = .large, ...) -> Self
public static func secondary(_ title: String, size: Size = .large, ...) -> Self
```

변형이 늘어날 때마다 팩토리가 `String` 변형과 `StyledText` 변형으로 2배씩 늘어나고, 기본값과
인자 순서가 두 경로에 중복됩니다. `ActionButton`은 팩토리 9개가 모두 같은 본문을 반복합니다.

### 1.1 대상 목록

| 파일 | 팩토리 | UI 내부 참조 | Feature·App 참조 |
| --- | --- | --- | --- |
| `Displays/StyledText.swift` | 10 (`headline1`~`caption2`) | 65 | 101 |
| `Controls/ActionButton.swift` | 9 (`primary`·`secondary`·`destructive`·`text`·`primaryText`) | 4 | 0 |
| `Controls/IconGlassButton.swift` | 3 (`neutral`·`accent`·`destructive`) | 13 | 11 |
| `Displays/TagBadge.swift` | 4 (`neutral`·`accent`·`selected`·`muted`) | 19 | 2 |
| `Displays/LabeledCard.swift` | 2 (`accent`·`neutral`) | 7 | 3 |
| `Overlays/ScreenEdgeScrim.swift` | 2 (`top`·`bottom`) | 5 | 0 |

`ActionButton`의 Feature 참조가 0인 것은 햅틱 이전 작업에서 31곳을 `FeedbackActionButton`
초기화 메서드로 이미 옮겼기 때문입니다. 이 문서의 나머지 대상은 아직 팩토리를 씁니다.

### 1.2 성격이 다른 두 선언

아래 둘은 생성 팩토리가 아니므로 이 요구사항의 대상이 아닙니다.

- `Scaffolds/TabShell/TabShellItem.swift`의 `tabColor(isSelected:)` — `ColorToken`을 돌려주는 계산
- `Displays/ResourceImage.swift`의 `resizable(_:)` — `Image` 값을 돌려주는 변환

## 2. 충돌하는 기존 규칙

[Typography 컨벤션](../conventions/view-tokens/typography.md)은 **"문자열 렌더링은 `Text`를 직접
구성하지 않고 `StyledText`의 Typography 팩토리를 사용합니다"**를 규칙으로 정하고 있습니다.
`StyledText`의 팩토리 10개는 이 규칙이 지정한 공개 경로이므로, 그것을 제거하려면 컨벤션 문서를
먼저 개정해야 합니다. 컨벤션을 그대로 둔 채 코드만 바꾸면
[Constitution 원칙 11](../../.specify/memory/constitution.md)의 근거 기반 설계와 어긋납니다.

`StyledText`는 나머지 대상과 성격도 다릅니다. `TextStyleToken`은 자간·행간·언어별 폰트 선택을
함께 결정하는 **의미 축**이고, `ActionButton.Style`은 배경·글자색을 고르는 **표현 축**입니다.
`StyledText.body2(text, color:)`를 `StyledText(text, style: .body2, color:)`로 바꾸는 것이 읽기
쉬워지는지는 별도로 판단해야 합니다.

## 3. 요구사항

- R1. `ActionButton`, `IconGlassButton`, `TagBadge`, `LabeledCard`의 정적 팩토리를 제거하고
  변형을 `style:` 파라미터로 받는 초기화 메서드만 공개합니다.
- R2. `ScreenEdgeScrim`의 `top`·`bottom`은 대응하는 enum(예: 가장자리 축)을 먼저 정의한 뒤
  파라미터로 전환합니다. 현재는 파라미터로 표현할 enum이 없습니다.
- R3. `StyledText`는 R1과 분리해 결정합니다. 제거를 선택하면 Typography 컨벤션을 같은 변경에서
  개정하고, 유지를 선택하면 유지 근거를 컨벤션에 남깁니다.
- R4. 호출부 전환은 패키지 경계를 넘는 하나의 불가분한 변경입니다. UI의 공개 API 제거와
  Feature·App 호출부 수정이 같은 커밋 단위에 들어가야 중간 상태가 compile됩니다
  ([Constitution 원칙 7](../../.specify/memory/constitution.md)의 integration unit).
- R5. 전환 후 전체 build·compile·test가 통과해야 하며, 화면 표현은 변하지 않아야 합니다.

## 4. 범위와 위험

- 변경 파일: UI 6개 + 호출부 약 130곳(`StyledText` 제외 시 약 30곳)
- 공개 API 제거이므로 되돌리기 비용이 높습니다. 팩토리를 `@available(*, deprecated)`로 먼저
  표시하고 호출부를 옮긴 뒤 제거하는 2단계도 선택지입니다.
- 프리뷰와 테스트의 호출부도 같은 범위에 포함됩니다.

## 5. 후속

이 문서는 요구사항만 정의합니다. 실행은 `$speckit-specify`로 기능을 만들고
`$speckit-plan`·`$speckit-tasks`가 컨벤션 문서를 근거로 커밋 단위를 설계한 뒤
`$speckit-implement`가 수행합니다.
