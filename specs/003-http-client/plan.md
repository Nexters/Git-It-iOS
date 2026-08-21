# 구현 계획: HTTP 통신 기술 API

**Git-flow 유형**: `feature`

**브랜치**: `feature/http-client` (생성됨)

**날짜**: 2026-08-14 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/003-http-client/spec.md`의 기능 명세

**참고**: 이 템플릿은 `/speckit-plan`이 채운다. 스킬 정의에는 실행 흐름이 설명되어 있다.

## 요약

`Core` 패키지에 신규 target `CoreHTTP`를 만들어 HTTP 요청-응답 통신을 프로젝트 소유의 범용
기술 API로 제공한다. 공개 경계는 요청 값(`HTTPRequest`, `HTTPMethod`, `HTTPHeaders`),
응답 값(`HTTPResponse`), 여섯
가지 실패 원인(`HTTPClientError`), 호출자가 소유하는 본문 변환 계약(`HTTPBodyCoding`)과
대체 가능한 전송 수단(`HTTPTransport`)으로 구성한다. URL Loading System 타입은 `URLSessionTransport` 안에만 두고 경계 밖으로 내보내지
않는다.

설계에서 특히 중요한 세 가지는 조사에서 실측으로 확정했다(research.md).

1. **요청 대상 조립과 쿼리 부호화**: `URL(string:relativeTo:)`는 기본 주소의 경로를 조용히
   버리고, `URLComponents.queryItems`는 `+`를 부호화하지 않아 값의 의미를 손상시킨다. 각각
   `URL.appending(path:)`와 직접 백분율 부호화로 대체한다.
2. **리다이렉트 자동 추적**: `URLSession`의 기본 동작을 그대로 사용해 3xx 이동 대상을
   자동 요청하고 최종 응답만 전달한다.
3. **마감 시한과 취소 우선**: 마감을 `HTTPClient`가 소유해야 실제 네트워크 없이 시간 초과를
   검증할 수 있다. 취소 우선(FR-009)은 판정 순서를 고정해야 성립하며, SC-011 검증은 벽시계
   경쟁이 아니라 "취소가 먼저 관찰된 상태"를 결정적으로 구성해 수행해야 한다.

## 기술 맥락

**언어/버전**: Swift — tools-version 6.0, target 언어 모드 5.0(`Target+Module.swift`의
`SWIFT_VERSION: 5.0`). 타입 지정 throws(`throws(HTTPClientError)`)를 이 모드에서 사용할 수
있음을 실측으로 확인(research.md §2)

**주요 의존성**: Foundation(URL Loading System 포함)만 사용. 외부 SPM 패키지 의존성 없음.
Core는 프로젝트 내부 패키지에 의존하지 않는다(package-rules/core.md)

**저장소**: N/A — 이 기능은 상태를 보관하지 않는다. 캐시와 오프라인 보관은 명세의 범위 제외

**테스트**: Swift Testing(`import Testing`, `@Suite`, `@Test`, `#expect`)과 백틱 한국어
테스트 이름. 기존 `CoreAuthenticationTests` 관례를 따름

**대상 플랫폼**: iOS 26.0+

**프로젝트 유형**: 모바일 앱(Tuist 다중 모듈). 이 기능은 `Core` 패키지에 `CoreHTTP`와
`CoreHTTPTests` target을 추가한다

**성능 목표**: N/A — 요청당 처리는 문자열 부호화와 본문 변환 위임뿐이며 명세에 처리량·지연
목표가 없다. 대기 한도(기본 15초)는 성능 목표가 아니라 기능 요구사항(FR-007, FR-008)이다

**제약 조건(명세에서 도출)**: 공개 API에 URL Loading System 타입 비노출(FR-005, SC-004) ·
자동 재시도 금지와 리다이렉트 자동 추적(FR-015, FR-016) · 상태 코드의 서비스적 의미 판단
금지(FR-003) · 자체 기록과 관찰 수단 제공 금지(FR-023) · 자동 테스트는 실제 네트워크에
의존하지 않음(SC-003)

**제약 조건(실측에서 확정)**: 아래는 계획 단계에서 실제로 실행해 확인한 제약이다. 위반하면
컴파일 성공 여부와 무관하게 런타임 또는 검증이 깨진다.

