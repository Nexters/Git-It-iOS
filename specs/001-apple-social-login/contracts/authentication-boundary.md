# 인증 경계 계약

**적용 범위**: 공급자 인증과 Git It 서버 세션의 시작·복원·갱신·로그아웃을 분리하고
Domain `SignIn`에서 연결하는 앱 내부 계약

이 계약은 Feature와 실제 서버 HTTP 형식 사이의 안정적인 경계를 정의한다. 실제 서버의 URL,
HTTP method, 헤더, JSON 필드, Apple client secret과 데이터베이스 스키마는 아직 확정되지
않았으며 이 문서가 그것들을 추측하거나 고정하지 않는다.

## 계약 원칙

- Domain `AuthenticationMethod.apple`은 지원 방식이라는 비즈니스 값이며 Apple API 타입이나
  실행 논리를 포함하지 않는다.
- `AuthenticationRepository`는 외부 인증과 단발성 `AuthenticationGrant` 발급만 담당하고,
  `SessionRepository`는 서버 세션 시작·저장·복원·종료만 담당한다.
- Domain `AuthenticationRepository` Adapter는 Data의 공급자 중립
  `ExternalAuthenticationProvider`만 사용하고, 별도 Data↔Core Adapter만 Core Apple 기술
  API를 사용한다.
- Apple 인증 원시 값은 서버 검증 입력이고 Git It 세션 토큰이 아니며 Domain grant에 포함하지 않는다.
- Feature와 App은 토큰 값을 받지 않는다. 성공 결과에는 안전한 사용자 정보와 인증 상태만
  전달한다.
- 실제 서버 Adapter, 인증 Mock, 세션 Mock, unavailable 구현은 같은 Domain 결과와 오류 의미를 반환한다.
- 모든 production 의존성은 `AppComposition`에서 생성해 Feature initializer에 전달한다.
- 서버에 endpoint가 없는 릴리스 구성은 인증 성공을 반환하지 않고 재시도 가능한 unavailable
  결과로 닫힌다.

## 입력과 출력 의미

| 값 | 생산자 | 소비자 | 수명·보호 규칙 |
| --- | --- | --- | --- |
| `AuthenticationMethod` | Domain | Feature·Domain use case·Composition | 현재 `.apple`을 지원한다. 공급자 선택 의미만 가지며 API 타입이나 credential을 포함하지 않는다. |
| `AuthenticationAttempt` | Core `AppleAuthorizationProvider` | 같은 Core API | `attemptID`, `nonce`, `state`, 만료 시각을 포함하며 Core 밖에 노출하지 않고 메모리에서만 유지한다. |
| `ExternalAuthenticationEvidence` | Composition Data↔Core Adapter | Composition Domain↔Data Adapter | method identifier, 불투명 공급자 참조와 payload만 포함한다. Apple 필드명·상태 case를 포함하지 않는다. |
| `AuthenticationGrant` | `AuthenticationRepository` | Domain `SignIn`·`SessionRepository` | Domain에는 grant ID와 method만 포함한다. 단발성이며 저장·로그·재사용하지 않는다. |
| grant payload | Composition Domain↔Data 인증 Adapter | Composition `SessionRepository` Adapter | Data evidence의 불투명 payload를 vault에만 보관하고 한 번 소비한 뒤 폐기한다. Domain Adapter는 Apple 내부 필드를 해석하지 않는다. |
| `AuthenticatedSession` | `SessionRemote` 또는 Mock | 세션 저장 Adapter | 사용자, access/refresh token, access 만료를 포함한다. 공급자 인증 참조와 분리해 Keychain에 저장한다. |
| `AuthenticationOutcome` | Domain use case | Feature/App | `authenticated(user)`, `unauthenticated`, `recoverableFailure` 중 하나다. 원시 토큰과 외부 오류를 포함하지 않는다. |

## Domain Repository 계약

