# 빠른 시작: HTTP 통신 기술 API 검증

**날짜**: 2026-08-14 | **명세**: [spec.md](./spec.md) |
**계약**: [contracts/http-client-api.md](./contracts/http-client-api.md)

이 문서는 구현이 끝난 뒤 기능이 실제로 동작하는지 확인하는 실행 절차입니다. 타입의 상세
정의는 [data-model.md](./data-model.md), 서명은 계약 문서를 참조합니다. 구현 코드는 여기에
싣지 않으며 실제 작업 배정은 `tasks.md`가 담당합니다.

## 사전 조건

- `make init`으로 workspace와 Git 훅이 설치되어 있어야 합니다.
- Tuist 설정에 `CoreHTTP`·`CoreHTTPTests` target과 `CoreHTTP` scheme이 추가된 뒤
  `tuist generate`가 실행되어 있어야 합니다.
- **네트워크 연결은 필요하지 않습니다.** 모든 검증은 대체 전송 수단으로 수행합니다
  (FR-011, SC-003).

## 실행 절차

저장소 루트에서 실행합니다.

```bash
cd sources && tuist install && tuist generate
```

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER) && "$project_build_runner" build
```

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER) && "$project_build_runner" compile && "$project_build_runner" test
```

세 명령은 `sources/DerivedData/PreCommit`을 공유하므로 순차 실행을 전제로 합니다. 기본
테스트 대상은 `platform=iOS Simulator,name=iPhone 17 Pro`이며 `GIT_IT_TEST_DESTINATION`으로
바꿀 수 있습니다.

**기대 결과**: `CoreHTTP` scheme 빌드가 성공하고 `CoreHTTPTests`의 모든 테스트가 통과합니다.

## 검증 시나리오

각 시나리오는 `CoreHTTPTests`에서 자동 테스트로 확인합니다. 괄호 안은 명세의 수용 시나리오와
성공 기준입니다.

### A. 요청 구성과 응답 전달 (사용자 스토리 1)

| # | 확인 내용 | 기대 결과 |
| --- | --- | --- |
| A-1 | 기본 주소와 공통 헤더를 구성하고 상대 경로로 조회 요청 | 전송된 절대 주소가 기본 주소와 경로의 결합이고 공통 헤더가 함께 전달된다 (US1-1) |
| A-2 | 기본 주소의 끝 슬래시 유무를 바꿔 같은 경로로 요청 | 두 경우의 절대 주소가 같고 기본 주소의 경로가 유실되지 않는다 (research.md §3) |
| A-3 | 공통 헤더와 요청별 헤더에 표기만 다른 같은 이름을 지정 | 하나의 헤더로 합쳐지고 요청별 값만 전송된다 (US1-2, SC-016) |
| A-4 | 공백·비ASCII·`+`·`&`·`=`가 든 쿼리 값을 지정 | 호출자가 부호화하지 않았는데도 의미가 손상되지 않은 주소로 전송된다 (US1-3, SC-014) |
| A-5 | 같은 이름의 쿼리를 값만 달리해 두 번 지정하고 빈 값도 포함 | 지정 순서대로 모두 전송되고 빈 값 파라미터가 제거되지 않는다 (US1-4, SC-015) |
| A-6 | 호출자 값으로 본문을 지정한 생성 요청 | 호출자가 지정한 변환 규칙의 결과가 그대로 전송된다 (US1-5) |
| A-7 | 성공 상태 코드 응답 수신 | 본문이 지정한 형식으로 변환되어 상태 코드·헤더와 함께 전달된다 (US1-6) |
| A-8 | 성공이 아닌 상태 코드 응답 수신 | 변환을 시도하지 않고 상태 코드·헤더와 원형 본문이 전달되며 실패가 아니다 (US1-7, SC-009) |
| A-9 | 성공이 아닌 응답의 본문이 성공 형식과 다름 | 변환 실패가 아니라 정상 응답으로 전달된다 (US1-8) |
| A-10 | 빈 본문을 허용하는 변환 규칙 + 성공 상태 코드 + 빈 본문 | 시스템이 따로 판단하지 않고 규칙에 넘겨 정상 응답이 된다 (US1-9, FR-013) |
| A-11 | 성공 상태 코드로 원소가 없는 목록 응답 | 본문 없음이나 실패가 아니라 빈 값으로 변환되어 전달된다 (US1-10, SC-010) |
| A-12 | 이동 지시(3xx) 응답 | 이동 대상으로 요청이 자동 전송되고 최종 응답이 전달된다 (US1-11, FR-016, SC-008) |
| A-13 | 응답 헤더를 서로 다른 표기로 조회 | 어떤 표기로도 같은 값을 찾는다 (FR-022) |

### B. 실패 원인 구분 (사용자 스토리 2)

