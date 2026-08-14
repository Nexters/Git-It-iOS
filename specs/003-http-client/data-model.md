# 데이터 모델: HTTP 통신 기술 API

**날짜**: 2026-08-14 | **명세**: [spec.md](./spec.md) | **조사**: [research.md](./research.md)

명세의 핵심 엔터티를 `CoreHTTP` target이 소유하는 타입으로 옮긴 결과입니다. 모든 타입은
프로젝트가 소유하며 URL Loading System 타입을 공개 API에 노출하지 않습니다
(research.md §15). 공개 타입은 모두 `Sendable`입니다.

명세가 요구하지 않는 래퍼 타입은 두지 않습니다. 최상위 공개 타입은 10개이고, 소유자가
하나뿐인 두 타입은 그 소유자 안에 중첩합니다(research.md §16).

## 엔터티 대응

| 명세의 핵심 엔터티 | 타입 |
| --- | --- |
| 원격 요청 | `HTTPRequest`(+ 중첩 `QueryItem`), `HTTPMethod`, `HTTPHeaders` |
| 원격 응답 | `HTTPResponse<Value>`(+ 중첩 `Body`) |
| 본문 변환 규칙 | `HTTPBodyCoding` |
| 통신 실패 원인 | `HTTPClientError` |
| 통신 구성 | `HTTPClient`의 생성 인자(별도 타입 없음) |
| (전송 seam) | `HTTPTransport`, `HTTPTransportRequest`, `HTTPTransportResponse` |

## 1. 요청

### `HTTPMethod`

연관값 없는 닫힌 열거. `get`, `post`, `put`, `patch`, `delete`, `head` 여섯 케이스만
존재합니다.

| 항목 | 내용 |
| --- | --- |
| 검증 규칙 | 외부에서 임의 값을 만들 수 없어야 한다. 문자열을 받는 공개 생성자를 두지 않는다 |
| 전송 표기 | 대문자 표기(`GET`, `POST`, …)를 내부 프로퍼티로만 노출한다 |
| 근거 | FR-021, research.md §6 |

### `HTTPHeaders`

헤더 이름을 대소문자 구분 없이 다루는 모음입니다. 키는 `String`이며 내부에서 소문자로
정규화해 보관합니다. 이름 전용 래퍼 타입은 두지 않습니다(research.md §16).

| 연산 | 설명 |
| --- | --- |
| 조회·설정 | `subscript(name: String)`. 어떤 표기로 조회해도 같은 값을 찾는다 |
| 병합 | `overridden(by:)`. 인자가 우선한다. 표기만 다른 같은 이름은 하나로 합쳐진다 |
| 열거 | `names`가 정규화된 이름을, `all`이 이름과 값의 쌍을 제공한다 |
| 생성 | 딕셔너리 리터럴(`["Accept": "application/json"]`)로 만들 수 있다 |

| 항목 | 내용 |
| --- | --- |
| 근거 | FR-022, SC-016, research.md §5, §16 |

### `HTTPRequest`

호출자가 만드는 요청 값입니다. 아직 해소되지 않은 상태(상대 경로, 선택적 대기 한도)를
가집니다.

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `method` | `HTTPMethod` | 요청 방식 |
| `path` | `String` | 기본 주소에 붙일 상대 경로 |
| `queryItems` | `[QueryItem]` | 순서와 중복을 보존하는 쿼리 파라미터. 기본값은 빈 배열 |
| `headers` | `HTTPHeaders` | 이 요청에만 적용할 헤더. 기본값은 빈 모음 |
| `responseTimeout` | `Duration?` | 이 요청에만 적용할 응답 대기 한도. `nil`이면 생성 시 값을 쓴다 |

| 항목 | 내용 |
| --- | --- |
| 본문 | 이 타입에 담지 않는다. 요청 본문은 전송 연산의 인자로 받아 변환 실패를 전송 실패와 같은 경계에서 다룬다 |
| 근거 | FR-001, FR-007 |

### `HTTPRequest.QueryItem`

