---

description: "HTTP 통신 기술 API 구현 작업 목록"
---

# 작업 목록: HTTP 통신 기술 API

**입력**: `/specs/003-http-client/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/http-client-api.md](./contracts/http-client-api.md),
[quickstart.md](./quickstart.md)

**테스트**: 포함한다. 사용자 스토리 3이 "실제 서버 없이 통신 경계를 검증한다"를 요구하고
FR-011·SC-003이 자동 테스트를 기능 요구사항으로 정하므로 테스트 작업은 선택이 아니다.

**구성**: 이 명세의 적용 대상 패키지는 `Core` 하나다. `Domain → Data → Core → Composition
→ UI → Feature → App` 순서에서 `Core` 앞뒤 패키지는 모두 변경 대상이 아니므로 건너뛴다
(plan.md "패키지 진행").

## 형식: `[ID] [P?] [스토리?] 설명`

- **[P]**: 승인된 현재 패키지 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[스토리]**: 작업이 지원하는 사용자 스토리(US1, US2, US3)
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행 또는 수동 검증
- 파일 변경 작업은 정확한 저장소 상대 경로 하나와 정확히 하나의 책임 패키지를 가져야 한다.
- 서로 다른 패키지는 같은 의존 깊이에 있어도 승인 게이트를 넘어 병렬 실행하지 않는다.
- 공개 API의 신설·rename 작업은 확정한 식별자와 책임을 설명에 명시한다. 네이밍 변경과
  동작·상태 수명·책임·의존 방향 변경은 하나의 작업으로 합치지 않는다.

## 패키지 소유권 규칙

- 패키지 소스·테스트와 패키지 전용 설정은 해당 패키지 단계가 소유한다.
- 준비, 기반, 정리와 횡단 관심사는 별도 구현 단계로 만들지 않고 책임 패키지 단계에 넣는다.
- 공용 구성 파일이 여러 패키지 선언을 바꿔야 하면 패키지별 작업으로 분리하고, 각 작업은
  현재 패키지에 필요한 선언만 변경한다.
- 패키지에 속하지 않는 파일 변경은 그 변경을 최초로 필요로 하는 책임 패키지에 명시적으로
  배정한다.
- 전체 기능을 대상으로 하는 검증은 마지막 적용 대상 패키지 뒤에 `[no-write]`로만 둔다.
- `trouble-shooting.md`와 `tacit-knowledge.md` 기록은 구현 작업이나 패키지 소유 파일로
  만들지 않는다.

**패키지에 속하지 않는 파일의 배정**: T001·T002가 변경하는 두 Tuist 설정 파일은
`sources/Projects/<패키지>` 밖에 있지만 `Core` 프로젝트의 선언만 바꾸며, 이 변경을 최초로
필요로 하는 책임 패키지가 `Core`이므로 `Core` 단계에 배정한다(plan.md "패키지 진행").

## 반드시 지켜야 할 구현 제약

계획 단계에서 실측으로 확정한 제약이다. 위반하면 컴파일 성공 여부와 무관하게 런타임 또는
검증이 깨진다(plan.md "제약 조건(실측에서 확정)").

| 제약 | 위반 시 결과 | 해당 작업 |
| --- | --- | --- |
| SC-011 검증은 벽시계 경쟁이 아니라 "취소가 먼저 관찰된 상태"를 결정적으로 구성한다 | 실시간 경쟁 200회 중 14회가 `timedOut`으로 나와 반복 실행에서 실패한다(research.md §10) | T011, T026 |
| `URL(string:relativeTo:)`를 쓰지 않고 `URL.appending(path:)`를 쓴다 | 기본 주소에 끝 슬래시가 없으면 마지막 경로 구성요소가 조용히 사라진다(research.md §3) | T024 |
| 쿼리는 `URLComponents.queryItems`가 아니라 직접 부호화 후 `percentEncodedQuery`에 대입한다 | `+`가 부호화되지 않아 서버가 공백으로 해석한다(research.md §4) | T024 |
| `ProjectName.swift`에 scheme을 `testTarget:`과 함께 등록한다 | `automaticSchemesOptions: .disabled`이라 등록이 없으면 빌드·테스트 대상에서 빠진다 | T002 |
| `CoreModuleName`의 `targets` 배열에 항목을 추가한다 | 이 enum은 `CaseIterable`이 아니라 케이스만 추가하면 target이 생성되지 않는다 | T001 |

---

## 작업 패키지 1: Core

**목표**: HTTP 요청-응답 통신을 프로젝트가 소유한 범용 기술 API로 제공하는 `CoreHTTP`
target을 신설하고, 실제 네트워크 없이 전 경로를 검증하는 `CoreHTTPTests`를 함께 만든다.

**소유 경로**: `sources/Projects/Core/CoreHTTP/`,
`sources/Projects/Core/CoreHTTPTests/`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/CoreModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`

