# 0단계 조사: Git-It Server API 전체 Data 패키지 구현

## 결정 1 — 기존 `DataAuthentication` refresh/revoke 계약 제거

- **결정**: 기존 `LoginSessionRemote`(`startSession`/`refreshSession`/`revokeRefreshToken`),
  `RefreshRequestDTO`/`RefreshResponseDTO`, `DataAuthenticationError`(`refreshRejectedOrExpired`,
  `revocationFailure` 등)를 제거하고, 참조 문서 AUTH-01(Apple 로그인)·AUTH-02(Access Token
  확인) 두 operation만 표현하는 `AuthenticationRemote` 계약으로 교체한다.
- **근거**: `sources/Projects/Data/Authentication/Contracts/LoginSessionRemote.swift`를
  확인한 결과 `refreshSession`·`revokeRefreshToken` 메서드가 이미 존재하며, 이는
  spec.md FR-012("refresh/revoke/logout 계열 operation을 추정 구현하지 않아야 한다")와
  spec.md 15절 가정("배포 계약에는 refresh/revoke API가 존재하지 않는다")에 정면으로
  위배된다. 참조 문서 11절도 `POST /auth/refresh`, `POST /auth/revoke`를 명시적으로
  추정 금지 목록에 올린다. 이 구현은 이전 스펙(001-apple-social-login 계열)에서 만들어진
  것으로 SPEC-DATA-API-001 도입 이전 상태다.
- **검토한 대안**:
  - a) 기존 refresh/revoke 계약을 유지하고 새 AUTH-01/AUTH-02만 추가 — 기각. production/test
    target에 refresh/revoke 관련 타입이 남아 SC-008("refresh/revoke/logout 관련 구현 검색
    결과 0건")을 위반한다.
  - b) refresh/revoke 계약에 `@available(*, deprecated)`만 붙이고 유지 — 기각. deprecated
    표시는 존재 자체를 없애지 않으므로 SC-008 검증(검색 결과 0건)을 통과할 수 없다.
- **영향받는 기존 파일**(구현 단계에서 제거·재작성 대상, 이 계획 단계에서는 수정하지 않음):
  `Authentication/Contracts/LoginSessionRemote.swift`,
  `Authentication/Contracts/LoginSessionStorage.swift`,
  `Authentication/Contracts/AuthenticationAuthorizationStorage.swift`,
  `Authentication/Contracts/AuthenticationProvider.swift`,
  `Authentication/DTOs/LoginSessionResponseDTO.swift`,
  `Authentication/DTOs/LoginSessionStartRequestDTO.swift`,
  `Authentication/DTOs/RefreshRequestDTO.swift`,
  `Authentication/DTOs/RefreshResponseDTO.swift`,
  `Authentication/Errors/DataAuthenticationError.swift`,
  `Authentication/Models/AuthenticationEvidence.swift`,
  `Authentication/Models/AuthorizationState.swift`,
  `Authentication/Models/StoredAuthorizationReference.swift`,
  `Authentication/Models/StoredLoginSession.swift`, 그리고 대응하는
  `Tests/Authentication/**` 전체.