`HTTPRequest` 안에 중첩합니다. 요청 밖에서 단독으로 쓰이는 곳이 없기 때문입니다.

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `name` | `String` | 부호화하지 않은 원본 이름 |
| `value` | `String` | 부호화하지 않은 원본 값. 선택적이지 않다 |

| 항목 | 내용 |
| --- | --- |
| 검증 규칙 | 값이 빈 문자열이어도 유효하며 제거하지 않는다 |
| 순서·중복 | 요청이 배열로 보유해 지정 순서와 같은 이름의 반복을 보존한다 |
| 부호화 | 이 타입이 아니라 전송 대상 조립 시점에 수행한다(research.md §4) |
| 근거 | FR-019, FR-020, SC-014, SC-015 |

`value`를 선택적으로 두지 않는 이유는 명세가 요구하는 것이 "이름만 있는 파라미터"가 아니라
"빈 값을 가진 파라미터"이기 때문입니다(research.md §4).

## 2. 응답

상태 코드는 `Int` 그대로 다룹니다. 성공 범위(200...299) 판정은 `HTTPClient` 내부 판단이며
그 결과가 `HTTPResponse.Body`의 케이스로 이미 드러나므로, 별도의 상태 코드 래퍼 타입을 두지
않습니다(research.md §16).

### `HTTPResponse<Value>`

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `statusCode` | `Int` | 손실 없이 전달되는 상태 코드 |
| `headers` | `HTTPHeaders` | 정규화된 이름으로 담긴 응답 헤더 |
| `body` | `Body` | 변환된 값 또는 원형 본문 |

`statusCode`와 `headers`는 결과와 무관하게 항상 존재하고 `body`만 분기합니다. 그래서 분기를
응답 전체가 아니라 본문 필드에 둡니다.

| 항목 | 내용 |
| --- | --- |
| 금지 사항 | 상태 코드의 의미별 케이스나 분류 타입을 제공하지 않는다 |
| 근거 | FR-002, FR-003, FR-022, SC-009 |

### `HTTPResponse.Body`

`HTTPResponse` 안에 중첩하며 바깥 제네릭 `Value`를 그대로 씁니다. 응답 밖에서 단독으로
쓰이는 곳이 없기 때문입니다.

| 케이스 | 연관값 | 조건 |
| --- | --- | --- |
| `decoded` | `Value` | 상태 코드가 성공 범위이며 호출자의 변환 규칙이 성공했을 때 |
| `raw` | `Data` | 상태 코드가 성공 범위가 아닐 때. 변환을 시도하지 않은 원형 본문 |

성공 범위인데 변환에 실패하면 이 열거의 값이 만들어지지 않고
`HTTPClientError.responseDecodingFailed`가 전달됩니다. 따라서 `raw`는 "변환에 실패한 본문"이
아니라 "변환 대상이 아니었던 본문"입니다.

두 케이스를 옵셔널 두 필드로 펼치지 않는 이유는 배타성 때문입니다. `decodedBody: Value?`와
`rawBody: Data?`는 둘 다 `nil`이거나 둘 다 존재하는 잘못된 상태를 표현할 수 있지만, 열거는
컴파일러가 배타성을 보장합니다.

| 항목 | 내용 |
| --- | --- |
| 근거 | FR-002, FR-016, FR-017, SC-009, SC-010, research.md §7 |

## 3. 본문 변환 규칙

`CoreHTTP`는 계약만 소유하고 구체 구현을 제공하지 않습니다(research.md §11).

### `HTTPBodyCoding`

호출자의 값과 전송 바이트 사이를 양방향으로 변환하는 능력입니다. 인코딩과 디코딩을 한
프로토콜에 둡니다. 호출자가 언제나 둘을 한 쌍으로 구성하기 때문입니다(research.md §11).

| 연산 | 적용 시점 |
| --- | --- |
| `encode` | 요청 본문이 있는 모든 요청 |
| `decode` | 상태 코드가 성공 범위일 때만 |

| 항목 | 내용 |
| --- | --- |
| 소유자 | 대상 형식과 필드 표기 대응 규칙은 구현체(호출자)가 소유한다 |
| 빈 본문 | 클라이언트는 빈 바이트도 판단 없이 그대로 넘기고, 성공 여부는 구현체가 정한다 |
| 실패 | 구현체가 던진 오류는 각각 `requestEncodingFailed`, `responseDecodingFailed`로 변환된다. 원인 오류는 경계 밖으로 전달하지 않는다 |
| 근거 | FR-014, FR-013, FR-004, SC-005, SC-010 |