**관련 사용자 스토리**: US1(요청 전송과 응답 수신), US2(실패 원인 구분),
US3(실제 서버 없는 검증)

**독립 검증**: `CoreHTTP`는 프로젝트 내부 패키지에 의존하지 않으므로 `CoreHTTP` scheme
단독 빌드·테스트로 책임과 의존 방향을 모두 검증할 수 있다. 공개 선언에 URL Loading System
타입이 없는지도 이 패키지 안에서 확인한다.

### 준비와 기반

- [X] T001 [US1] [US3] `sources/Tuist/ProjectDescriptionHelpers/Projects/CoreModuleName.swift`에
  `CoreHTTP`·`CoreHTTPTests` 케이스를 추가하고, `targets` 배열에
  `.module(name: CoreModuleName.CoreHTTP.rawValue, dependencies: [])`와
  `.testModule(name: CoreModuleName.CoreHTTPTests.rawValue, productionTarget: .target(name: CoreModuleName.CoreHTTP.rawValue))`를
  추가한다. 이 enum은 `CaseIterable`이 아니므로 케이스 추가만으로는 target이 생성되지 않는다.
  `CoreHTTP`는 Foundation만 사용하므로 `.sdk` 의존성을 추가하지 않는다
- [X] T002 [US1] [US3] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의
  `case .Core` schemes 배열에 `.module(name: "CoreHTTP", testTarget: "CoreHTTPTests")`를
  추가한다. `Project.Options`가 `automaticSchemesOptions: .disabled`이므로 이 등록이 없으면
  `CoreHTTP`는 빌드도 테스트도 되지 않고, `testTarget:`이 없으면
  `tools/githooks/project-build`가 `<TestableReference` 부재로 `compile`·`test` 대상에서
  제외한다
- [X] T003 [no-write] 저장소 루트에서 `make tuist`를 실행하고,
  `sources/Projects/Core/xcshareddata/xcschemes/CoreHTTP.xcscheme`에 `<TestableReference`가
  포함되었는지 확인한다

### 테스트 (US1, US2, US3)

테스트 대역은 `CoreHTTPTests`가 소유한다. `CoreHTTP`는 구체 본문 변환 구현을 제공하지
않으므로(research.md §11) 테스트용 JSON 변환 구현도 테스트 target에 둔다.

- [X] T004 [US3] `sources/Projects/Core/CoreHTTPTests/TestDouble/RecordingTransport.swift`에
  `HTTPTransport`를 구현하는 테스트 대역을 작성한다. 미리 정한 `HTTPTransportResponse`
  반환, 지정한 `HTTPClientError` 던지기, 응답하지 않고 무기한 대기, 취소를 관찰할 때까지
  대기하는 네 가지 동작을 선택할 수 있어야 하고, 전달받은 `HTTPTransportRequest` 전부와
  호출 횟수를 순서대로 기록해야 한다(US3-2, US3-3, SC-008)
- [X] T005 [P] [US1] `sources/Projects/Core/CoreHTTPTests/TestDouble/StubBodyCoding.swift`에
  `HTTPBodyCoding`을 구현하는 JSON 변환 대역과, 인코딩·디코딩이 각각 실패하는 대역을
  작성한다. 빈 본문 허용 여부를 선택할 수 있어야 한다(A-10, B-5, B-6)
- [X] T006 [P] [US1] `sources/Projects/Core/CoreHTTPTests/RequestCompositionTests.swift`에
  quickstart A-1~A-6 검증을 작성한다: 기본 주소·공통 헤더 결합, 끝 슬래시 유무가 결과를
  바꾸지 않음, 표기만 다른 헤더의 단일 병합, 공백·비ASCII·`+`·`&`·`=` 쿼리 값의 무손실
  전송, 같은 이름 쿼리의 순서 보존과 빈 값 유지, 요청 본문 변환 결과 전송
