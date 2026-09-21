# 프리뷰

[Git It iOS View 컨벤션](../view.md)의 규칙 문서입니다.

| 대상 | 위치 | 이름 |
|---|---|---|
| UIComponent | 컴포넌트 파일 하단 `#Preview` | 컴포넌트 이름 |
| Feature 화면 | 그 화면 폴더의 `Previews/` 안 `<화면 타입 이름>Previews.swift` | 화면과 상태를 설명하는 한국어 이름 |

- 컴포넌트 프리뷰는 모든 시각 변형을 한 프리뷰에 나열해 변형 간 차이를 함께 봅니다.
  시각 변형은 `ActionButton(title: "삭제").style(.destructive)`처럼 계약 메서드로 나열하고, 상태
  `Binding`은 `.constant(...)`로 넘깁니다.
- 컴포넌트 프리뷰의 배경은 `designSystemBackground(.grey700)`으로 실제 화면 배경 위의
  대비를 확인합니다.
- 화면 프리뷰는 `catalogPreviewFrame()`으로 동일한 검토 프레임을 사용합니다.
- 화면 파일 안에 `#Preview`를 두지 않습니다. 화면 프리뷰는 상태 조합마다 늘어나므로
  화면 구현과 분리합니다.
- Feature 프리뷰 파일이 놓이는 `Previews/` 폴더의 자리는
  [디렉터리·파일 컨벤션 — Feature 패키지의 흐름 배치](../directory-file/feature-layout.md)가
  소유합니다.
- 파일 이름은 화면 타입 이름 뒤에 `Previews`를 붙입니다 —
  `RepositoryConfirmationScreenPreviews.swift`, `OnboardingRouterPreviews.swift`.
- 프리뷰 전용 타입은 프리뷰가 필요한 컴포넌트 파일이 아니라 독립 파일에 둡니다.
