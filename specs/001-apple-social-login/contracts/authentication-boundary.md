# 인증 경계 계약

**적용 범위**: Apple 네이티브 인증, Git It 세션의 교환·복원·갱신·로그아웃을 연결하는
앱 내부 계약

이 계약은 Feature와 실제 서버 HTTP 형식 사이의 안정적인 경계를 정의한다. 실제 서버의 URL,
HTTP method, 헤더, JSON 필드, Apple client secret과 데이터베이스 스키마는 아직 확정되지
않았으며 이 문서가 그것들을 추측하거나 고정하지 않는다.

## 계약 원칙

- Apple 인증 원시 값은 서버 검증 입력이고 Git It 세션 토큰이 아니다.
- Feature와 App은 토큰 값을 받지 않는다. 성공 결과에는 안전한 사용자 정보와 인증 상태만
  전달한다.
- 실제 서버 Adapter, Mock, unavailable 구현은 같은 Domain 결과와 오류 의미를 반환한다.
- 모든 production 의존성은 `AppComposition`에서 생성해 Feature initializer에 전달한다.
- 서버에 endpoint가 없는 릴리스 구성은 인증 성공을 반환하지 않고 재시도 가능한 unavailable
  결과로 닫힌다.

## 입력과 출력 의미

| 값 | 생산자 | 소비자 | 수명·보호 규칙 |
| --- | --- | --- | --- |
| `AuthenticationAttempt` | `Core` 난수 API와 Domain 흐름 | Apple authorization client | `attemptID`, `nonce`, `state`, 만료 시각을 포함하며 메모리에서만 유지한다. |
| `AppleAuthorizationCredential` | `Core` Apple Adapter | `AuthenticationRemote` | Apple 사용자 식별자, `identityToken`, `authorizationCode`, 선택 이름·이메일, 반환 state를 포함한다. 교환 뒤 즉시 폐기한다. |
| `AuthenticatedSession` | 서버 교환/갱신 또는 Mock | 세션 저장 Adapter | 사용자, access/refresh token, access 만료, Apple 사용자 식별자를 포함한다. 토큰은 Keychain에만 저장한다. |
| `AuthenticationOutcome` | Domain use case | Feature/App | `authenticated(user)`, `unauthenticated`, `recoverableFailure` 중 하나다. 원시 토큰과 외부 오류를 포함하지 않는다. |

## 연산 계약

### Apple 로그인 시작

**전제**: 사용자가 로그인 제어를 명시적으로 탭했고 진행 중인 인증 시도가 없다.

1. 현재 시도에만 유효한 `AuthenticationAttempt`를 만든다.
2. Apple 요청에 `nonce`, `state`, 선택 scope를 적용하고 시스템 인증 UI를 연다.
3. 취소면 `unauthenticated`를 반환하고 경고·저장·서버 교환을 하지 않는다.
4. 성공 콜백은 현재 `attemptID`와 `state`, 필수 Apple 원시 값의 존재를 검증한다.
5. 검증된 credential을 한 번만 `exchangeAppleCredential`에 전달한다.
6. 교환 결과가 유효한 `AuthenticatedSession`이면 Keychain에 저장하고
   `authenticated(user)`를 반환한다. 그 전에는 보호된 콘텐츠를 열지 않는다.

**실패 의미**:

| 조건 | 결과 | 저장소 |
| --- | --- | --- |
| 사용자 취소 | `unauthenticated` | 변경 없음 |
| state·시도 불일치, 예상 밖 credential, 원시 값 누락 | `recoverableFailure` 또는 로그인 화면 | 변경 없음 |
| Apple/교환의 일시 오류 | `recoverableFailure` | 변경 없음 |
| 서버가 계정 이용 불가를 확정 | `unauthenticated` | 기존 세션이 있다면 삭제 |

### 앱 시작 세션 복원과 재시도

**전제**: 앱이 시작했거나 사용자가 복구 화면에서 재시도를 선택했다.

