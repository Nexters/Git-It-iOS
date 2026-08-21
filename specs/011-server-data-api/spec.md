# 기능 명세: Git-It Server API 전체 Data 패키지 구현

**Git-flow 유형**: `feature`

**기능 브랜치**: `미생성 (예정: feature/server-data-api)`

**생성일**: 2026-08-21

**상태**: 초안

**입력**: 사용자 설명: "@Git-It Server API 전체 Data 패키지 구현 명세 — SPEC-DATA-API-001 문서를 통해 spec 엔드포인트를 모두 지원하도록 Data 패키지에 구현"

**참조 문서**: [`Git-It Server API 전체 Data 패키지 구현 명세 — SPEC-DATA-API-001.md`](../../Git-It%20Server%20API%20%EC%A0%84%EC%B2%B4%20Data%20%ED%8C%A8%ED%82%A4%EC%A7%80%20%EA%B5%AC%ED%98%84%20%EB%AA%85%EC%84%B8%20%E2%80%94%20SPEC-DATA-API-001.md)
(Spec ID: `SPEC-DATA-API-001`, 대상 계층: `Data`, API 정본: 배포 서버 OpenAPI 문서)

## 명확화

### 세션 2026-08-21

- 질문: 스팩 문서에 API의 URL(method/path)을 명시하는가? → 답변: 명시하지 않는다. HTTP
  method·path 등 구체적인 URL 계약은 참조 문서(SPEC-DATA-API-001)의 operation ID(AUTH-XX,
  PROJECT-XX, MEMBER-XX)로만 지칭하고, 이 spec 문서 본문에는 리터럴 URL을 적지 않는다.

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - Data 계층이 서버 API 19개 operation을 계약대로 노출한다 (우선순위: P1)

Data 패키지를 사용하는 상위 계층(Composition/Infrastructure 연동 개발자)은 Authentication,
LearningProject, Member 세 도메인에 대해 서버가 정의한 19개 operation을 Remote 프로토콜과
Request/Response DTO로 호출할 수 있어야 한다. 각 operation은 배포 서버의 HTTP
method·path·query·body 계약과 정확히 일치해야 하며, Google 로그인처럼 iOS 제품 범위 밖의
API는 구현하지 않는다.

**주요 행위자**: Data 패키지를 소비하는 개발자(Composition 계층에서 network adapter를 조립하는
개발자) 및 향후 production network adapter

**우선순위 이유**: 19개 operation 전체 구현이 이 기능의 완료 판정 기준이며, 하나라도 누락되면
상위 계층이 해당 기능을 조립할 수 없다.

**독립 테스트**: 각 operation에 대한 request/response contract test를 실행해 19/19 operation이
성공적으로 인코딩·디코딩됨을 확인한다. Operation completeness test로 "Expected 19 / Actual 19 /
Missing 0 / Unexpected 0"을 검증할 수 있다.

**수용 시나리오**:

1. **전제** Data 패키지가 빌드된 상태, **실행** `AuthenticationRemote`, `LearningProjectRemote`,
   `MemberRemote`의 모든 메서드를 열거, **결과** Auth 2개·Project 11개·Member 6개, 총 19개
   operation이 모두 존재한다.
2. **전제** Apple 로그인을 제외한 18개 endpoint 호출, **실행** 요청 생성, **결과** 모든 요청에
   `Authorization: Bearer <accessToken>` 헤더가 포함된다.
3. **전제** 서버가 nullable 필드(`repositoryImageUrl`, `nextSetId`, `nextQuestionId`,
   `myAnswer` 등)를 `null`로 응답, **실행** DTO decoding 수행, **결과** decoding이 실패하지
   않고 값이 `nil`로 보존된다.

---

### 시나리오 2 - Data 계층이 서버 오류 코드를 구분해서 보존한다 (우선순위: P1)

Data 패키지를 사용하는 개발자는 서버가 반환하는 HTTP 상태 코드와 오류 코드(`COMMON-001`,
`PROJECT-001`, `QUIZ-005`, `QUIZ-006`, `QUIZ-007`, `MEMBER-001`, `COMMON-005` 등)를 `DataAPIError`
케이스로 구분해서 받을 수 있어야 하며, Data 계층이 임의로 오류를 뭉뚱그리거나 존재하지 않는
성공 상태를 추론해서는 안 된다.