## 4. 실패 원인

### `HTTPClientError`

연관값 없는 평면 여섯 케이스입니다.

| 케이스 | 의미 | 발생 시점 |
| --- | --- | --- |
| `invalidURL` | 요청 대상을 만들 수 없음 | 전송 전 |
| `requestEncodingFailed` | 요청 본문을 변환하지 못함 | 전송 전 |
| `connectionFailed` | 요청이 서버에 닿지 못함 | 전송 중 |
| `timedOut` | 응답이 대기 한도 안에 오지 않음 | 전송 중 |
| `cancelled` | 요청이 취소됨 | 전송 전·중 |
| `responseDecodingFailed` | 성공 응답의 본문을 변환하지 못함 | 응답 수신 후 |

| 항목 | 내용 |
| --- | --- |
| 상태 전이 | `invalidURL`과 `requestEncodingFailed`가 성립하면 서버로 아무것도 전송되지 않는다 |
| 우선순위 | 취소가 성립하면 시간 초과보다 우선한다 |
| 연관값 | 두지 않는다. 원인 오류·URL·헤더를 싣지 않는다 |
| 근거 | FR-004, FR-009, SC-002, SC-011, research.md §9 |

## 5. 클라이언트와 구성

### `HTTPClient`

구성값은 별도 타입 없이 생성자가 직접 받습니다. 생성 지점을 하나로 유지하기
위해서입니다(research.md §16).

| 생성 인자 | 타입 | 설명 |
| --- | --- | --- |
| `baseURL` | `URL` | 상대 경로를 붙일 기본 주소 |
| `bodyCoding` | `any HTTPBodyCoding` | 본문 변환 규칙 |
| `commonHeaders` | `HTTPHeaders` | 모든 요청에 함께 보내는 헤더. 기본값은 빈 모음 |
| `responseTimeout` | `Duration` | 기본 응답 대기 한도. 기본값은 `defaultResponseTimeout` |
| `transport` | `any HTTPTransport` | 생략하면 실제 통신 수단을 쓴다 |

| 정적 값 | 타입 | 값 |
| --- | --- | --- |
| `defaultResponseTimeout` | `Duration` | 15초 |

| 항목 | 내용 |
| --- | --- |
| 상태 | 불변 값만 갖는 `Sendable` 구조체. 공유 가변 상태를 두지 않는다 |
| 단일 정의 지점 | 기본 대기 한도는 `HTTPClient.defaultResponseTimeout` 한 곳에만 정의한다 |
| 고정 금지 | 특정 서버 주소·엔드포인트·데이터 형식을 내부에 두지 않는다 |
| 근거 | FR-006, FR-007, FR-010, FR-018, SC-005, SC-006, SC-013, research.md §14, §16 |

## 6. 전송 수단 seam

`HTTPClient`가 해소를 끝낸 뒤 실제 전송만 위임하는 경계입니다.

### `HTTPTransportRequest`

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `url` | `URL` | 기본 주소·경로·부호화된 쿼리가 모두 반영된 절대 주소 |
| `method` | `HTTPMethod` | 요청 방식 |
| `headers` | `HTTPHeaders` | 공통 헤더와 요청별 헤더를 병합한 최종 헤더 |
| `body` | `Data?` | 부호화를 마친 본문. 본문이 없으면 `nil` |
| `responseTimeout` | `Duration` | 확정된 대기 한도 |

`HTTPRequest`와 분리하는 이유는 검증 때문입니다. 가짜 전송 수단이 이 값을 기록하면 실제로
전달된 요청 방식·대상·쿼리·헤더와 변환된 본문을 그대로 검사할 수 있습니다
(사용자 스토리 3 시나리오 3, research.md §12).

### `HTTPTransportResponse`

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `statusCode` | `Int` | 서버 상태 코드 |
| `headers` | `HTTPHeaders` | 정규화된 응답 헤더 |
| `body` | `Data` | 변환하지 않은 원형 본문. 본문이 없으면 빈 값 |

