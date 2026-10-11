# 계약: `CoreHTTP` 공개 API

**날짜**: 2026-08-14 | **명세**: [spec.md](../spec.md) |
**데이터 모델**: [data-model.md](../data-model.md) | **조사**: [research.md](../research.md)

`CoreHTTP` target이 Composition Adapter에게 제공하는 인터페이스입니다. 아래 서명은 구현
지침이며, 타입의 필드 의미와 검증 규칙은 데이터 모델을 정본으로 합니다.

## 공개 표면

최상위 공개 타입은 10개입니다. 명세가 요구하지 않는 래퍼 타입은 두지 않습니다(research.md §16).

`HTTPMethod`, `HTTPHeaders`, `HTTPRequest`, `HTTPResponse`, `HTTPClientError`,
`HTTPBodyCoding`, `HTTPClient`, `HTTPTransport`, `HTTPTransportRequest`,
`HTTPTransportResponse`

소유자가 하나뿐인 두 타입은 그 소유자 안에 중첩합니다: `HTTPRequest.QueryItem`,
`HTTPResponse.Body`. 나머지 타입은 소유자가 여럿이거나(`HTTPMethod`, `HTTPHeaders`)
프로토콜이 소유자여서(`HTTPTransportRequest`, `HTTPTransportResponse`) 중첩할 수 없습니다.

`URLSessionTransport`, `RequestURLBuilder`는 internal입니다.

## 비노출 보장

다음 타입은 이 계약의 어떤 공개 선언에도 등장하지 않습니다(FR-005, SC-004).

`URLSession`, `URLSessionConfiguration`, `URLSessionTask`, `URLRequest`, `URLResponse`,
`HTTPURLResponse`, `URLError`, `URLComponents`, `URLQueryItem`

공개 API에 사용하는 외부 타입은 플랫폼 표준 값 타입인 `Data`, `URL`과 표준 라이브러리의
`Duration`, `Int`뿐입니다(research.md §15).

## 1. 요청 값

```swift
public enum HTTPMethod: Sendable {
    case get, post, put, patch, delete, head
}

public struct HTTPHeaders: Equatable, Sendable, ExpressibleByDictionaryLiteral {
    public init()
    public init(dictionaryLiteral elements: (String, String)...)

    /// 이름은 대소문자를 구분하지 않는다. 내부에서 소문자로 정규화해 보관한다.
    public subscript(name: String) -> String? { get set }

    /// 같은 이름이 양쪽에 있으면 `other`의 값이 남는다.
    public func overridden(by other: HTTPHeaders) -> HTTPHeaders

    public var names: [String] { get }
    public var all: [(name: String, value: String)] { get }
}

public struct HTTPRequest: Sendable {

    public struct QueryItem: Equatable, Sendable {
        public let name: String

        /// `URLQueryItem.value`와 달리 선택적이지 않다. 빈 문자열도 유효한 값이며 제거하지 않는다.
        public let value: String

        public init(name: String, value: String)
    }

    public var method: HTTPMethod
    public var path: String
    public var queryItems: [QueryItem]
    public var headers: HTTPHeaders
    public var responseTimeout: Duration?

    public init(
        method: HTTPMethod,
        path: String,
        queryItems: [QueryItem] = [],
        headers: HTTPHeaders = [:],
        responseTimeout: Duration? = nil,
    )
}
```

### 계약

| 항목 | 보장 |
| --- | --- |
| 요청 방식 | 여섯 케이스 밖의 값을 만들 수 없다 |
| 쿼리 순서 | 배열의 지정 순서를 그대로 전송한다 |
| 쿼리 중복 | 같은 이름을 여러 번 지정할 수 있고 모두 전송한다 |
| 쿼리 빈 값 | `value`가 빈 문자열이어도 `이름=` 형태로 전송하며 제거하지 않는다 |
| 쿼리 부호화 | 호출자는 부호화하지 않은 원본을 넘긴다. 공백·비ASCII·`+`·`&`·`=`가 포함돼도 의미가 손상되지 않는다 |
| 헤더 대소문자 | `headers["Content-Type"]`과 `headers["content-type"]`은 같은 항목이다 |
| 헤더 표기 | 정규화된 소문자 이름으로 전달한다. 서버가 보낸 원래 표기는 보존하지 않는다 |