| # | 확인 내용 | 기대 결과 |
| --- | --- | --- |
| B-1 | 연결 실패를 일으키는 전송 수단 | `connectionFailed` (US2-1) |
| B-2 | 응답하지 않는 전송 수단 + 짧은 대기 한도 | `timedOut`이 전달되고 대기가 종료된다 (US2-2) |
| B-3 | 진행 중 요청을 감싼 `Task` 취소 | 통신이 중단되고 `cancelled` (US2-3) |
| B-4 | 취소가 관찰된 뒤 대기 한도가 만료되는 구성을 반복 실행 | 항상 `cancelled`가 전달된다 (US2-4, SC-011) |
| B-5 | 성공 상태 코드 + 지정 형식과 다른 본문 | `responseDecodingFailed` (US2-5) |
| B-6 | 요청 본문 변환이 실패하는 규칙 | `requestEncodingFailed`가 전달되고 전송 수단이 한 번도 호출되지 않는다 (US2-6) |
| B-7 | 기본 주소와 결합해 유효한 대상을 만들 수 없는 경로 | `invalidURL`이 전달되고 전송 수단이 호출되지 않는다 (FR-004) |
| B-8 | 연결 실패나 시간 초과 발생 | 한 번의 `HTTPClient.send` 호출에서 `HTTPTransport.send`가 1회만 호출되고 실패 뒤 다시 호출되지 않는다 (US2-7, SC-008) |
| B-10 | 여섯 실패 원인을 `switch`로 분기 | 완전성 검사를 통과하며 원인별 분기를 모두 작성할 수 있다 (SC-002) |

### C. 실제 서버 없는 검증 (사용자 스토리 3)

| # | 확인 내용 | 기대 결과 |
| --- | --- | --- |
| C-1 | 미리 정한 응답을 돌려주는 전송 수단 | 네트워크 접근 없이 그 응답이 호출자에게 전달된다 (US3-1) |
| C-2 | 특정 실패를 일으키는 전송 수단 | 해당 실패 원인이 그대로 전달된다 (US3-2) |
| C-3 | 전송 수단이 기록한 `HTTPTransportRequest` 검사 | 요청 방식·절대 주소·부호화된 쿼리·병합된 헤더·변환된 본문을 모두 확인할 수 있다 (US3-3) |
| C-4 | 성공이 아닌 상태 코드를 돌려주는 전송 수단 | 호출자가 상태 코드와 원형 본문을 검사해 오류 응답 분기를 검증할 수 있다 (US3-4) |

### D. 구성과 동시성

| # | 확인 내용 | 기대 결과 |
| --- | --- | --- |
| D-1 | 대기 한도를 지정하지 않고 생성한 클라이언트 | 확정된 대기 한도가 15초다 (FR-007, SC-012) |
| D-2 | 요청별 대기 한도 지정 | 생성 시 값 대신 요청별 값이 전송 수단에 전달된다 (FR-007) |
| D-3 | 기본 대기 한도 정의 지점 확인 | `HTTPClient.defaultResponseTimeout` 한 곳이며 호출자 수정이 필요 없다 (SC-013) |
| D-4 | 서로 다른 요청 10개를 동시 전송하고 그중 1개만 취소 | 취소한 1개는 `cancelled`, 나머지 9개는 각자의 올바른 결과를 받는다 (SC-006, FR-010) |
| D-5 | 요청 방식을 여섯 케이스 밖의 값으로 지정 시도 | 컴파일되지 않는다(닫힌 집합). 코드가 아닌 타입 정의로 확인 (FR-021) |

## 계약 확인

자동 테스트로 확인하기 어려운 항목은 코드 검토로 확인합니다.

| 항목 | 확인 방법 |
| --- | --- |
| SC-004 (외부 타입 비노출) | `CoreHTTP`의 `public` 선언에 `URLSession`, `URLRequest`, `URLResponse`, `HTTPURLResponse`, `URLError`, `URLComponents`, `URLQueryItem`이 등장하지 않는지 검사 |
| FR-023 (기록·관찰 수단 없음) | `CoreHTTP`에 로깅 호출과 호출자용 관찰 훅이 없는지 검사 |
| FR-005 (오류 격리) | `URLError` 처리가 `URLSessionTransport` 안에서만 이뤄지는지 검사 |
| SC-001 / SC-005 | 새 요청 추가와 서버 형식 변경이 구성·호출자 수정만으로 가능한지 검토 |

`SC-004` 확인용 보조 명령입니다.

```bash
grep -rnE "URLSession|URLRequest|URLResponse|HTTPURLResponse|URLError|URLComponents|URLQueryItem" sources/Projects/Core/CoreHTTP --include="*.swift" | grep -E "^[^:]+:[0-9]+:\s*public"
```

**기대 결과**: 출력이 없습니다.

## 검증 전 확인 사항

- 실제 네트워크에 접속하는 테스트가 없어야 합니다. 테스트에서 `URLSessionTransport`를
  직접 사용하지 않습니다.
- 리다이렉트 자동 추적은 `URLSessionTransport`의 구현 사항이다. `URLProtocol` 대역으로 3xx와
  최종 응답을 구성해, 실제 외부 네트워크 없이 A-12를 검증한다.