**주요 행위자**: Data 패키지를 소비하는 개발자, 향후 오류 메시지를 사용자에게 노출하는 상위 계층

**우선순위 이유**: 오류 코드 구분이 없으면 재시도 가능 오류(예: 생성 재시도 409)와 복구 불가능
오류(예: 401)를 상위 계층이 구분할 수 없다.

**독립 테스트**: 각 대표 오류 매핑(HTTP status + code)에 대한 fixture로 `DataAPIError`가
기대한 케이스로 변환되는지 확인한다.

**수용 시나리오**:

1. **전제** 서버가 404 + `PROJECT-001` 응답, **실행** 프로젝트 상세 조회, **결과**
   `DataAPIError.projectUnavailable`로 변환된다.
2. **전제** 서버가 409 + `QUIZ-007` 응답, **실행** 생성 재시도 호출, **결과**
   `DataAPIError.generationRetryUnavailable`로 변환되고 다른 오류와 혼동되지 않는다.
3. **전제** Access Token 확인 operation(참조 문서 AUTH-02)이 200을 반환, **실행** 응답 처리,
   **결과** Data 계층은 "온보딩 완료" 또는 "큐레이션 불필요" 같은 부가 상태를 추론하지 않는다.

---

### 시나리오 3 - Data 계층이 iOS 제품 범위 밖 API를 의도적으로 제외한다 (우선순위: P2)

Data 패키지를 리뷰하는 개발자는 배포 서버 OpenAPI에 존재하지만 iOS 제품이 사용하지 않는
Google 로그인 operation과 refresh/revoke/logout 계열 operation이 production/test 어디에도
구현되지 않았음을 코드 검색으로 확인할 수 있어야 한다.

**주요 행위자**: 코드 리뷰어, Data 패키지 유지보수 개발자

**우선순위 이유**: 존재하지 않는 API를 추정 구현하면 배포 서버와 계약 불일치가 발생하고,
Google 인증처럼 제품 범위 밖 기능이 섞이면 유지보수 비용이 늘어난다.

**독립 테스트**: `GoogleLoginRequestDTO`, `googleLogin(`, `GoogleLoginEndpoint`와 refresh/revoke/
logout 관련 Remote 메서드·Endpoint 타입 이름에 대한 저장소 전체 검색 결과가 0건임을 확인한다
(문서·`excludedOperations` 목록 표기는 예외).

**수용 시나리오**:

1. **전제** Data 패키지 전체 소스, **실행** `GoogleLogin` 관련 타입·메서드 검색, **결과**
   production 및 test target 어디에도 결과가 없다.
2. **전제** `AuthenticationRemote` 프로토콜, **실행** 메서드 목록 확인, **결과**
   `appleLogin(idToken:)`과 `verifyAccessToken()`만 존재한다.

---

### 예외·경계 사례

- Unit 응답(`data` 키가 없거나 `null`)을 반환하는 endpoint(access token 확인, 프로젝트 삭제,
  생성 재시도, 회원 탈퇴 등)에서 decoding이 실패하면 어떤 결과가 발생하는가? → 정상 decode로
  처리해야 하며 실패로 취급하지 않는다.
- 서버가 `QuizGenerationStatusResponseDTO.status`에 알려지지 않은 raw value를 반환하면 시스템은
  어떻게 처리하는가? → decoding failure로 처리하지 않고 raw 문자열을 그대로 보존한다.
- Apple ID Token, Access Token, Refresh Token, Authorization header 원문이 로그나 debug
  description에 노출되는 경계 조건이 발생하면 어떤 결과가 발생하는가? → 원문이 노출되어서는
  안 되며 마스킹되거나 제외되어야 한다.
- 북마크 설정 요청이 toggle이 아니라 최종 상태(`bookmarked: Bool`)로 전달되는데, 클라이언트가
  현재 상태를 모른 채 반복 호출하면 어떤 결과가 발생하는가? → Data 계층은 최종 상태 설정
  API로만 동작하며 이전 상태를 추론하거나 toggle 로직을 추가하지 않는다.
