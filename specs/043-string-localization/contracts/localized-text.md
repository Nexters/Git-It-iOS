# 계약: 모듈별 문구 전용 타입 `LocalizedText`

**기능**: [spec.md](../spec.md) | **데이터 모델**: [data-model.md](../data-model.md)

모듈 내부 계약이다. `internal`이므로 다른 모듈의 공개 API에는 나타나지 않는다.

## 형태

```swift
// Feature/Shared/Localization/LocalizedText.swift
enum LocalizedText {}

// Feature/Shared/Localization/LocalizedText+Settings.swift
extension LocalizedText {
    enum Settings {
        static var title: String { String(localized: .Settings.settingsTitle) }
        static func profileJoinedDays(count: Int) -> String {
            String(localized: .Settings.profileJoinedDays(count: count))
        }
    }
}
```

위 코드는 선언 형태를 보여 주는 예시이며 키 이름은 실제 문구에 맞춰 정한다. 생성 심볼의 정확한
이름·인자 레이블은 [research.md R1](../research.md#위험과-확인-절차) 확인 결과를 따른다.

## 규칙

1. `LocalizedText`는 case와 인스턴스 멤버가 없는 `enum`이다.
2. 중첩 enum 하나는 카탈로그 테이블 하나 또는 그 테이블 안의 컴포넌트·기능 묶음에 대응한다.
   - `Feature`: 흐름 이름과 같은 중첩 enum이 같은 이름의 테이블을 조회한다.
   - `UIComponent`: `Localizable` 테이블을 쓰고 중첩 enum은 컴포넌트 이름(`WebSheet`, `ScreenControlBar` 등)으로 나눈다.
   - `GitIt`: `Localizable` 테이블을 쓰고 중첩 enum은 기능 이름(`GenerationReminder`)으로 나눈다.
3. 멤버는 항목마다 하나다. 멤버 이름은 키에서 중첩 enum 이름에 해당하는 첫 단어를 뗀 나머지를 lowerCamelCase로
   쓴 것이다. 첫 단어가 중첩 enum 이름과 다르면 키를 그대로 쓴다.
   - `Feature`: 중첩 enum이 흐름(`Settings`)이고 키의 첫 단어는 화면(`profile…`)이므로 대부분 키와 같다.
     흐름과 이름이 같은 화면의 키(`settingsTitle`)만 `title`이 된다.
   - `UIComponent`: 키 `webSheetCloseAccessibilityLabel` → `LocalizedText.WebSheet.closeAccessibilityLabel`
   - `GitIt`: 키 `generationReminderCompletedTitle` → `LocalizedText.GenerationReminder.completedTitle`

   인자가 없으면 `static var ...: String`, 있으면 `static func ...(...) -> String`이다. 본문은 생성 심볼을
   `String(localized:)`로 해석하는 식 하나다.
4. 멤버는 값을 저장하지 않는다(`static let` 금지). 조회는 호출 시점에 한다.
5. 호출부는 `LocalizedText.<중첩>.<멤버>`로만 사용자 노출 문구를 얻는다. View `Constant`, 표시 모델,
   Reducer는 한국어 리터럴이나 생성 심볼을 직접 두지 않는다.
6. 멤버에 서버·사용자 입력 값을 키로 넘기는 API를 두지 않는다. 동적 값은 보간 인자로만 받는다(FR-006).
7. 컴포넌트 공개 입력(`String`)과 초기화 인자·메서드 계약은 바꾸지 않는다(FR-015).

## 호출 예시

```swift
StyledText(text: LocalizedText.Settings.title)
    .textStyle(.title2)

.accessibilityLabel(LocalizedText.ScreenControlBar.backAccessibilityLabel)
```

`Text(_:)`에 `String` 값을 넘기면 SwiftUI는 그 값을 키로 다시 조회하지 않는다. 한국어 리터럴을
`Text("…")`로 직접 넘기는 코드는 남기지 않는다.
