# DomainAuthentication

`DomainAuthentication`은 외부 인증과 Git It 세션을 조정하는 공급자 중립 Domain
계약과 유스케이스를 제공합니다. 이 문서는 `DomainAuthenticationTests`에서 직접
검증하는 동작만 설명합니다.

## 공개 모델

- `AuthenticationMethod`는 외부 프레임워크 타입 없이 Apple 인증 방식을 표현합니다.
- `AuthenticationGrant`는 불투명한 `ID`와 인증 방식만 보유합니다.
- `AuthenticatedUser`는 서버 사용자 ID, 계정 이용 가능 상태와 선택적 표시 이름을
  표현합니다.
- `AuthenticationOutcome`은 인증된 사용자, 비인증, 복구 가능한 실패 중 하나입니다.
- `AuthorizationStatus`는 인증됨, 재인증 필요, 일시적 조회 불가를
  구분합니다.
- `AuthenticationError`는 사용자 취소와 일시적 외부 인증 실패를 구분합니다.
- `LoginSessionError`는 일시적 실패, refresh 거부 또는 만료, 계정 이용 불가를 구분합니다.

## Repository 계약

`AuthenticationRepository`는 다음 외부 인증 경계를 제공합니다.

- 선택한 방식으로 인증하고 `AuthenticationGrant`를 발급합니다.
- 현재 authorization 상태를 조회합니다.
- authorization 상태 변경을 `AsyncStream`으로 제공합니다.
- 남아 있는 인증 참조를 정리합니다.

`LoginSessionRepository`는 다음 Git It 로그인 세션 경계를 제공합니다.

- `AuthenticationGrant`로 세션을 시작합니다.
- 저장된 세션을 복원하며 내부 refresh 결과를 함께 반환합니다.
- 로그아웃을 요청합니다.

두 계약은 `Sendable`이며 외부 인증과 Git It 세션의 책임을 서로 분리합니다.

## 유스케이스가 보장하는 동작

### SignIn

- 선택한 인증 방식으로 외부 인증을 먼저 수행한 뒤 발급된 grant로 세션을 시작합니다.
- 인증이 실패하면 세션을 시작하지 않고 복구 가능한 실패를 반환합니다.
- 사용자가 인증을 취소하면 비인증 결과를 반환합니다.
- grant 발급 후 세션 시작이 실패하면 인증 참조를 정리하고 복구 가능한 실패를
  반환합니다.

### RestoreSession

- 저장된 세션이 없으면 남은 인증 참조를 정리하고 비인증 결과를 반환합니다.
- 세션과 authorization이 모두 유효하면 인증된 사용자를 반환합니다.
- authorization 조회가 일시적으로 불가능하면 저장 상태를 정리하지 않고 복구 가능한
  실패를 반환합니다.
- 재인증이 필요하면 세션을 먼저 종료한 뒤 인증 참조를 정리합니다.
- refresh가 일시적으로 실패하면 저장 상태를 유지하고 복구 가능한 실패를 반환합니다.
- refresh가 거부되거나 만료되면 세션과 인증 참조를 순서대로 정리합니다.

### ObserveAuthorizationChanges

- authorization 변경을 인증 결과 stream으로 변환합니다.
- 인증됨 상태에서는 저장된 사용자를 복원합니다.
- 일시적 조회 불가 상태는 복구 가능한 실패로 변환합니다.
- 재인증 필요 상태에서는 세션과 인증 참조를 정리하고 비인증 결과를 반환합니다.

### SignOut

- Git It 세션 종료를 먼저 요청한 뒤 외부 인증 참조를 정리합니다.
- 세션 종료 또는 인증 참조 정리가 실패하더라도 비인증 결과로 수렴합니다.

## 민감 정보 경계

테스트는 공개 모델, 오류와 결과의 저장 필드 및 문자열 표현에 다음 외부 인증 비밀을
나타내는 필드가 없음을 검증합니다.

- `AuthenticationServices`, `ASAuthorization`
- `identityToken`, `authorizationCode`, `credential`, `token`
- `nonce`, `state`

## 보장하지 않는 범위

이 타겟의 테스트는 다음 동작을 검증하지 않습니다.

- 실제 Apple 인증 화면과 `AuthenticationServices` 연동
- 서버 API 요청, 응답 및 계정 생성
- Keychain 또는 다른 영구 저장소의 실제 저장·삭제
- Feature 화면 상태와 Navigation
- Composition의 production adapter 변환 및 rollback

이 동작들은 해당 구현 타겟의 테스트가 추가되고 통과한 뒤 그 타겟의 문서에서 다룹니다.

## 검증 근거

- 모델과 민감 정보 경계: `DomainAuthenticationTests/Models/`,
  `DomainAuthenticationTests/Security/`
- Repository 계약: `DomainAuthenticationTests/Contracts/`
- 유스케이스와 호출 순서: `DomainAuthenticationTests/UseCases/`

문서의 보장 범위는 위 테스트와 함께 변경해야 합니다. 테스트로 검증되지 않은 계획,
구현 의도 또는 하위 타겟의 동작을 보장된 기능으로 추가하지 않습니다.
