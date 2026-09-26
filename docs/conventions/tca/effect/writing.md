# Effect 작성

[Git It iOS TCA 컨벤션 — Reducer와 Effect](../effect.md)의 규칙 문서입니다.

Effect는 Domain Use Case 호출, 비동기 대기, timer·clock, notification·stream 관찰,
cancellation 또는 후속 Action 전달이 필요할 때만 만듭니다.

- Effect는 성공, 실패와 취소 시의 State 정리 경로를 명확히 합니다.
- 알려진 Domain 오류는 보존하고 알 수 없는 오류는 Feature가 의존하는 Domain 오류의
  fallback case로 변환합니다. `any Error`를 Action이나 State에 전달하지 않습니다.
- 교체 가능한 요청은 request identity와 cancellation ID를 함께 사용해 최신 결과만
  반영합니다.
- 동시에 실행되면 안 되거나 소유 State 제거 시 끝나야 하는 Effect에는 안정적인
  cancellation ID와 명시적인 취소 경로를 둡니다.
- helper 이름은 `loadInitialItems`, `deleteItem`처럼 대상과 의도를 표현합니다.
  반환 타입이 이미 `Effect<Action>`이면 `Effect`를 이름에 반복하지 않습니다.