- **주의**: `AuthenticationAuthorizationStorage`/`LoginSessionStorage`/
  `AuthenticationProvider`/`AuthorizationState`/`StoredLoginSession` 등은 accessToken 저장·
  조회 책임을 표현하며 SPEC-DATA-API-001에는 없는 개념이다(참조 문서는 Remote 계약과 DTO만
  범위로 한다). 이 계획은 이런 저장 계약의 존치 여부를 결정하지 않는다 — `/speckit-tasks`
  실행 시 spec.md 가정("Composition 계층에서의 실제 URLSession 기반 network adapter 연결은
  별도 후속 작업")과 대조해 Remote 계약 범위만 재작성하고 저장 계약은 별도 작업으로 분리할지
  판단한다.

## 결정 2 — `DataLearningProject`는 신규 구현으로 취급

- **결정**: `DataLearningProject`는 `DataLearningProjectPlaceholder.swift`(빌드 가능 여부만
  표시하는 빈 enum)만 남아 있으므로, 기존 코드와의 정합이 아니라 참조 문서 PROJECT-01~11을
  기준으로 한 신규 구현으로 취급한다.
- **근거**: 커밋 `adce9e3 [Remove] LearningProject Data와 Composition 구현 제거`가 이전
  구현을 이미 제거했다. `git log`로 확인.
- **검토한 대안**: 제거된 커밋을 revert해 기존 구조를 재사용 — 기각. 제거 사유가 이번
  스펙 범위와 무관하게 이미 확정된 저장소 상태이므로, 새 계약 이름(`LearningProjectRemote`
  등)을 참조 문서 기준으로 처음부터 설계하는 편이 FR-002/FR-007 등과 충돌할 위험이 적다.

## 결정 3 — 도메인별 오류 타입 분리(공유 Data 하위 모듈 없음)

- **결정**: `DataAPIError`로 표현된 FR-006의 오류 케이스 집합을 하나의 공유 target으로
  묶지 않고, 각 도메인 target(`DataAuthentication`/`DataLearningProject`/`DataMember`)이
  자신의 범위에 해당하는 케이스만 갖는 개별 오류 타입(예: `DataAuthenticationError`,
  `DataLearningProjectError`, `DataMemberError`)으로 표현한다. 세 타입 모두 공통 형태
  (`invalidRequest`, `unauthorized`, `temporarilyUnavailable`, `transport`, `decoding`,
  `unexpectedStatus`)를 반복하고, 도메인 전용 케이스(`projectUnavailable`,
  `questionUnavailable`, `learningSetUnavailable`, `generationRetryUnavailable`는
  LearningProject; `memberUnavailable`은 Member)만 해당 타입에 추가한다.
- **근거**: [아키텍처 문서](../../docs/architecture.md) 3.1은 패키지 간 의존성 표에서
  `Data | —`로 Data 패키지가 다른 최상위 패키지에 의존하지 않음을 명시하고, [Data 패키지
  규칙](../../docs/package-rules/data.md)은 "Data target은 독립적인 테스트 실행 단위를
  구성해야 합니다"를 요구한다. 참조 문서 3절도 Authentication/LearningProject/Member를
  독립된 6-폴더 모듈로 나열하며 공유 모듈을 두지 않는다. 도메인 간 target 의존을 새로
  만드는 근거가 없으므로 각 target이 자기 완결적으로 오류 타입을 소유한다.
- **검토한 대안**:
  - a) `DataCommon` 같은 4번째 target을 만들어 `APIResponseDTO`/`ServerAPIError`/
    `DataAPIError`를 공유 — 기각. 참조 문서와 기존 Project.swift 어디에도 공유 target이
    선언되어 있지 않고, 새 target 추가는 Tuist 구성 변경 범위가 커서 이 스펙의 "19개
    operation 구현" 목적을 벗어난다. 필요해지면 별도 스펙으로 분리한다.
  - b) 세 도메인이 모두 동일한 이름의 `DataAPIError`를 각자 target에 중복 선언 — 기각.
    같은 이름의 타입이 서로 다른 target에 존재하면 상위 계층에서 import 충돌·오인 위험이
    있다. 네이밍 컨벤션 3.4(모델·DTO 이름은 소유 경계를 식별할 수 있어야 함)에 따라 도메인
    접두어를 포함한 이름을 사용한다.
- **영향**: FR-006이 나열한 단일 `DataAPIError` 표기는 spec.md 표현을 간결하게 하기 위한
  것이며, 실제 구현은 도메인별로 분리된 3개 타입으로 FR-006의 요구(오류 코드 구분 보존)를
  충족한다. spec.md 자체는 계획 단계 산출물이 아니므로 수정하지 않는다.

## 결정 4 — 공통 Envelope/DTO 중복 정책

- **결정**: `APIResponseDTO<Data>`, `FieldErrorDTO`, `ServerAPIError`와 같은 공통 응답
  포맷은 세 도메인 target에 동일한 형태로 각각 선언한다(결정 3과 동일한 이유로 공유
  target을 두지 않는다). 세 선언은 필드 구성이 완전히 같아야 하며, 계약 테스트로 직렬화·
  역직렬화 동작이 세 target에서 동일함을 검증한다(quickstart.md 참고).
