# 데이터 및 상태 모델: Apple 소셜 로그인

이 문서는 앱이 다루는 인증 의미와 상태 전이를 정의한다. 실제 서버 데이터베이스 스키마와
HTTP DTO는 아직 확정되지 않았으며, 해당 구현은 앱 내부 계약을 만족하는 후속 Adapter 작업이다.

## 엔터티

### 인증 방식

| 필드 | 의미 | 검증·보관 규칙 |
| --- | --- | --- |
| `AuthenticationMethod.apple` | 현재 Domain이 지원하는 Apple 소셜 인증 방식 | Domain의 비즈니스 값이며 `AuthenticationServices` 타입이나 Apple 실행 절차를 포함하지 않는다. |

**관계**: Feature는 사용자가 선택한 값을 Domain `SignIn`에 전달한다. Composition은 이 값을
Data method identifier로 변환하고, 별도 Data↔Core Adapter가 Core Apple 기술 API를 선택한다.
Domain과 Domain↔Data Adapter는 해당 기술 매핑을 알지 않는다.

### 인증 grant

| 필드 | 의미 | 수명·검증 규칙 |
| --- | --- | --- |
| `id` | 외부 인증 결과를 한 번 소비하기 위한 불투명 식별자 | CSPRNG로 만들고 원시 credential을 포함하지 않는다. |
| `method` | grant를 발급한 `AuthenticationMethod` | 현재는 `.apple`이며 서버 세션 시작 시 동일 method인지 확인한다. |

**관계**: `AuthenticationRepository`가 외부 인증 성공 후 발급하고 `SessionRepository`가 서버
세션 시작에 한 번만 소비한다. 실제 `identityToken`·`authorizationCode`·공급자 사용자 식별자는
Data↔Core Adapter가 만든 불투명 evidence payload 안에서만 Composition
`AuthenticationGrantVault`에 존재하며 Domain grant에는 포함되지 않는다.

### Git It 사용자 계정

| 필드 | 의미 | 검증·보관 규칙 |
| --- | --- | --- |
| `id` | Git It 서버가 발급한 안정적인 사용자 식별자 | 서버 교환 성공 후에만 신뢰한다. |
| `availability` | 인증된 콘텐츠를 사용할 수 있는지 나타내는 상태 | 이용 불가이면 세션을 인증 상태로 복원하지 않는다. |
| `displayName` | 선택적 표시용 이름 | Apple 이름의 부재를 로그인 실패로 만들지 않는다. |

**관계**: 유효한 로그인 세션은 정확히 하나의 Git It 사용자 계정과 연결된다.

### 공급자 인증 참조

| 필드 | 의미 | 검증·보관 규칙 |
| --- | --- | --- |
| `methodIdentifier` | 인증 방식을 나타내는 공급자 중립 저장 식별자 | Composition이 Domain `AuthenticationMethod`와 변환한다. Data/Core는 Domain enum에 의존하지 않는다. |
| `providerSubjectReference` | 공급자 authorization status 조회에 필요한 불투명 사용자 참조 | 인증 참조 저장소에만 보호 저장하고 서버 세션 토큰과 같은 모델에 넣지 않는다. Data↔Core 외부 인증 Adapter만 기술적 의미를 해석한다. |

**관계**: 이번 기능에서 참조의 실제 공급자는 Apple이다. `AuthenticationRepository` 구현이
저장·조회·삭제하고 Domain에는 `authorized`·`reauthenticationRequired`·
`temporarilyUnavailable`이라는 비즈니스 상태와 상태 변경 stream만 반환한다. Apple의 세부
credential state는 Adapter 밖으로 나오지 않으며 이메일만 같은 두 계정은 자동으로 연결하지 않는다.

### 외부 인증 evidence(Data/Composition 기술 모델)

| 필드 | 의미 | 수명·검증 규칙 |
| --- | --- | --- |
| `methodIdentifier` | Data가 이해하는 공급자 중립 인증 방식 식별자 | Domain enum이나 Apple 타입을 포함하지 않는다. |
| `providerSubjectReference` | authorization 상태를 다시 확인하기 위한 불투명 참조 | 인증 참조 저장소로 분리해 보호 저장한다. |
| `opaquePayload` | Git It 서버 세션 시작에 한 번 사용할 외부 인증 증거 | Apple 필드명을 공개하지 않고 비교·로그·영구 저장을 금지한다. |

**관계**: Data `ExternalAuthenticationProvider`가 반환하고 Domain↔Data 인증 Adapter가
`opaquePayload`를 Composition grant vault에 등록한다. `SessionRepository` Adapter가 한 번
소비해 Data `SessionRemote`에 전달하며 Domain에는 evidence나 payload가 노출되지 않는다.

