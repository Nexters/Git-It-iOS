# 데이터 및 상태 모델: Apple 소셜 로그인

이 문서는 앱이 다루는 인증 의미와 상태 전이를 정의한다. 실제 서버 데이터베이스 스키마와
HTTP DTO는 아직 확정되지 않았으며, 해당 구현은 앱 내부 계약을 만족하는 후속 Adapter 작업이다.

## 엔터티

### Git It 사용자 계정

| 필드 | 의미 | 검증·보관 규칙 |
| --- | --- | --- |
| `id` | Git It 서버가 발급한 안정적인 사용자 식별자 | 서버 교환 성공 후에만 신뢰한다. |
| `availability` | 인증된 콘텐츠를 사용할 수 있는지 나타내는 상태 | 이용 불가이면 세션을 인증 상태로 복원하지 않는다. |
| `displayName` | 선택적 표시용 이름 | Apple 이름의 부재를 로그인 실패로 만들지 않는다. |

**관계**: 유효한 로그인 세션은 정확히 하나의 Git It 사용자 계정과 연결된다.

### Apple 계정 연결

| 필드 | 의미 | 검증·보관 규칙 |
| --- | --- | --- |
| `appleUserID` | Apple이 제공하는 개발자 팀 범위의 사용자 식별자 | 서버가 검증한 Apple subject와 연결한다. 앱에는 credential state 조회 목적만으로 Keychain에 저장한다. |
| `email` | Apple이 최초 승인에서 선택적으로 제공하는 이메일 | 계정 식별·자동 병합의 키가 아니다. 앱의 영구 저장소에 보관하지 않는다. |
| `fullName` | Apple이 최초 승인에서 선택적으로 제공하는 이름 | 제공되지 않아도 로그인할 수 있다. 서버 저장 전 정제한다. |

**관계**: 하나의 Git It 사용자 계정은 하나의 검증된 Apple 계정 연결로 식별된다. 이메일만
같은 두 계정은 자동으로 연결하지 않는다.

### Apple 인증 시도

| 필드 | 의미 | 수명·검증 규칙 |
| --- | --- | --- |
| `attemptID` | 현재 로그인 시도를 구분하는 값 | 로그인 시작부터 성공·실패·취소까지 메모리에만 존재한다. 이전 시도 콜백은 무시한다. |
| `nonce` | Apple ID token과 현재 요청을 결속하는 단발성 값 | CSPRNG로 생성하고 재사용하지 않는다. 로그·Keychain에 쓰지 않는다. |
| `state` | 요청과 콜백의 상관관계 값 | 반환값이 현재 시도와 다르면 교환을 시작하지 않는다. |
| `expiresAt` | 시도 유효 기한 | 만료한 콜백은 실패로 처리하고 새 시도를 요구한다. |

**관계**: 인증 시도는 최대 하나만 진행 중일 수 있고 성공 여부와 무관하게 종료 시 폐기된다.

### Apple 인증 결과

| 필드 | 의미 | 수명·검증 규칙 |
| --- | --- | --- |
| `identityToken` | Apple이 발급한 JWT 원시 값 | 서버 검증 입력일 뿐 Git It 세션이 아니다. 교환 직후 메모리에서 폐기한다. |
| `authorizationCode` | Apple 서버 교환에 쓰는 단발성 코드 | 서버 교환 입력으로만 사용하고 영구 저장하지 않는다. |
| `appleUserID` | 반환 credential의 사용자 식별자 | 서버가 검증한 JWT subject와 일치하는지 확인하는 데 사용한다. |
| `email`, `fullName` | 선택적 프로필 정보 | 누락 가능하며 로그인 성공 여부를 결정하지 않는다. |

### Git It 로그인 세션

| 필드 | 의미 | 보관·검증 규칙 |
| --- | --- | --- |
| `accessToken` | 인증된 API 접근에 쓰는 Git It 토큰 | Keychain에만 저장한다. 화면·로그·오류 문자열에 넣지 않는다. |
| `refreshToken` | access token 갱신과 서버 폐기에 쓰는 Git It 토큰 | Keychain에만 저장한다. 로그아웃 후 메모리에서만 best-effort 폐기 요청에 사용할 수 있다. |
| `accessExpiresAt` | access token의 만료 시점 | 현재 시각보다 이르면 refresh를 시도한다. |
| `user` | 인증된 Git It 사용자 계정 | 인증된 화면에는 안전한 표시 정보만 전달한다. |
| `appleUserID` | Apple credential state 조회용 식별자 | access/refresh token과 함께 Keychain에 저장하고 세션 삭제 때 함께 제거한다. |
| `generation` | 비동기 결과의 유효성을 판단하는 세션 세대 | 저장소 내부·조정 actor에서만 사용한다. 로그아웃 시 증가한다. |

