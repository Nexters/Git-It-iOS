# 조사: HTTP 통신 기술 API

**날짜**: 2026-08-14 | **명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

이 문서는 계획의 기술 맥락에 남아 있던 미확정 항목을 해소한 근거를 기록합니다. 각 항목은
결정, 근거, 검토한 대안 순으로 정리합니다.

## 검증 방법과 한계

아래 §3·§4·§8·§9·§10의 결정은 추정이 아니라 실제 실행 결과를 근거로 합니다. 저장소 밖의
임시 디렉터리에서 Swift 6.3.3 컴파일러를 `-swift-version 5`(프로젝트의 `SWIFT_VERSION`과
동일한 언어 모드)로 사용해 다음을 실행했습니다.

- Foundation의 URL·쿼리 부호화 동작 확인
- 타입 지정 throws, 제네릭 메서드를 가진 프로토콜의 existential 사용, 구조적 동시성 경쟁 확인
- `127.0.0.1`에 띄운 로컬 HTTP 서버를 상대로 한 `URLSession` 실제 동작 확인(리다이렉트,
  비성공 상태 코드, 요청별 시간 초과, 취소, 연결 실패, 응답 헤더 표기)

**한계**: 검증은 macOS 호스트에서 수행했고 이 기능의 실제 대상은 iOS 26 시뮬레이터입니다.
확인한 동작은 모두 Foundation·URL Loading System 수준의 플랫폼 공통 동작이지만, 최종
확인은 `tasks.md`가 정의하는 iOS 시뮬레이터 테스트 실행에서 이뤄집니다. 로컬 서버는 검증
용도로만 사용했고 저장소에 남기지 않았으며, 자동 테스트는 §12의 대체 전송 수단만
사용합니다(FR-011, SC-003).

## 1. 대상 패키지와 target 경계

**결정**: `Core` 패키지에 신규 target `CoreHTTP`와 검증 target `CoreHTTPTests`를 만든다.
기존 `CoreAuthentication`에는 넣지 않는다.

**근거**: [Infrastructure 패키지 규칙](../../docs/package-rules/infrastructure.md)은 "모든 내부 target은
하나의 범용 기술 기능을 프로젝트 내부 API로 제공해야 한다"고 정한다. HTTP 요청-응답 통신은
인증과 다른 기술 기능이다. 기존 `CoreAuthentication`/`CoreAuthenticationTests` 쌍이 이미
`Core<기술 기능>` + `<동명>Tests` 구조를 쓰므로 같은 구조를 따른다.

**이름 선택**: `CoreNetwork`·`CoreNetworking` 대신 `CoreHTTP`를 쓴다. 명세의 범위 제외
항목이 지속 연결, 스트리밍, 업로드·다운로드 진행률, 캐시를 명시적으로 배제하므로 이 target이
실제로 소유하는 책임은 HTTP 요청-응답 하나다. [네이밍 컨벤션](../../docs/conventions/naming.md)
§2.1은 선언이 맡지 않는 미래 책임을 이름에 넣지 않도록 요구하고, §6은 `HTTP`를 의미 그대로
쓸 때 유지할 수 있는 고정 약어로 인정한다.

**검토한 대안**:

- `CoreAuthentication`에 추가 → Core 규칙의 "target 하나당 기술 기능 하나"에 어긋나고,
  인증과 무관한 호출자가 인증 target에 의존하게 된다. 기각.
- `CoreNetwork`/`CoreNetworking` → 명세가 배제한 스트리밍·소켓 책임을 이름이 암시한다. 기각.

## 2. 언어·동시성·테스트 도구 기준

**결정**: 언어 모드는 기존 설정(`SWIFT_VERSION` 5.0, tools-version 6.0)을 그대로 쓴다.
공개 실패 타입은 타입 지정 throws(`throws(HTTPClientError)`)로 노출한다. 테스트는 Swift
Testing(`import Testing`, `@Suite`, `@Test`, `#expect`)과 백틱 한국어 테스트 이름을 쓴다.

**근거**: `Target+Module.swift`가 모든 target에 `SWIFT_VERSION: 5.0`을 지정하고 있어 새
target도 같은 모드로 빌드된다. 타입 지정 throws는 Swift 6.0 기능이지만 언어 모드 5에서도
동작하는 것을 확인했다(동기·async 모두). 테스트 도구는 `KeychainStoreTests.swift` 등 기존
`CoreAuthenticationTests`의 관례를 따른다.

**의미**: 타입 지정 throws는 SC-002("호출자가 원인별 분기를 100% 작성")를 컴파일러가 강제하는
수단이 된다. 호출자는 `catch` 절에서 `HTTPClientError`를 그대로 받으며 `switch`의
완전성 검사를 받는다.

**계약이 의존하는 타입 시스템 성립 여부**: 계약 문서의 서명이 실제로 컴파일되는지 언어 모드
5에서 확인했다.