| 계약 | 연산 | 책임과 사후 조건 |
| --- | --- | --- |
| `AuthenticationRepository` | `authenticate(using: AuthenticationMethod) -> AuthenticationGrant` | 선택한 외부 인증만 수행한다. 성공 시 Domain grant를 반환하고 서버 세션을 만들거나 저장하지 않는다. |
| `AuthenticationRepository` | `authorizationStatus() -> AuthenticationAuthorizationStatus` | 별도 인증 참조를 이용해 `authorized`·`reauthenticationRequired`·`temporarilyUnavailable` 중 하나를 반환한다. Data 상태는 Domain↔Data Adapter에서 비즈니스 의미로 변환한다. |
| `AuthenticationRepository` | `authorizationChanges() -> AsyncStream<AuthenticationAuthorizationStatus>` | 공급자 상태 변경을 Domain 상태 stream으로 전달한다. Apple notification과 credential state 타입은 Data↔Core Adapter 내부에만 둔다. |
| `AuthenticationRepository` | `clearAuthorization()` | 공급자 인증 참조와 미소비 grant를 정리한다. Git It 서버 세션이나 토큰은 변경하지 않는다. |
| `SessionRepository` | `start(with: AuthenticationGrant) -> AuthenticatedUser` | grant를 한 번 소비해 서버 세션을 발급받고 보호 저장까지 성공한 뒤 사용자만 반환한다. 공급자 인증 API를 실행하지 않는다. |
| `SessionRepository` | `restore() -> AuthenticatedUser?` | 저장 서버 세션을 읽고 access token이 만료했다면 내부적으로 갱신한다. 공급자 authorization 판단은 수행하지 않는다. |
| `SessionRepository` | `signOut()` | 로컬 서버 세션을 즉시 삭제하고 서버 refresh token 폐기를 best-effort로 요청한다. 공급자 인증 참조는 변경하지 않는다. |

`SignIn`, `RestoreSession`, `ObserveAuthorizationChanges`, `SignOut` use case가 위 계약을
조정한다. `ObserveAuthorizationChanges`는 Repository 변경 stream을 소비해 필요한 인증 참조·
서버 세션 정리를 수행하고 `AuthenticationOutcome`만 Feature에 전달한다. Feature는 Repository나
authorization status를 직접 구독·판단하지 않는다. Repository 구현끼리 직접 호출하지 않으며
공유 기술 상태가 필요한 경우에도 `AuthenticationGrantVault`와 세션 조정 actor를 각 Adapter에
initializer로 명시적으로 주입한다.

## Data 외부 인증 계약

| 계약 | 연산 | 책임과 사후 조건 |
| --- | --- | --- |
| `ExternalAuthenticationProvider` | `authenticate(methodIdentifier: String) -> ExternalAuthenticationEvidence` | method identifier에 해당하는 외부 인증을 수행하고 Data 소유의 불투명 evidence를 반환한다. Domain과 Apple 타입을 참조하지 않는다. |
| `ExternalAuthenticationProvider` | `authorizationState(methodIdentifier: String, subjectReference: String) -> ExternalAuthorizationState` | `active`·`inactive`·`temporarilyUnavailable` 중 하나를 반환한다. 공급자의 기술 상태 case를 공개하지 않는다. |
| `ExternalAuthenticationProvider` | `authorizationChanges(methodIdentifier: String, subjectReference: String) -> AsyncStream<ExternalAuthorizationState>` | 공급자 상태 변경을 Data 소유 stream으로 전달한다. 외부 notification 타입을 공개하지 않는다. |

Composition의 Data↔Core Adapter만 위 계약을 Core `AppleAuthorizationProvider`와 연결한다.
Domain↔Data Adapter는 Domain `.apple`을 안정적인 method identifier로 변환하고 Data
`.active`·`.inactive`·`.temporarilyUnavailable`을 각각 Domain `.authorized`·
`.reauthenticationRequired`·`.temporarilyUnavailable`로 변환한다. 어느 Data 공개 API에도
Apple credential 필드명이나 credential state case가 들어가지 않는다.

## 연산 계약

### 외부 인증과 grant 발급

**전제**: 사용자가 로그인 제어를 명시적으로 탭했고 진행 중인 인증 시도가 없다.

1. Feature는 Domain `AuthenticationMethod.apple`을 `SignIn`에 전달한다.
2. `SignIn`은 `AuthenticationRepository.authenticate(using: .apple)`을 호출한다.
3. Domain↔Data 인증 Adapter는 `.apple`을 method identifier로 변환해 Data
   `ExternalAuthenticationProvider`를 호출한다.
4. Data↔Core Adapter는 method identifier를 Core `AppleAuthorizationProvider`에 연결한다.
   Core가 현재 시도에만 유효한 `AuthenticationAttempt`를 만들고 `nonce`, `state`, 선택 scope를
   적용해 시스템 인증 UI를 연다.
5. Core는 성공 콜백의 현재 `attemptID`·`state`와 필수 Apple 원시 값의 존재를 검증한다.
   Data↔Core Adapter는 성공을 불투명 `ExternalAuthenticationEvidence`로, 취소·오류를 Data
   오류로 변환한다.
6. Domain↔Data Adapter는 취소를 Domain `AuthenticationError.cancelled`로 변환한다. 성공이면
   evidence payload를 `AuthenticationGrantVault`에 등록한다. vault는 initializer로 주입된 grant
   ID 생성기를 사용하고, Adapter는 공급자 참조를 별도 저장한 뒤 반환 ID와 `.apple`만 가진
   Domain `AuthenticationGrant`를 반환한다. 이 시점에는 Git It 서버 세션이 아직 없다.