**저장 위치**: `accessToken`, `refreshToken`, `appleUserID`, `accessExpiresAt`은 기기 한정
Keychain에 원자적으로 저장·삭제한다. `generation`은 프로세스 내 조정 상태로 충분하며,
앱 재시작에서 새 세션 복원 시 다시 시작한다.

### 세션 복구 상태

| 상태 | 의미 | 사용자에게 허용되는 동작 |
| --- | --- | --- |
| `checking` | 앱 시작 시 저장 세션·Apple credential state·토큰 수명을 확인 중 | 보호된 콘텐츠를 표시하지 않는다. |
| `unauthenticated` | 저장 세션이 없거나 유효하지 않음 | Apple 로그인 시작을 허용한다. |
| `authenticating` | Apple 인증과 서버 교환이 진행 중 | 중복 시작을 막고 진행 상태를 알린다. |
| `authenticated` | 검증된 Git It 세션이 있음 | 인증된 첫 화면과 로그아웃을 제공한다. |
| `recoverableFailure` | 일시 오류로 세션을 확정할 수 없음 | 보호된 콘텐츠 없이 재시도 동작만 제공한다. |

## 관계와 소유

```text
Apple 인증 시도 ── 성공 콜백 ──> Apple 인증 결과 ── 서버 검증·교환 ──> Git It 로그인 세션
                                                                  │
                                                                  └──> Git It 사용자 계정

Apple 계정 연결 ── appleUserID ──> 앱 시작 credential state 확인
```

- 서버가 Apple 인증 결과를 검증하고 Apple 계정 연결과 Git It 사용자 계정의 관계를 소유한다.
- 앱은 세션 복원에 필요한 최소 정보만 Keychain에 보관한다.
- Feature와 App은 사용자 계정의 안전한 표시 정보와 세션 복구 상태만 받으며 토큰 값은 받지 않는다.

## 상태 전이

```text
앱 시작
  └─> checking
        ├─ 저장 세션 없음 ──────────────────────────────> unauthenticated
        ├─ Apple 철회·리프레시 거부·계정 이용 불가 ─────> 세션 삭제 ─> unauthenticated
        ├─ 유효 access token 또는 refresh 성공 ────────> authenticated
        └─ credential 조회·갱신의 일시 오류 ───────────> recoverableFailure

unauthenticated
  └─ Apple 로그인 시작 ─> authenticating
        ├─ 사용자 취소 ─────────────────────────────────> unauthenticated
        ├─ 검증·교환 성공 ─> 세션 저장 ────────────────> authenticated
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
| `ASAuthorizationError.Code.canceled` | 저장·삭제하지 않음 | 경고 없이 로그인 화면 유지 |
| Apple credential `.revoked` 또는 `.notFound` | access token, refresh token, `appleUserID`를 삭제 | 로그인 화면 |
| Apple credential `.transferred` | 자동 연결·새 계정 생성을 하지 않음 | 보호된 콘텐츠를 막고 후속 마이그레이션 경로로 안내 |
| credential state 조회 일시 오류 | 토큰을 유지 | 재시도 화면 |
| refresh 일시 네트워크 오류 | 토큰을 유지 | 재시도 화면 |
| refresh 거부·만료 또는 계정 이용 불가 | access token, refresh token, `appleUserID`를 삭제 | 로그인 화면 |
| 로그아웃 | 즉시 모두 삭제, 세대 증가 | 로그인 화면; 서버 폐기는 비차단 best-effort |

## 검증 규칙

- Apple 사용자 식별과 Git It 계정 연결은 서버 검증 후에만 확정한다.
- 이메일·이름의 존재 여부와 이메일 일치는 계정 식별·병합·로그인 성공의 근거가 아니다.
- 현재 `attemptID`·`state`가 일치하지 않거나 `identityToken` 또는 `authorizationCode`가 없으면
  서버 교환을 호출하지 않는다.
- `generation`이 바뀐 비동기 결과는 저장소·화면 상태를 바꾸지 않는다.
- 민감 값은 `Equatable` 비교 덤프, `CustomStringConvertible`, 오류 메시지, 분석 이벤트에 넣지
  않는다.
