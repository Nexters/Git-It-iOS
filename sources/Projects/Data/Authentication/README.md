# DataAuthentication

`DataAuthentication`은 외부 인증, Git It 서버 세션, 로컬 저장소의 경계를 공급자
중립 데이터 계약과 DTO·저장 모델로 표현합니다. 이 문서는
`DataAuthenticationTests`에서 직접 검증하는 동작만 설명합니다.

## 공개 모델과 DTO

- `AuthenticationEvidence`는 `methodIdentifier`, `providerSubjectReference`, 불투명
  `opaquePayload`를 표현합니다. payload는 `Equatable`이 아니며 문자열·디버그
  표현에서 숨겨집니다.
- `AuthorizationState`는 `active`, `inactive`,
  `temporarilyUnavailable` 상태만 제공합니다.
- `LoginSessionStartRequestDTO`는 인증 방식 식별자와 단발성 불투명 payload로 세션 시작
  입력을 표현합니다.
- `LoginSessionResponseDTO`는 Git It 사용자와 access token, refresh token, access 만료를
  표현합니다. 사용자는 ID, 이용 가능 상태와 선택적 표시 이름을 가집니다.
- `RefreshRequestDTO`는 refresh token으로 갱신 입력을, `RefreshResponseDTO`는 새
  access token·만료와 선택적 교체 refresh token으로 갱신 결과를 표현합니다.
- `StoredLoginSession`은 서버 세션 값과 사용자를 저장하는 모델입니다.
- `StoredAuthorizationReference`는 서버 세션과 분리된 `methodIdentifier`와
  `providerSubjectReference`를 저장합니다.
- `DataAuthenticationError`는 취소, 일시적 이용 불가, 저장 실패, 세션 시작 거부,
  refresh 거부 또는 만료, refresh token 폐기 실패를 구분합니다.

## 계약

모든 계약은 `Sendable`입니다.

- `AuthenticationProvider`는 방식 식별자로 인증하고, 해당 subject의
  authorization 상태 조회 및 상태 변경 stream을 제공합니다.
- `LoginSessionRemote`는 세션 시작, token 갱신, refresh token 폐기를 제공합니다.
- `LoginSessionStorage`는 서버 세션을 저장·읽기·삭제합니다.
- `AuthenticationAuthorizationStorage`는 공급자 인증 참조를 서버 세션과 분리해
  저장·읽기·삭제합니다.

## 민감 정보 경계

테스트는 다음 값이 `description`과 `debugDescription`에 노출되지 않음을 검증합니다.

- 외부 인증의 불투명 payload
- access token과 refresh token

또한 외부 인증 evidence와 세션 시작 요청은 Apple 고유 필드가 아닌 방식 식별자와
불투명 값으로만 표현되며, 저장 세션은 `appleUserID`나 공급자 subject 참조를 보유하지
않습니다.

## 보장하지 않는 범위

이 타겟의 테스트는 다음 동작을 검증하지 않습니다.

- 실제 Apple 인증 API 또는 credential state와의 연동
- 서버 HTTP 요청·응답의 직렬화와 실제 endpoint 통신
- Keychain·파일 시스템 등 영구 저장소의 실제 저장·삭제
- Domain 모델 변환, Repository 구현 또는 유스케이스 흐름
- Composition에서의 Data↔Infrastructure adapter 조립

이 동작들은 해당 구현 타겟의 테스트가 추가되고 통과한 뒤 그 타겟의 문서에서 다룹니다.

## 검증 근거

- 계약: `Tests/Authentication/Contracts/`
- 모델·DTO·오류 의미: `Tests/Authentication/Models/`,
  `Tests/Authentication/DTOs/`, `Tests/Authentication/Errors/`
- 민감 값 비노출: `Tests/Authentication/Security/`

문서의 보장 범위는 위 테스트와 함께 변경해야 합니다. 테스트로 검증되지 않은 계획,
구현 의도 또는 하위 타겟의 동작을 보장된 기능으로 추가하지 않습니다.