### `HTTPTransport`

요청 하나를 실제로 전송하고 원형 응답을 돌려주는 능력입니다.

| 항목 | 내용 |
| --- | --- |
| 실패 | `HTTPClientError`의 `connectionFailed`, `timedOut`, `cancelled`만 던진다 |
| 리다이렉트 | `URLSessionTransport`는 URL Loading System의 표준 동작으로 이동 대상을 따라가고 최종 응답을 돌려준다 |
| 실제 구현 | `URLSessionTransport`(internal) |
| 대체 구현 | `CoreHTTPTests`가 소유한다. 프로덕션 target에 테스트 전용 구현을 두지 않는다 |
| 근거 | FR-011, FR-016, FR-005, SC-003, SC-008, research.md §8, §12 |

### 접근 수준

| 선언 | 수준 | 근거 |
| --- | --- | --- |
| `HTTPTransport` | public | 상위 경계 테스트가 구현해 갈아끼운다(US3) |
| `HTTPTransportResponse` + 생성자 | public | 대체 구현이 응답을 직접 만든다 |
| `HTTPTransportRequest` | public 타입 / internal 생성자 | 대체 구현은 받아서 읽을 뿐 만들지 않는다 |
| `URLSessionTransport` | internal | 바깥에서 이름을 부를 일이 없다 |
| `RequestURLBuilder` | internal | `HTTPClient`의 대상 조립 구현 세부 |

## 타입 관계

```text
                    ┌─ baseURL, commonHeaders, responseTimeout (생성 인자)
                    ├─ any HTTPBodyCoding
      HTTPClient ───┤
           │        └─ any HTTPTransport ──► URLSessionTransport (internal)
           │                              └► (테스트 대역)
           │
  HTTPRequest ──────┤ 해소(URL 조립·헤더 병합·본문 부호화·한도 확정)
  (method, path,    ▼
   query, headers,  HTTPTransportRequest
   timeout?)        │ 전송
                    ▼
                    HTTPTransportResponse
                    │ 200...299 판정 → 변환
                    ▼
                    HTTPResponse<Value>
                    (statusCode: Int, headers,
                     body: .decoded | .raw)

  실패 경로 ────────► HTTPClientError (평면 6 케이스)
```

## 요구사항 추적

| 요구사항 | 담당 타입 |
| --- | --- |
| FR-001 | `HTTPRequest`(+ `QueryItem`), `HTTPMethod`, `HTTPHeaders` |
| FR-002 | `HTTPResponse`, `HTTPResponse.Body` |
| FR-003 | `HTTPResponse.statusCode`(`Int`), `HTTPClient`의 200...299 판정 |
| FR-004 | `HTTPClientError` |
| FR-005 | `HTTPTransport`, `HTTPTransportRequest`, `HTTPTransportResponse` |
| FR-006 | `HTTPClient` 생성 인자 |
| FR-007 | `HTTPClient` 생성 인자, `HTTPRequest.responseTimeout` |
| FR-008 | `HTTPClient`(마감 소유), `HTTPClientError.timedOut` |
| FR-009 | `HTTPClient`(취소 우선 판정), `HTTPClientError.cancelled` |
| FR-010 | `HTTPClient`(불변 값 타입) |
| FR-011 | `HTTPTransport` |
| FR-013 | `HTTPResponse.Body`, `HTTPBodyCoding` |
| FR-014 | `HTTPBodyCoding` |
| FR-015 | `HTTPClient`(재시도 없음) |
| FR-016 | `URLSessionTransport` |
| FR-017 | `HTTPBodyCoding`(호출자 규칙이 결정) |
| FR-018 | `HTTPClient.defaultResponseTimeout` |
| FR-019 | `RequestURLBuilder`(internal), `HTTPRequest.QueryItem` |
| FR-020 | `[HTTPRequest.QueryItem]` |
| FR-021 | `HTTPMethod` |
| FR-022 | `HTTPHeaders` |
| FR-023 | 해당 타입 없음(기록·관찰 수단을 정의하지 않음) |
