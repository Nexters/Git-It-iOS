# 조사 기록: Apple 소셜 로그인

**기능**: `001-apple-social-login`  
**조사일**: 2026-08-10

## 1. Apple 인증 시작과 결과 검증

### 결정

`CoreAuthentication`이 `AuthenticationServices`를 감싸고, 사용자의 명시적 탭에서만 Apple 인증을
시작한다. 요청마다 CSPRNG 기반 `nonce`, `state`, `attemptID`를 만들며, 성공 콜백이 현재
시도와 일치하고 `identityToken`·`authorizationCode`를 정상적으로 얻은 경우에만 서버 교환
경계로 넘긴다. `.fullName`과 `.email`은 선택 정보로 요청하되 로그인 성공의 필수값으로
사용하지 않는다.

### 근거

Apple 인증은 `ASAuthorizationAppleIDProvider`와 `ASAuthorizationController` 흐름으로
시작할 수 있으며, Apple 사용자 식별자는 반복 로그인 식별에 쓰고 이름·이메일은 최초 승인
이후 생략될 수 있다. 시도별 nonce와 state는 오래된 콜백·재전송·요청 혼동을 막는 데
필요하다. 앱은 서버 검증 전 Apple 인증 결과를 Git It 로그인으로 간주할 수 없다.

### 검토한 대안

- Apple `identityToken`을 Git It 세션 토큰으로 직접 사용: 자체 서버 검증·세션 수명·로그아웃
  경계가 사라져 FR-008과 FR-027에 맞지 않아 제외한다.
- 이메일을 사용자 키 또는 자동 병합 근거로 사용: private relay, 미제공, 반복 응답 생략과
  FR-014에 맞지 않아 제외한다.
- nonce/state 없이 콜백을 교환: 이전 시도와 늦은 콜백을 안전하게 구분하지 못해 제외한다.

## 2. 서버 검증과 앱의 토큰 경계

### 결정

Apple `identityToken`과 `authorizationCode`는 TLS를 통한 Git It 서버 교환의 입력으로만
사용하고 앱 Keychain·진단 로그·화면 상태에 저장하지 않는다. 서버는 Apple 서명, issuer,
audience, expiration, nonce와 단발성 authorization code를 검증한 뒤에만 Git It 액세스
토큰·리프레시 토큰을 발급한다. 앱은 서버가 발급한 두 Git It 토큰만 불투명한 값으로 보관한다.

### 근거

Apple 원시 토큰은 Git It 세션 권한이 아니며, 클라이언트가 검증 책임을 가지면 Apple private
key, client secret 또는 검증 키 배포 위험이 생긴다. 실제 HTTP endpoint가 아직 없으므로
모바일 앱에는 endpoint 모양이 아닌 `AuthenticationRemote` 계약을 먼저 두고, Mock과 실제
Adapter를 같은 자리에서 교체한다.

### 검토한 대안

- 앱에서 Apple JWT를 완전히 검증하고 세션을 발급: 서버 신뢰 경계와 비밀 관리가 무너져
  제외한다.
- Mock을 릴리스 기본 구현으로 사용: 실제 인증 없이 보호된 콘텐츠를 열 수 있어 제외한다.
- 현재 미정인 HTTP 경로·JSON 필드를 문서에서 확정: 백엔드 계약을 추측하게 되므로 제외한다.

## 3. 안전한 세션 저장과 복원

### 결정

Git It 액세스 토큰·리프레시 토큰·Apple 사용자 식별자는 `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
상당의 기기 한정 Keychain 접근성으로 저장한다. 앱 시작에는 저장값을 읽은 직후 보호 화면을
열지 않고 Apple credential state와 토큰 수명을 검사한다. 유효한 액세스 토큰은 계속 사용하고,
만료된 액세스 토큰은 리프레시 토큰으로 갱신한다.

### 근거

기기 잠금 상태에서 세션 비밀을 읽지 않게 하고 백업·다른 기기로의 복원을 피하면서도 사용자가
잠금을 푼 뒤 앱을 다시 시작하면 자동 로그인 요구를 충족한다. Apple credential state의
`.revoked`·`.notFound`와 revoked notification은 Apple 연결 철회의 근거지만, 조회 자체의
일시 오류는 철회 증거가 아니다.

### 검토한 대안

- UserDefaults 또는 파일에 토큰 저장: 보호 저장소 요구(FR-025)에 맞지 않아 제외한다.
- 서버 리프레시만 확인하고 Apple credential state를 확인하지 않음: Apple 연결 철회를
  놓칠 수 있어 제외한다.
- credential state 조회 실패 때 즉시 토큰 삭제: 일시적인 기술 오류에서 불필요한 로그아웃을
  만들므로 제외한다.

## 4. 실패 분류과 비동기 경쟁

### 결정

사용자 취소는 무경고로 로그인 화면을 유지한다. 일시적 네트워크 오류와 credential state
조회 오류는 토큰을 보존한 채 재시도 화면을 제공하며, 리프레시 거부·만료, Apple 연결 철회,
계정 이용 불가는 토큰을 삭제하고 로그인 상태로 전환한다. 공유 세션 조정 actor가 세션 세대를
관리해 로그아웃 후 늦게 끝난 갱신·교환이 Keychain이나 화면을 되살리지 못하게 한다.

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

Composition에서 동일한 `AuthenticationRemote` 및 세션 저장 계약의 Mock을 선택한다. Mock은
Apple 사용자 식별자별 신규·기존 계정, 이름·이메일의 부재, 갱신 성공, 일시 오류, 리프레시
거부, 서버 폐기 실패를 결정적으로 재현한다. Preview와 단위 테스트는 생성자로 Mock을
주입하며 실제 네트워크나 Keychain을 요구하지 않는다.

### 근거

서버 endpoint가 미확정인 현재도 FR-018과 SC-008을 검증해야 한다. Mock이 Feature와 다른
경로를 사용하면 실제 Adapter 교체 때 사용자 흐름이 달라질 위험이 있다.

### 검토한 대안

- Feature에서만 성공 결과를 만들어 화면 전환을 테스트: 서버 교환·저장·갱신 경계를
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