### Git It 서버 세션 시작

**전제**: `AuthenticationRepository`가 아직 소비되지 않은 grant를 반환했다.

1. Domain `SignIn`은 `SessionRepository.start(with: grant)`를 호출한다.
2. Composition Session Adapter는 grant ID와 method를 확인하고 vault payload를 원자적으로 한 번 소비한다.
3. Adapter는 공급자 중립 `SessionRemote.startSession`에 method identifier와 불투명한 일회성
   payload를 전달한다. `SessionRemote`는 Apple 타입·필드명·분기 논리를 공개 계약에 갖지 않는다.
4. 서버와 Mock은 실제 공급자 증거를 검증한 뒤 Git It 사용자와 access/refresh token을 반환한다.
5. Session Adapter가 응답을 세션 저장소에 원자적으로 보관한 뒤에만 `AuthenticatedUser`를 반환한다.
6. 서버 교환이나 저장이 실패하면 grant와 부분 세션을 정리하고 인증 성공을 반환하지 않는다.

**실패 의미**:

| 조건 | 결과 | 저장소 |
| --- | --- | --- |
| 사용자 취소 | `unauthenticated` | grant·인증 참조·세션 변경 없음 |
| state·시도 불일치, 예상 밖 credential, 원시 값 누락 | `recoverableFailure` 또는 로그인 화면 | grant를 발급하지 않음 |
| 인증 참조 저장 실패 | `recoverableFailure` | 등록한 vault payload를 폐기하고 grant·세션을 만들지 않음 |
| grant 만료·중복 소비·method 불일치 | `recoverableFailure` | grant 폐기, 세션 변경 없음 |
| 외부 인증/세션 시작의 일시 오류 | `recoverableFailure` | grant·임시 인증 상태·부분 세션 정리 |
| 서버가 계정 이용 불가를 확정 | `unauthenticated` | grant와 기존 서버 세션·인증 참조를 각 Repository에서 정리 |

### 앱 시작 세션 복원과 재시도

**전제**: 앱이 시작했거나 사용자가 복구 화면에서 재시도를 선택했다.

1. Domain `RestoreSession`은 `SessionRepository`에서 저장된 Git It 세션 존재와 상태를 확인한다.
   값이 없으면 중단된 최초 로그인에서 남았을 수 있는 인증 참조와 grant를
   `AuthenticationRepository.clearAuthorization()`으로 정리하고 `unauthenticated`를 반환한다.
2. `AuthenticationRepository`는 별도 인증 참조 저장소의 method와 공급자 참조를 사용해 generic
   authorization status를 반환한다. Apple credential state 타입은 Adapter 밖으로 나오지 않는다.
3. authorization status가 `authorized`이면 `SessionRepository`가 access token을 확인하고
   만료했다면 내부적으로 리프레시 토큰으로 갱신한다.
4. authorization `reauthenticationRequired`·서버 refresh 거부·계정 이용 불가가 확인되면
   `RestoreSession`이 서버 세션과 인증 참조를 각 Repository를 통해 정리하고
   `unauthenticated`를 반환한다.
5. authorization 조회·갱신의 일시 오류면 두 저장소를 유지하고 `recoverableFailure`를 반환한다.
6. 공급자 authorization과 Git It 서버 세션이 모두 유효한 경우만 `authenticated(user)`로 전환한다.

### 로그아웃

**전제**: 사용자가 인증된 상태에서 로그아웃을 선택했다.

1. `SignOut`은 `SessionRepository.signOut()`을 먼저 호출한다.
2. 세션 조정 actor가 세션 세대를 증가시키고 진행 중 세션 시작·복원·갱신 결과를 무효화한 뒤
   access token과 refresh token을 즉시 삭제한다.
3. 삭제 전 메모리에 있던 refresh token으로 서버 폐기를 best-effort 요청한다.
4. `SignOut`은 폐기 결과와 관계없이 `AuthenticationRepository.clearAuthorization()`을 호출해
   공급자 인증 참조와 남은 grant를 별도로 삭제한다.
5. 서버 폐기·인증 참조 정리의 성공 여부와 관계없이 `unauthenticated`를 반환한다.
6. 늦은 세션 시작·갱신 응답은 이전 세대이므로 저장하거나 인증 화면을 되살릴 수 없다.

## 구현 교체 계약

