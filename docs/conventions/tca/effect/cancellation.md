# 취소와 mutation

[Git It iOS TCA 컨벤션 — Reducer와 Effect](../effect.md)의 규칙 문서입니다.

취소 정책은 작업의 의미에 따라 구분합니다.

| 작업 | `cancelInFlight` | 사용자 취소 |
| --- | --- | --- |
| 검색·검증·새로고침처럼 새 요청이 이전 요청을 대체 | 허용 | 최신 요청만 유지할 수 있음 |
| pagination | 동일 page 중복만 차단하고 원칙적으로 대체하지 않음 | 명시적인 화면 정책이 있을 때만 |
| debounce·delay | 허용 | 새 입력이 이전 작업을 대체 |
| 장기 observation | 허용 | 소유 State 제거 시 취소 |
| 서버 mutation | `true` 금지 | 요청 전 confirmation에서만 허용 |

로컬 Effect를 취소하는 것은 서버 mutation이 rollback됐다는 의미가 아닙니다. 삭제, 제출,
탈퇴 같은 파괴적 작업은 `idle → confirming → committing → success | failure` 상태 전이를
드러내고 다음을 지킵니다.

- `confirming`에서는 취소할 수 있습니다.
- `committing` 진입 뒤에는 중복 요청, 취소와 해당 상태를 잃는 dismiss를 차단합니다.
- 성공하기 전에 서버 정본과 연결된 local 항목을 제거하지 않습니다.
- 불가피하게 화면 수명이 먼저 끝나 결과를 잃을 수 있으면, 소유자를 상위로 올리거나
  재진입 시 서버 정본을 다시 조회하는 조정 경로를 둡니다.