| 제약 | 위반 시 결과 | 근거 |
| --- | --- | --- |
| SC-011(취소 우선) 검증은 벽시계 경쟁이 아니라 "취소가 먼저 관찰된 상태"를 결정적으로 구성한다 | 실시간 경쟁 200회 중 14회가 `timedOut`으로 나와 반복 실행에서 실패한다 | research.md §10 |
| `ProjectName.swift`의 `case .Core` scheme 목록에 `CoreHTTP`를 등록한다 | `automaticSchemesOptions: .disabled`이므로 scheme이 없으면 `CoreHTTP`가 빌드도 테스트도 되지 않는다 | research.md §2 |
| scheme을 `testTarget:`과 함께 선언한다 | `project-build`가 `<TestableReference`로 테스트 대상을 판별하므로 없으면 `compile`·`test`에서 제외된다 | `tools/githooks/project-build/core/workspace.sh:36`, `core/scheme-policy.sh:19-23` |
| `CoreModuleName`의 `targets` 배열에 항목을 추가한다 | 이 enum은 `CaseIterable`이 아니라 명시적 배열을 쓰므로 케이스만 추가하면 target이 생성되지 않는다 | research.md §2 |

계약 서명이 의존하는 타입 시스템 성립 여부(프로토콜 요구사항의 타입 지정 throws,
existential 호출, `URLSession` 보유 타입의 `Sendable`, 기본 인자의 자기 타입 static 참조)는
언어 모드 5에서 모두 확인했다. 표는 research.md §2에 있다.

**규모/범위**: 신규 target 2개, 프로덕션 Swift 파일 15개, 최상위 공개 타입 10개
(`HTTPMethod`, `HTTPHeaders`, `HTTPRequest`, `HTTPResponse`, `HTTPClientError`,
`HTTPBodyCoding`, `HTTPClient`, `HTTPTransport`, `HTTPTransportRequest`,
`HTTPTransportResponse`) + 중첩 2개(`HTTPRequest.QueryItem`, `HTTPResponse.Body`)
+ internal 2개(`URLSessionTransport`, `RequestURLBuilder`).
Tuist 설정 파일 2개 수정

명세가 요구하지 않는 래퍼 타입은 두지 않는다. 초안의 `HTTPHeaderName`, `HTTPStatusCode`,
`HTTPClientConfiguration`을 제거하고 본문 변환 프로토콜 두 개를 `HTTPBodyCoding` 하나로
합쳐 17개를 12개로 줄인 뒤, 소유자가 하나뿐인 두 타입을 중첩해 최상위 10개로 정리했다.
잃는 FR·SC는 없다(research.md §16)

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

- **명시적인 경계(원칙 1)**: `CoreHTTP`는 프로젝트 내부 패키지에 의존하지 않고 Tuist
  의존성도 추가하지 않는다. Core 규칙의 "target 하나당 범용 기술 기능 하나"에 따라 기존
  `CoreAuthentication`과 분리한다(research.md §1). 순환 의존은 발생하지 않는다. **통과**.
- **상태와 데이터 안전성(원칙 2)**: `HTTPClient`는 불변 값만 갖는 `Sendable` 구조체이며 공유
  가변 상태를 두지 않는다(research.md §14). 비동기 작업의 오류 경로는
  `HTTPClientError` 여섯 케이스로, 취소 경로는 취소 우선 판정으로 모두 처리한다
  (FR-004, FR-009). **통과**.
- **검증 가능한 변경(원칙 3)**: 동작 검증은 `CoreHTTPTests`와 빌드 결과로 남긴다. 계획
  단계에서 Git index나 작업 파일을 바꾸는 명령을 실행하지 않았으므로 Git 실행 직렬화 규칙에
  저촉되지 않는다. 조사에 사용한 검증 스크립트와 로컬 서버는 저장소 밖 임시 디렉터리에서
  실행하고 종료했다. **통과**.
