# 계약: 디자인 토큰 적용 API

**입력**: [data-model.md](../data-model.md), [research.md](../research.md)

이 기능은 서버·클라이언트 API가 아닌 Swift 라이브러리이므로, 계약은 `DesignSystem`
타겟이 다른 패키지(주로 Feature)에 공개하는 Swift 공개 API 서명입니다. 이 서명은
`sources/Projects/UI/DesignSystem/Application/`에 구현하며, FR-014~FR-017을 만족해야
합니다.

## 텍스트 스타일 적용 (FR-014, FR-015)

```swift
extension View {
    /// 글꼴·굵기·크기·행간·자간을 한 번에 적용한다. 문자열 내 한글·기본 문자는
    /// Noto Sans, 영문 알파벳은 Plus Jakarta Sans가 문자 단위로 적용된다(FR-010).
    public func tokenTextStyle(_ name: TextStyleToken.Name) -> some View
}
```

**사전조건**: 없음(모든 `TextStyleToken.Name` 케이스가 유효).
**사후조건**: 반환된 View는 `DesignTokenSet.current.textStyles[name]`의 굵기·크기·행간·
자간이 모두 반영된 상태다. 개별 속성을 별도로 지정할 필요가 없다(FR-015).

## 전경색·배경색 적용 (FR-014)

```swift
extension View {
    public func tokenForeground(_ name: ColorToken.Name) -> some View
    public func tokenBackground(_ name: ColorToken.Name) -> some View
}
```

**사후조건**: 지정한 `ColorToken`의 `RGBAComponents`가 `SwiftUI.Color(.sRGB, red:green:
blue:opacity:)`로 변환되어 적용된다.

## 그라데이션 배경 적용 (FR-008a, FR-014)

```swift
extension View {
    public func tokenGradientBackground(_ name: GradientToken.Name) -> some View
}
```

**사후조건**: `GradientToken.start`·`end`가 `UnitPoint(x:y:)`로 그대로 대응되어(research.md
§5), 요소 크기와 무관하게 상대 위치가 유지되는 `LinearGradient`가 배경으로 적용된다.

## 레이아웃 여백 적용 (FR-013, FR-014)

```swift
extension View {
    /// 화면 좌우 여백(Margin, 20)을 적용한다.
    public func tokenScreenMargin() -> some View

    /// 요소 사이 간격(Gutter, 12)만큼의 Spacing 값을 반환한다.
    public static var tokenGutter: CGFloat { get }
}
```

## 값 모델 직접 접근 (사용자 스토리 3, FR-001)

화면 구성 없이 값을 검증하기 위한 읽기 전용 진입점. `Token/` 폴더에 위치하며 SwiftUI에
의존하지 않는다.

```swift
public enum DesignTokenSet {
    public static let current: DesignTokenSetValue
}
```

`DesignTokenSetValue`(data-model.md의 `DesignTokenSet`)는 `colors` `gradients`
`fontFamilies` `textStyles` `layouts` 딕셔너리를 그대로 노출해, 테스트가 `Name.allCases`
와 대조할 수 있게 한다.

## 계약 검증 방법 (Story 3 대응)

- 위 API는 모두 `DesignSystemTests`(신규 unitTests 타겟)에서 시뮬레이터·렌더링 없이
  타입 수준으로 호출 가능성과 반환 값을 검증한다.
- `tokenTextStyle`/`tokenForeground`/`tokenBackground`/`tokenGradientBackground`는
  SwiftUI `View` 프로토콜 반환 타입이라 직접 렌더링 결과 비교는 계약 범위 밖이며,
  "컴파일된다 + 내부적으로 올바른 토큰 값을 참조한다"까지만 이 계약이 보장한다. 실제
  픽셀 일치는 사용자 스토리 1의 수동/스냅샷 검증(quickstart.md) 영역이다.