- 서술형 답변 제출(`PROJECT-09`) 응답에는 `correct` 필드가 없는데 상위 계층이 정오답을
  요구하면 어떤 결과가 발생하는가? → Data는 `correct`를 생성하지 않고 없는 그대로 노출한다.

## 요구사항 *(필수)*

### 기능 요구사항

- **FR-001**: Data 계층은 iOS 제품 범위의 서버 API 19개 operation(Auth 2, Project 11, Member 6)을
  Remote 프로토콜과 Request/Response DTO로 제공해야 한다.
- **FR-002**: Data 계층은 Google 로그인 operation(참조 문서 AUTH 영역 중 iOS 제품 범위에서
  명시적으로 제외된 항목)을 구현하지 않아야 하며, 관련 DTO·Remote 메서드·테스트 fixture를
  production/test target 어디에도 포함하지 않아야 한다.
- **FR-003**: Data 계층은 Apple 로그인(참조 문서 AUTH-01)을 제외한 나머지 18개 operation 요청에
  `Authorization: Bearer <accessToken>`, `Accept: application/json`,
  `Content-Type: application/json` 헤더를 적용해야 한다.
- **FR-004**: 각 operation의 HTTP method·path·query·body 구조는 참조 문서(SPEC-DATA-API-001)의
  operation ID(AUTH-XX/PROJECT-XX/MEMBER-XX)별 배포 계약과 정확히 일치해야 한다. 이 spec
  문서에는 구체적인 URL을 명시하지 않는다.
- **FR-005**: Data 계층은 공통 응답 envelope(`APIResponseDTO<Data>`: `success`, `data`, `code`,
  `message`, `errors`)을 사용하고, `data`가 없거나 `null`인 Unit 응답도 정상 decode해야 한다.
- **FR-006**: Data 계층은 서버 오류를 `ServerAPIError`(httpStatus, code, message, fieldErrors)로
  받아 `DataAPIError`(invalidRequest, unauthorized, projectUnavailable, questionUnavailable,
  learningSetUnavailable, memberUnavailable, generationRetryUnavailable, temporarilyUnavailable,
  transport, decoding, unexpectedStatus)로 구분해서 변환해야 한다.
- **FR-007**: Data 계층은 nullable 필드(예: `repositoryImageUrl`, `nextSetId`, `nextQuestionId`,
  `myAnswer`, `summary`, `deviceToken`, `projectId` 쿼리)를 non-optional로 임의 변경하지 않아야
  한다.
- **FR-008**: 북마크 설정(`PROJECT-10`)은 toggle이 아니라 최종 `bookmarked` 상태를 전달하는
  command로 구현해야 한다.
- **FR-009**: Data 계층은 서버가 반환한 배열(예: `weeklyChart`, `sets`, `questions`, `choices`)의
  순서를 재정렬하지 않아야 한다.
- **FR-010**: 서술형 답변 제출 응답(`SubmitEssayAnswerResponseDTO`)에는 `correct` 필드를 생성해
  포함하지 않아야 한다.
- **FR-011**: `QuizGenerationStatusResponseDTO.status`의 알려지지 않은 raw value는 decoding
  failure로 처리하지 않고 원문 문자열을 보존해야 한다.
- **FR-012**: Data 계층은 참조 문서에 정의되지 않은 refresh/revoke/logout 계열 operation을
  추정 구현하지 않아야 하며, `LoginResponseDTO.refreshToken`은 원문 그대로 보존하되 존재하지
  않는 API 구현의 근거로 사용하지 않는다.
- **FR-013**: Data 계층은 Member API 6개(프로필 조회, 기기 정보 등록, 큐레이션, 분야 변경,
  수준 변경, 회원 탈퇴)를 전부 구현해야 한다.
- **FR-014**: Data 계층은 Apple ID Token, Access Token, Refresh Token, Authorization header
  원문을 로그 및 debug description에 노출하지 않아야 한다.
- **FR-015**: 각 operation은 request/response contract test를 가져야 하며, operation
  completeness test는 "Expected 19 / Actual 19 / Missing 0 / Unexpected(제품 범위 API 기준) 0"을
  검증해야 한다.