| 확인 항목 | 결과 |
| --- | --- |
| 프로토콜 요구사항의 타입 지정 throws(`HTTPTransport.send`) | 성립 |
| `any HTTPTransport` existential로 호출하며 타입 지정 throws 유지 | 성립 |
| 제네릭 메서드를 가진 `any HTTPBodyCoding` 저장·호출 | 성립 |
| `catch`가 `HTTPClientError`로 좁혀져 `default` 없는 `switch`가 컴파일 | 성립(SC-002의 강제 수단 확인) |
| `withThrowingTaskGroup`(비타입 throws) 결과를 타입 지정 throws로 다시 던지기 | `do`/`catch` 래핑으로 성립 |
| 기본 인자에서 자기 타입의 static 참조(`= HTTPClient.defaultResponseTimeout`) | 성립(15초 확인) |
| `URLSession`을 보유한 `URLSessionTransport`의 `Sendable` 적합 | `-strict-concurrency=complete`에서도 경고 0건 |

**Tuist·빌드 훅 제약**: `Project.Options`가 `automaticSchemesOptions: .disabled`이므로 자동
scheme이 생성되지 않는다. `ProjectName.swift`의 `case .Core` scheme 목록에 항목을 추가하지
않으면 `CoreHTTP`는 빌드도 테스트도 되지 않는다. `tools/githooks/project-build`의
`core/workspace.sh`는 공유 `.xcscheme`에서 `<TestableReference`를 grep해
`core/scheme-policy.sh`로 판정하며, `testable` 범위(`compile`·`test`)는
`TestableReference`가 있는 scheme만 대상으로 삼는다. 따라서 scheme을
`.module(name: "CoreHTTP", testTarget: "CoreHTTPTests")` 형태로 선언해야 테스트가 실행된다.
또한 `CoreModuleName`은 `CaseIterable`이 아니라 명시적 `targets` 배열을 쓰므로, enum 케이스만
추가하고 배열에 넣지 않으면 target이 생성되지 않는다.

**검토한 대안**: 일반 `throws` + 문서화 → 호출자가 실패 타입을 다시 캐스팅해야 하고 분기
누락을 컴파일러가 잡지 못한다. 기각.

## 3. 요청 대상 조립

**결정**: 기본 주소와 상대 경로를 `URL.appending(path:)`로 결합한다.
`URL(string:relativeTo:)`는 쓰지 않는다.

**근거**: 실측 결과 `URL(string:relativeTo:)`는 기본 주소에 끝 슬래시가 없으면 마지막 경로
구성요소를 조용히 버린다.

| 방식 | 기본 주소 `…/v1` | 기본 주소 `…/v1/` |
| --- | --- | --- |
| `URL(string: "users", relativeTo:)` | `https://api.example.com/users` (**`/v1` 유실**) | `https://api.example.com/v1/users` |
| `baseURL.appending(path: "users")` | `https://api.example.com/v1/users` | `https://api.example.com/v1/users` |

`appending(path:)`는 두 경우 모두 동일한 결과를 내고, 앞 슬래시가 붙은 경로와 공백·비ASCII
경로도 정상 처리한다(`…/us%20ers/%ED%95%9C%EA%B8%80`). 구성 실수가 조용한 요청 대상 오류로
이어지지 않아야 하므로 이 방식을 쓴다.

**유효하지 않은 대상 판정**: 결합 결과로 `URLComponents(url:resolvingAgainstBaseURL: false)`를
만들지 못하거나, 쿼리를 반영한 뒤 `components.url`이 `nil`이면
`HTTPClientError.invalidURL`으로 전달한다(FR-004, 예외·경계 사례 1).

**검토한 대안**: 문자열 연결 후 `URL(string:)` → 경로 부호화와 중복 슬래시를 직접 처리해야
하고 실수 여지가 크다. 기각.

## 4. 쿼리 파라미터 부호화

**결정**: `URLComponents.queryItems`를 쓰지 않고, 이름·값을 프로젝트가 정한 허용 문자
집합으로 직접 백분율 부호화한 뒤 `URLComponents.percentEncodedQuery`에 대입한다. 허용 집합은
`CharacterSet.urlQueryAllowed`에서 `+`, `&`, `=`, `?`, `#`을 뺀 값이다.

**근거**: 실측 결과 `URLComponents.queryItems`는 `+`를 부호화하지 않는다. 값 `a+b`가
`q=a+b`로 전송되고, 다수의 서버가 이를 `a b`로 해석하므로 값의 의미가 손상된다. FR-019는
"예약 문자가 값에 포함되어도 의미가 손상되지 않아야 한다"를 요구하므로 이 동작은 그대로 쓸 수
없다.

| 값 | `queryItems` 결과 | 직접 부호화 결과 |
| --- | --- | --- |
| `a b` | `q=a%20b` | `q=a%20b` |
| `한글` | `q=%ED%95%9C%EA%B8%80` | `q=%ED%95%9C%EA%B8%80` |
| `a+b` | `q=a+b` (**의미 손상**) | `q=a%2Bb` |
| `a&b` | `q=a%26b` | `q=a%26b` |
| `a=b` | `q=a%3Db` | `q=a%3Db` |