1. Keychain에서 저장된 Git It 세션을 읽는다. 값이 없으면 `unauthenticated`다.
2. 저장된 Apple 사용자 식별자로 credential state를 확인한다.
3. `.authorized`이면 access token이 유효한지 확인하고, 만료했다면 리프레시 토큰으로 갱신한다.
4. credential 철회·리프레시 거부·계정 이용 불가가 확인되면 Keychain의 세션 전체를 삭제하고
   `unauthenticated`를 반환한다.
5. credential 조회·갱신의 일시 오류면 Keychain을 유지하고 `recoverableFailure`를 반환한다.
6. 유효하거나 갱신된 세션만 `authenticated(user)`로 전환한다.

### 로그아웃

**전제**: 사용자가 인증된 상태에서 로그아웃을 선택했다.

1. 세션 조정 actor가 세션 세대를 증가시키고 모든 진행 중 로그인·복원·갱신 결과를 무효화한다.
2. access token, refresh token, Apple 사용자 식별자를 Keychain에서 즉시 삭제한다.
3. 삭제 전 메모리에 있던 refresh token으로 서버 폐기를 best-effort 요청한다.
4. 폐기 성공·실패·통신 오류와 관계없이 `unauthenticated`를 반환한다.
5. 늦은 교환·갱신 응답은 이전 세대이므로 저장하거나 인증 화면을 되살릴 수 없다.

## 구현 교체 계약

| 구현 | 선택 위치 | 허용 환경 | 의무 |
| --- | --- | --- | --- |
| `MockAuthenticationRemote` | `Composition` | 단위 테스트, UI 미리보기, 명시적인 개발 구성 | 신규·기존 사용자, 선택 프로필 부재, 갱신, 일시 오류, 거부, 폐기 실패를 결정적으로 재현한다. |
| `LiveAuthenticationRemote` | `Composition` | 서버 endpoint와 계약이 확정된 뒤의 production 구성 | 이 문서의 입력·출력·실패 의미를 유지하고 Apple 결과를 TLS로 서버에만 전달한다. |
| `UnavailableAuthenticationRemote` | `Composition` | live endpoint가 없는 릴리스 구성 | 보호된 콘텐츠를 열지 않고 안전한 재시도 안내를 반환한다. |

Mock은 동일한 `AuthenticationRemote` 계약을 구현해야 하며 Feature가 Mock 전용 action이나
토큰 값을 알게 해서는 안 된다.

## 보안 및 관찰성 계약

- Keychain은 기기 한정·잠금 중 비노출 접근성을 사용한다.
- `identityToken`, `authorizationCode`, access token, refresh token, nonce, state는 로그,
  분석 이벤트, 오류 메시지, 화면 접근성 값, 테스트 실패 덤프에 넣지 않는다.
- 서버는 Apple JWT의 서명, issuer, audience, expiration, nonce와 authorization code의
  단발성을 검증한다. 서버 Apple private key와 client secret은 앱에 포함하지 않는다.
- Apple credential revoked 알림을 수신하면 복원 규칙과 같은 세션 무효화 경로를 실행한다.
- Apple credential `.transferred`는 자동 병합·자동 새 계정 생성을 하지 않는다. 사용자 식별자
  마이그레이션은 실제 서버 계약이 준비된 별도 기능에서 처리한다.

## 계약 검증 사례

- state가 다른 늦은 콜백, 누락 token/code, 중복 탭은 교환을 호출하지 않는다.
- 취소는 오류 경고와 토큰 생성을 남기지 않는다.
- 유효한 리프레시 토큰은 새 access token으로 세션을 복원한다.
- 일시 오류는 토큰을 보존하고 보호 화면을 막으며, 거부·만료는 세션 전체를 제거한다.
- 로그아웃과 갱신을 경쟁시키면 로그아웃 뒤의 갱신 결과가 Keychain에 저장되지 않는다.
- Mock을 Live Adapter로 바꿔도 Feature의 action·state·delegate 계약은 바뀌지 않는다.