## 2. 응답 값

```swift
public struct HTTPResponse<Value: Sendable>: Sendable {

    public enum Body: Sendable {
        case decoded(Value)  // 성공 상태 코드에서 변환에 성공한 값
        case raw(Data)       // 성공이 아닌 상태 코드의 원형 본문. 변환을 시도하지 않았다
    }

    public let statusCode: Int
    public let headers: HTTPHeaders
    public let body: Body
}
```

### 계약

| 항목 | 보장 |
| --- | --- |
| 상태 코드 전달 | 수신한 상태 코드를 `Int` 그대로 손실 없이 전달한다 |
| 의미 판단 없음 | 성공 범위(200...299) 판정 외에 상태 코드를 해석하지 않는다. 의미별 케이스나 분류 타입을 제공하지 않는다 |
| 실패 아님 | 응답을 정상 수신했다면 상태 코드와 무관하게 실패가 아닌 결과로 전달한다 |
| 본문 분기 | 성공 범위면 `decoded`, 그 밖이면 `raw`다. 성공이 아닌 응답이 변환 실패로 전달되지 않는다 |
| 이동 지시 | `URLSession`이 표준 HTTP 리다이렉트를 자동으로 처리하고, 호출자에게는 최종 응답만 전달한다 |
| 케이스 의미 | `raw`는 "변환을 시도하지 않은 원형 본문"이며 변환 실패가 아니다. 변환 실패는 `responseDecodingFailed`로 던져지고 응답 값이 만들어지지 않는다 |
| 헤더 조회 | 어떤 표기로 조회해도 같은 값을 찾는다 |

성공 여부는 `body`가 이미 알려 주므로(`decoded` = 성공 범위) 별도의 판정 프로퍼티를 두지
않습니다.

## 3. 본문 변환 계약

```swift
public protocol HTTPBodyCoding: Sendable {
    func encode(_ body: some Encodable) throws -> Data
    func decode<Body: Decodable>(_ type: Body.Type, from data: Data) throws -> Body
}
```

### 계약

| 항목 | 보장 |
| --- | --- |
| 소유자 | 대상 형식과 필드 표기 대응 규칙은 구현체가 소유한다. `CoreHTTP`는 구체 구현을 제공하지 않는다 |
| 요청 본문 | 본문이 있는 요청에서 항상 `encode`를 호출한다 |
| 응답 본문 | 상태 코드가 성공 범위일 때만 `decode`를 호출한다 |
| 빈 본문 | 성공 상태 코드의 본문이 비어 있어도 특별 취급 없이 그대로 `decode`에 넘긴다. 성공 여부는 구현체가 정한다 |
| 오류 변환 | 구현체가 던진 오류는 `requestEncodingFailed` 또는 `responseDecodingFailed`로 변환되며 원인 오류는 전달되지 않는다 |

`any HTTPBodyCoding` 형태로 저장하고 호출할 수 있습니다. 인코딩과 디코딩을 한 프로토콜로
두는 이유는 호출자가 언제나 둘을 한 쌍(`JSONEncoder`/`JSONDecoder` 등)으로 구성하기
때문입니다(research.md §11).

## 4. 실패

```swift
public enum HTTPClientError: Error, Equatable, Sendable {
    case invalidURL
    case requestEncodingFailed
    case connectionFailed
    case timedOut
    case cancelled
    case responseDecodingFailed
}
```

### 계약

| 항목 | 보장 |
| --- | --- |
| 구분 가능성 | 여섯 원인이 서로 다른 케이스로 전달되어 호출자가 원인별 분기를 작성할 수 있다 |
| 연관값 없음 | 원인 오류·URL·헤더·본문을 싣지 않는다 |
| 전송 여부 | `invalidURL`과 `requestEncodingFailed`가 전달되면 서버로 아무것도 전송되지 않았다 |
| 재시도 없음 | 연결 실패나 시간 초과 뒤 클라이언트가 같은 요청을 자동으로 다시 보내지 않는다. 표준 HTTP 리다이렉트 전송은 자동 재시도로 보지 않는다 |
| 취소 우선 | 취소가 결과 확정 전에 관찰되면 시간 초과가 아니라 `cancelled`를 전달한다 |