**중복 이름과 순서, 빈 값**: 쿼리를 배열로 다루고 지정 순서대로 `&`로 이어 붙이므로 같은
이름의 반복과 순서가 보존된다(FR-020). 빈 값은 `empty=` 형태로 남으며 제거되지 않는 것을
확인했다.

**값의 선택성**: `URLQueryItem`의 `value`가 `nil`이면 `nilv`처럼 이름만 전송된다. 명세는
이름 없는 값이 아니라 "빈 값"을 요구하므로(FR-020) `HTTPRequest.QueryItem.value`를 선택적이지 않은
`String`으로 정의해 `이름=` 형태만 만든다.

**검토한 대안**:

- `queryItems` 사용 후 `+`만 후처리 치환 → 이미 부호화된 문자열을 다시 문자열 치환하는
  방식이라 정상적인 `%2B`까지 건드릴 위험이 있다. 기각.
- 호출자가 경로에 직접 쿼리를 넣기 → FR-019가 명시적으로 금지한다. 기각.

## 5. 헤더 이름 정규화

**결정**: 헤더 모음 `HTTPHeaders`가 `String` 키를 받아 **내부에서** 소문자로 정규화해
보관한다. 이름 전용 래퍼 타입은 두지 않는다. 서버가 보낸 원래 표기는 보존하지 않는다.

**근거**: FR-022는 병합·조회 모두 대소문자를 구분하지 않고 하나의 표기로 정규화할 것을
요구하며, 명확화 세션에서 원래 표기 보존은 불필요하다고 확정했다. 실측 결과
`HTTPURLResponse.value(forHTTPHeaderField:)`는 이미 대소문자를 구분하지 않지만
`allHeaderFields`는 서버 표기(`X-Mixed-Case-Header`)를 그대로 남긴다. 응답 헤더를 모음으로
전달하려면 `allHeaderFields`를 거쳐야 하므로 정규화를 우리가 직접 수행해야 한다. 소문자는
HTTP/2·HTTP/3가 쓰는 표기이므로 임의 규칙이 아니다.

**병합 규칙**: 공통 헤더에 요청별 헤더를 덮어써서 병합한다. 표기만 다른 같은 이름은 정규화
후 같은 키가 되므로 요청별 값 하나만 남는다(사용자 스토리 1 시나리오 2, SC-016).

**검토한 대안**:

- 원래 표기 보존 + 대소문자 무시 비교 → 명확화에서 배제됐고, 같은 헤더가 표기 차이로 중복
  전송될 여지가 남는다. 기각.
- 이름 전용 타입 `HTTPHeaderName`(정규화 + `Hashable` + `ExpressibleByStringLiteral`) →
  동작은 같지만 공개 타입이 하나 늘고 호출자가 헤더 이름을 쓸 때마다 프로젝트 고유 타입을
  거쳐야 한다. 정규화 책임은 모음 안에 두면 충분하고, `String` 키가 플랫폼 관례
  (`setValue(_:forHTTPHeaderField:)`)와도 일치한다. 기각(§16).

## 6. 요청 방식의 닫힌 집합

**결정**: `HTTPMethod`를 연관값 없는 `enum`으로 정의하고 `get`, `post`, `put`, `patch`,
`delete`, `head` 여섯 케이스만 둔다. 임의 문자열을 받는 생성자를 공개하지 않는다.

**근거**: FR-021이 닫힌 집합을 요구하고 "그 밖의 값을 지정할 수 없어야 한다"고 정한다.
`RawRepresentable`의 `init?(rawValue:)`를 공개하면 문자열 경로가 다시 열리므로, 전송용 표기는
내부 계산 프로퍼티로만 노출한다.

**검토한 대안**: `struct` + 정적 상수(확장 가능한 열거 패턴) → 확장 가능성이 장점이지만
FR-021은 그 확장을 명시적으로 금지한다. 기각.

## 7. 상태 코드 취급과 응답 본문 변환 분기

**결정**: 상태 코드를 `Int` 그대로 전달한다. 래퍼 타입을 두지 않고 `unauthorized`,
`notFound` 같은 의미 케이스도 정의하지 않는다. 성공 범위(200...299) 판정은 `HTTPClient`
내부에서만 수행하며, 성공 범위일 때만 호출자의 변환 규칙을 적용하고 그 밖의 모든 상태
코드는 변환하지 않은 원형 본문을 그대로 전달한다. HTTP 리다이렉트는 `URLSession`이 최종 응답을
받기 전에 처리하므로, 호출자에게는 최종 응답만 전달한다.

**근거**: FR-003은 상태 코드를 성공 범위 판정 용도로만 쓰고 서비스적 의미를 판단하지 말라고
정한다. 의미 케이스를 타입에 넣는 순간 Core가 그 판단을 소유하게 된다. 실측 결과 404 응답은
`URLSession`에서 오류가 아니라 정상 응답으로 도착하므로(본문 `{"error":"nope"}` 수신) 이를
실패로 바꾸지 않고 그대로 전달하면 FR-003과 SC-009를 만족한다.

**표현**: 응답 본문을 `HTTPResponse.Body` 열거로 표현해 `decoded(Value)`와
`raw(Data)`를 구분한다. 호출자는 상태 코드를 보지 않고도 본문이 변환됐는지 알 수 있고,
성공이 아닌 응답이 변환 실패로 둔갑하지 않는다(SC-009).

