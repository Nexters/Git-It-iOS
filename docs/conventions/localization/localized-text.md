# `LocalizedText`

[Git It iOS 현지화 컨벤션](../localization.md)의 규칙 문서입니다.

**문구를 쓰는 target마다 case와 인스턴스 멤버가 없는 `internal enum LocalizedText` 하나를 둡니다.**

- 위치는 그 target 소스 루트의 `Localization/LocalizedText.swift`입니다.
- 여러 흐름을 한 target에 담는 `Feature` 패키지는 루트를 `Feature/Shared/Localization/LocalizedText.swift`에
  두고, 흐름마다 `LocalizedText+<흐름>.swift` 확장 파일을 둡니다. 중첩 구조는 흐름 > 화면·서브뷰입니다.
- 흐름이 없는 target은 `LocalizedText.swift` 한 파일에 둡니다.

## 중첩 규칙 (`Feature`)

- 흐름 enum 이름은 `Feature/<흐름>/` 폴더 이름과 같습니다.
- 흐름 화면 자체의 문구는 흐름 enum 아래에 둡니다 → `LocalizedText.Example.title`.
- 흐름 안 화면·서브뷰의 문구는 그 이름의 중첩 enum 아래에 둡니다 →
  `LocalizedText.Example.Detail.title`, `LocalizedText.Example.SummaryCard.LastWeek.label`.
- 흐름 enum에 직접 둘 멤버가 없으면 이름공간으로만 둡니다(`enum <흐름> { }`).
- 흐름 파일 하나가 `extension LocalizedText { enum <흐름> { … } }`로 그 흐름의 화면 enum까지 모두
  중첩해 선언합니다. 화면마다 파일을 나누지 않습니다. 흐름 enum 안의 순서는 흐름 자체 멤버, 흐름의
  주제 enum, 화면 enum입니다.
- 흐름이 없는 target은 컴포넌트 또는 기능 이름 enum 아래에 둡니다 →
  `LocalizedText.ExampleButton.title`, `LocalizedText.ExampleReminder.Done.title`.

## 주제·요소·용도 분할

**화면·컴포넌트·기능 enum 아래 경로는 `<주제>.<요소>.<용도>`입니다.** 문구 이름을 다음 순서로
나눕니다.

1. **용도**: 끝의 표시 위치 어휘입니다. `buttonTitle`, `title`, `message`, `label`, `description`,
   `reason`, `value`, `placeholder`, `caption`, `guidance`, `badge`, `body`, `step`, `paragraph`,
   `line`, `range`, `metadata`, `version`, `count` 중 가장 긴 일치를 쓰며 멤버 이름이 됩니다.
2. **주제**: 같은 enum 안에서 첫 단어가 같은 멤버가 둘 이상이면, 그 멤버들의 공통 접두어가 주제
   enum이 됩니다.
3. **요소**: 주제와 용도 사이에 남은 단어 전체가 요소 enum 하나가 됩니다. 남은 단어가 없으면 멤버를
   주제 enum에 바로 둡니다.

주제 없이 단독인 멤버는 `<요소>.<용도>`, 용도만 남으면 소속 enum의 멤버가 됩니다.

| 문구 | 경로 |
| --- | --- |
| 상세 화면 오류 제목 | `LocalizedText.Example.Detail.Error.title` |
| 상세 화면 오류 확인 버튼 | `LocalizedText.Example.Detail.ErrorDismiss.buttonTitle` |
| 권한 필요 알림 제목 | `LocalizedText.Example.PermissionRequired.title` |
| 요약 탭 제목 | `LocalizedText.Example.Pane.Summary.title` |
| 목록 화면 다시 불러오기 버튼 | `LocalizedText.ExampleList.Reload.buttonTitle` |
| 목록 화면 제목 | `LocalizedText.ExampleList.title` |

- 공통 접두어가 의미 단위를 쪼개면 의미 단위를 주제로 씁니다. 예: `lastWeekLabel`·`lastMonthLabel`은
  `Last.Week`가 아니라 `LastWeek.label`·`LastMonth.label`입니다.
- 주제·요소 enum 이름이 같은 흐름의 화면 enum과 같으면 그 화면 enum에 합칩니다. 예: `Example` 흐름
  화면의 상세 행 레이블(`detailLabel`)은 주제 `Detail`이 같은 흐름의 `Detail` 화면 enum과 같으므로
  `LocalizedText.Example.Detail.label`로 그 화면 enum에 둡니다.
- 주제·요소 enum은 소속 흐름 파일(Feature) 또는 `LocalizedText.swift`(흐름이 없는 target) 안에
  중첩하며 파일로 나누지 않습니다.

## 멤버

**항목마다 멤버 하나를 둡니다.** 멤버 이름은 위 분할의 용도입니다. 인자가 없으면
`static var <용도>: String`, 인자가 있으면 `static func <용도>(<인자>) -> String`이며 인자 레이블은
생성 심볼의 인자 레이블과 같게 둡니다.

**멤버 본문은 생성 심볼을 `String(localized:)`로 해석하는 식 하나입니다.** 키는 멤버 경로와 같고
([키](./key.md)), 심볼은 그 경로의 점을 없앤 lowerCamelCase입니다. 값을 저장하는
`static let`을 쓰지 않고 호출 시점에 조회합니다.

```swift
// Feature/Shared/Localization/LocalizedText+Example.swift
extension LocalizedText {
    enum Example {
        static var title: String {
            String(localized: .exampleTitle)
        }

        enum Detail {
            static var title: String {
                String(localized: .exampleDetailTitle)
            }

            enum Summary {
                enum Done {
                    static func title(count: Int) -> String {
                        String(localized: .exampleDetailSummaryDoneTitle(count: count))
                    }
                }
            }
        }
    }
}
```

- `LocalizedText`는 동적 문자열을 키로 받는 멤버를 두지 않습니다.
- `LocalizedText`와 그 확장은 문자열 조회만 하며 흐름·화면 타입을 참조하지 않습니다. 그래서 흐름별
  확장을 `Feature/Shared/`에 두어도 `Feature/Shared/**`의 참조 방향 제약을 지킵니다.
