# 키

[Git It iOS 현지화 컨벤션](../localization.md)의 규칙 문서입니다.

**키는 `LocalizedText` 경로와 같은 점(`.`) 구분 이름입니다.** `LocalizedText.` 뒤의 경로를 그대로
키로 씁니다. 키를 보면 호출 경로를, 호출 경로를 보면 키를 알 수 있습니다.

| 키 | `LocalizedText` 경로 |
| --- | --- |
| `Example.Detail.ErrorDismiss.buttonTitle` | `LocalizedText.Example.Detail.ErrorDismiss.buttonTitle` |
| `Example.Detail.Summary.Done.title` | `LocalizedText.Example.Detail.Summary.Done.title(count:)` |

- 경로 구성(흐름·화면·주제·요소 enum과 용도)은 [`LocalizedText`](./localized-text.md)가 정합니다.
  키는 그 결과를 따르며 따로 이름을 짓지 않습니다.
- 각 세그먼트는 Swift 식별자입니다. enum 세그먼트는 UpperCamelCase, 마지막 용도 세그먼트는
  lowerCamelCase입니다. 밑줄·공백·한국어를 쓰지 않습니다.
- 생성 심볼은 Xcode가 점을 없애고 이어 붙인 lowerCamelCase입니다.
  `Example.Pane.Summary.title` → `.examplePaneSummaryTitle`. 두 키가 같은 심볼을 만들면 빌드가 실패하므로
  경로가 유일하면 심볼도 유일합니다.
- 같은 한국어 값이라도 용도나 화면이 다르면 다른 키를 둡니다. 값이 같다는 이유로 키를 공유하지
  않습니다.
- 한국어 값을 고쳐도 키는 바꾸지 않습니다. `LocalizedText` 경로가 바뀌면 키도 같은 커밋에서 함께
  바꿉니다.

이름 판단의 일반 기준은 [네이밍 컨벤션](../naming.md)이 소유합니다.