**검토한 대안**:

- `HTTPResponse.body`를 항상 `Data`로 두고 변환을 호출자에게 넘김 → FR-002·FR-014가 성공
  응답의 변환을 이 기능의 책임으로 정했다. 기각.
- 성공/실패를 `Result`로 나눠 전달 → 성공이 아닌 상태 코드를 실패로 단정하지 말라는 FR-003에
  어긋난다. 기각.
- `HTTPStatusCode` 래퍼 타입(`rawValue` + `isSuccessful`) → 호출자가 쓸 멤버가 없다.
  성공 여부는 `HTTPResponse.Body`의 케이스가 이미 알려 주고(`decoded` = 성공 범위), 상태
  코드 값 자체는 `Int`로 충분하다. 공개 타입만 하나 늘어난다. 기각(§16).

## 8. 리다이렉트 자동 추적

**결정**: `URLSession.data(for:)`의 기본 동작을 사용해 HTTP 리다이렉트를 자동으로 따른다.
중간 3xx 응답과 이동 대상 주소는 호출자에게 전달하지 않고 최종 응답만 `HTTPTransportResponse`로
변환한다.

**근거**: `URLSession`의 기본 동작은 리다이렉트 자동 추적이며, 새 FR-016·SC-008의 요구와
일치한다.
로컬 서버로 실측한 결과는 다음과 같다.

| 구성 | 결과 |
| --- | --- |
| delegate 없음(기본) | 302를 따라가 최종 `200`과 `{"ok":true}` 수신 — FR-016 충족 |
| 차단 delegate 지정 | `302`와 원형 본문 `redirect-body` 수신 — 새 요구사항 위반 |

별도 리다이렉트 delegate를 두지 않으므로 delegate 수명과 세션 무효화 책임을 추가하지 않는다.

**검토한 대안**:

- 리다이렉트 차단 delegate → 중간 3xx를 노출해야 하는 이전 요구사항에만 필요하며, 최종 응답만
  전달하는 현재 요구사항과 맞지 않아 기각.
- `URLSession.shared` 사용 → 공유 세션은 구성 변경이 불가능하고 세션별 기본값을 통제할 수
  없다. 전용 세션을 만든다. 기각.

## 9. 실패 원인 분류

**결정**: `HTTPClientError`를 연관값 없는 **평면** 여섯 케이스로 정의하고, `URLError`를 아래
표대로 대응시킨다. 이 대응은 `URLSessionTransport` 안에서만 수행한다.

**타입 이름**: 이 타입을 소유하고 던지는 주체가 `HTTPClient`이므로 저장소의
`<소유 타입>Error` 관례(`AppleAuthorizationError`, `KeychainStoreError`)를 따른다. 같은
도메인의 swift-server `async-http-client`도 동명 `HTTPClientError`를 쓰며, 상태 코드를 오류가
아니라 응답으로 다루는 점까지 이 설계와 같다.

**케이스 이름**: 생태계에서 이미 쓰이는 어휘만 사용한다. `invalidURL`은 Alamofire
`AFError.invalidURL`, `timedOut`과 `cancelled`는 `URLError`의 동명 코드,
`responseDecodingFailed`는 Alamofire `responseSerializationFailed`에 대응한다.
`requestEncodingFailed`와 `responseDecodingFailed`는 방향이 대칭이라 평면 목록에서도 서로
혼동되지 않는다.

**평면 구조를 유지하는 이유**: 계획 과정에서 단계별 중첩
(`requestFailed(reason:)`·`transportFailed(reason:)` 형태)을 검토했다. "서버로 전송됐는가"를
타입에 새길 수 있다는 장점이 있었으나, 여섯 원인을 모두 다루는 호출부의 패턴이 길어지고
FR-004가 요구하는 것은 여섯 원인의 구분일 뿐 그 그룹화가 아니다. 평면 목록이 요구사항을
그대로 만족하면서 더 단순하므로 중첩을 도입하지 않는다.

**검토하고 기각한 이름**:

- `HTTPRequestError` → 여섯 중 셋(`connectionFailed`, `timedOut`, `responseDecodingFailed`)이
  요청과 무관해 이름이 실제 범위보다 좁다. HTTP 오류 응답(4xx·5xx)을 담는 타입으로 오독될
  여지도 있는데, FR-003에 따라 이 타입은 상태 코드를 담지 않는다. 기각.
- `HTTPExchangeError`·`HTTPCommunicationError` → 범위는 정확하지만 저장소와 생태계 어디에도
  선례가 없는 어휘다. 네이밍 가이드 §6의 "경계 밖 독자가 원형을 복원할 수 있는가" 기준에서
  이점이 없다. 기각.

