# 요청 식별

[Git It iOS TCA 컨벤션 — State](../state.md)의 규칙 문서입니다.

- 새 요청이 이전 요청을 대체하거나 같은 종류의 요청이 겹칠 수 있으면 State가 현재
  request generation 또는 request ID를 보존합니다.
- Effect event는 자신이 속한 request identity를 함께 전달하고, Reducer는 현재 요청과
  일치하는 결과만 반영합니다.
- cancellation만으로 늦은 응답이 State에 반영되지 않는다고 가정하지 않습니다.
- 서로 겹칠 수 없도록 State 전이로 입력을 차단한 mutation에는 불필요한 request ID를
  추가하지 않아도 되지만, 결과의 대상 ID는 event에 보존합니다.