- [X] T007 [P] [US1] `sources/Projects/Core/CoreHTTPTests/ResponseDeliveryTests.swift`에
  quickstart A-7~A-11·A-13 검증을 작성한다: 2xx 본문 변환 전달, 비2xx의 원형 본문 전달과 실패
  아님, 비2xx 본문이 성공 형식과 달라도 정상 응답, 빈 본문의 규칙 위임, 원소 없는 목록의
  정상 전달, 응답 헤더의 대소문자 무관 조회
- [X] T008 [P] [US2] `sources/Projects/Core/CoreHTTPTests/ErrorClassificationTests.swift`에
  quickstart B-1~B-8과 B-10 검증을 작성한다: 여섯 원인이 서로 다르게 전달되는지,
  `requestEncodingFailed`·`invalidURL`에서 전송 수단이 한 번도 호출되지
  않는지, 연결 실패나 시간 초과 뒤 `HTTPClient`가 같은 전송 수단을 다시 호출하지 않아 한 번의
  `HTTPClient.send` 호출당 `HTTPTransport.send` 호출 횟수가 1회인지, `default` 없는 `switch`로
  여섯 케이스를 모두 분기할 수 있는지
- [X] T010 [P] [US3] `sources/Projects/Core/CoreHTTPTests/TransportSubstitutionTests.swift`에
  quickstart C-1~C-4 검증을 작성한다: 미리 정한 응답 전달, 지정한 실패 전달, 기록된
  `HTTPTransportRequest`로 요청 방식·절대 주소·부호화된 쿼리·병합된 헤더·변환된 본문 검사,
  비2xx 상태 코드와 원형 본문 검사
- [X] T011 [P] [US1] [US2] quickstart D-1~D-4 검증을 책임에 따라 두 파일로 나눠 작성한다.
  `sources/Projects/Core/CoreHTTPTests/ConfigurationDefaultsTests.swift`에 D-1~D-3(대기 한도를
  지정하지 않은 클라이언트의 15초 확정, 요청별 값이 생성 시 값을 대신함,
  `HTTPClient.defaultResponseTimeout`이 유일한 정의 지점)을 담는다(FR-007, SC-012, SC-013).
  `sources/Projects/Core/CoreHTTPTests/ConcurrencyIsolationTests.swift`에 D-4와 취소 우선
  검증을 담는다. D-4는 요청 10개를 동시에 보내고 1개만 취소해 나머지 9개가 각자의 결과를
  받는지 검증한다(FR-010, SC-006). SC-011 테스트는 벽시계 경쟁으로 작성하지 않는다. 전송
  대역이 취소를 관찰할 때까지 대기하도록 구성하고 대기 한도를 그보다 충분히 크게 두어
  "취소가 먼저 관찰된 상태"를 결정적으로 만든 뒤 반복 실행해 항상 `cancelled`가 나오는지
  검증한다(SC-011)
- [X] T012 [no-write] `xcodebuild test -workspace GitIt.xcworkspace -scheme CoreHTTP
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`를 실행해 T004~T008·T010~T011이 `CoreHTTP`
  타입 미구현으로 컴파일 실패하는지 확인한다(Red 단계)

### 구현 — 요청 값 타입 (US1)

- [X] T013 [P] [US1] `sources/Projects/Core/CoreHTTP/HTTPMessage/HTTPMethod.swift`에 연관값 없는
  `public enum HTTPMethod: Sendable`을 `get`, `post`, `put`, `patch`, `delete`, `head` 여섯
  케이스로 구현한다. 문자열을 받는 공개 생성자를 두지 않고 전송 표기(`GET` 등)는 내부
  프로퍼티로만 노출한다(FR-021, data-model.md §1)
- [X] T014 [P] [US1] `sources/Projects/Core/CoreHTTP/HTTPMessage/HTTPRequest+QueryItem.swift`에
  `extension HTTPRequest`로 `name: String`, `value: String`(선택적 아님)을 갖는
  `public struct QueryItem`을 중첩 구현한다. 최상위 `HTTPQueryItem`으로 두지 않는다. 빈 값도
  유효하며 부호화하지 않은 원본을 보관한다(FR-019, FR-020, research.md §16)