- **스킬별 수정 경로(원칙 4·5)**: 이 명령은 `specs/003-http-client/`의 `plan.md`,
  `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 만들었다.
  `sources/**`와 Tuist 설정은 아래 "프로젝트 구조"에 경로만 기록하고 `tasks.md`가 실제
  변경을 배정한다. **통과**.
- **패키지 단위 구현 진행(원칙 7)**: 아래 "패키지 진행" 참조. 적용 대상 패키지는 `Core`
  하나다. **통과**.
- **한국어 Spec-Kit 산출물(원칙 6)**: 이 문서를 포함한 모든 계획 산출물을 한국어로 작성했다.
  Swift 식별자, 명령어, 파일 경로, 외부 API 고유 명칭만 원문을 유지한다. **통과**.
- **Git-flow 브랜치 네임스페이스(원칙 8)**: 현재 브랜치는 `feature/http-client`로 이미
  `feature/` 네임스페이스를 사용한다. 접미사는 소문자 kebab-case이고 추가 `/`가 없다. 이
  계획은 브랜치를 새로 만들지 않는다. spec 디렉터리 이름 `003-http-client`는 브랜치 이름과
  독립적으로 유지한다. **통과**.
- **책임과 문맥에 따른 네이밍(원칙 10)**: 아래 "책임 기반 네이밍" 참조. **통과**.

**브랜치 네임스페이스**: 이 헌법 개정 후 새로 생성한 브랜치는 `feature/`, `hotfix/`,
`release/` 중 목적에 맞는 네임스페이스를 사용해야 한다. 개정 전에 생성된 기존 브랜치는
소급해 바꾸지 않고 기존 브랜치임을 기록한다. 생성 훅이 실행되지 않았다면 실제 브랜치가
생성된 것처럼 기록하지 않는다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정할 수 있다. 이 산출물 밖의 구현 파일은 정확한
경로를 `tasks.md`에 기록하며 계획 단계에서는 수정하지 않는다.

**세션 지식 기록**: 실제 문제가 발생하면 `/speckit-troubleshooting`, 여러 세션의 독립
근거에서 암묵적인 판단 기준을 해석하면 `/speckit-tacit-knowledge`가 각 전용 파일에
append-only로 기록한다. 두 파일은 계획 산출물이나 구현 작업이 아니며 조건을 충족하지
않으면 빈 파일을 만들지 않는다.

이번 계획 실행에서 여러 세션에 걸친 독립 근거의 해석은 없었으므로 `tacit-knowledge.md`는
만들지 않는다.

**Git 실행 직렬화**: 같은 checkout에서 `git commit`, pre-commit과 staged formatter처럼
Git index, 작업 파일 또는 공유 formatter cache를 사용하는 변경 체인은 하나만 실행한다.
기존 체인의 종료와 결과를 확인하기 전에는 재시도하지 않으며, 중복 실행을 발견하면 실행
소유자와 index·작업 파일 상태를 확인하고 사용자 승인 없이 임의로 종료하지 않는다. 읽기
전용 Git 조회, 서로 다른 checkout과 실행별로 격리된 build·test 경로는 이 제한에서 제외한다.

**책임 기반 네이밍**: 프로젝트가 소유하는 공개 API와 경계를 넘는 값은 실제 책임과 필요한
최소 문맥을 드러내야 한다. 표면적인 통일만을 위한 공통 접두어·접미어·축약은 적용하지 않고,
저장·전달되는 값은 독립적으로 목적을 식별할 수 있게 계획한다. 외부 계약의 고정 이름은
보존하고 공급자 중립 경계에는 특정 공급자나 저장 기술의 용어를 노출하지 않는다. 네이밍과
설계·동작 변경이 함께 필요하면 범위와 검증을 분리한다.

이 기능에 적용한 판단은 다음과 같다([네이밍 컨벤션](../../docs/conventions/naming.md) 기준).

| 결정 | 근거 |
| --- | --- |
| target 이름을 `CoreHTTP`로 하고 `CoreNetwork(ing)`을 쓰지 않음 | 명세가 스트리밍·지속 연결·캐시를 배제하므로 실제 책임은 HTTP 요청-응답 하나다. §2.1(맡지 않는 미래 책임을 이름에 넣지 않음) |
| 공개 타입에 `HTTP` 접두어 사용 | 패키지 이름 반복(§5 금지)이 아니라 프로토콜 표준의 고정 약어다. §6이 `HTTP`를 인정한다 |
| 본문 변환을 `HTTPBodyCoding` 하나로 둠 | 방향별로 나누면 같은 구현체가 두 인자에 중복 주입될 뿐 실제 구분을 제공하지 못한다. §5의 "제거하면 어떤 실제 충돌이나 오해가 생기는가" 기준 미충족 |
| 상태 코드를 `Int`로 두고 래퍼·의미 케이스를 만들지 않음 | 상태 코드의 서비스적 의미는 Core가 소유하지 않는 책임이고(FR-003), 성공 여부는 `HTTPResponse.Body`가 이미 알려 준다. §4의 Core 문맥, §2.1 |
| `URLSessionTransport`에 플랫폼 고유 명칭 유지 | 그 대상을 직접 감싸는 Core 구현 경계이므로 §7이 허용한다 |
| `HTTPClient`(architecture.md §3.3의 기존 표기) 채택 | 아키텍처 문서가 이미 Data↔Core Adapter의 위임 대상으로 이 이름을 쓰고 있다 |
| `HTTPRequest`와 `HTTPTransportRequest` 분리 | 미해소 요청과 해소된 전송 단위는 수명과 내용이 다르다. §3.4의 방향·수명 구분 |
| 실패 타입을 `HTTPClientError`로 명명하고 케이스를 평면으로 유지 | 이 타입을 소유하고 던지는 주체가 `HTTPClient`다. 기존 Core의 `AppleAuthorizationError`·`KeychainStoreError`와 같은 `<소유 타입>Error` 형태이며, 같은 도메인의 `async-http-client`도 동명 타입을 쓴다. `HTTPRequestError`는 여섯 중 셋(`connectionFailed`, `timedOut`, `responseDecodingFailed`)이 요청과 무관해 실제 범위보다 좁고, HTTP 오류 응답을 담는 타입으로 오독될 여지가 있어 기각했다. research.md §9 |
| 케이스 이름을 생태계 표준 어휘로 채택 | `invalidURL`은 Alamofire `AFError.invalidURL`, `timedOut`·`cancelled`는 `URLError`의 동명 코드, `responseDecodingFailed`는 Alamofire `responseSerializationFailed`에 대응한다. 발명한 어휘를 쓰지 않아 경계 밖 독자가 원형을 복원할 필요가 없다. 네이밍 가이드 §6·§7 |
| 응답 본문의 비변환 케이스를 `raw`로 명명하고 `undecoded`를 쓰지 않음 | 부정형 이름은 판별 근거(성공 범위 밖)가 아니라 결과만 말하며, 같은 API의 `responseDecodingFailed`와 묶여 "변환을 시도했다가 실패한 본문"으로 오독된다. 실제 변환 실패는 값이 만들어지지 않고 던져진다. §2.1 |
| `send`의 응답 제네릭을 `ResponseBody`로 두고 `Body`를 쓰지 않음 | 본문 있는 오버로드에서 `RequestBody`와 짝을 이루어야 방향이 읽힌다. 반면 `HTTPResponse<Value>`의 중첩 `Body`는 타입 자체가 문맥을 제공하므로 수식어를 반복하지 않는다. §2.2 |
| 헤더 병합 연산을 `overridden(by:)`로 명명 | `merging(_:)`은 호출부에서 우선순위 방향이 보이지 않는다. 표준 `Dictionary.merging`이 `uniquingKeysWith:`를 강제하는 이유가 같다. §3.3(동사와 목적어가 실제 효과를 드러낸다) |
| URL 조립 타입을 `RequestURLBuilder`로 명명하고 `RequestTargetResolving`을 쓰지 않음 | 이 저장소에서 `target`은 Tuist target을 뜻하므로 같은 단어가 두 개념을 가리킨다. 또한 같은 개념을 `baseURL`·`HTTPTransportRequest.url`·`invalidURL`이 모두 URL로 부른다. §2.2 |
| 소유자가 하나뿐인 타입을 중첩(`HTTPRequest.QueryItem`, `HTTPResponse.Body`) | `body: HTTPResponseBody<Body>`처럼 한 선언에 같은 단어가 세 번 나오는 것은 소유 관계를 이름의 접두어로만 표현했기 때문이다. 중첩하면 구조가 그 관계를 표현하고 선언이 `body: Body`가 된다. `HTTPMethod`·`HTTPHeaders`는 소유자가 여럿이라, `HTTPTransportRequest`·`HTTPTransportResponse`는 Swift 프로토콜이 중첩 타입을 선언할 수 없어 최상위에 남는다. §2.2, research.md §16 |
| 헤더 모음을 `HTTPHeaders`로 명명하고 `HTTPHeaderFields`를 쓰지 않음 | HTTP에서 헤더 항목 자체가 field이므로 `HeaderFields`는 같은 말의 반복이다. `headers: HTTPHeaderFields`가 `body: Body`와 비대칭으로 읽히던 원인이기도 하다. Alamofire `HTTPHeaders`, Apple swift-http-types `HTTPFields`와 같은 계열이라 경계 밖 독자가 원형을 복원할 필요가 없다. §2.2, §6 |
| `HTTPHeaders`의 열거 프로퍼티를 `all`로 두고 `fields`를 쓰지 않음 | 타입이 이미 제공하는 문맥을 프로퍼티가 반복한다(`headers.fields`). `Sequence` 채택은 연산 집합이 바뀌는 설계 변경이므로 §8에 따라 이 범위에서 분리했다 |
| 테스트 대역을 `StubBodyCoding`으로 명명하고 `TestBodyCoding`을 쓰지 않음 | `Test`는 타깃 소속만 표시하고 책임을 설명하지 않는다(§5 금지). 같은 디렉터리의 `RecordingTransport`가 이미 동작으로 명명돼 있어 어휘도 어긋났다 |
| 테스트를 `ConfigurationDefaultsTests`와 `ConcurrencyIsolationTests`로 분리 | 한 이름이 무관한 두 책임(기본값 확정 D-1~D-3, 동시성 격리 D-4)을 결합하고 있었다. §2.1 |

`HTTPRequest.QueryItem`은 `URLQueryItem`과 역할이 같지만 `value`가 선택적이지 않다. 생태계
가독성을 위해 이름을 유지하되 그 차이를 계약 문서에 명시했다(§7: 외부 계약과의 대응을 숨기지
않는다).

다음 두 이름은 검토 후 현행을 유지하기로 결정했다.

| 유지 결정 | 근거 |
| --- | --- |
| `requestEncodingFailed`·`responseDecodingFailed`에 `Body`를 넣지 않음 | 실패하는 대상이 본문 변환이라는 점에서 `requestBodyEncodingFailed`가 더 정확하지만, 위 "생태계 표준 어휘" 결정과 충돌한다. 대신 `invalidURL`과의 경계를 계약 문서의 케이스 의미 항목으로 구분한다 |
| `HTTPClient.init`의 `responseTimeout`에 `common` 접두어를 붙이지 않음 | `commonHeaders`와 역할은 같지만, 같은 이름이 `HTTPRequest`·`HTTPTransportRequest`에도 있어 선별 치환이 필요하고 오적용 위험이 이득보다 크다. fallback 관계는 계약 문서의 처리 순서 4단계가 규정한다 |

이 기능은 신규 선언만 추가하고 기존 선언을 rename하지 않으므로 §8의 rename 분리 기준은
적용 대상이 없다. 위 네이밍 조정은 모두 구현 착수 전 설계 산출물 안에서 이뤄졌고 `spec.md`와
`checklists/`의 요구사항 문장은 바뀌지 않았다.

**패키지 진행**: 현재 명세가 변경하는 패키지를 식별하고 `Domain → Data → Core →
Composition → UI → Feature → App` 순서로 구현 경계를 계획한다. 적용되지 않는 패키지는
건너뛰며, 각 적용 대상 패키지는 구현·검증·결과 보고·사용자 승인 후에만 다음 패키지로
진행한다.

**이 기능의 적용 대상 패키지는 `Core` 하나다.**

| 패키지 | 적용 | 근거 |
| --- | --- | --- |
| Domain | 제외 | 비즈니스 모델·정책을 바꾸지 않는다. 명세 범위 제외에 서비스 의미 해석이 들어 있다 |
| Data | 제외 | DTO·Data 계약을 정의하지 않는다. 명세 범위 제외에 특정 서비스 형식이 들어 있다 |
| **Core** | **적용** | 범용 기술 API 신설. 이 명세의 전부 |
| Composition | 제외 | Data↔Core Adapter 구현은 명세 범위 제외("실제 서버 연동을 위한 경계 변환 구현과 그 배치") |
| UI / Feature / App | 제외 | 화면·상태·흐름을 바꾸지 않는다 |

따라서 `tasks.md`는 **Core 단계 하나**만 정의하고, 그 단계 끝에 검증·결과 보고·사용자
승인 게이트를 둔다. 다음 적용 대상 패키지가 없으므로 순서 위반 가능성 자체가 없다.

**패키지에 속하지 않는 파일의 배정**: 아래 두 Tuist 설정 파일은 `sources/Projects/<패키지>`
밖에 있지만, 이 변경을 최초로 필요로 하는 책임 패키지는 `Core`다. 두 파일 모두 `Core`
단계에 배정한다.

| 파일 | 변경 내용 | 배정 |
| --- | --- | --- |
| `sources/Tuist/ProjectDescriptionHelpers/Projects/CoreModuleName.swift` | `CoreHTTP`·`CoreHTTPTests` 케이스와 target 정의 추가 | Core 단계 |
| `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift` | `case .Core`의 scheme 목록에 `CoreHTTP` scheme 추가 | Core 단계 |

두 파일의 변경은 모두 `Core` 프로젝트의 선언만 바꾸며 다른 패키지의 선언을 건드리지 않는다.
따라서 원칙 7이 금지하는 "여러 패키지의 선언을 바꾸는 공용 파일 작업"에 해당하지 않고,
패키지별로 분리할 필요가 없다. 배정 불가로 계획을 중단해야 하는 파일은 없다.

### 1단계 설계 후 재점검

Phase 1 산출물(data-model.md, contracts/http-client-api.md, quickstart.md)을 반영해도 위
게이트는 모두 그대로 통과한다. 설계에서 새로 확인한 사항은 다음과 같다.

- 설계가 추가한 target은 `CoreHTTP`와 `CoreHTTPTests` 둘뿐이며 모두 `Core` 패키지 내부
  산출물이다. 패키지 경계와 의존 방향이 바뀌지 않으므로 `docs/architecture.md`를
  수정할 필요가 없다(원칙 3: 아키텍처 문서는 구조 결정이 바뀔 때만 갱신).
- 테스트 전용 전송 수단 구현을 `CoreHTTPTests`가 소유하도록 해 프로덕션 target에 테스트
  코드가 들어가지 않는다(research.md §12).
- 본문 변환의 구체 구현을 `CoreHTTP`에 두지 않기로 한 결정(research.md §11)이 Core 규칙의
  "서비스 고유 데이터 형식 비소유"와 명세의 범위 제외를 동시에 만족한다.
- 정당화가 필요한 헌법 위반은 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/003-http-client/
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md        # 1단계 산출물(/speckit-plan)
├── quickstart.md        # 1단계 산출물(/speckit-plan)
├── contracts/
│   └── http-client-api.md   # 1단계 산출물(/speckit-plan)
├── checklists/
│   └── requirements.md      # /speckit-checklist 산출물(기존)
└── tasks.md             # 2단계 산출물(/speckit-tasks, /speckit-plan이 생성하지 않음)
```

### 소스 코드(저장소 루트)

아래 경로는 `tasks.md`가 `Core` 단계에 배정할 대상이며, 계획 단계에서는 생성·수정하지
않는다. 파일 분할은 기존 `CoreAuthentication`의 책임별 하위 디렉터리 관례를 따른다.

```text
sources/Projects/Core/
├── Project.swift                       # 기존 파일, 변경 없음(CoreModuleName.targets 참조)
├── CoreHTTP/                           # 신규 framework target
│   ├── HTTPMessage/                    # 요청·응답과 공유 HTTP 값
│   │   ├── HTTPMethod.swift
│   │   ├── HTTPRequest.swift
│   │   ├── HTTPRequest+QueryItem.swift # 중첩 QueryItem
│   │   ├── HTTPHeaders.swift            # String 키 소문자 정규화·덮어쓰기 병합
│   │   ├── HTTPResponse.swift           # statusCode는 Int
│   │   └── HTTPResponse+Body.swift      # 중첩 Body(decoded / raw)
│   ├── Client/
│   │   ├── HTTPClient.swift             # 생성 인자·해소·마감 경쟁·취소 우선·defaultResponseTimeout
│   │   ├── HTTPBodyCoding.swift         # encode+decode 한 프로토콜, 구체 구현 없음
│   │   ├── HTTPClientError.swift        # 연관값 없는 6 케이스
│   │   └── RequestURLBuilder.swift      # internal. appending(path:) + 직접 쿼리 부호화
│   └── Transport/
│       ├── HTTPTransport.swift
│       ├── HTTPTransportRequest.swift      # 타입 public, 생성자 internal
│       ├── HTTPTransportResponse.swift
│       └── URLSessionTransport.swift       # internal. 자동 리다이렉트, URLError 분류, URL Loading System 격리
└── CoreHTTPTests/                      # 신규 unitTests target
    ├── TestDouble/
    │   ├── RecordingTransport.swift    # 미리 정한 응답·실패, 요청 기록
    │   └── StubBodyCoding.swift        # HTTPBodyCoding 구현(JSON·실패·빈 본문)
    ├── RequestCompositionTests.swift   # quickstart A-1~A-6
    ├── ResponseDeliveryTests.swift     # quickstart A-7~A-13
    ├── ErrorClassificationTests.swift   # quickstart B-1~B-8, B-10
    ├── TransportSubstitutionTests.swift # quickstart C-1~C-4
    ├── ConfigurationDefaultsTests.swift # quickstart D-1~D-3
    └── ConcurrencyIsolationTests.swift # quickstart D-4
```

Tuist 설정 변경 대상(`Core` 단계에 배정):

```text
sources/Tuist/ProjectDescriptionHelpers/Projects/CoreModuleName.swift
  - CoreHTTP, CoreHTTPTests 케이스 추가
  - targets에 .module(name: "CoreHTTP", dependencies: [])  # Foundation만 사용
  - targets에 .testModule(name: "CoreHTTPTests", productionTarget: .target(name: "CoreHTTP"))
    ※ 이 enum은 CaseIterable이 아니다. 케이스만 추가하고 targets 배열에 넣지 않으면
      target이 생성되지 않는다

sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift
  - case .Core의 schemes에 .module(name: "CoreHTTP", testTarget: "CoreHTTPTests") 추가
    ※ Project.Options가 automaticSchemesOptions: .disabled이므로 이 등록이 없으면
      CoreHTTP는 빌드도 테스트도 되지 않는다
    → tools/githooks/project-build가 TestableReference 존재로 test 대상을 판별하므로
      testTarget: 인자를 반드시 함께 지정한다
```

**구조 결정**: 템플릿의 단일 프로젝트/웹/모바일+API 선택지는 이 저장소에 해당하지 않으므로
실제 Tuist 다중 모듈 경로로 대체했다. 신규 패키지를 만들지 않고 기존 `Core` 패키지에 target
두 개를 추가한다. 프로덕션 target 내부는 요청·헤더·응답·실패·본문 변환·클라이언트·전송
수단의 일곱 책임으로 디렉터리를 나눠, URL Loading System 사용이 `Transport/`에만 나타나도록
경계를 파일 배치로도 드러낸다. 테스트 대역은 프로덕션 target이 아니라 `CoreHTTPTests`가
소유한다.

## 복잡성 추적

> **헌법 점검에서 정당화해야 하는 위반이 있을 때만 작성한다**

해당 없음 — 헌법 점검의 모든 게이트를 위반 없이 통과했다.

## 다음 단계

`/speckit-tasks`로 `tasks.md`를 생성한다. `tasks.md`가 반드시 반영해야 할 제약은 다음과
같다.

1. 모든 파일 변경 작업을 **Core 단계 하나**에 배정하고, 단계 끝에 검증·보고·승인 게이트를
   둔다(원칙 7). Tuist 설정 파일 2개도 Core 단계에 포함한다.
2. SC-011(취소 우선) 테스트는 벽시계 경쟁이 아니라 "취소가 먼저 관찰된 상태"를 결정적으로
   구성해 작성한다. 실시간 경쟁으로 작성하면 반복 실행에서 실패한다(research.md §10).
3. 자동 테스트는 `URLSessionTransport`를 사용하지 않는다. 실제 네트워크 의존 테스트를
   만들지 않는다(SC-003).
4. SC-004(외부 타입 비노출)와 FR-023(기록·관찰 수단 없음)은 자동 테스트가 아니라
   quickstart.md의 계약 확인 절차로 검증한다.
5. Tuist 설정 작업은 scheme 등록(`testTarget:` 포함)과 `targets` 배열 추가를 각각 별도
   확인 항목으로 둔다. 둘 중 하나만 해도 컴파일은 통과하지만 `CoreHTTP`가 빌드·테스트
   대상에서 빠진다.