- **근거**: 결정 3과 동일(아키텍처 3.1의 `Data | —`, Data 패키지 규칙의 target 독립성).
- **검토한 대안**: Infrastructure 패키지에 공통 HTTP envelope 디코딩 유틸리티를 두고 Data가
  참조 — 기각. Data 패키지 규칙은 "Infrastructure 타입 또는 외부 라이브러리의 구체 API를
  직접 참조해서는 안 됩니다"를 명시하고, 아키텍처 표는 `Data → Infrastructure`를 허용
  의존성 목록에 포함하지 않는다(`Composition`만 두 계층을 연결한다).

## 결정 5 — ISO-8601 date-time decoding 전략

- **결정**: 각 도메인 target의 JSON 디코딩에는 `JSONDecoder.DateDecodingStrategy
  .iso8601`(Foundation 표준)을 사용하고, 서버가 fractional seconds를 포함해 응답할 가능성에
  대비해 `ISO8601DateFormatter`에 `withFractionalSeconds` 옵션을 허용하는 커스텀 전략으로
  대체할 수 있도록 각 target의 디코딩 설정 지점을 한 곳(Endpoints 또는 Remotes 계층)에
  모은다.
- **근거**: 참조 문서 1절 "ISO-8601 date-time decoding"을 요구 사항으로 명시하지만 fractional
  seconds 포함 여부는 명시하지 않는다. `MyAnswerResponseDTO.answeredAt: Date`가 유일한
  date-time 필드로 확인된다(참조 문서 8절 PROJECT-07).
- **검토한 대안**: `.deferredToDate`(epoch 초) — 기각. 참조 문서가 ISO-8601을 명시했고 서버
  envelope도 REST JSON API 관례를 따른다.

## 결정 6 — 민감 값 문자열 노출 방지 패턴

- **결정**: Apple ID Token, Access Token, Refresh Token, Authorization header 원문을 담는
  DTO/모델은 기존 `RefreshRequestDTO`가 사용한 패턴(`CustomStringConvertible`/
  `CustomDebugStringConvertible`를 채택해 `description`/`debugDescription`에서 `<redacted>`
  치환)을 재사용한다. 단, 결정 1에 따라 `RefreshRequestDTO` 자체는 제거되므로 이 패턴만
  `AppleLoginRequestDTO`(idToken), Bearer header를 구성하는 값 등 신규 타입에 이식한다.
- **근거**: `Authentication/DTOs/RefreshRequestDTO.swift`에서 이미 검증된 프로젝트 관례이며
  spec.md FR-014·SC-006과 직접 대응한다.
- **검토한 대안**: 별도 `Redacted<T>` wrapper 타입 도입 — 기각. 기존 관례와 다른 새 추상을
  도입하는 것은 이번 스펙의 필요를 넘어서는 범위 확장이다(YAGNI).

## 결정 7 — Operation ID를 통한 URL 계약 참조

- **결정**: Data 패키지의 Endpoint 정의(HTTP method/path/query/body)는 참조 문서
  SPEC-DATA-API-001의 operation ID(AUTH-01/AUTH-02, PROJECT-01~11, MEMBER-01~06)별 섹션을
  구현 시점의 유일한 정본으로 삼는다. 이 계획과 spec.md, `contracts/`는 클라이언트 측
  ID`select:<name>[,<name>...]` 만 명시하고 리터럴 URL 문자열을 재기재하지 않는다.
- **근거**: `/speckit-clarify` 세션 2026-08-21에서 사용자가 "스팩 문서에 API의 URL은
  명시하지 않는다"를 확정했다(spec.md `## 명확화` 참고). 계획 산출물도 같은 규칙을
  일관되게 적용한다.
- **검토한 대안**: `contracts/`에 실제 HTTP method/path 표를 재작성 — 기각. 명확화 답변과
  충돌하고, URL 변경 시 두 문서(참조 문서·계획 문서)를 동시에 갱신해야 하는 이중 관리
  위험이 생긴다.
