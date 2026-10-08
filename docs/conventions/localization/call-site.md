# 호출부

[Git It iOS 현지화 컨벤션](../localization.md)의 규칙 문서입니다.

**사용자 노출 문구는 `LocalizedText.<흐름>[.<화면>][.<주제>][.<요소>].<용도>`로만 얻습니다.** production 소스에서 한국어 문자열
리터럴, 생성 심볼, `String(localized:)`, `LocalizedStringKey` 리터럴을 `LocalizedText` 밖에서 직접
쓰지 않습니다.

```swift
StyledText(text: LocalizedText.Settings.title)
    .textStyle(.title2)

StyledText(text: LocalizedText.Settings.Profile.title)

ActionButton(title: LocalizedText.MainShell.SingleQuestion.FailureConfirm.buttonTitle)
```

- View `Constant`는 현지화 문구를 소유하지 않습니다. 한 View에서만 쓰는 문구라도 `LocalizedText`에
  둡니다([`Constant`](../view-declarations/constant.md)).
- 표시 모델(`ViewModels/`)과 Reducer가 사용자 노출 문구를 만들 때도 `LocalizedText`를 씁니다.
- `UIComponent` 공개 입력은 `String`입니다. Feature는 `LocalizedText`로 얻은 `String`을 넘기고,
  `UIComponent`는 내부 고정 문구를 스스로 조회합니다. 현지화를 이유로 컴포넌트 공개 API를 바꾸지
  않습니다.
- SwiftUI `Text`·`Button`·`alert` 등에는 `String` 값을 넘깁니다. `Text("리터럴")`로 문구를 넘기지
  않습니다. `String` 값은 SwiftUI가 키로 다시 조회하지 않습니다.