- [X] T015 [P] [US1] `sources/Projects/Core/CoreHTTP/HTTPMessage/HTTPHeaders.swift`에 헤더
  모음을 구현한다. 키는 `String`이며 **내부에서** 소문자로 정규화해 보관한다. 이름 전용 래퍼
  타입은 만들지 않는다. `subscript(name: String)`(표기 무관 조회·설정), `overridden(by:)`(인자
  우선), `names`·`all` 열거, `ExpressibleByDictionaryLiteral`을 제공한다
  (FR-022, research.md §5, §16)
- [X] T016 [US1] `sources/Projects/Core/CoreHTTP/HTTPMessage/HTTPRequest.swift`에 `method`,
  `path`, `queryItems: [QueryItem]`(기본 빈 배열), `headers`(기본 `[:]`),
  `responseTimeout: Duration?`(기본 `nil`)을 갖는 `public struct HTTPRequest`를 구현한다.
  본문은 담지 않는다(FR-001, FR-007)

### 구현 — 응답 값 타입과 실패 (US1, US2)

- [X] T017 [P] [US1] `sources/Projects/Core/CoreHTTP/HTTPMessage/HTTPResponse+Body.swift`에
  `extension HTTPResponse`로 `public enum Body: Sendable`을 `decoded(Value)`와 `raw(Data)`
  두 케이스로 중첩 구현한다. 바깥 제네릭 `Value`를 그대로 쓰며 최상위 `HTTPResponseBody`로
  두지 않는다. `raw`는 변환 실패가 아니라 변환 대상이 아니었던 본문이다
  (FR-002, research.md §16)
- [X] T018 [US1] `sources/Projects/Core/CoreHTTP/HTTPMessage/HTTPResponse.swift`에
  `statusCode: Int`, `headers`, `body: Body`를 갖는
  `public struct HTTPResponse<Value: Sendable>`를 구현한다. 제네릭 이름은 `Value`이며 중첩 타입
  이름 `Body`와 겹치지 않게 한다. 상태 코드
  래퍼 타입을 만들지 않고 `Int`를 그대로 쓰며, 의미별 케이스나 성공 판정 프로퍼티도 두지
  않는다(FR-002, FR-003, research.md §7, §16)
- [X] T019 [P] [US2] `sources/Projects/Core/CoreHTTP/Client/HTTPClientError.swift`에 연관값
  없는 평면 여섯 케이스(`invalidURL`, `requestEncodingFailed`, `connectionFailed`,
  `timedOut`, `cancelled`, `responseDecodingFailed`)를 구현한다(FR-004)

### 구현 — 본문 변환 계약과 전송 seam (US1, US3)

- [X] T020 [P] [US1] `sources/Projects/Core/CoreHTTP/Client/HTTPBodyCoding.swift`에
  `func encode(_ body: some Encodable) throws -> Data`와
  `func decode<Body: Decodable>(_ type: Body.Type, from data: Data) throws -> Body`를 함께
  요구하는 `public protocol HTTPBodyCoding: Sendable`을 정의한다. 프로토콜을 방향별로 나누지
  않고, 구체 구현도 제공하지 않는다(FR-014, research.md §11, §16)
- [X] T021 [P] [US3] `sources/Projects/Core/CoreHTTP/Transport/HTTPTransportRequest.swift`에
  `url: URL`, `method`, `headers`, `body: Data?`, `responseTimeout: Duration`을 갖는 해소
  완료 전송 단위를 구현한다. **타입은 public이되 생성자는 internal**로 둔다. `HTTPClient`만
  만들고 대체 구현은 받아서 읽기만 한다(FR-005, research.md §12)
- [X] T022 [P] [US3] `sources/Projects/Core/CoreHTTP/Transport/HTTPTransportResponse.swift`에
  `statusCode: Int`, `headers`, `body: Data`를 갖는 원형 응답 타입을 구현한다. 대체 구현이
  직접 구성할 수 있도록 **공개 생성자**를 제공한다(FR-011, research.md §12)