- **FR-016**: production target(`DataAuthentication`, `DataLearningProject`, `DataMember`)에는
  test fixture와 Mock을 포함하지 않아야 하며, 이들은 각각의 Tests target
  (`DataAuthenticationTests`, `DataLearningProjectTests`, `DataMemberTests`)에만 존재해야 한다.

### 핵심 엔터티 *(기능에 데이터가 포함되면 작성)*

- **AuthenticationRemote 계약**: Apple 로그인 요청/응답(`AppleLoginRequestDTO`,
  `LoginResponseDTO`)과 access token 확인을 표현하며, Google 인증 관련 타입은 포함하지 않는다.
- **LearningProjectRemote 계약**: 프로젝트 등록·목록·상세·삭제·생성 상태·생성 재시도·학습
  세트·객관식/서술형 답변 제출·북마크 설정/목록을 표현하며, 각 항목은 프로젝트/세트/질문
  식별자 체계를 nullable 여부 그대로 보존한다.
- **MemberRemote 계약**: 회원 프로필, 기기 정보, 큐레이션, 분야·수준 변경, 회원 탈퇴를
  표현하며, iOS에서는 `deviceType = "ios"`로 고정한다.
- **DataAPIError**: 서버 HTTP status와 도메인 오류 코드를 Data 계층의 언어로 구분한 오류
  케이스 집합으로, 상위 계층이 재시도 가능 여부와 복구 전략을 판단하는 근거가 된다.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: iOS 제품 범위 operation 개수와 Data 계층이 실제로 구현한 operation 개수가 모두
  19로 일치한다(Auth 2, Project 11, Member 6).
- **SC-002**: 저장소 전체에서 `GoogleLoginRequestDTO`, `googleLogin(`, `GoogleLoginEndpoint`
  검색 결과가 0건이다(문서·`excludedOperations` 표기 제외).
- **SC-003**: 19개 operation 각각에 대한 request/response contract test가 100% 통과한다.
- **SC-004**: nullable 필드를 포함한 대표 fixture(북마크 목록의 `nextSetId`/`nextQuestionId`
  nil 포함, `myAnswer` nil 포함 학습 세트 등)에서 decoding failure가 0건이다.
- **SC-005**: 알려지지 않은 generation status raw value를 포함한 fixture에서 decoding failure가
  0건이다.
- **SC-006**: 민감 credential(Apple ID Token, Access Token, Refresh Token, Authorization
  header) 로그 노출을 검증하는 테스트가 모두 통과한다.
- **SC-007**: `DataAuthentication`, `DataAuthenticationTests`, `DataLearningProject`,
  `DataLearningProjectTests`, `DataMember`, `DataMemberTests` 6개 target이 프로젝트 build 및
  test 대상에 실제로 포함된다.
- **SC-008**: 저장소 전체에서 refresh/revoke/logout 관련 Remote 메서드·Endpoint 구현 검색
  결과가 0건이다.

## 가정

- 참조 문서 `SPEC-DATA-API-001`에 기술된 배포 서버 OpenAPI 계약이 구현 시점 기준 최신이라고
  가정한다. 구체적인 URL·엔드포인트 계약은 이 spec 문서가 아니라 참조 문서를 정본으로 삼는다.
- Member 도메인의 Data 모듈(`DataMember`, `DataMemberTests`)은 아직 저장소에 존재하지 않으므로
  기존 `Authentication`, `LearningProject` 모듈과 동일한 폴더 구조
  (`Contracts`/`DTOs`/`Errors`/`Models`/`Endpoints`/`Remotes`)로 신규 생성한다고 가정한다.
- 이 기능은 Remote 계약과 production network adapter가 사용할 API 계약까지를 범위로 하며,
  Composition 계층에서의 실제 URLSession 기반 network adapter 연결은 별도 후속 작업으로
  간주한다.
- 기존 `DataLearningProject` 모듈에 이미 구현된 코드가 있다면, 이번 작업은 SPEC-DATA-API-001과의
  계약 불일치를 정합하는 방향으로 수정한다고 가정한다.
- 인증 없는 요청은 Apple 로그인 1건뿐이며, 그 외 18개 endpoint는 모두 Bearer 인증을 전제한다고
  가정한다.