## 5. 클라이언트

```swift
public struct HTTPClient: Sendable {

    /// 기본 응답 대기 한도의 유일한 정의 지점 (FR-018, SC-013)
    public static let defaultResponseTimeout: Duration = .seconds(15)

    /// 전송 수단을 직접 지정한다. 테스트와 대체 구현이 사용한다.
    public init(
        baseURL: URL,
        bodyCoding: any HTTPBodyCoding,
        commonHeaders: HTTPHeaders = [:],
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
        transport: any HTTPTransport,
    )

    /// 실제 통신 수단을 사용한다.
    public init(
        baseURL: URL,
        bodyCoding: any HTTPBodyCoding,
        commonHeaders: HTTPHeaders = [:],
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
    )

    /// 본문이 없는 요청
    public func send<ResponseBody: Decodable & Sendable>(
        _ request: HTTPRequest,
        expecting: ResponseBody.Type,
    ) async throws(HTTPClientError) -> HTTPResponse<ResponseBody>

    /// 본문이 있는 요청
    public func send<RequestBody: Encodable & Sendable, ResponseBody: Decodable & Sendable>(
        _ request: HTTPRequest,
        body: RequestBody,
        expecting: ResponseBody.Type,
    ) async throws(HTTPClientError) -> HTTPResponse<ResponseBody>
}
```

구성값(`baseURL`, `commonHeaders`, `responseTimeout`)은 별도 구성 타입 없이 생성자가 직접
받습니다. 생성 지점을 하나로 유지하기 위해서입니다(research.md §16).

### 전송 연산의 처리 순서

각 단계에서 실패하면 그 시점의 원인을 던지고 이후 단계를 수행하지 않습니다.

| 순서 | 단계 | 실패 시 |
| --- | --- | --- |
| 1 | 기본 주소와 상대 경로를 결합하고 쿼리를 부호화해 절대 주소를 만든다 | `invalidURL` |
| 2 | 공통 헤더에 요청별 헤더를 덮어써 병합한다 | — |
| 3 | 본문이 있으면 `HTTPBodyCoding.encode`로 변환한다 | `requestEncodingFailed` (서버 전송 없음) |
| 4 | 요청별 대기 한도가 있으면 그것을, 없으면 생성 시 값을 확정한다 | — |
| 5 | 마감 시한과 경쟁시키며 `HTTPTransport`에 전송을 위임한다 | `cancelled` / `timedOut` / `connectionFailed` |
| 6 | 상태 코드가 200...299면 `HTTPBodyCoding.decode`로 변환한다 | `responseDecodingFailed` |
| 7 | 그 밖이면 원형 본문을 `raw`로 담는다 | — |

### 계약

| 항목 | 보장 |
| --- | --- |
| 기본 주소 결합 | 기본 주소의 경로가 유실되지 않는다. 끝 슬래시 유무가 결과를 바꾸지 않는다 |
| 헤더 우선순위 | 요청별 헤더가 공통 헤더를 대신한다. 표기만 다른 같은 이름은 하나만 전송된다 |
| 기본 대기 한도 | 요청별 값이 없으면 생성 시 값을, 생성 시에도 없으면 15초를 쓴다 |
| 단일 정의 지점 | 기본 대기 한도를 바꾸려면 `HTTPClient.defaultResponseTimeout` 한 곳만 고친다 |
| 자동 재시도 없음 | 한 번의 `send` 호출에서 연결 실패나 시간 초과 뒤 `HTTPTransport.send`를 다시 호출하지 않는다. URL Loading System의 표준 HTTP 리다이렉트 전송은 제외한다 |
| 동시성 | 여러 `send`를 동시에 호출해도 요청과 응답이 섞이지 않는다 |
| 취소 격리 | 한 호출을 감싼 `Task`를 취소해도 다른 호출에 영향을 주지 않는다 |
| 기록 없음 | 자체 기록을 남기지 않고 호출자가 끼워 넣는 관찰 수단을 제공하지 않는다 |

