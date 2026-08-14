# RequestURLBuilder 오류 경계 분리

**상태**: 미해결

**범위**: `CoreHTTP` 리팩터링
**관련 코드**: `sources/Projects/Core/CoreHTTP/Client/RequestURLBuilder.swift`,
`sources/Projects/Core/CoreHTTP/Client/HTTPClient.swift`

## 문제

`RequestURLBuilder`는 기본 URL·경로·쿼리를 전송 URL로 조립하는 내부 구현 타입이지만,
실패 시 `HTTPClientError.invalidURL`을 직접 반환한다. 이 때문에 URL 조립의 내부 실패가
`HTTPClient`의 공개 오류 계약에 직접 결합된다.

`HTTPClientError`의 외부 전달과 의미 결정은 `HTTPClient`가 맡아야 한다. URL 조립기는
성공·실패라는 자신의 기술적 결과만 표현해야 한다.

## 리팩터링 방향

1. `RequestURLBuilder` 전용의 내부 실패 타입(예: `RequestURLBuilderError.invalidURL`)을
   정의하거나, 단일 실패만 필요한 경우 `URL?` 반환으로 실패를 표현한다.
2. `HTTPClient`가 URL 조립 실패를 잡아 `HTTPClientError.invalidURL`로 변환한다.
3. 공개 API와 호출자가 관찰하는 동작은 유지한다. 유효하지 않은 URL이면 전송 수단을
   호출하지 않고 `HTTPClientError.invalidURL`을 던져야 한다.

## 완료 조건

- `RequestURLBuilder`의 함수 시그니처와 구현에서 `HTTPClientError` 참조가 제거된다.
- `HTTPClient`만 `RequestURLBuilder`의 실패를 `HTTPClientError.invalidURL`로 매핑한다.
- 기존 `invalidURL` 분류와 전송 수단 미호출 검증이 통과한다.
- 새 내부 오류 타입은 `CoreHTTP`의 public API에 노출되지 않는다.

## 비범위

- `HTTPClientError`의 공개 케이스 변경
- URL 조립·쿼리 부호화 규칙 변경
- 전송, 시간 초과, 취소 오류 처리 변경