| 상황 | 근거 | `HTTPClientError` |
| --- | --- | --- |
| 대상 조립 실패 | `URLComponents`/`url`이 `nil` | `invalidURL` |
| 요청 본문 부호화 실패 | 호출자 변환 규칙이 throw | `requestEncodingFailed` |
| 작업 취소 | `URLError.cancelled` 또는 `Task.isCancelled` | `cancelled` |
| 응답 대기 한도 초과 | `URLError.timedOut` 또는 클라이언트 마감 만료 | `timedOut` |
| 그 밖의 전송 오류 | `URLError` 나머지(실측 예: 연결 거부 `-1004`), `HTTPURLResponse` 캐스팅 실패, `URLError`가 아닌 오류 | `connectionFailed` |
| 성공 응답 본문 변환 실패 | 호출자 변환 규칙이 throw | `responseDecodingFailed` |

**근거**: FR-004가 정확히 여섯 가지 구분을 요구한다. 명세에 없는 상황(응답이
`HTTPURLResponse`가 아님, `URLError`가 아닌 오류)까지 새 케이스를 만들면 닫힌 집합이 깨지고
호출자 분기가 늘어나므로 `connectionFailed`로 흡수한다. 실측에서 연결 거부는
`URLError` `-1004`로, 취소는 `URLError.cancelled`로, 요청별 시간 초과는 `URLError.timedOut`
(`-1001`)로 도착하는 것을 확인했다.

**연관값을 두지 않는 이유**: 호출자가 분기하는 데 필요한 것은 여섯 실패 원인의 구분이며,
URL Loading System의 구체 오류나 URL을 함께 전달하면 FR-005의 외부 오류 비노출 경계를
약화한다. 진단 정보의 손실은 감수하며, 이는 이 기능이 자체 기록과 관찰 수단을 제공하지 않는다는
FR-023·범위 제외와 일관된다.

**검토한 대안**:

- `case connectionFailed(underlying: URLError)` → FR-005의 외부 오류 비노출을 위반한다. 기각.
- `case connectionFailed(code: Int)` → 외부 타입은 감추지만 URL Loading System의 오류 코드
  체계를 경계 밖으로 유출해 SC-004의 취지에 어긋난다. 기각.

## 10. 응답 대기 한도와 취소 우선 판정

**결정**: 마감 시한을 `HTTPClient`가 소유한다. `withThrowingTaskGroup`으로 전송 작업과
`Task.sleep(for:)` 마감 작업을 경쟁시키고, 먼저 끝난 쪽의 결과를 쓴 뒤 나머지를 취소한다.
`URLSessionTransport`는 이와 별개로 `URLRequest.timeoutInterval`을 같은 값으로 설정해
이중으로 방어한다. 실패를 매핑하기 전에 항상 `Task.isCancelled`를 먼저 확인해 취소를
우선한다.

**근거**:

- 마감을 클라이언트가 소유하면 어떤 전송 수단을 끼워도 한도가 동일하게 적용되고, 응답하지
  않는 가짜 전송 수단만으로 시간 초과를 검증할 수 있다(FR-011, SC-003). 마감을
  `URLSessionTransport`에만 두면 SC-012 검증에 실제 네트워크가 필요해진다.
- `URLRequest.timeoutInterval`은 실제로 적용된다(세션 기본 대기 한도와 별개로 요청에 1초를
  지정하니 1.007초 만에 `URLError.timedOut`). 다만 이 값은 총 경과 시간이 아니라 데이터
  수신 간격 기준이므로, 총 경과 기준의 결정적 마감은 클라이언트 쪽 경쟁이 담당한다.
- 기본값 15초는 `HTTPClient.defaultResponseTimeout` 한 곳에만 둔다(FR-018, SC-013).

**취소 우선(FR-009, SC-011)이 걸린 지점**: 단순히 경쟁 결과를 그대로 던지면 취소와 마감이
겹칠 때 결과가 갈린다. 200회 반복 실측에서 벽시계 시각을 맞춘 경쟁은 `cancelled` 186회,
`timedOut` 14회로 나왔다. 마감이 실제로 먼저 만료된 경우까지 취소로 바꿀 수는 없으므로,
판정 규칙을 다음과 같이 확정한다.

1. 마감 자식 작업은 `Task.sleep` 이후 `Task.checkCancellation()`을 먼저 수행한 뒤에만
   시간 초과를 던진다.
2. 경쟁에서 나온 오류를 매핑하기 전에 `Task.isCancelled`를 확인해 참이면 `cancelled`로
   전달한다.
3. 시간 초과로 매핑하려는 경우에 한해 `await Task.yield()` 후 취소를 한 번 더 확인한다.

이 규칙에서 "동시에 성립"은 **결과가 확정되기 전에 취소가 관찰된 상태**를 뜻한다. 그렇게
구성한 200회 반복 실측은 `cancelled` 200회로 편차가 없었다.

**검증 방법의 제약**: 따라서 SC-011 검증은 벽시계 경쟁이 아니라 결정적 구성으로 작성해야
한다. 가짜 전송 수단이 취소를 관찰할 때까지 대기하도록 만들고 마감 한도를 그보다 충분히 크게
두면, 취소가 먼저 관찰된 상태를 반복 실행에서 100% 재현할 수 있다. `tasks.md`는 SC-011
테스트를 이 형태로 배정해야 한다.

**검토한 대안**:

