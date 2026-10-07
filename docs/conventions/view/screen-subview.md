# 화면 전용 서브뷰

[Git It iOS View 컨벤션](../view.md)의 규칙 문서입니다.

**UIComponent가 지원하지 않는 표현이면서 한 화면에서만 쓰는 렌더링 조각은, 화면
타입에 중첩한 `View` 타입으로 정의해 화면에서 그 책임을 분리합니다.** 재사용 가능한
표현이면 서브뷰로 만들지 않고
[UIComponent 컨벤션 — 재사용 판단](../ui-component/reuse.md)에 따라 컴포넌트로 옮깁니다.

```swift
// ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationScreen+ThumbnailView.swift
extension RepositoryConfirmationScreen {
    struct ThumbnailView: View {
        var body: some View { ... }

        private enum Constant {
            static let cornerRadius: CGFloat = 12
        }
    }
}
```

- 서브뷰는 화면 타입에 중첩합니다. 화면 파일 최상위나 다른 화면에서 참조할 수 있는
  위치에 두지 않습니다.
- **화면 `body`에서 서브뷰를 호출할 때는 `Self.`을 붙입니다.** 그 표현이 이 화면이
  소유한 서브뷰라는 것을 호출부에서 바로 드러내기 위한 것입니다
  (`Self.ThumbnailView()`).
- 서브뷰의 상수는 화면과 같은 방식으로 **서브뷰 자신의 `Constant`** 에 정의합니다.
  부모 화면의 `Constant`를 직접 참조하지 않으며, 같은 값을 써야 하면 서브뷰 생성자로
  주입받고 부모 화면이 초기화 시 넘깁니다
  ([View 내부 선언 컨벤션 — `Constant`](../view-declarations/constant.md)).
- **서브뷰는 SwiftUI와 UI 패키지에만 의존합니다.** 서브뷰 파일이 `import`할 수 있는
  것은 `SwiftUI`, `DesignSystem`, `UIComponent`와 `Foundation`·`CoreGraphics`뿐입니다.
  `ComposableArchitecture`와 Domain 패키지를 import하면 규칙 위반이며, 이것이 이
  규칙의 기계적 확인 기준입니다.
- 따라서 `StoreOf<Feature>`, `Feature.State.*`, `Action`, Domain 모델을 서브뷰의
  입력으로 쓰지 않습니다. **화면이 그 값을 표시 값으로 변환해 전달합니다** — 문자열,
  숫자, `Bool`, 콜백, 그리고 UIComponent가 정의한 타입입니다.
- 화면이 서브뷰에게 이름 붙인 경계가 필요하면 화면 파일에 `typealias`로 정의합니다.
  같은 모듈이라 import가 필요 없으므로 위 제약을 지키면서 이름을 줄 수 있습니다.
  값을 담는 표시 타입은 화면에 중첩하지 않고 최상위 타입으로 분리합니다
  ([View 내부 선언 컨벤션 — 선언 소유 판단](../view-declarations/ownership.md)).

  ```swift
  extension HomeScreen {
      struct ProfileHeaderView: View {
          let name: String?
          let role: String
          let isFailed: Bool
          let onRetry: () -> Void
      }
  }
  ```

  화면은 `HomeFeature.State.ProfileLoad`를 읽어 이 값들을 만들어 넘깁니다. 서브뷰는
  Feature도 Domain도 모릅니다.

- 화면 파일이 길어지면 서브뷰를
  [파일·형태 어휘 컨벤션 — 파일 규칙](../file-vocabulary/nested-type-split.md)의
  `{화면}+{서브뷰}.swift`로 나누고, 그 화면 폴더의 `SubViews/`에 둡니다
  ([디렉터리·파일 컨벤션 — Feature 패키지의 흐름 배치](../directory-file/feature-layout.md)).