- [X] T023 [US3] `sources/Projects/Core/CoreHTTP/Transport/HTTPTransport.swift`에
  `func send(_ request: HTTPTransportRequest) async throws(HTTPClientError) ->
  HTTPTransportResponse`를 요구하는 `public protocol HTTPTransport: Sendable`을 정의한다.
  구현체는 `connectionFailed`, `timedOut`, `cancelled`만 던진다(FR-011, FR-005)

### 구현 — 클라이언트 (US1, US2)

- [X] T024 [US1] `sources/Projects/Core/CoreHTTP/Client/RequestURLBuilder.swift`에 기본
  주소·상대 경로·쿼리를 절대 주소로 조립하는 **internal** `struct RequestURLBuilder`를
  구현한다. `HTTPClient`만 쓰며 공개 표면에 등장하지 않는다. 경로 결합은
  `URL.appending(path:)`를 쓰고 `URL(string:relativeTo:)`는 쓰지 않는다. 쿼리는
  `URLComponents.queryItems`를 쓰지 않고 `CharacterSet.urlQueryAllowed`에서 `+`, `&`, `=`,
  `?`, `#`을 뺀 집합으로 이름·값을 직접 백분율 부호화한 뒤 지정 순서대로 `&`로 이어
  `percentEncodedQuery`에 대입한다. 조립에 실패하면 `invalidURL`을 던진다
  (FR-019, FR-020, research.md §3, §4)
- [X] T025 [US1] `sources/Projects/Core/CoreHTTP/Client/HTTPClient.swift`에 불변 값만 갖는
  `public struct HTTPClient: Sendable`을 구현한다. 별도 구성 타입을 만들지 않고 생성자가
  `baseURL`, `bodyCoding`, `commonHeaders`(기본 `[:]`), `responseTimeout`(기본
  `HTTPClient.defaultResponseTimeout`), `transport`를 직접 받는다. `transport`를 생략하는
  두 번째 생성자는 본문에서 `URLSessionTransport()`를 구성한다(internal 타입이라 기본 인자로
  둘 수 없다). `public static let defaultResponseTimeout: Duration = .seconds(15)`을 유일한
  기본값 정의 지점으로 둔다. 두 `send` 오버로드(본문 없음·본문 있음)의 응답 제네릭은
  `ResponseBody`로, 요청 본문 제네릭은 `RequestBody`로 이름 짓는다(`HTTPResponse<Body>`와
  `HTTPResponse<Value>`의 제네릭 이름은 그대로 둔다). 두 오버로드에서 계약 문서의 처리
  순서 1~4·6~7을 따른다: 대상 조립 → 공통 헤더에 요청별 헤더 덮어쓰기 → 본문이 있으면
  `bodyCoding.encode`(실패 시 `requestEncodingFailed`, 서버 전송 없음) → 대기 한도 확정 →
  상태 코드가 200...299면 `bodyCoding.decode`(실패 시 `responseDecodingFailed`) → 그 밖이면
  `raw`로 담기
  (FR-001, FR-002, FR-003, FR-006, FR-007, FR-014, FR-018, SC-013, contracts §5)
- [X] T026 [US2] `sources/Projects/Core/CoreHTTP/Client/HTTPClient.swift`에 마감 시한과 취소
  우선 판정을 구현한다(처리 순서 5). `withThrowingTaskGroup`으로 전송 작업과
  `Task.sleep(for:)` 마감 작업을 경쟁시키고 먼저 끝난 쪽을 채택한 뒤 나머지를 취소한다.
  취소 우선은 세 단계로 고정한다: (1) 마감 자식은 `Task.sleep` 후
  `Task.checkCancellation()`을 먼저 수행한 뒤에만 시간 초과를 던진다, (2) 오류를 매핑하기
  전에 `Task.isCancelled`를 확인해 참이면 `cancelled`, (3) 시간 초과로 매핑하려는 경우에만
  `await Task.yield()` 후 취소를 한 번 더 확인한다. 자동 재시도를 넣지 않는다
  (FR-008, FR-009, FR-015, SC-011, research.md §10)

### 구현 — 실제 전송 수단 (US1, US2)

