# 조사 기록: Apple 소셜 로그인

**기능**: `001-apple-social-login`
**조사일**: 2026-08-10

## 1. Apple 인증 시작과 결과 검증

### 결정

Domain은 지원하는 인증 방식을 자체 `AuthenticationMethod`로 정의하고 이번 기능에서 `.apple`을
제공한다. `AuthenticationRepository`는 선택한 방식의 외부 인증까지만 담당하고 공급자 중립
`AuthenticationGrant`를 반환한다. production `AuthenticationRepository` Adapter는 Data의
공급자 중립 `ExternalAuthenticationProvider`만 사용한다. 별도 Data↔Core Adapter가 method
identifier를 Core `AppleAuthorizationProvider`에 연결하고, Core만 `AuthenticationServices`를
감싸 사용자의 명시적 탭에서 Apple 인증을 시작한다. 요청마다 CSPRNG 기반 `nonce`, `state`,
`attemptID`를 만들며 성공 콜백이 현재 시도와 일치하고 `identityToken`·`authorizationCode`를
정상적으로 얻은 경우에만 불투명 evidence를 거쳐 grant를 만든다. `.fullName`과 `.email`은 선택
정보로 요청하되 로그인 성공의 필수값으로 사용하지 않는다.

### 근거

Apple 인증은 `ASAuthorizationAppleIDProvider`와 `ASAuthorizationController` 흐름으로
시작할 수 있으며, Apple 사용자 식별자는 반복 로그인 식별에 쓰고 이름·이메일은 최초 승인
이후 생략될 수 있다. 시도별 nonce와 state는 오래된 콜백·재전송·요청 혼동을 막는 데
필요하다. `.apple`은 도메인이 지원하는 방식이라는 비즈니스 값이지만 Apple API·credential·
오류 매핑·credential state는 기술 논리이므로 Domain 계약과 use case에서 배제한다. 앱은
서버 검증 전 Apple 인증 결과를 Git It 로그인으로 간주할 수 없다.

### 검토한 대안

- Apple `identityToken`을 Git It 세션 토큰으로 직접 사용: 자체 서버 검증·세션 수명·로그아웃
  경계가 사라져 FR-008과 FR-027에 맞지 않아 제외한다.
- 이메일을 사용자 키 또는 자동 병합 근거로 사용: private relay, 미제공, 반복 응답 생략과
  FR-014에 맞지 않아 제외한다.
- nonce/state 없이 콜백을 교환: 이전 시도와 늦은 콜백을 안전하게 구분하지 못해 제외한다.
- Domain `AppleAuthorizationClient` 또는 `SignInWithApple` 계약: 프로토콜이어도 Apple 실행
  기술과 흐름을 Domain 언어로 고정하므로 제외한다.
- Domain `AuthenticationRepository` Adapter가 Core Apple API를 직접 사용: Domain↔Data와
  Data↔Core 변환 책임을 합치고 인증 서비스 구현에 Apple 분기를 고정하므로 제외한다.

## 2. 서버 검증과 앱의 토큰 경계

### 결정

Apple `identityToken`과 `authorizationCode`는 Data↔Core Adapter에서 Apple 필드가 없는
불투명 evidence payload로 변환해 Composition의 `AuthenticationGrantVault`에 메모리로만
보관하고 공급자 중립 grant ID로 한 번만 소비한다. Domain `SignIn`은
`AuthenticationRepository`에서 grant를 받은 뒤 `SessionRepository.start(with:)`를 호출한다.
`SessionRepository` 구현은 grant를 Git It 서버와 교환하고 응답을 보호 저장한 뒤에만
`AuthenticatedUser`를 반환한다. 서버는 Apple 서명, issuer, audience, expiration, nonce와
단발성 authorization code를 검증한 뒤에만 Git It 액세스 토큰·리프레시 토큰을 발급한다.

### 근거

Apple 원시 토큰은 Git It 세션 권한이 아니며, 클라이언트가 검증 책임을 가지면 Apple private
key, client secret 또는 검증 키 배포 위험이 생긴다. 실제 HTTP endpoint가 아직 없으므로
모바일 앱에는 endpoint 모양이 아닌 공급자 중립 `SessionRemote` 계약을 먼저 둔다. 이 계약은
인증 method identifier와 불투명한 일회성 payload를 세션 시작 입력으로 취급하며 Apple 필드나
분기 논리를 소유하지 않는다. Mock과 실제 Adapter는 같은 세션 경계에서 교체한다.

### 검토한 대안

- 앱에서 Apple JWT를 완전히 검증하고 세션을 발급: 서버 신뢰 경계와 비밀 관리가 무너져
  제외한다.
- Mock을 릴리스 기본 구현으로 사용: 실제 인증 없이 보호된 콘텐츠를 열 수 있어 제외한다.
- 현재 미정인 HTTP 경로·JSON 필드를 문서에서 확정: 백엔드 계약을 추측하게 되므로 제외한다.
- `AuthenticationRepository`가 서버 교환과 최초 세션 저장까지 담당: 외부 인증과 Git It
  서버 세션의 책임이 다시 결합되므로 제외한다.

## 3. 안전한 세션 저장과 복원

### 결정

