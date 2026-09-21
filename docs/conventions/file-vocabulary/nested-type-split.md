# 중첩 타입 분리

[Git It iOS 파일·형태 어휘 컨벤션](../file-vocabulary.md)의 규칙 문서입니다.

타입에 중첩한 선언을 별도 파일로 나눌 때는 `{상위타입}+{중첩타입}.swift`를 사용하고,
파일 안에서는 `extension`으로 선언합니다.

```swift
// Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+ChoiceSection.swift
extension QuestionSolvingScreen {
    struct ChoiceSection: View { ... }
}
```

다른 화면 전용 서브뷰도 같은 규칙을 씁니다 —
`ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationScreen+ThumbnailView.swift`.
`Constant`는 예외로 파일을 나누지 않고 소유 View와 같은 파일에 둡니다
([View 내부 선언 컨벤션 — `Constant`](../view-declarations/constant.md)).

중첩할지 여부 자체는
[View 내부 선언 컨벤션 — View 내부 선언](../view-declarations/internal-declarations.md)가, 화면 전용
서브뷰를 만드는 기준은 [View 컨벤션 — 화면 전용 서브뷰](../view/screen-subview.md)이 정합니다.
이 문서는 나눈 파일의 이름과 위치만 정합니다.