- `URLRequest.timeoutInterval`만 사용 → 총 경과 기준이 아니고, 실제 네트워크 없이 검증할 수
  없다(SC-003 위반). 기각.
- 마감을 `URLSessionTransport`에만 배치 → 대체 전송 수단에 한도가 적용되지 않아 FR-008이
  전송 수단마다 달라진다. 기각.
- 취소를 마지막에 확인 → 위 실측대로 SC-011을 만족하지 못한다. 기각.

## 11. 본문 변환 계약의 소유자

**결정**: `HTTPBodyCoding` 프로토콜 **하나**만 `CoreHTTP`가 정의하고, 구체 구현(JSON 등)은
제공하지 않는다. 구현은 호출자(Composition Adapter와 테스트 target)가 소유한다.

**근거**: FR-014는 "시스템은 특정 서비스의 본문 형식이나 필드 표기 규칙을 내부에 고정해서는
안 된다"고 정하고, 범위 제외에 "특정 서비스의 필드 표기 규칙 소유"가 들어 있다. Core 패키지
규칙도 "Data DTO, 서버 API 또는 서비스 고유 데이터 형식을 소유해서는 안 된다"고 제한한다.
구체 코더를 두지 않으면 SC-005(응답 형식이 바뀌어도 이 기능을 수정하지 않음)가 구조적으로
보장된다.

**형태**: `encode`와 `decode`를 한 프로토콜에 둔다. 적용 시점은 다르지만(요청은 항상, 응답은
성공 상태 코드에서만) 그 차이는 `HTTPClient`의 처리 순서가 정하는 것이지 계약을 나눌 근거가
아니다. 호출자는 언제나 둘을 한 쌍(`JSONEncoder`/`JSONDecoder` 등)으로 구성하므로, 나누면
같은 객체를 두 인자로 두 번 주입하게 된다.

이 프로토콜은 제네릭 메서드를 갖지만 `any HTTPBodyCoding` 형태의 existential로 저장·호출할
수 있음을 확인했다. 따라서 `HTTPClient`를 제네릭 타입으로 만들지 않아도 된다.

**빈 본문(FR-013, SC-010)**: 성공 상태 코드의 본문이 비어 있어도 클라이언트는 아무 판단 없이
그대로 호출자의 변환 규칙에 넘긴다. 빈 본문을 성공으로 볼지 실패로 볼지는 그 규칙이 정한다.
원소가 없는 목록도 규칙이 정상 변환하므로 본문 없음이나 실패로 해석되지 않는다.

**검토한 대안**:

- JSON 구현을 함께 제공 → 편의는 늘지만 형식 선택이 Core로 들어오고, 명세의 범위 제외와
  충돌한다. 기각. (호출자가 필요로 하는 JSON 구현은 이 기능이 아닌 Composition Adapter
  명세에서 다룬다.)
- `Encodable`/`Decodable` 대신 클로저(`(Value) throws -> Data`)로 받기 → 요청마다 클로저를
  넘겨야 해 호출부가 번잡해지고, 클라이언트 수준 정책으로 재사용하기 어렵다. 기각.
- `RequestBodyEncoding`·`ResponseBodyDecoding` 두 프로토콜로 분리 → 방향을 타입으로
  구분한다는 장점이 있으나, 실사용에서 같은 구현체가 두 인자에 중복 주입되고 `HTTPClient`
  생성자만 길어진다. 분리가 실제 구분을 제공하지 못하므로 네이밍 가이드 §5의 "제거하면 어떤
  실제 충돌이나 오해가 생기는가" 기준을 통과하지 못한다. 기각(§16).

## 12. 전송 수단 대체 seam

**결정**: `HTTPTransport` 프로토콜을 공개하고 `HTTPClient`가 이를 주입받는다. 실제 구현은
`URLSessionTransport`다. 프로토콜의 입출력은 `HTTPTransportRequest`와
`HTTPTransportResponse`로, 모두 프로젝트가 소유한 타입이다.

**근거**: FR-011은 실제 통신 수단을 대체 가능한 형태로 제공할 것을 요구한다. 프로토콜의
입출력에 `URLRequest`·`URLResponse`를 쓰면 대체는 되지만 FR-005·SC-004를 위반한다.

