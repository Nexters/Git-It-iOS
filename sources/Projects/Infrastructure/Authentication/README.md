# InfrastructureAuthentication

`InfrastructureAuthentication`은 Apple 인증, Apple credential 상태, Keychain, 암호학적으로 안전한
난수를 프로젝트 소유 기술 API로 감쌉니다. 이 문서는
`InfrastructureAuthenticationTests`에서 직접 검증하는 동작만 설명합니다.

## Apple 인증 시도와 credential

`AppleAuthorizationProvider`는 Apple 인증 요청을 시작하기 전에
`AppleAuthorizationAttempt`를 만듭니다. 시도에는 난수 기반 `id`, `nonce`, `state`와
만료 시각이 포함됩니다.

- `beginAuthorization()`은 명시적으로 시작한 시도만 현재 시도로 유지합니다.
- `startAuthorization()`은 Apple 요청에 `.email`, `.fullName` scope와 해당 시도의
  nonce·state를 적용합니다.
- `complete(credential:state:attemptID:)`는 현재 시도의 ID와 state가 모두 일치하고
  만료되지 않았으며 identity token과 authorization code가 존재할 때만 credential을
  반환합니다.
- `cancel(attemptID:)`는 일치하는 현재 시도를 제거하고 `cancelled` 오류를 반환합니다.
- 일치하지 않는 콜백, 만료된 시도, 누락된 credential은 각각 Infrastructure 소유 오류로
  구분됩니다.

`AppleCredential`은 user ID, Apple 원시 credential 값, 선택적 이메일·이름, 요청한
scope를 표현합니다. Apple 프레임워크 타입은 provider 구현 안에만 머물며 공개 API로
노출되지 않습니다.

## Apple credential 상태

`AppleCredentialStateProvider`는 Apple platform 상태를 Infrastructure 타입으로 변환합니다.

- `authorized`, `revoked`, `notFound`, `transferred` 상태를 구분합니다.
- 상태 조회가 실패하면 `temporarilyUnavailable`을 반환합니다.
- `changes()`는 revoked 상태를 전달하는 `AsyncStream`을 제공합니다.

## Keychain 저장소

`KeychainStore`는 `KeychainNamespace`와 key 조합별로 값을 저장·읽기·삭제합니다.

- 동일한 key라도 namespace가 다르면 서로 다른 값으로 격리됩니다.
- 저장 값의 접근성은 `whenUnlockedThisDeviceOnly`입니다.
- 저장, 읽기, 삭제는 값 전체를 단위로 수행하며 Keychain 실패는
  `KeychainStoreError.unavailable`로 격리합니다.

## 보안 난수

`SecureRandomGenerator`는 Security 기반 CSPRNG로 URL-safe 문자열을 생성합니다.

- 요청한 길이의 값을 생성하며, 별도 호출의 값이 서로 다른지 테스트로 확인합니다.
- 0 이하 길이는 `invalidLength`, 시스템 난수 생성 실패는 `unavailable` 오류로
  전달합니다.
- nonce, state, attempt ID, grant ID에 사용할 수 있는 기술 API입니다.

## 민감 정보 경계

테스트는 다음 값이 `description`과 `debugDescription`에 포함되지 않음을 검증합니다.

- Apple identity token과 authorization code
- authorization attempt의 nonce와 state
- Keychain 저장 값

따라서 credential과 authorization attempt의 문자열 표현은 값을 표시하지 않습니다.

## 보장하지 않는 범위

이 타겟의 테스트는 다음 동작을 검증하지 않습니다.

- 실제 Apple 시스템 UI의 성공·실패 콜백 전달
- Apple revoked 시스템 알림을 수신하는 등록 방식
- 서버 세션 교환, Domain 모델 변환, Repository 구현
- Keychain에 저장하는 세션·인증 참조의 직렬화 정책
- Feature 화면 상태 및 앱의 로그인 흐름

이 동작들은 Composition, Domain, Feature, App이 각각 구현되고 해당 타겟의 테스트가
추가된 뒤 그 경계의 문서에서 다룹니다.

## 검증 근거

- Apple 인증 시도와 credential 검증: `AuthenticationTests/AppleAuthentication/AppleAuthorizationProviderTests.swift`
- credential 상태와 stream: `AuthenticationTests/AppleAuthentication/AppleCredentialStateProviderTests.swift`
- Keychain CRUD·namespace·접근성: `AuthenticationTests/Keychain/KeychainStoreTests.swift`
- CSPRNG 출력과 오류: `AuthenticationTests/RandomGenerator/SecureRandomGeneratorTests.swift`
- 민감 값 비노출: `AuthenticationTests/Security/SensitiveValueExposureTests.swift`

문서의 보장 범위는 위 테스트와 함께 변경해야 합니다. 테스트로 검증되지 않은 계획,
구현 의도 또는 다른 타겟의 동작을 보장된 기능으로 추가하지 않습니다.