| 구현 | 선택 위치 | 허용 환경 | 의무 |
| --- | --- | --- | --- |
| `MockAuthenticationRepository` | `Composition` | Feature/App 통합 테스트, UI 미리보기, 명시적인 개발 구성 | method 선택, 성공 grant, 취소, 일시 오류, authorization status를 결정적으로 재현하고 서버 세션을 만들지 않는다. Domain 단위 테스트는 Domain test target 안의 local Test Double을 사용한다. |
| Domain `AuthenticationRepository` Adapter | `Composition` | production·통합 테스트 구성 | Domain method/status/error와 Data method identifier/state/error를 변환하고 evidence를 vault·인증 참조 저장소에 분리한다. Core·Apple 타입이나 분기 논리를 사용하지 않는다. |
| Data↔Core `ExternalAuthenticationProvider` Adapter | `Composition` | 실제 Apple 인증 구성 | Data method identifier를 Core Apple API에 연결하고 Core credential·상태·오류를 Apple 필드가 없는 Data evidence·상태·오류로 변환한다. Domain 타입을 사용하지 않는다. |
| `MockExternalAuthenticationProvider` | `Composition` | Adapter 단위 테스트와 명시적인 개발 구성 | Data 외부 인증 계약의 evidence·상태·오류를 실제 Apple UI 없이 결정적으로 재현한다. |
| `MockSessionRemote` | `Composition` | 단위 테스트, UI 미리보기, 명시적인 개발 구성 | 신규·기존 사용자, 선택 프로필 부재, 세션 시작·갱신, 일시 오류, 거부, 폐기 실패를 결정적으로 재현한다. |
| `LiveSessionRemote` | `Composition` | 서버 endpoint와 계약이 확정된 뒤의 production 구성 | 공급자 중립 세션 계약을 구현하고 일회성 payload를 TLS로 서버에만 전달한다. |
| `UnavailableSessionRemote` | `Composition` | live endpoint가 없는 릴리스 구성 | 외부 인증 grant가 있어도 서버 세션 성공을 반환하지 않고 안전한 재시도 안내로 닫힌다. |

인증 Mock과 세션 Mock은 각각 동일한 Domain/Data/`SessionRemote` 계약의 해당 경계를 구현해야
하며 Feature가 Mock 전용 action, grant payload나 토큰 값을 알게 해서는 안 된다.

## 보안 및 관찰성 계약

- Keychain은 기기 한정·잠금 중 비노출 접근성을 사용한다.
- `identityToken`, `authorizationCode`, access token, refresh token, nonce, state는 로그,
  분석 이벤트, 오류 메시지, 화면 접근성 값, 테스트 실패 덤프에 넣지 않는다.
- `AuthenticationGrant`에는 ID와 method만 두며 grant payload는 `Equatable`,
  `CustomStringConvertible`, 영구 저장 대상이 아니다. vault는 단발 소비·만료·명시적 전체 정리를
  지원하고 전역 접근을 제공하지 않는다.
- 서버는 Apple JWT의 서명, issuer, audience, expiration, nonce와 authorization code의
  단발성을 검증한다. 서버 Apple private key와 client secret은 앱에 포함하지 않는다.
- Apple credential revoked 알림은 Data↔Core Adapter에서 Data `.inactive`로, Domain↔Data
  Adapter에서 Domain `.reauthenticationRequired`로 변환한 뒤 복원 규칙과 같은 세션 무효화
  경로를 실행한다.
- Apple credential `.transferred`도 Data↔Core Adapter에서 `.inactive`로 수렴시키고 자동 병합·
  자동 새 계정 생성을 하지 않는다. 사용자 식별자 마이그레이션은 실제 서버 계약이 준비된 별도
  기능에서 처리한다.

## 계약 검증 사례

- state가 다른 늦은 콜백, 누락 token/code, 중복 탭은 grant를 발급하지 않는다.
- Domain 인증 Adapter 단위 테스트는 Core 모듈이나 Apple Test Double 없이 Data
  `ExternalAuthenticationProvider` Test Double만으로 통과한다.
- 한 grant를 두 번 사용하면 첫 세션 시작만 vault payload를 소비하고 두 번째 요청은 서버를 호출하지 않는다.
- 취소는 오류 경고와 토큰 생성을 남기지 않는다.
- 유효한 리프레시 토큰은 새 access token으로 세션을 복원한다.
- 일시 오류는 토큰을 보존하고 보호 화면을 막으며, 거부·만료는 세션 전체를 제거한다.
- 로그아웃과 갱신을 경쟁시키면 로그아웃 뒤의 갱신 결과가 Keychain에 저장되지 않는다.
- 인증 또는 세션 Mock을 Live Adapter로 바꿔도 Feature의 action·state·delegate와 Domain 두
  Repository 계약은 바뀌지 않는다.