## 6. 전송 수단

```swift
public struct HTTPTransportRequest: Sendable {
    public let url: URL
    public let method: HTTPMethod
    public let headers: HTTPHeaders
    public let body: Data?
    public let responseTimeout: Duration
    // 생성자는 internal — HTTPClient만 만든다
}

public struct HTTPTransportResponse: Sendable {
    public let statusCode: Int
    public let headers: HTTPHeaders
    public let body: Data

    public init(statusCode: Int, headers: HTTPHeaders, body: Data)
}

public protocol HTTPTransport: Sendable {
    func send(_ request: HTTPTransportRequest) async throws(HTTPClientError)
        -> HTTPTransportResponse
}
```

### 접근 수준

| 선언 | 수준 | 근거 |
| --- | --- | --- |
| `HTTPTransport` | public | 상위 경계(Composition Adapter) 테스트가 구현해 갈아끼운다(US3) |
| `HTTPTransportResponse` + `init` | public | 대체 구현이 응답을 직접 만든다 |
| `HTTPTransportRequest` | public 타입 / internal 생성자 | 대체 구현은 받아서 읽을 뿐 만들지 않는다 |
| `URLSessionTransport` | internal | 바깥에서 이름을 부를 일이 없다. 실제 통신은 전송 수단을 생략한 `HTTPClient.init`이 제공한다 |
| `RequestURLBuilder` | internal | `HTTPClient`의 처리 순서 1단계 구현 세부. 호출자가 이름을 부를 일이 없다 |

### 계약

| 항목 | 보장 |
| --- | --- |
| 대체 가능성 | 호출자가 `HTTPTransport`를 구현해 실제 네트워크 없이 요청 구성·본문 변환·응답 전달·실패 구분·취소를 검증할 수 있다 |
| 검사 가능성 | 구현체는 받은 `HTTPTransportRequest`로 요청 방식, 절대 주소(부호화된 쿼리 포함), 병합된 헤더, 변환된 본문을 검사할 수 있다 |
| 실패 범위 | `connectionFailed`, `timedOut`, `cancelled`만 던진다 |
| 리다이렉트 | `URLSessionTransport`는 URL Loading System의 표준 동작으로 이동 대상을 자동 요청하고 최종 응답을 돌려준다 |
| 오류 격리 | `URLError`를 포함한 외부 오류가 이 경계를 넘지 않는다 |

## 성공 기준 대응

| 성공 기준 | 이 계약에서의 근거 |
| --- | --- |
| SC-001 | 새 요청은 `HTTPRequest` 구성과 `send` 호출만으로 완료된다 |
| SC-002 | `HTTPClientError` 여섯 케이스 + 타입 지정 throws로 분기 완전성을 컴파일러가 검사한다 |
| SC-003 | `HTTPTransport` 대체로 모든 시나리오를 네트워크 없이 실행한다 |
| SC-004 | §비노출 보장 |
| SC-005 | 주소·엔드포인트·형식이 모두 생성 인자와 호출자 소유다 |
| SC-006 | 클라이언트에 공유 가변 상태가 없고 취소가 호출별로 격리된다 |
| SC-008 | 자동 재시도 없음 + 표준 HTTP 리다이렉트 자동 추적 |
| SC-009 | 성공 범위가 아니면 변환을 시도하지 않고 `raw`로 전달하며 `statusCode`를 그대로 노출한다 |
| SC-010 | 빈 컬렉션은 호출자 변환 규칙이 정상 값으로 변환한다 |
| SC-011 | 취소를 시간 초과보다 먼저 판정한다 |
| SC-012 | 요청별 값이 없으면 15초 기본값이 적용된다 |
| SC-013 | `HTTPClient.defaultResponseTimeout` 한 곳 |
| SC-014 | 호출자가 원본 값을 넘기고 부호화는 클라이언트가 수행한다 |
| SC-015 | 쿼리를 배열로 다뤄 순서·중복·빈 값을 보존한다 |
| SC-016 | `HTTPHeaders`가 이름을 소문자로 정규화한다 |