Git It 액세스 토큰·리프레시 토큰은 `SessionRepository` 소유 세션 저장소에,
`AuthenticationMethod`와 공급자 사용자 참조는 `AuthenticationRepository` 소유 인증 참조
저장소에 분리한다. 둘 다 `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` 상당의 기기 한정
Keychain 접근성을 사용하지만 계약과 key namespace를 공유하지 않는다. 앱 시작에는 Domain
`RestoreSession`이 generic authorization status와 서버 세션 상태를 조정한 뒤에만 보호 화면을
연다. 유효한 액세스 토큰은 계속 사용하고 만료된 액세스 토큰은 `SessionRepository` 내부에서
리프레시 토큰으로 갱신한다.

### 근거

기기 잠금 상태에서 세션 비밀을 읽지 않게 하고 백업·다른 기기로의 복원을 피하면서도 사용자가
잠금을 푼 뒤 앱을 다시 시작하면 자동 로그인 요구를 충족한다. Apple credential state의
`.revoked`·`.notFound`·`.transferred`와 revoked notification은 Data↔Core Adapter가 Data
`.inactive`로 수렴시키고 Domain↔Data Adapter가 Domain `.reauthenticationRequired`로
변환한다. Domain과 Data는 Apple 상태 case를 복제하지 않으며 조회 자체의 일시 오류는
`.temporarilyUnavailable`이지 재인증이 필요하다는 증거가 아니다.

### 검토한 대안

- UserDefaults 또는 파일에 토큰 저장: 보호 저장소 요구(FR-025)에 맞지 않아 제외한다.
- `StoredSession`에 `appleUserID`를 포함해 세션 저장소가 Apple 상태를 직접 소유: 인증과
  세션 책임이 결합되므로 제외한다.
- 서버 리프레시만 확인하고 공급자 authorization status를 확인하지 않음: Apple 연결 철회를
  놓칠 수 있어 제외한다.
- credential state 조회 실패 때 즉시 토큰 삭제: 일시적인 기술 오류에서 불필요한 로그아웃을
  만들므로 제외한다.

## 4. 실패 분류와 비동기 경쟁

### 결정

사용자 취소는 `AuthenticationRepository`가 Domain `cancelled`로 변환해 무경고 로그인 화면을
유지한다. 세션 시작 실패 시 `SignIn`은 grant와 임시 인증 상태를 정리한다. credential state
조회 오류는 인증 참조를, 세션 갱신의 일시 오류는 토큰을 보존한 채 재시도 화면을 제공한다.
리프레시 거부·만료, Apple 연결 철회, 계정 이용 불가는 Domain use case가 두 Repository의
저장 상태를 각각 정리한다. grant vault actor는 grant 재사용을, 세션 조정 actor는 로그아웃 후
늦게 끝난 세션 시작·갱신이 Keychain이나 화면을 되살리는 것을 차단한다.

### 근거

명세는 취소와 오류의 UX, 일시적 실패와 명시적 리프레시 거부의 저장 정책을 구분한다.
비동기 갱신과 로그아웃은 동시에 일어날 수 있으므로 단순한 UI 취소만으로는 저장소 재기록을
막을 수 없다.

### 검토한 대안

- 취소를 일반 오류 경고와 동일하게 표시: FR-011에 맞지 않아 제외한다.
- 갱신 실패마다 토큰 삭제: FR-022의 재시도 가능성을 없애므로 제외한다.
- 로그아웃 뒤 서버 폐기 응답을 기다린 후 로컬 삭제: 네트워크 장애가 로그아웃을 막아
  FR-019·FR-024에 맞지 않아 제외한다.

## 5. 테스트 가능한 Mock 경계

### 결정

Composition에서 인증과 서버 세션 Mock을 별도로 선택한다. Mock 인증 구현은 `.apple` 성공,
취소, 오류, authorization status와 단발성 grant를 재현한다. `MockSessionRemote`는 신규·기존
계정, 이름·이메일 부재, 세션 시작·갱신 성공, 일시 오류, 리프레시 거부, 서버 폐기 실패를
결정적으로 재현한다. Preview와 단위 테스트는 두 Domain Repository 또는 하위 기술 Mock을
생성자로 주입하며 실제 네트워크나 Keychain을 요구하지 않는다.

### 근거

서버 endpoint가 미확정인 현재도 FR-018과 SC-008을 검증해야 한다. Mock이 Feature와 다른
경로를 사용하면 실제 Adapter 교체 때 사용자 흐름이 달라질 위험이 있다.

### 검토한 대안

- Feature에서만 성공 결과를 만들어 화면 전환을 테스트: 외부 인증·서버 교환·저장·갱신 경계를
  검증하지 못해 제외한다.
- 실제 서버가 준비될 때까지 인증 기능 전체를 미룸: 명세가 요구하는 Mock 기반 개발과
  검증을 충족하지 못해 제외한다.

## 참고한 1차 문서

- [Authenticating users with Sign in with Apple](https://developer.apple.com/documentation/signinwithapple/authenticating-users-with-sign-in-with-apple)
- [Verifying a user](https://developer.apple.com/documentation/signinwithapple/verifying-a-user)
- [ASAuthorizationAppleIDCredential](https://developer.apple.com/documentation/authenticationservices/asauthorizationappleidcredential)
- [Receiving a User’s Identity Token](https://developer.apple.com/documentation/signinwithapple/receiving-a-users-identity-token)
- [CredentialState](https://developer.apple.com/documentation/authenticationservices/asauthorizationappleidprovider/credentialstate)
- [credentialRevokedNotification](https://developer.apple.com/documentation/authenticationservices/asauthorizationappleidprovider/credentialrevokednotification)