### Apple 인증 시도(Core/Composition 기술 모델)

| 필드 | 의미 | 수명·검증 규칙 |
| --- | --- | --- |
| `attemptID` | 현재 로그인 시도를 구분하는 값 | 로그인 시작부터 성공·실패·취소까지 메모리에만 존재한다. 이전 시도 콜백은 무시한다. |
| `nonce` | Apple ID token과 현재 요청을 결속하는 단발성 값 | CSPRNG로 생성하고 재사용하지 않는다. 로그·Keychain에 쓰지 않는다. |
| `state` | 요청과 콜백의 상관관계 값 | 반환값이 현재 시도와 다르면 교환을 시작하지 않는다. |
| `expiresAt` | 시도 유효 기한 | 만료한 콜백은 실패로 처리하고 새 시도를 요구한다. |

**관계**: 인증 시도는 최대 하나만 진행 중일 수 있고 성공 여부와 무관하게 종료 시 폐기된다.

### Apple 인증 결과(Core/Composition 기술 모델)

| 필드 | 의미 | 수명·검증 규칙 |
| --- | --- | --- |
| `identityToken` | Apple이 발급한 JWT 원시 값 | 서버 검증 입력일 뿐 Git It 세션이 아니다. 교환 직후 메모리에서 폐기한다. |
| `authorizationCode` | Apple 서버 교환에 쓰는 단발성 코드 | 서버 교환 입력으로만 사용하고 영구 저장하지 않는다. |
| `appleUserID` | 반환 credential의 사용자 식별자 | 서버가 검증한 JWT subject와 일치하는지 확인하는 데 사용한다. |
| `email`, `fullName` | 선택적 프로필 정보 | 누락 가능하며 로그인 성공 여부를 결정하지 않는다. |

이 두 Apple 모델은 Core 내부에만 존재한다. Data↔Core 외부 인증 Adapter가 이를 Data
`ExternalAuthenticationEvidence`로 변환하고 그 뒤에는 Apple 필드명이나 상태 case를 전달하지
않는다. Domain `AuthenticationRepository` 계약, use case, Feature action에는 노출하지 않는다.

### Git It 로그인 세션

| 필드 | 의미 | 보관·검증 규칙 |
| --- | --- | --- |
| `accessToken` | 인증된 API 접근에 쓰는 Git It 토큰 | Keychain에만 저장한다. 화면·로그·오류 문자열에 넣지 않는다. |
| `refreshToken` | access token 갱신과 서버 폐기에 쓰는 Git It 토큰 | Keychain에만 저장한다. 로그아웃 후 메모리에서만 best-effort 폐기 요청에 사용할 수 있다. |
| `accessExpiresAt` | access token의 만료 시점 | 현재 시각보다 이르면 refresh를 시도한다. |
| `user` | 인증된 Git It 사용자 계정 | 인증된 화면에는 안전한 표시 정보만 전달한다. |
| `generation` | 비동기 결과의 유효성을 판단하는 세션 세대 | 저장소 내부·조정 actor에서만 사용한다. 로그아웃 시 증가한다. |

**저장 위치**: `accessToken`, `refreshToken`, `accessExpiresAt`은 서버 세션 전용 key
namespace의 기기 한정 Keychain에 원자적으로 저장·삭제한다. 공급자 인증 참조와 저장 모델을
공유하지 않는다. `generation`은 프로세스 내 조정 상태로 충분하며 앱 재시작에서 새 세션 복원
시 다시 시작한다.

### 세션 복구 상태

| 상태 | 의미 | 사용자에게 허용되는 동작 |
| --- | --- | --- |
| `checking` | 앱 시작 시 공급자 authorization status와 Git It 서버 세션을 확인 중 | 보호된 콘텐츠를 표시하지 않는다. |
| `unauthenticated` | 유효한 공급자 인증 또는 서버 세션이 없음 | 지원하는 인증 방식 선택을 허용한다. |
| `authenticating` | 선택한 방식의 외부 인증이 진행 중 | 중복 시작을 막고 진행 상태를 알린다. |
| `establishingSession` | 발급된 grant로 Git It 서버 세션을 시작·저장 중 | 외부 인증을 다시 시작하지 않고 보호된 콘텐츠를 표시하지 않는다. |
| `authenticated` | 검증된 Git It 세션이 있음 | 인증된 첫 화면과 로그아웃을 제공한다. |
| `recoverableFailure` | 일시 오류로 세션을 확정할 수 없음 | 보호된 콘텐츠 없이 재시도 동작만 제공한다. |

