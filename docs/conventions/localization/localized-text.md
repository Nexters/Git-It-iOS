# `LocalizedText`

[Git It iOS 현지화 컨벤션](../localization.md)의 규칙 문서입니다.

**문구를 쓰는 target마다 case와 인스턴스 멤버가 없는 `internal enum LocalizedText` 하나를 둡니다.**

| target | 위치 | 중첩 enum |
| --- | --- | --- |
| `Feature` | 루트는 `Feature/Shared/Localization/LocalizedText.swift`, 흐름마다 `Feature/Shared/Localization/LocalizedText+<흐름>.swift` | 테이블(흐름) 이름 |
| `UIComponent` | `UI/Component/Localization/LocalizedText.swift` 한 파일 | 컴포넌트 이름 |
| `GitIt` | `App/GitIt/Localization/LocalizedText.swift` 한 파일 | 기능 이름 |

`Feature`의 흐름별 파일은 `extension LocalizedText { enum <흐름> { … } }`만 선언합니다.

**항목마다 멤버 하나를 둡니다.** 멤버 이름은 키에서 중첩 enum 이름과 같은 첫 단어를 뗀 이름이며,
첫 단어가 다르면 키를 그대로 씁니다.

- `webSheetCloseAccessibilityLabel` → `LocalizedText.WebSheet.closeAccessibilityLabel`
- `Settings` 흐름의 `settingsTitle` → `LocalizedText.Settings.title`
- `Settings` 흐름의 `profileTitle` → `LocalizedText.Settings.profileTitle`

인자가 없으면 `static var <멤버>: String`, 인자가 있으면 `static func <멤버>(<인자>) -> String`입니다.

**멤버 본문은 생성 심볼을 `String(localized:)`로 해석하는 식 하나입니다.** 기본 테이블
(`Localizable`)의 심볼은 `.<key>`, 그 밖의 테이블은 `.<테이블>.<key>`입니다. 값을 저장하는
`static let`을 쓰지 않고 호출 시점에 조회합니다.

```swift
enum LocalizedText {
    enum WebSheet {
        static var closeAccessibilityLabel: String {
            String(localized: .webSheetCloseAccessibilityLabel)
        }
    }

    enum ProjectRow {
        static func deleteAccessibilityLabel(name: String) -> String {
            String(localized: .projectRowDeleteAccessibilityLabel(name: name))
        }
    }
}
```

```swift
extension LocalizedText {
    enum Settings {
        static var title: String {
            String(localized: .Settings.settingsTitle)
        }
    }
}
```

- `LocalizedText`는 동적 문자열을 키로 받는 멤버를 두지 않습니다.
- `LocalizedText`와 그 확장은 문자열 조회만 하며 흐름·화면 타입을 참조하지 않습니다. 그래서 흐름별
  확장을 `Feature/Shared/`에 두어도 `Feature/Shared/**`의 참조 방향 제약을 지킵니다.