**해소된 요청과의 분리**: `HTTPRequest`는 호출자가 만드는 값(상대 경로, 선택적 대기 한도,
변환 전 본문)이고, `HTTPTransportRequest`는 클라이언트가 해소한 값(절대 URL, 병합된 헤더,
부호화된 본문, 확정된 대기 한도)이다. 이 분리 덕분에 가짜 전송 수단이
`HTTPTransportRequest`를 그대로 기록하면 사용자 스토리 3 시나리오 3("실제로 전달된 요청
방식·대상·쿼리 파라미터·헤더와 변환된 본문을 검사")을 직접 검증할 수 있다.

**가짜 구현의 위치**: `CoreHTTP`는 프로토콜만 제공하고 미리 정한 응답이나 실패를 돌려주는
구현은 `CoreHTTPTests`가 소유한다. 프로덕션 target에 테스트 전용 코드를 넣지 않기 위해서다.

**접근 수준**: seam을 공개하는 근거는 편의가 아니라 명세다. 사용자 스토리 3은 "통신 수단으로
갈아끼워 **상위 경계의 동작을 확인**한다"고 정한다. 상위 경계는 Composition Adapter이고,
`HTTPClient`가 프로토콜이 아닌 구체 타입이므로 Adapter 테스트가 통제할 수 있는 지점은 주입된
전송 수단뿐이다. 즉 `CoreHTTP` 밖의 테스트 target이 `HTTPTransport`를 구현하고
`HTTPTransportResponse`를 만들어야 한다.

| 선언 | 수준 | 근거 |
| --- | --- | --- |
| `HTTPTransport` | public | 상위 경계 테스트가 구현한다(US3) |
| `HTTPTransportResponse` + 생성자 | public | 대체 구현이 응답을 만든다 |
| `HTTPTransportRequest` | public 타입 / internal 생성자 | 대체 구현은 받아서 읽을 뿐 만들지 않는다. 방향이 반대이므로 접근 수준도 반대다 |
| `URLSessionTransport` | internal | 바깥에서 이름을 부를 일이 없다. 인자 없는 생성자라 구성할 여지도 없고, 실제 통신은 전송 수단을 생략한 `HTTPClient.init`이 제공한다. 공개 표면에서 이름에 `URLSession`이 들어간 타입이 사라져 SC-004 검증도 단순해진다 |
| `RequestURLBuilder` | internal | `HTTPClient`의 대상 조립 구현 세부 |

`CoreHTTPTests`만 놓고 보면 `@testable import`로 충분하지만(기존 `CoreAuthenticationTests`의
관례), FR-011의 "제공" 대상이 자기 테스트만은 아니라는 것이 US3의 문장이다.

**검토한 대안**:

- `HTTPClient`를 프로토콜로 만들고 통째로 대체 → 대체 지점이 통신 수단이 아니라 클라이언트가
  되어 요청 조립·헤더 병합·본문 변환·실패 분류가 검증 대상에서 빠진다. FR-011이 요구하는
  "요청 구성, 본문 변환, 응답 전달, 실패 구분과 취소" 검증이 불가능해진다. 기각.
- `URLProtocol` 하위 클래스로 가로채기 → 실제 URL Loading System을 거치므로 검증 대상이
  넓어지고, 취소·시간 초과 시나리오의 결정성이 떨어진다. 기각.

## 14. 동시성과 취소 격리

**결정**: `HTTPClient`를 불변 값만 갖는 `Sendable` 구조체로 정의하고 공유 가변 상태를 두지
않는다. 하나의 `URLSession`을 여러 요청이 공유하되, 요청별 취소는 각 호출을 감싼 `Task`의
취소로만 이뤄진다.

**근거**: FR-010·SC-006은 동시 요청 시 상태 오염이 없을 것과, 하나를 취소해도 나머지가 각자의
결과를 받을 것을 요구한다. 클라이언트에 가변 상태가 없으면 오염 경로 자체가 없다.
`URLSession.data(for:delegate:)`는 호출을 감싼 `Task`의 취소만 관찰하므로 다른 요청의 작업에
영향을 주지 않는다. 리다이렉트는 `URLSession`의 기본 동작으로 처리하며 별도 공유 상태를 두지
않는다(§8).

**검토한 대안**: 요청마다 `URLSession` 생성 → 연결 재사용이 사라지고 세션 무효화 책임이
생긴다. 기각. 클라이언트에 진행 중 작업 표를 두고 식별자로 취소 → 공유 가변 상태를 도입해
FR-010의 위험을 스스로 만든다. 구조적 동시성의 취소로 충분하다. 기각.

## 15. 외부 타입 비노출 경계의 정의

**결정**: SC-004에서 "외부 통신 기술의 고유 타입"은 URL Loading System 타입
(`URLSession`, `URLSessionConfiguration`, `URLRequest`, `URLResponse`, `HTTPURLResponse`,
`URLError`, `URLComponents`, `URLQueryItem`)으로 정의한다. 이들은 `CoreHTTP`의 공개 API에
등장하지 않는다. `Foundation`의 범용 값 타입인 `Data`, `URL`과 표준 라이브러리의 `Duration`,
`Int`는 공개 API에 사용한다.

**근거**: FR-005는 "외부 **통신 기술**의 구체 타입과 오류"를 대상으로 한다. `Data`와 `URL`은
특정 통신 기술이 아니라 플랫폼 표준 값 타입이며, 이를 배제하면 원형 본문(FR-002)과 기본
주소(FR-007)를 표현할 방법이 사라진다. 기존 Core 코드도 같은 기준을 쓴다
(`KeychainStore`가 `Data`를 공개 API에 노출).

**검증 가능성**: 이 정의는 SC-004를 기계적으로 확인할 수 있게 한다. `CoreHTTP`의 공개 선언에
위 목록의 타입이 등장하지 않는지 검사하면 된다.

**검토한 대안**: `Data`도 감싸는 프로젝트 소유 타입 도입 → 실익 없이 모든 호출부에 변환을
강제하고, 기존 Core 관례와 어긋난다. 기각.

## 16. 공개 표면 축소

**결정**: 명세가 요구하지 않는 래퍼 타입과 분리를 두지 않는다. 최상위 공개 타입은 10개다.

`HTTPMethod`, `HTTPHeaders`, `HTTPRequest`, `HTTPResponse`, `HTTPClientError`,
`HTTPBodyCoding`, `HTTPClient`, `HTTPTransport`, `HTTPTransportRequest`,
`HTTPTransportResponse`

소유자가 하나뿐인 두 타입은 최상위에 두지 않고 그 소유자 안에 중첩한다:
`HTTPRequest.QueryItem`, `HTTPResponse.Body`.

**근거**: 초안은 공개 타입이 17개였다. 각 타입에 "이 타입이 없으면 어떤 요구사항을 만족하지
못하는가"를 물어 네 건을 제거하거나 합쳤다. 어느 것도 FR·SC를 잃지 않는다.

| 제거·병합 | 대체 | 잃지 않는 요구사항 |
| --- | --- | --- |
| `HTTPHeaderName` 제거 | `HTTPHeaders`가 `String` 키를 내부에서 정규화 | FR-022, SC-016 (§5) |
| `HTTPStatusCode` 제거 | `statusCode: Int` | FR-003, SC-009 (§7) |
| `RequestBodyEncoding` + `ResponseBodyDecoding` 병합 | `HTTPBodyCoding` 하나 | FR-014, FR-013 (§11) |
| `HTTPClientConfiguration` 제거 | `HTTPClient.init`이 `baseURL`·`commonHeaders`·`responseTimeout`을 직접 받고, 기본값은 `HTTPClient.defaultResponseTimeout` | FR-006, FR-007, FR-018, SC-013 |
| `URLSessionTransport` public → internal | 전송 수단을 생략한 `HTTPClient.init` | FR-011 (§12) |

**구성 타입을 없앤 이유**: `HTTPClientConfiguration`은 세 필드를 담는 값 구조체였고, 호출자가
구성 객체를 만든 뒤 클라이언트를 만드는 두 단계를 거치게 했다. 필드를 생성자로 옮기면 생성
지점이 하나가 되고, `defaultResponseTimeout`이 `HTTPClient`의 정적 상수로 이동해도
SC-013("수정해야 하는 지점이 1곳")은 그대로 성립한다.

**검증**: 축소한 형태로 헤더 대소문자 무관 조회, 딕셔너리 리터럴 생성, 2xx 변환 경로,
전송 수단 생략 생성자, `defaultResponseTimeout` 참조를 실제로 컴파일·실행해 확인했다.

**유지한 것**: 응답과 본문 분기의 분리, `HTTPRequest`와 `HTTPTransportRequest`의 분리는
남긴다. 전자는 FR-002가 요구하는 "성공 범위에서만 변환"을 타입으로 표현하고, 후자는 US3
시나리오 3의 검사 대상을 제공한다. 둘 다 제거하면 잃는 요구사항이 있다.

**중첩으로 옮긴 두 타입**: 분리 자체는 위와 같이 필요하지만, 그 타입이 **최상위**에 있을
필요는 없다. `HTTPResponseBody`와 `HTTPQueryItem`은 각각 `HTTPResponse`와 `HTTPRequest`
밖에서 단독으로 쓰이는 곳이 계약에 없으므로 소유자 안으로 옮겼다. 얻는 것은 세 가지다.

| 항목 | 이전 | 중첩 후 |
| --- | --- | --- |
| 응답의 본문 필드 선언 | `body: HTTPResponseBody<Body>` (`Body` 3회) | `body: Body` |
| 소유 관계 | 이름의 접두어로만 암시 | 타입 구조가 표현 |
| 최상위 공개 타입 | 12개 | 10개 |

호출부 문법은 바뀌지 않는다. `switch response.body { case .decoded(let value): … }`와
`queryItems: [.init(name:value:)]`는 leading-dot 추론으로 그대로 동작한다. 잃는 FR·SC는 없다.

**중첩하지 않은 타입**: `HTTPMethod`는 `HTTPRequest`와 `HTTPTransportRequest` 둘이 쓰고,
`HTTPHeaders`는 요청·응답·전송 요청·전송 응답·`HTTPClient` 생성 인자 다섯 곳이 쓴다.
소유자가 하나가 아니므로 어디에 넣어도 나머지 사용처에서 이름이 어긋난다.
`HTTPTransportRequest`·`HTTPTransportResponse`는 소유자가 `HTTPTransport` 하나뿐이지만
**Swift 프로토콜은 중첩 타입을 선언할 수 없으므로** 최상위에 남는다. `HTTPClientError`는
`HTTPClient.send`와 `HTTPTransport.send`가 함께 던지고, 기존 Core의
`AppleAuthorizationError`·`KeychainStoreError`가 최상위인 관례와도 맞춰 그대로 둔다.

## 미해결 항목

없음. 계획의 기술 맥락에 `NEEDS CLARIFICATION`으로 남은 항목이 없다.