## 관계와 소유

```text
AuthenticationMethod.apple
  └─ AuthenticationRepository ─> Data ExternalAuthenticationProvider ─> AuthenticationGrant
                                      └─ SessionRepository ─> Git It 로그인 세션
                                                                  └─ Git It 사용자 계정

공급자 인증 참조 ── AuthenticationRepository ─> Data ExternalAuthenticationProvider
                                            └─> generic authorization status
Git It 로그인 세션 ── SessionRepository ──────> 복원·갱신·종료
```

- 서버가 Apple 인증 결과를 검증하고 Apple 계정 연결과 Git It 사용자 계정의 관계를 소유한다.
- 앱은 공급자 인증 참조와 Git It 서버 세션을 분리된 보호 저장 경계에 보관한다.
- Feature와 App은 사용자 계정의 안전한 표시 정보와 세션 복구 상태만 받으며 토큰 값은 받지 않는다.

## 상태 전이

```text
앱 시작
  └─> checking
        ├─ 저장 세션 없음 ─> 남은 인증 참조·grant 정리 ──> unauthenticated
        ├─ 공급자 철회·리프레시 거부·계정 이용 불가 ─────> 인증 참조·세션 개별 삭제 ─> unauthenticated
        ├─ authorization 유효 + access 유효/refresh 성공 ─> authenticated
        └─ authorization 조회·갱신의 일시 오류 ─────────> recoverableFailure

unauthenticated
  └─ AuthenticationMethod.apple 선택 ─> authenticating
        ├─ 사용자 취소 ─────────────────────────────────> unauthenticated
        ├─ 외부 인증 성공 ─> grant 발급 ─> establishingSession
        │                                  ├─ 서버 교환·저장 성공 ─> authenticated
        │                                  └─ 실패 ─> grant·임시 인증 정리 ─> recoverableFailure
        └─ 오류·시도 불일치·값 누락 ───────────────────> unauthenticated 또는 recoverableFailure

authenticated
  ├─ access token 만료 ─> checking ─> refresh 성공 ───> authenticated
  ├─ 일시 갱신 오류 ───────────────────────────────────> recoverableFailure
  └─ 로그아웃 ─> 세션 삭제·세대 증가 ─────────────────> unauthenticated

recoverableFailure
  ├─ 재시도 성공 ──────────────────────────────────────> authenticated
  └─ 리프레시 거부 확인 ─> 세션 삭제 ──────────────────> unauthenticated
```

## 무효화 규칙

| 사건 | 로컬 세션 | 화면 결과 |
| --- | --- | --- |
| Domain `AuthenticationError.cancelled` | grant·세션을 만들지 않음 | 경고 없이 로그인 화면 유지 |
| Domain authorization status `reauthenticationRequired` | 인증 참조와 서버 세션을 각각 삭제 | 로그인 화면 |
| authorization status 조회 일시 오류 | 인증 참조와 토큰을 유지 | 재시도 화면 |
| grant 만료·중복 소비·세션 시작 실패 | grant와 임시 인증 상태를 정리하고 서버 세션을 저장하지 않음 | 재시도 화면 |
| refresh 일시 네트워크 오류 | 토큰을 유지 | 재시도 화면 |
| refresh 거부·만료 또는 계정 이용 불가 | 서버 세션을 삭제하고 필요한 경우 인증 참조도 별도 정리 | 로그인 화면 |
| 로그아웃 | 서버 세션 즉시 삭제·세대 증가 후 인증 참조와 grant 별도 정리 | 로그인 화면; 서버 폐기는 비차단 best-effort |

## 검증 규칙

- Apple 사용자 식별과 Git It 계정 연결은 서버 검증 후에만 확정한다.
- 이메일·이름의 존재 여부와 이메일 일치는 계정 식별·병합·로그인 성공의 근거가 아니다.
- 현재 `attemptID`·`state`가 일치하지 않거나 `identityToken` 또는 `authorizationCode`가 없으면
  grant를 발급하지 않는다.
- grant ID와 method가 일치하고 vault에서 첫 소비에 성공한 경우에만 서버 세션 시작을 호출한다.
- Domain·Feature·Data `ExternalAuthenticationProvider`·`SessionRemote`에는 Apple credential
  타입, credential state case나 Apple 전용 연산을 노출하지 않는다.
- `generation`이 바뀐 비동기 결과는 저장소·화면 상태를 바꾸지 않는다.
- 민감 값은 `Equatable` 비교 덤프, `CustomStringConvertible`, 오류 메시지, 분석 이벤트에 넣지
  않는다.