- [X] T027 [US1] [US2] `sources/Projects/Core/CoreHTTP/Transport/URLSessionTransport.swift`에
  `HTTPTransport`를 구현하는 **internal** `struct URLSessionTransport`를 작성한다. public이
  아니어야 한다. `URLSessionConfiguration`으로 전용 세션을 만들되 `waitsForConnectivity =
  false`로 두고 `data(for:)`의 표준 HTTP 리다이렉트 자동 추적을 사용한다. 테스트에서
  `URLProtocol` 대역을 등록한 session configuration을 주입할 수 있는 internal 생성자를 제공한다.
  `URLRequest.timeoutInterval`에 확정된 대기 한도를 설정하고, `URLError`를
  `cancelled`(`.cancelled`), `timedOut`(`.timedOut`),
  `connectionFailed`(그 외, `HTTPURLResponse` 캐스팅 실패와 `URLError`가 아닌 오류 포함)로
  분류하고, 매핑 전에 `Task.isCancelled`를 먼저 확인한다. `URLError`를 포함한 외부 오류가
  이 파일 밖으로 나가지 않아야 한다(FR-005, FR-016, research.md §8, §9)
- [ ] T028 [US1] `sources/Projects/Core/CoreHTTPTests/ResponseDeliveryTests.swift`에 `URLProtocol`
  대역을 추가해 quickstart A-12를 검증한다. 대역이 3xx와 이동 대상을 제공하면
  `URLSessionTransport`가 이동 대상 요청을 자동 전송하고 최종 응답만 전달하는지, 실제 외부
  네트워크에 접속하지 않고 확인한다(FR-016, SC-003, SC-008)

### 정리와 패키지 검증

- [ ] T029 [no-write] `xcodebuild test -workspace GitIt.xcworkspace -scheme CoreHTTP
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`를 실행해 T004~T008·T010~T011의 모든
  테스트가 통과하는지 확인한다(Green 단계). 실패가 남으면 원인을 기록하고 해당 구현
  작업으로 돌아간다
- [ ] T030 [no-write] SC-004를 확인한다. `CoreHTTP`의 공개 선언을
  `contracts/http-client-api.md`의 공개 표면과 대조해 `URLSession`, `URLRequest`,
  `URLResponse`, `HTTPURLResponse`, `URLError`, `URLComponents`, `URLQueryItem`이 public API
  서명에 없음을 확인한다. `URLSessionTransport`가 internal이므로 이 검사에 걸리지 않아야 한다
- [ ] T031 [no-write] FR-023과 FR-005를 코드 검토로 확인한다.
  `sources/Projects/Core/CoreHTTP/`에 로깅 호출과 호출자용 관찰 훅이 없고, `URLError`
  처리가 `Transport/URLSessionTransport.swift` 안에서만 이뤄지는지 검사한다. 최상위 공개
  타입이 10개이고 중첩 타입이 `HTTPRequest.QueryItem`·`HTTPResponse.Body` 둘인지, 제거하기로
  한 `HTTPHeaderName`·`HTTPStatusCode`·`HTTPClientConfiguration`과 방향별 변환 프로토콜,
  중첩하기로 한 `HTTPQueryItem`·`HTTPResponseBody`, 이름을 바꾼 `HTTPHeaderFields`가 다시
  생기지 않았는지 함께 확인한다(research.md §16)

**승인 게이트**: T001~T031의 변경 파일과 검증 결과를 보고한 뒤 중단한다. `Core`는 이
명세의 유일한 적용 대상 패키지이므로 이후 패키지 단계는 없다. 아래 전체 완료 검증은 이
보고와 사용자 확인 뒤에만 실행한다.

---

## 전체 완료 검증

**선행 조건**: `Core` 패키지의 구현·검증·결과 보고가 완료되어야 한다. 이 단계는 파일을
변경하지 않는다.

- [ ] T032 [no-write] 저장소 루트에서
  `project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh
  GIT_IT_PROJECT_BUILD_RUNNER)`로 경로를 구한 뒤 `"$project_build_runner" build`,
  `"$project_build_runner" compile`, `"$project_build_runner" test`를 순서대로 실행하고
  결과를 기록한다. 세 명령은 `sources/DerivedData/PreCommit`을 공유하므로 순차 실행한다
- [ ] T033 [no-write] 사용자 스토리별 독립 수용 시나리오를 검증한다. US1은 quickstart
  A-1~A-13, US2는 B-1~B-8과 B-10, US3은 C-1~C-4, 구성·동시성은 D-1~D-5의 결과로 확인하고, 실제
  네트워크에 접속한 테스트가 0건인지 함께 확인한다(SC-003)

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

