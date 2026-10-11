# 정본과 파생값

[Git It iOS TCA 컨벤션 — State](../state.md)의 규칙 문서입니다.

- `State`는 사용자가 인지하는 Presentation 상태와 화면 흐름에 필요한 최소 정본만
  소유합니다.
- 화면에 필요한 Domain 모델과 ID, 사용자 입력과 operation 상태는 보존할 수 있지만
  Domain 규칙이나 Data DTO를 복제하지 않습니다.
- 표시 문자열, progress 비율과 버튼 활성 여부처럼 정본에서 전부 계산할 수 있는 값은
  computed property나 View 변환으로 만듭니다.
- 같은 값을 화면 `ViewModel`, SwiftUI `@State` 또는 별도 참조 타입에 복제하지 않습니다.
- UI 표시를 위한 변환은 할 수 있지만 누락된 ID를 생성하거나 문자열을 해석해 Domain
  의미를 새로 추론하지 않습니다.

State에는 다음을 저장하지 않습니다.

- `Effect<Action>`, `Task`, Use Case, Repository, dependency 또는 closure
- UIComponent의 표시 입력을 묶은 wrapper
- 서버 메시지 원문이나 `any Error`
- Domain 값에서 단순 계산할 수 있는 중복 표시값
- 현재 요청과 연결되지 않아 유효성을 판단할 수 없는 임시 응답