- 이 명세의 적용 대상 패키지는 `Core` 하나다. `Domain → Data → Core → Composition → UI →
  Feature → App` 순서에서 나머지 패키지는 변경 대상이 아니므로 건너뛴다.
- 한 번에 한 패키지만 구현한다. `Core`의 모든 작업과 검증이 끝나기 전에는 전체 완료 검증을
  시작하지 않는다.
- `Core`의 변경 파일과 검증 결과를 보고하고 명시적 사용자 승인을 받은 뒤 전체 완료 검증으로
  진행한다.
- 후속 작업에서 `Core` 밖 패키지 수정이 필요해지면 구현을 중단하고 `/speckit-tasks`로 작업
  소유권과 실행 순서를 다시 조정한다. Composition Adapter 구현은 이 명세의 범위 제외이며
  별도 명세가 다룬다.

### 사용자 스토리 추적성

| 사용자 스토리 | 작업 | 독립 수용 기준 |
| --- | --- | --- |
| US1 요청 전송과 응답 수신 (P1) | T001, T002, T005~T007, T013~T018, T020~T022, T024~T025, T027~T028 | quickstart A-1~A-13이 모두 통과한다 |
| US2 실패 원인 구분 (P2) | T008, T011, T019, T026, T027 | quickstart B-1~B-8과 B-10이 모두 통과하고 여섯 원인이 `default` 없는 `switch`로 분기된다 |
| US3 실제 서버 없는 검증 (P3) | T001~T004, T010, T021~T023 | quickstart C-1~C-4가 실제 네트워크 없이 통과한다 |

- 사용자 스토리는 `Core` 패키지가 완료된 뒤 위 기준으로 독립 검증한다.
- MVP 범위도 패키지 승인 게이트를 건너뛰지 않는다.

### 패키지 내부 실행

- 테스트(T004~T008·T010~T011)를 구현 전에 작성하고 T012에서 예상한 이유(타입 미구현으로 인한 컴파일
  실패)로 실패하는지 확인한다.
- `[P]`는 승인된 `Core` 패키지 안의 서로 다른 파일에만 사용한다.
- T025와 T026은 같은 파일(`HTTPClient.swift`)을 변경하므로 순차 실행한다.
- T016은 T013·T014·T015에, T018은 T017에, T028은 T027에 의존한다.
- T024·T025·T026은 T013~T023이 모두 끝난 뒤 실행한다.

### 패키지 내부 병렬 실행 예시

```text
# 테스트 대역과 테스트 작성 — T004 완료 후 함께 실행 가능
T005, T006, T007, T008, T010, T011

# 값 타입 1라운드 — 함께 실행 가능
T013, T014, T015, T017, T019

# 값 타입 2라운드(1라운드 완료 후) — 함께 실행 가능
T016, T018

# 계약과 전송 seam — 함께 실행 가능
T020, T021, T022

# 전송 수단과 자동 리다이렉트 검증 — T027 완료 후 T028
T027 → T028
```

## 구현 전략

1. `Core`(유일한 적용 대상 패키지)의 준비 T001~T003을 완료해 target과 scheme을 만든다.
2. 테스트 T004~T008·T010~T011을 작성하고 T012로 Red를 확인한다.
3. 값 타입·계약·seam(T013~T023), 클라이언트(T024~T026), 전송 수단과 자동 리다이렉트 검증(T027~T028)을 구현한다.
4. T029~T031로 패키지를 검증하고, 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다.
5. 사용자 승인 후에만 T032~T033의 읽기 전용 전체 검증과 스토리 수용 검증을 실행한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 파일 변경 작업은 정확한 경로를 포함한다. 이 목록의 경로가
  `/speckit-implement`의 쓰기 허용 목록이다.
- 사용자 스토리 독립성은 유지하되 구현·승인 단위는 `Core` 패키지다.
- 모호한 소유권, 다중 패키지 작업, 승인 게이트를 넘는 병렬 실행을 허용하지 않는다.
- 문제 해결과 암묵지 기록은 구현 작업 ID로 만들지 않는다. 실제 문제가 발생하면
  `$speckit-troubleshooting`이 별도로 기록한다.
