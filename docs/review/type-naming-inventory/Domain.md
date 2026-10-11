# Domain 패키지 타입 목록

[인덱스로 돌아가기](README.md) · [단어 사전](glossary.md)

타입 110개, 관심사 폴더 33개. 항목은 파일 경로와 선언 줄 순서다. 각 항목은 `이름` 종류 · 접근 수준 · 파일 링크, 한 줄 설명, 그리고 이름을 이루는 단어와 정의로 구성된다.

| 종류 | 개수 |
|---|---|
| actor | 5 |
| enum | 25 |
| protocol | 25 |
| struct | 47 |
| typealias | 8 |

## Account/Contracts

- **`AuthenticationRepository`** `protocol` · public · [AuthenticationRepository.swift:1](../../../sources/Projects/Domain/Account/Contracts/AuthenticationRepository.swift#L1) · 채택: Sendable  
  SignInMethod로 인증해 AuthenticationGrant를 얻고, 현재 인가 상태(SignInVerification)를 조회하며, 인증 정보를 지우는 세 동작을 정의하는 Account 관심사의 계약. Account 유스케이스가 주입받아 사용하고 Composition의 AuthenticationRepositoryAdapter가 구현한다.  
  단어: `Authentication` 인증. 여기서는 Apple 로그인 등 외부 제공자로 사용자 신원을 확인하는 절차 · `Repository` 저장소 패턴. 여기서는 Data 계층이 구현하는 외부 자원 접근 경계(Composition의 *Adapter가 채택)
- **`PolicyConsentRepository`** `protocol` · public · [PolicyConsentRepository.swift:1](../../../sources/Projects/Domain/Account/Contracts/PolicyConsentRepository.swift#L1) · 채택: Sendable  
  저장된 PolicyConsent 목록 조회, 동의 기록, 전체 삭제를 정의하는 계약. Account 유스케이스가 약관 동의 상태 계산·동의 저장·탈퇴 시 정리에 사용하며 Composition의 PolicyConsentRepositoryAdapter가 구현한다.  
  단어: `Policy` 정책·약관. 여기서는 사용자가 동의해야 하는 서비스 약관 문서 · `Consent` 동의. 여기서는 사용자가 특정 약관 버전에 동의한 사실 · `Repository` 저장소 패턴. 여기서는 Data 계층이 구현하는 외부 자원 접근 경계(Composition의 *Adapter가 채택)
- **`SignInRepository`** `protocol` · public · [SignInRepository.swift:1](../../../sources/Projects/Domain/Account/Contracts/SignInRepository.swift#L1) · 채택: Sendable  
  AuthenticationGrant로 로그인 세션을 시작해 SignInRecord를 받고, 저장된 세션 복원, 로그아웃, 공유 로그인 상태(Bool?)와 사용 가능한 자격 증명 보유 여부를 조회하는 계약. Account 유스케이스가 사용하며 Composition의 SignInRepositoryAdapter가 구현한다.  
  단어: `SignIn` Sign + In, 로그인. 여기서는 Apple 인증으로 Git It 계정에 로그인하는 행위 · `Repository` 저장소 패턴. 여기서는 Data 계층이 구현하는 외부 자원 접근 경계(Composition의 *Adapter가 채택)
- **`WithdrawalRepository`** `protocol` · public · [WithdrawalRepository.swift:1](../../../sources/Projects/Domain/Account/Contracts/WithdrawalRepository.swift#L1) · 채택: Sendable  
  회원 탈퇴(withdraw) 한 동작만 정의하는 계약. Account 유스케이스의 withdraw()가 호출하며 Composition의 WithdrawalRepositoryAdapter가 구현한다.  
  단어: `Withdrawal` 철회·탈퇴. 여기서는 Git It 계정을 삭제하는 회원 탈퇴 · `Repository` 저장소 패턴. 여기서는 Data 계층이 구현하는 외부 자원 접근 경계(Composition의 *Adapter가 채택)

## Account/Errors

- **`AccountError`** `enum` · public · [AccountError.swift:1](../../../sources/Projects/Domain/Account/Errors/AccountError.swift#L1) · 채택: CaseIterable, Equatable, Error, Sendable  
  Account 관심사에서 던지는 오류 열거형으로 signInCancelled, policyUnavailable, withdrawalUnavailable, unauthorized, temporarilyUnavailable 다섯 case를 가진다. Account 유스케이스가 signInCancelled와 unauthorized를 catch해 SignInResult.cancelled, 재로그인 처리로 분기한다.  
  단어: `Account` 계정. 여기서는 Git It 서비스의 사용자 계정 관심사 · `Error` 오류. 여기서는 Swift Error를 채택한 도메인 실패 유형

## Account/Models/PolicyConsent

- **`PolicyConsent`** `struct` · public · [PolicyConsent.swift:3](../../../sources/Projects/Domain/Account/Models/PolicyConsent/PolicyConsent.swift#L3) · 채택: Equatable, Sendable  
  사용자가 특정 약관 문서(documentID)의 특정 version에 consentedAt 시각에 동의했다는 사실을 담는 값 모델. Account.consent(to:)가 생성해 PolicyConsentRepository에 기록하고, policyConsentStatus()가 필수 문서 충족 여부 계산에 사용한다.  
  단어: `Policy` 정책·약관. 여기서는 사용자가 동의해야 하는 서비스 약관 문서 · `Consent` 동의. 여기서는 약관 문서 버전에 대한 사용자의 동의 기록
- **`PolicyConsentStatus`** `struct` · public · [PolicyConsentStatus.swift:1](../../../sources/Projects/Domain/Account/Models/PolicyConsent/PolicyConsentStatus.swift#L1) · 채택: Equatable, Sendable  
  전체 약관 문서 목록(documents), 사용자가 남긴 동의 목록(consents), 필수 문서가 모두 최신 버전으로 동의됐는지(isSatisfied)를 묶은 조회 결과 모델. Account.policyConsentStatus()가 반환한다.  
  단어: `Policy` 정책·약관. 여기서는 서비스 약관 문서 · `Consent` 동의. 여기서는 약관에 대한 사용자 동의 · `Status` 상태. 여기서는 문서·동의 목록과 충족 여부를 합친 현재 동의 상태 스냅숏
- **`PolicyDocument`** `struct` · public · [PolicyDocument.swift:3](../../../sources/Projects/Domain/Account/Models/PolicyConsent/PolicyDocument.swift#L3) · 채택: Equatable, Sendable  
  약관 문서 하나를 나타내는 값 모델로 id, 표시 이름(displayName), version, 문서 본문 주소(approvedURL), 필수 여부(isRequired)를 가진다. Account 유스케이스가 생성 시 목록으로 주입받아 동의 충족 계산과 PolicyConsent 생성에 사용한다.  
  단어: `Policy` 정책·약관. 여기서는 서비스 이용약관·개인정보 처리방침 같은 문서 · `Document` 문서. 여기서는 버전과 URL을 가진 약관 문서 한 건
- **`PolicyDocumentID`** `typealias` · public · [PolicyDocumentID.swift:1](../../../sources/Projects/Domain/Account/Models/PolicyConsent/PolicyDocumentID.swift#L1) · 그래프 미수집(grep 보강)  
  String의 typealias로 약관 문서 식별자를 뜻한다. PolicyDocument.id, PolicyConsent.documentID, AccountUseCase.consent(to:)의 인자 타입으로 쓰이며 Feature의 Onboarding LegalAgreement에서도 참조한다.  
  단어: `Policy` 정책·약관. 여기서는 서비스 약관 문서 · `Document` 문서. 여기서는 약관 문서 한 건 · `ID` Identifier, 식별자. 여기서는 약관 문서를 구분하는 문자열 키

## Account/Models/SignIn

- **`AccountID`** `typealias` · public · [AccountID.swift:1](../../../sources/Projects/Domain/Account/Models/SignIn/AccountID.swift#L1) · 그래프 미수집(grep 보강)  
  String의 typealias로 로그인된 계정의 식별자를 뜻한다. SignedInAccount.id와 SignInState.signedIn의 연관값 타입으로만 사용된다.  
  단어: `Account` 계정. 여기서는 Git It 사용자 계정 · `ID` Identifier, 식별자. 여기서는 계정을 구분하는 문자열 키
- **`AuthenticationGrant`** `struct` · public · [AuthenticationGrant.swift:1](../../../sources/Projects/Domain/Account/Models/SignIn/AuthenticationGrant.swift#L1) · 채택: Equatable, Hashable, Sendable  
  인증 제공자가 발급한 인증 결과를 담는 값 모델로 id(String)와 사용한 SignInMethod를 가진다. AuthenticationRepository.authenticate(using:)가 반환하고 SignInRepository.start(with:)가 받아 로그인 세션을 시작한다.  
  단어: `Authentication` 인증. 여기서는 Apple 등 외부 제공자의 신원 확인 · `Grant` 부여·승인. 여기서는 인증 성공으로 발급된 식별자와 방식의 묶음
- **`SignInAvailability`** `enum` · public · [SignInAvailability.swift:1](../../../sources/Projects/Domain/Account/Models/SignIn/SignInAvailability.swift#L1) · 채택: CaseIterable, Equatable, Sendable  
  signedIn, signInRequired, appLaunchRequired 세 case로 로그인 가능 여부를 나타내는 열거형. Account.signInAvailability()가 SignInRepository의 공유 로그인 상태와 자격 증명 보유 여부를 조합해 반환한다.  
  단어: `SignIn` Sign + In, 로그인. 여기서는 Apple 인증으로 Git It 계정에 로그인하는 행위 · `Availability` 가용성·이용 가능 여부. 여기서는 로그인 상태를 바로 쓸 수 있는지, 로그인이나 앱 실행이 필요한지의 판정
- **`SignInMethod`** `enum` · public · [SignInMethod.swift:1](../../../sources/Projects/Domain/Account/Models/SignIn/SignInMethod.swift#L1) · 채택: CaseIterable, Equatable, Hashable, Sendable  
  로그인 방식을 나타내는 열거형으로 현재 apple 한 case만 있다. AccountUseCase.signIn(with:), AuthenticationRepository.authenticate(using:), AuthenticationGrant.method에서 사용한다.  
  단어: `SignIn` Sign + In, 로그인. 여기서는 Apple 인증으로 Git It 계정에 로그인하는 행위 · `Method` 방법·방식. 여기서는 로그인에 사용하는 인증 제공자 종류
- **`SignInRecord`** `struct` · public · [SignInRecord.swift:1](../../../sources/Projects/Domain/Account/Models/SignIn/SignInRecord.swift#L1) · 채택: Equatable, Sendable  
  로그인 세션 시작·복원 결과로 SignedInAccount와 그 계정이 서버에서 유효한지(isAccountAvailable)를 담는 값 모델. SignInRepository.start(with:)와 restore()가 반환하며 Account.restoreSignIn()이 isAccountAvailable이 false면 세션을 정리한다.  
  단어: `SignIn` Sign + In, 로그인. 여기서는 Apple 인증으로 Git It 계정에 로그인하는 행위 · `Record` 기록. 여기서는 로그인 세션이 남긴 계정 정보와 유효 여부 한 건
- **`SignInRestoration`** `enum` · public · [SignInRestoration.swift:1](../../../sources/Projects/Domain/Account/Models/SignIn/SignInRestoration.swift#L1) · 채택: Equatable, Sendable  
  앱 시작 시 저장된 로그인 세션 복원 결과를 나타내는 열거형으로 signedIn(SignedInAccount), signedOut, temporarilyUnavailable 세 case를 가진다. AccountUseCase.restoreSignIn()이 반환한다.  
  단어: `SignIn` Sign + In, 로그인. 여기서는 Apple 인증으로 Git It 계정에 로그인하는 행위 · `Restoration` 복원. 여기서는 이전에 저장된 로그인 세션을 되살리는 시도의 결과
- **`SignInResult`** `enum` · public · [SignInResult.swift:1](../../../sources/Projects/Domain/Account/Models/SignIn/SignInResult.swift#L1) · 채택: Equatable, Sendable  
  로그인 시도 결과를 나타내는 열거형으로 signedIn(SignedInAccount), cancelled, retryableFailure 세 case를 가진다. AccountUseCase.signIn(with:)이 오류를 던지지 않고 이 값으로 성공·취소·재시도 가능 실패를 구분해 반환한다.  
  단어: `SignIn` Sign + In, 로그인. 여기서는 Apple 인증으로 Git It 계정에 로그인하는 행위 · `Result` 결과. 여기서는 로그인 시도 한 번의 성공·취소·실패 결과
- **`SignInState`** `enum` · public · [SignInState.swift:1](../../../sources/Projects/Domain/Account/Models/SignIn/SignInState.swift#L1) · 채택: Equatable, Sendable  
  현재 로그인 상태를 나타내는 열거형으로 unknown, signedIn(AccountID), signedOut 세 case를 가진다. Account actor가 내부 상태로 보관하며 signInStates()가 반환하는 AsyncStream으로 구독자에게 변경을 방송한다.  
  단어: `SignIn` Sign + In, 로그인. 여기서는 Apple 인증으로 Git It 계정에 로그인하는 행위 · `State` 상태. 여기서는 시간에 따라 바뀌는 계정의 현재 로그인 상태
- **`SignInVerification`** `enum` · public · [SignInVerification.swift:1](../../../sources/Projects/Domain/Account/Models/SignIn/SignInVerification.swift#L1) · 채택: CaseIterable, Equatable, Sendable  
  저장된 인증이 아직 유효한지 검증한 결과로 valid, reauthenticationRequired, temporarilyUnavailable 세 case를 가진다. AuthenticationRepository.authorizationStatus()와 AccountUseCase.verifySignIn()이 반환하며 reauthenticationRequired면 Account가 세션을 정리한다.  
  단어: `SignIn` Sign + In, 로그인. 여기서는 Apple 인증으로 Git It 계정에 로그인하는 행위 · `Verification` 검증. 여기서는 기존 로그인 인증이 여전히 유효한지 확인한 판정
- **`SignOutResult`** `enum` · public · [SignOutResult.swift:1](../../../sources/Projects/Domain/Account/Models/SignIn/SignOutResult.swift#L1) · 채택: CaseIterable, Equatable, Sendable  
  로그아웃 시도 결과를 나타내는 열거형으로 signedOut, retryableFailure 두 case를 가진다. AccountUseCase.signOut()이 반환한다.  
  단어: `SignOut` Sign + Out, 로그아웃. 여기서는 로그인 세션과 인증 정보를 지우는 행위 · `Result` 결과. 여기서는 로그아웃 시도의 성공·재시도 가능 실패
- **`SignedInAccount`** `struct` · public · [SignedInAccount.swift:1](../../../sources/Projects/Domain/Account/Models/SignIn/SignedInAccount.swift#L1) · 채택: Equatable, Sendable  
  로그인된 계정 정보를 담는 값 모델로 id(AccountID), 선택적 displayName, 초기 큐레이션(온보딩) 필요 여부(needsCuration)를 가진다. SignInRecord.account에 담기고 SignInResult·SignInRestoration의 signedIn 연관값으로 Feature에 전달된다.  
  단어: `SignedIn` Signed + In, 로그인된. 여기서는 로그인이 완료된 상태의 · `Account` 계정. 여기서는 Git It 사용자 계정의 식별자·표시 이름·큐레이션 여부

## Account/UseCases

- **`Account`** `actor` · public · [Account.swift:3](../../../sources/Projects/Domain/Account/UseCases/Account.swift#L3) · 채택: AccountUseCase · 그래프 미수집(grep 보강)  
  AccountUseCase의 production 구현 actor. 네 Repository 계약과 PolicyDocument 목록, 로그인 무효화 스트림(signInInvalidations), 현재 시각 클로저를 생성자 주입받아 로그인·로그아웃·복원·검증·가용성·약관 동의·탈퇴를 수행하고, SignInState를 내부에 보관하며 구독자에게 AsyncStream으로 방송한다.  
  단어(단일): `Account` 계정. 여기서는 계정 관심사 전체를 다루는 유스케이스 구현체
- **`AccountUseCase`** `protocol` · public · [AccountUseCase.swift:1](../../../sources/Projects/Domain/Account/UseCases/AccountUseCase.swift#L1) · 채택: Sendable  
  계정 관심사의 유스케이스 공개 계약으로 signIn, signOut, signInStates, restoreSignIn, verifySignIn, signInAvailability, policyConsentStatus, consent(to:), withdraw 아홉 동작을 정의한다. Domain의 Account actor가 구현하고 App의 AppRootView에는 NoopAccount 대역이 있다.  
  단어: `Account` 계정. 여기서는 Git It 사용자 계정 관심사 · `UseCase` Use + Case, 유스케이스. 여기서는 Feature가 호출하는 Domain 동작 단위의 공개 계약

## AppSetting/Contracts

- **`DeviceIdentifierRepository`** `protocol` · public · [DeviceIdentifierRepository.swift:1](../../../sources/Projects/Domain/AppSetting/Contracts/DeviceIdentifierRepository.swift#L1) · 채택: Sendable  
  현재 기기의 DeviceID를 비동기로 돌려주는 currentDeviceID() 한 동작만 정의하는 계약. AppSetting 유스케이스가 DeviceRegistration을 만들 때 호출하며 Composition의 DeviceIdentifierRepositoryAdapter가 구현한다.  
  단어: `Device` 기기. 여기서는 앱이 실행 중인 iOS 기기 · `Identifier` 식별자. 여기서는 기기를 구분하는 고유 문자열 · `Repository` 저장소 패턴. 여기서는 Data 계층이 구현하는 외부 자원 접근 경계(Composition의 *Adapter가 채택)
- **`DeviceRegistrationRepository`** `protocol` · public · [DeviceRegistrationRepository.swift:1](../../../sources/Projects/Domain/AppSetting/Contracts/DeviceRegistrationRepository.swift#L1) · 채택: Sendable  
  DeviceRegistration 값을 서버에 등록하는 register(_:) 한 동작만 정의하는 계약. AppSetting 유스케이스의 registerDevice()와 updateDeviceToken(_:)이 호출하며 Composition의 DeviceRegistrationRepositoryAdapter가 구현한다.  
  단어: `Device` 기기. 여기서는 앱이 실행 중인 iOS 기기 · `Registration` 등록. 여기서는 기기 정보와 푸시 토큰을 서버에 등록하는 행위 · `Repository` 저장소 패턴. 여기서는 Data 계층이 구현하는 외부 자원 접근 경계(Composition의 *Adapter가 채택)
- **`NotificationAuthorization`** `protocol` · public · [NotificationAuthorization.swift:1](../../../sources/Projects/Domain/AppSetting/Contracts/NotificationAuthorization.swift#L1) · 채택: Sendable  
  알림 권한의 현재 상태 조회(status)와 권한 요청(requestAuthorization)을 정의하는 계약으로 둘 다 NotificationAuthorizationStatus를 반환한다. AppSetting 유스케이스가 그대로 위임해 호출하며 Composition의 NotificationAuthorizationAdapter가 구현한다. 다른 계약과 달리 Repository 접미어가 없다.  
  단어: `Notification` 알림. 여기서는 iOS 푸시·로컬 알림 · `Authorization` 인가·권한 부여. 여기서는 사용자가 앱에 알림 표시를 허용했는지의 권한

## AppSetting/Errors

- **`AppSettingError`** `enum` · public · [AppSettingError.swift:1](../../../sources/Projects/Domain/AppSetting/Errors/AppSettingError.swift#L1) · 채택: CaseIterable, Equatable, Error, Sendable  
  AppSetting 관심사의 오류 열거형으로 invalidRequest, unauthorized, temporarilyUnavailable 세 case를 가진다. Domain 소스 안에서는 던지는 곳이 없고 Data 어댑터가 서버 오류를 이 타입으로 변환해 올리도록 공개돼 있다.  
  단어: `App` Application, 앱. 여기서는 Git It iOS 앱 자체 · `Setting` 설정. 여기서는 알림 권한·기기 등록 같은 앱 수준 설정 관심사 · `Error` 오류. 여기서는 Swift Error를 채택한 도메인 실패 유형

## AppSetting/Models

- **`DeviceID`** `typealias` · public · [DeviceID.swift:1](../../../sources/Projects/Domain/AppSetting/Models/DeviceID.swift#L1) · 그래프 미수집(grep 보강)  
  String의 typealias로 기기 고유 식별자를 뜻한다. DeviceIdentifierRepository.currentDeviceID()의 반환 타입과 DeviceRegistration.deviceID의 타입으로 사용된다.  
  단어: `Device` 기기. 여기서는 앱이 실행 중인 iOS 기기 · `ID` Identifier, 식별자. 여기서는 기기를 구분하는 문자열 키
- **`DevicePlatform`** `enum` · public · [DevicePlatform.swift:1](../../../sources/Projects/Domain/AppSetting/Models/DevicePlatform.swift#L1) · 채택: CaseIterable, Equatable, Sendable  
  기기 플랫폼을 나타내는 열거형으로 ios 한 case만 있다. DeviceRegistration.platform의 타입이며 AppSetting.register(token:)가 항상 .ios를 넣는다.  
  단어: `Device` 기기. 여기서는 등록 대상 기기 · `Platform` 플랫폼. 여기서는 기기의 운영체제 종류(iOS)
- **`DeviceRegistration`** `struct` · public · [DeviceRegistration.swift:1](../../../sources/Projects/Domain/AppSetting/Models/DeviceRegistration.swift#L1) · 채택: Equatable, Sendable  
  서버에 등록할 기기 정보를 담는 값 모델로 deviceID, platform, appVersion, osVersion, 선택적 푸시 token을 가진다. AppSetting.register(token:)가 조립해 DeviceRegistrationRepository.register(_:)에 넘긴다.  
  단어: `Device` 기기. 여기서는 앱이 실행 중인 iOS 기기 · `Registration` 등록. 여기서는 서버에 보낼 기기 등록 요청 데이터
- **`DeviceToken`** `typealias` · public · [DeviceToken.swift:1](../../../sources/Projects/Domain/AppSetting/Models/DeviceToken.swift#L1) · 그래프 미수집(grep 보강)  
  String의 typealias로 푸시 알림용 기기 토큰을 뜻한다. DeviceRegistration.token, AppSettingUseCase.updateDeviceToken(_:)의 인자, AppSetting 생성자의 deviceToken 클로저 반환 타입으로 사용되며 Composition의 조립 코드에서도 참조한다.  
  단어: `Device` 기기. 여기서는 푸시 대상 iOS 기기 · `Token` 토큰. 여기서는 APNs가 기기에 발급한 푸시 알림 토큰 문자열
- **`NotificationAuthorizationStatus`** `enum` · public · [NotificationAuthorizationStatus.swift:1](../../../sources/Projects/Domain/AppSetting/Models/NotificationAuthorizationStatus.swift#L1) · 채택: CaseIterable, Equatable, Sendable  
  알림 권한 상태를 나타내는 열거형으로 notDetermined, authorized, denied 세 case를 가진다. NotificationAuthorization 계약과 AppSettingUseCase의 notificationAuthorization()·requestNotificationAuthorization()이 반환한다.  
  단어: `Notification` 알림. 여기서는 iOS 푸시·로컬 알림 · `Authorization` 인가·권한. 여기서는 알림 표시 허용 권한 · `Status` 상태. 여기서는 미결정·허용·거부 중 하나인 권한의 현재 값

## AppSetting/UseCases

- **`AppSetting`** `struct` · public · [AppSetting.swift:1](../../../sources/Projects/Domain/AppSetting/UseCases/AppSetting.swift#L1) · 채택: AppSettingUseCase  
  AppSettingUseCase의 production 구현 struct. NotificationAuthorization, DeviceRegistrationRepository, DeviceIdentifierRepository와 appVersion·osVersion 문자열, 푸시 토큰을 얻는 클로저를 생성자 주입받아 알림 권한 조회·요청을 위임하고 DeviceRegistration을 조립해 기기 등록·토큰 갱신을 수행한다.  
  단어: `App` Application, 앱. 여기서는 Git It iOS 앱 자체 · `Setting` 설정. 여기서는 알림 권한과 기기 등록을 다루는 앱 설정 유스케이스 구현체
- **`AppSettingUseCase`** `protocol` · public · [AppSettingUseCase.swift:1](../../../sources/Projects/Domain/AppSetting/UseCases/AppSettingUseCase.swift#L1) · 채택: Sendable  
  앱 설정 관심사의 유스케이스 공개 계약으로 notificationAuthorization, requestNotificationAuthorization, registerDevice, updateDeviceToken(_:) 네 동작을 정의한다. Domain의 AppSetting struct가 구현하고 App의 AppRootView에는 NoopAppSetting 대역이 있다.  
  단어: `App` Application, 앱. 여기서는 Git It iOS 앱 자체 · `Setting` 설정. 여기서는 알림 권한·기기 등록 같은 앱 수준 설정 관심사 · `UseCase` Use + Case, 유스케이스. 여기서는 Feature가 호출하는 Domain 동작 단위의 공개 계약

## ExternalRepository/Contracts

- **`ExternalRepositoryLocator`** `protocol` · public · [ExternalRepositoryLocator.swift:3](../../../sources/Projects/Domain/ExternalRepository/Contracts/ExternalRepositoryLocator.swift#L3) · 채택: Sendable  
  ExternalRepositoryURL 문자열을 동기적으로 파싱해 owner·name을 가진 ExternalRepositoryLocation을 돌려주거나 형식이 틀리면 nil을 반환하는 location(from:) 한 동작을 정의하는 계약. ExternalRepositoryResolver가 사용하며 Composition의 ExternalRepositoryLocatorAdapter와 Feature의 프리뷰 대역이 구현한다.  
  단어: `External` 외부의. 여기서는 앱 밖의 코드 호스팅 서비스(GitHub)에 있는 것 · `Repository` 저장소. 여기서는 GitHub 같은 외부 서비스에 있는 Git 원격 저장소 · `Locator` 위치 지정자. 여기서는 URL에서 저장소의 소유자·이름 위치를 찾아내는 파서 역할(Service Locator 패턴이 아님)
- **`ExternalRepositoryLookup`** `protocol` · public · [ExternalRepositoryLookup.swift:1](../../../sources/Projects/Domain/ExternalRepository/Contracts/ExternalRepositoryLookup.swift#L1) · 채택: Sendable  
  owner와 name으로 외부 서비스에서 저장소 정보를 비동기 조회해 ExternalRepository를 돌려주는 repository(owner:name:) 한 동작을 정의하는 계약. ExternalRepositoryResolver가 사용하며 Composition의 ExternalRepositoryLookupAdapter가 구현한다. Repository 접미어 대신 Lookup을 쓴다.  
  단어: `External` 외부의. 여기서는 앱 밖의 코드 호스팅 서비스(GitHub)에 있는 것 · `Repository` 저장소. 여기서는 GitHub 같은 외부 서비스에 있는 Git 원격 저장소 · `Lookup` 조회·찾아보기. 여기서는 소유자·이름으로 원격 저장소 메타데이터를 가져오는 동작

## ExternalRepository/Errors

- **`ExternalRepositoryError`** `enum` · public · [ExternalRepositoryError.swift:1](../../../sources/Projects/Domain/ExternalRepository/Errors/ExternalRepositoryError.swift#L1) · 채택: CaseIterable, Equatable, Error, Sendable  
  외부 저장소 조회 관심사의 오류 열거형으로 invalidURLFormat, offline, other 세 case를 가진다. ExternalRepositoryResolver가 URL 파싱 실패 시 invalidURLFormat을 던진다.  
  단어: `External` 외부의. 여기서는 앱 밖의 코드 호스팅 서비스(GitHub)에 있는 것 · `Repository` 저장소. 여기서는 GitHub 같은 외부 서비스에 있는 Git 원격 저장소 · `Error` 오류. 여기서는 Swift Error를 채택한 도메인 실패 유형

## ExternalRepository/Models

- **`ExternalRepository`** `struct` · public · [ExternalRepository.swift:3](../../../sources/Projects/Domain/ExternalRepository/Models/ExternalRepository.swift#L3) · 채택: Equatable, Sendable  
  외부 서비스에서 조회한 Git 저장소 메타데이터를 담는 값 모델로 canonicalURL(ExternalRepositoryURL), ownerName, repositoryName, 선택적 imageURL, starCount, techStack 목록을 가진다. ExternalRepositoryLookup과 ExternalRepositoryUseCase가 반환한다.  
  단어: `External` 외부의. 여기서는 앱 밖의 코드 호스팅 서비스(GitHub)에 있는 것 · `Repository` 저장소. 여기서는 GitHub 같은 외부 서비스에 있는 Git 원격 저장소의 메타데이터 모델
- **`ExternalRepositoryLocation`** `struct` · public · [ExternalRepositoryLocation.swift:1](../../../sources/Projects/Domain/ExternalRepository/Models/ExternalRepositoryLocation.swift#L1) · 채택: Equatable, Sendable  
  URL에서 추출한 저장소 소유자(owner)와 이름(name) 두 문자열을 담는 값 모델. ExternalRepositoryLocator.location(from:)이 반환하고 ExternalRepositoryResolver가 이 값을 풀어 ExternalRepositoryLookup에 넘긴다.  
  단어: `External` 외부의. 여기서는 앱 밖의 코드 호스팅 서비스(GitHub)에 있는 것 · `Repository` 저장소. 여기서는 GitHub 같은 외부 서비스에 있는 Git 원격 저장소 · `Location` 위치. 여기서는 저장소를 특정하는 소유자·이름 좌표

## ExternalRepository/UseCases

- **`ExternalRepositoryResolver`** `struct` · public · [ExternalRepositoryResolver.swift:3](../../../sources/Projects/Domain/ExternalRepository/UseCases/ExternalRepositoryResolver.swift#L3) · 채택: ExternalRepositoryUseCase  
  ExternalRepositoryUseCase의 production 구현 struct. ExternalRepositoryLookup과 ExternalRepositoryLocator를 생성자 주입받아 repository(at:)에서 URL을 Location으로 파싱한 뒤(실패 시 invalidURLFormat 오류) owner·name으로 저장소를 조회해 반환한다. 다른 관심사의 구현체(Account, AppSetting)와 달리 관심사 이름에 Resolver 접미어가 붙는다.  
  단어: `External` 외부의. 여기서는 앱 밖의 코드 호스팅 서비스(GitHub)에 있는 것 · `Repository` 저장소. 여기서는 GitHub 같은 외부 서비스에 있는 Git 원격 저장소 · `Resolver` 해석기·해결자. 여기서는 URL 문자열을 실제 저장소 정보로 풀어내는 유스케이스 구현체
- **`ExternalRepositoryUseCase`** `protocol` · public · [ExternalRepositoryUseCase.swift:3](../../../sources/Projects/Domain/ExternalRepository/UseCases/ExternalRepositoryUseCase.swift#L3) · 채택: Sendable  
  외부 저장소 관심사의 유스케이스 공개 계약으로 ExternalRepositoryURL을 받아 ExternalRepository를 돌려주는 repository(at:) 한 동작을 정의한다. Domain의 ExternalRepositoryResolver가 구현하고 App의 NoopExternalRepository와 Feature ShareRegistration 프리뷰 대역이 있다.  
  단어: `External` 외부의. 여기서는 앱 밖의 코드 호스팅 서비스(GitHub)에 있는 것 · `Repository` 저장소. 여기서는 GitHub 같은 외부 서비스에 있는 Git 원격 저장소 · `UseCase` Use + Case, 유스케이스. 여기서는 Feature가 호출하는 Domain 동작 단위의 공개 계약

## Identifier/Models

- **`ExternalRepositoryURL`** `typealias` · public · [ExternalRepositoryURL.swift:1](../../../sources/Projects/Domain/Identifier/Models/ExternalRepositoryURL.swift#L1) · 그래프 미수집(grep 보강)  
  String의 typealias로 외부 Git 저장소의 주소 문자열을 뜻하며 DomainIdentifier 모듈에 있어 여러 관심사가 공유한다. ExternalRepository.canonicalURL, ExternalRepositoryLocator·ExternalRepositoryUseCase의 입력, ProjectGeneration 관심사의 PendingGenerationRepository·GenerationState와 Feature의 RepositoryLinkInput에서 사용한다.  
  단어: `External` 외부의. 여기서는 앱 밖의 코드 호스팅 서비스(GitHub)에 있는 것 · `Repository` 저장소. 여기서는 GitHub 같은 외부 서비스에 있는 Git 원격 저장소 · `URL` Uniform Resource Locator, 저장소 주소 문자열
- **`ProjectID`** `typealias` · public · [ProjectID.swift:1](../../../sources/Projects/Domain/Identifier/Models/ProjectID.swift#L1) · 그래프 미수집(grep 보강)  
  String의 typealias로 학습 프로젝트의 식별자를 뜻하며 DomainIdentifier 모듈에 있어 관심사 간 공유된다. Composition의 LearningProject 어댑터들과 Feature의 Saved·ProjectDetail 등, App의 AppRootFeature에서 참조한다.  
  단어: `Project` 프로젝트. 여기서는 외부 저장소로부터 생성된 학습 프로젝트 · `ID` Identifier, 식별자. 여기서는 프로젝트를 구분하는 문자열 키
- **`QuizID`** `typealias` · public · [QuizID.swift:1](../../../sources/Projects/Domain/Identifier/Models/QuizID.swift#L1) · 그래프 미수집(grep 보강)  
  String의 typealias로 퀴즈 문항 하나의 식별자를 뜻하며 DomainIdentifier 모듈에 있어 관심사 간 공유된다. Composition의 QuizBookmarkRepositoryAdapter·ProjectRepositoryAdapter와 Feature의 Quiz·Saved 기능에서 참조한다.  
  단어: `Quiz` 퀴즈. 여기서는 학습 세트에 속한 문항 하나 · `ID` Identifier, 식별자. 여기서는 퀴즈 문항을 구분하는 문자열 키
- **`QuizSetID`** `typealias` · public · [QuizSetID.swift:1](../../../sources/Projects/Domain/Identifier/Models/QuizSetID.swift#L1) · 그래프 미수집(grep 보강)  
  String의 typealias로 퀴즈 묶음(학습 세트)의 식별자를 뜻하며 DomainIdentifier 모듈에 있어 관심사 간 공유된다. Composition의 QuizSetRepositoryAdapter와 Feature의 Home·ProjectList·ProjectDetail·Quiz 기능에서 참조한다.  
  단어: `Quiz` 퀴즈. 여기서는 학습용 문항 · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(학습 세트) · `ID` Identifier, 식별자. 여기서는 퀴즈 세트를 구분하는 문자열 키

## Project/Contracts

- **`ProjectRepository`** `protocol` · public · [ProjectRepository.swift:3](../../../sources/Projects/Domain/Project/Contracts/ProjectRepository.swift#L3) · 채택: Sendable  
  프로젝트 목록을 페이지 단위로 조회하는 page(_:size:), 단일 프로젝트 상세를 얻는 detail(of:), 프로젝트를 삭제하는 delete(_:)를 정의하는 Domain 계약(Contract)이다. Project 액터가 생성자 주입으로 받아 Data 계층 구현체에 접근하는 경계다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 하나를 등록해 만든 학습 단위(프로젝트) · `Repository` 저장소·보관소. 여기서는 데이터 접근을 추상화하는 Repository 패턴 계약(Git 저장소가 아님)

## Project/Errors

- **`ProjectError`** `enum` · public · [ProjectError.swift:1](../../../sources/Projects/Domain/Project/Errors/ProjectError.swift#L1) · 채택: CaseIterable, Equatable, Error, Sendable  
  프로젝트 조회·삭제 흐름에서 발생하는 도메인 오류로 invalidRequest, notFound, unauthorized, temporarilyUnavailable, unexpected 다섯 케이스를 가진다. 연관값 없이 원인 분류만 표현한다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Error` 오류. 여기서는 프로젝트 도메인 작업의 실패 원인을 나타내는 Swift Error 타입

## Project/Models

- **`ProjectDetail`** `struct` · public · [ProjectDetail.swift:3](../../../sources/Projects/Domain/Project/Models/ProjectDetail.swift#L3) · 채택: Equatable, Identifiable, Sendable  
  프로젝트 하나의 상세 정보를 담는 값 모델로 id(ProjectID), repository(ProjectRepositoryInfo), progressPercent, sets([ProjectSetProgress]), next(ProjectNextQuiz?)를 보유한다. ProjectRepository.detail(of:)와 ProjectUseCase.detail(of:)의 반환 타입이다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Detail` 세부·상세. 여기서는 목록 요약보다 많은 정보를 담은 프로젝트 상세 화면용 모델
- **`ProjectList`** `struct` · public · [ProjectList.swift:1](../../../sources/Projects/Domain/Project/Models/ProjectList.swift#L1) · 채택: Equatable, Sendable  
  Project 액터가 projects() 스트림으로 방출하는 현재 누적 목록 스냅샷으로 summaries([ProjectSummary]), hasNextPage, isLoaded를 보유한다. isLoaded로 첫 페이지가 아직 로드되지 않은 상태를 구분한다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `List` 목록. 여기서는 여러 페이지를 누적한 프로젝트 요약 목록과 로드 상태
- **`ProjectNextQuiz`** `struct` · public · [ProjectNextQuiz.swift:3](../../../sources/Projects/Domain/Project/Models/ProjectNextQuiz.swift#L3) · 채택: Equatable, Sendable  
  프로젝트에서 다음에 풀 퀴즈의 위치를 가리키는 값 모델로 setID(QuizSetID)와 선택적 quizID(QuizID?)를 보유한다. ProjectDetail.next와 ProjectSummary.next에 사용된다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Next` 다음. 여기서는 사용자가 이어서 풀어야 할 다음 순서 · `Quiz` 퀴즈·문제. 여기서는 프로젝트 학습 세트 안의 개별 문제
- **`ProjectPage`** `struct` · public · [ProjectPage.swift:1](../../../sources/Projects/Domain/Project/Models/ProjectPage.swift#L1) · 채택: Equatable, Sendable  
  ProjectRepository.page(_:size:)가 돌려주는 한 페이지분 결과로 summaries([ProjectSummary])와 hasNextPage를 보유한다. Project 액터가 replaceWithFirstPage와 appendPage에서 이를 누적해 ProjectList를 만든다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Page` 쪽·페이지. 여기서는 페이지네이션 조회의 한 번 응답 단위
- **`ProjectRepositoryInfo`** `struct` · public · [ProjectRepositoryInfo.swift:1](../../../sources/Projects/Domain/Project/Models/ProjectRepositoryInfo.swift#L1) · 채택: Equatable, Sendable  
  프로젝트의 원본 Git 저장소 정보를 담는 값 모델로 url, name, imageURL(선택), starCount, techStack([String])을 보유한다. ProjectDetail.repository 프로퍼티로 사용된다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Repository` 저장소. 여기서는 프로젝트의 원본이 된 외부 Git 소스 저장소(Repository 패턴이 아님) · `Info` Information의 축약, 정보. 여기서는 저장소의 이름·주소·별 수·기술 스택 등 표시용 속성 묶음
- **`ProjectSetLabel`** `struct` · public · [ProjectSetLabel.swift:1](../../../sources/Projects/Domain/Project/Models/ProjectSetLabel.swift#L1) · 채택: Equatable, Sendable  
  퀴즈 세트의 표시용 label과 title 두 문자열만 보유하는 값 모델이다. ProjectSummary.currentSet으로 현재 진행 중인 세트를 목록에서 표기할 때 사용된다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(학습 세트) · `Label` 라벨·표지. 여기서는 세트를 식별해 보여주는 짧은 표기 문자열과 제목
- **`ProjectSetProgress`** `struct` · public · [ProjectSetProgress.swift:3](../../../sources/Projects/Domain/Project/Models/ProjectSetProgress.swift#L3) · 채택: Equatable, Sendable  
  퀴즈 세트별 진행 상황을 담는 값 모델로 setID(QuizSetID), label, title, quizCount, completedCount를 보유한다. ProjectDetail.sets 배열의 원소로 사용된다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(학습 세트) · `Progress` 진행·진척. 여기서는 세트 내 전체 퀴즈 수 대비 완료 수
- **`ProjectSummary`** `struct` · public · [ProjectSummary.swift:3](../../../sources/Projects/Domain/Project/Models/ProjectSummary.swift#L3) · 채택: Equatable, Identifiable, Sendable  
  목록 셀 표시용 프로젝트 요약 값 모델로 id(ProjectID), repositoryName, repositoryImageURL, techStack, currentSet(ProjectSetLabel), next(ProjectNextQuiz?), progressPercent를 보유한다. ProjectPage와 ProjectList의 summaries 원소다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Summary` 요약. 여기서는 상세 대신 목록에 보여줄 프로젝트의 핵심 속성만 추린 모델

## Project/UseCases

- **`Project`** `actor` · public · [Project.swift:4](../../../sources/Projects/Domain/Project/UseCases/Project.swift#L4) · 채택: ProjectUseCase  
  ProjectUseCase를 구현하는 액터로, ProjectRepository·preparingProjectIDs 스트림·signedOutEvents 스트림·pageSize를 생성자 주입받아 페이지를 누적(loaded)하고 생성 중인 프로젝트 ID를 제외한 ProjectList를 구독자들에게 방출한다. 첫 페이지·다음 페이지 요청을 Task로 중복 제거하고 로그아웃 시 epoch를 올려 상태를 초기화하며, detail(of:)와 delete(_:)는 repository에 위임한다.  
  단어(단일): `Project` 기획·과제. 여기서는 프로젝트 목록·상세·삭제를 다루는 유스케이스 구현체 자체를 가리킴
- **`ProjectUseCase`** `protocol` · public · [ProjectUseCase.swift:3](../../../sources/Projects/Domain/Project/UseCases/ProjectUseCase.swift#L3) · 채택: Sendable  
  프로젝트 유스케이스 계약으로 projects()(AsyncStream<ProjectList>), refresh(), requestNextPage(), detail(of:), delete(_:)를 정의한다. Project 액터가 구현하며 Feature 계층이 이 프로토콜에 의존한다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `UseCase` Use + Case, 유스케이스. 여기서는 프로젝트 목록·상세·삭제 업무 시나리오를 노출하는 응용 계층 계약

## ProjectGeneration/Contracts

- **`GenerationOutcomeRepository`** `protocol` · public · [GenerationOutcomeRepository.swift:1](../../../sources/Projects/Domain/ProjectGeneration/Contracts/GenerationOutcomeRepository.swift#L1) · 채택: Sendable  
  프로젝트 생성의 완료·실패 결과(GenerationOutcome)를 AsyncStream으로 제공하는 outcomes() 하나만 정의하는 계약이다. ProjectGeneration 액터가 start()에서 구독해 finish(_:)로 기록 상태를 갱신한다.  
  단어: `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Outcome` 결과·귀결. 여기서는 생성 작업이 끝났을 때 통보되는 완료/실패 결과 · `Repository` 저장소·보관소. 여기서는 결과 이벤트를 공급하는 Repository 패턴 계약
- **`GenerationReminderScheduler`** `protocol` · public · [GenerationReminderScheduler.swift:3](../../../sources/Projects/Domain/ProjectGeneration/Contracts/GenerationReminderScheduler.swift#L3) · 채택: Sendable  
  알림 권한 여부를 묻는 isAuthorized()와 GenerationReminder를 특정 Date에 예약하는 schedule(_:at:)을 정의하는 계약이다. ProjectGeneration 액터가 완료 시 readyDate, 실패 시 현재 시각으로 예약한다.  
  단어: `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Reminder` 상기시키는 것·알림. 여기서는 생성 완료/실패를 사용자에게 알리는 예약 알림 · `Scheduler` 일정 관리자. 여기서는 알림을 지정 시각에 등록하는 역할
- **`PendingGenerationRepository`** `protocol` · public · [PendingGenerationRepository.swift:4](../../../sources/Projects/Domain/ProjectGeneration/Contracts/PendingGenerationRepository.swift#L4) · 채택: Sendable  
  진행 중 생성 기록(GenerationState)의 영속 조회·변경 스트림과 beginGeneration, attachProjectID, finishGeneration, releaseGeneration(URL/ID), releaseAll, 그리고 리마인더 큐(enqueueReminder, drainReminderProjectIDs)를 정의하는 계약이다. ProjectGeneration 액터가 요청·정리·관찰 전반에서 사용한다.  
  단어: `Pending` 보류 중·처리 대기 중. 여기서는 아직 결과가 확정되지 않았거나 준비 대기 중인 생성 요청 · `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Repository` 저장소·보관소. 여기서는 로컬 영속 기록에 접근하는 Repository 패턴 계약
- **`ProjectGenerationRepository`** `protocol` · public · [ProjectGenerationRepository.swift:1](../../../sources/Projects/Domain/ProjectGeneration/Contracts/ProjectGenerationRepository.swift#L1) · 채택: Sendable  
  ProjectGenerationRequest를 등록하고 ProjectGenerationReceipt를 돌려주는 register(_:) 하나만 정의하는 계약이다. ProjectGeneration.request(_:)가 중복 검사 후 호출한다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Repository` 저장소·보관소. 여기서는 생성 요청을 원격에 등록하는 Repository 패턴 계약

## ProjectGeneration/Errors

- **`ProjectGenerationError`** `enum` · public · [ProjectGenerationError.swift:1](../../../sources/Projects/Domain/ProjectGeneration/Errors/ProjectGenerationError.swift#L1) · 채택: CaseIterable, Equatable, Error, Sendable  
  프로젝트 생성 요청 흐름의 도메인 오류로 duplicateRequest, invalidRequest, unauthorized, temporarilyUnavailable, unexpected를 가진다. ProjectGeneration.request(_:)가 같은 URL로 생성 중이면 duplicateRequest를 던진다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Error` 오류. 여기서는 생성 요청 실패 원인을 나타내는 Swift Error 타입

## ProjectGeneration/Models

- **`GenerationWaitPolicy`** `struct` · public · [GenerationWaitPolicy.swift:3](../../../sources/Projects/Domain/ProjectGeneration/Models/GenerationWaitPolicy.swift#L3) · 채택: Equatable, Sendable  
  생성 요청 후 준비 완료로 간주하기까지의 minimumWait와 기록 보존 한도 retentionLimit(TimeInterval)를 담은 정책 값으로, standard(300초/3600초) 기본값과 readyDate(for:), isExpired(_:now:)를 제공한다. ProjectGeneration 액터가 단계 산출·타이머·만료 정리에 사용한다.  
  단어: `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Wait` 대기. 여기서는 요청 시각부터 준비 완료로 보기까지 기다리는 시간 · `Policy` 정책·규칙. 여기서는 대기·보존 시간을 정하는 설정 값 묶음
- **`ProjectGenerationPhase`** `enum` · public · [ProjectGenerationPhase.swift:3](../../../sources/Projects/Domain/ProjectGeneration/Models/ProjectGenerationPhase.swift#L3) · 채택: Equatable, Sendable  
  외부에 노출되는 생성 단계로 inProgress(readyAt:), preparing(readyAt:), ready, failed 네 케이스를 가진다. ProjectGeneration.phase(of:now:)가 GenerationRecord.Status와 GenerationWaitPolicy.readyDate를 결합해 산출하며 ProjectGenerationRequestState.phase에 담긴다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Phase` 국면·단계. 여기서는 진행 중→준비 중→준비 완료 또는 실패로 이어지는 화면용 단계
- **`ProjectGenerationReceipt`** `struct` · public · [ProjectGenerationReceipt.swift:3](../../../sources/Projects/Domain/ProjectGeneration/Models/ProjectGenerationReceipt.swift#L3) · 채택: Equatable, Sendable  
  생성 요청 등록에 대한 응답 값으로 projectID(ProjectID)와 quizLevel(QuizLevel)을 보유한다. ProjectGenerationRepository.register(_:)와 ProjectGenerationUseCase.request(_:)의 반환 타입이며 ProjectGeneration이 이 projectID를 기록에 부착한다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Receipt` 영수증·접수증. 여기서는 요청이 접수됐음을 증명하며 발급된 프로젝트 ID를 담는 값
- **`ProjectGenerationRequest`** `struct` · public · [ProjectGenerationRequest.swift:3](../../../sources/Projects/Domain/ProjectGeneration/Models/ProjectGenerationRequest.swift#L3) · 채택: Equatable, Sendable  
  생성 요청 입력 값으로 repositoryURL(ExternalRepositoryURL, String 별칭)과 quizLevel(QuizLevel)을 보유한다. ProjectGenerationUseCase.request(_:)와 ProjectGenerationRepository.register(_:)의 매개변수다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Request` 요청. 여기서는 사용자가 입력한 저장소 주소와 난이도로 구성된 생성 요청
- **`ProjectGenerationRequestState`** `struct` · public · [ProjectGenerationRequestState.swift:4](../../../sources/Projects/Domain/ProjectGeneration/Models/ProjectGenerationRequestState.swift#L4) · 채택: Equatable, Sendable  
  요청 하나의 현재 상태로 repositoryURL, projectID(ProjectID?), requestedAt(Date), phase(ProjectGenerationPhase)를 보유한다. ProjectGeneration.projectedState()가 내부 GenerationRecord를 이 타입으로 투영해 ProjectGenerationState.requests에 담는다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Request` 요청. 여기서는 개별 생성 요청 한 건 · `State` 상태. 여기서는 그 요청의 URL·ID·요청 시각·단계를 묶은 관찰용 스냅샷
- **`ProjectGenerationState`** `struct` · public · [ProjectGenerationState.swift:3](../../../sources/Projects/Domain/ProjectGeneration/Models/ProjectGenerationState.swift#L3) · 채택: Equatable, Sendable  
  ProjectGenerationUseCase.states() 스트림으로 방출되는 공개 상태로 requests([ProjectGenerationRequestState])와 preparingProjectIDs(Set<ProjectID>)를 보유한다. preparingProjectIDs는 inProgress·preparing 단계의 프로젝트 ID 집합이며 Project 액터가 목록에서 제외할 ID로 사용한다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `State` 상태. 여기서는 모든 생성 요청과 준비 중 ID를 묶어 외부에 공개하는 스냅샷
- **`QuizLevel`** `enum` · public · [QuizLevel.swift:1](../../../sources/Projects/Domain/ProjectGeneration/Models/QuizLevel.swift#L1) · 채택: CaseIterable, Equatable, Hashable, Sendable  
  퀴즈 난이도 수준을 나타내는 열거형으로 l1, l2, l3 세 케이스를 가진다. ProjectGenerationRequest와 ProjectGenerationReceipt의 quizLevel에 사용된다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 프로젝트에서 생성될 학습 문제 · `Level` 수준·단계. 여기서는 생성될 퀴즈의 난이도(l1~l3)

## ProjectGeneration/Models/Records

- **`GenerationOutcome`** `struct` · public · [GenerationOutcome.swift:3](../../../sources/Projects/Domain/ProjectGeneration/Models/Records/GenerationOutcome.swift#L3) · 채택: Equatable, Sendable  
  생성 작업이 끝났음을 알리는 이벤트 값으로 projectID(ProjectID)와 status(GenerationOutcome.Status)를 보유한다. GenerationOutcomeRepository.outcomes() 스트림 원소이며 ProjectGeneration.finish(_:)가 GenerationRecord.Status로 변환해 기록을 마감한다.  
  단어: `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Outcome` 결과·귀결. 여기서는 생성 작업 종료 시 통보되는 프로젝트 ID와 완료/실패 결과
- **`GenerationOutcome.Status`** `enum` · public · [GenerationOutcome.swift:17](../../../sources/Projects/Domain/ProjectGeneration/Models/Records/GenerationOutcome.swift#L17) · 채택: CaseIterable, Equatable, Sendable  
  GenerationOutcome에 중첩된 결과 상태로 completed와 failed 두 케이스만 가진다. 진행 중 상태가 없어 종료 이벤트만 표현한다.  
  단어(단일): `Status` 상태·지위. 여기서는 생성 작업의 최종 결과가 완료인지 실패인지
- **`GenerationRecord`** `struct` · public · [GenerationRecord.swift:4](../../../sources/Projects/Domain/ProjectGeneration/Models/Records/GenerationRecord.swift#L4) · 채택: Equatable, Sendable  
  생성 요청 한 건의 영속 기록으로 repositoryURL(생성자에서 normalizedURL로 소문자·공백·후행 슬래시 정규화), projectID(ProjectID?), requestedAt, status(GenerationRecord.Status), finishedAt(Date?)을 보유한다. attachingProjectID, finishing(status:at:), isExpired(now:retentionLimit:)로 불변 갱신·만료 판정을 제공하며 GenerationState.records의 원소다.  
  단어: `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Record` 기록. 여기서는 한 생성 요청의 URL·ID·시각·상태를 저장해 두는 영속 항목
- **`GenerationRecord.Status`** `enum` · public · [GenerationRecord.swift:24](../../../sources/Projects/Domain/ProjectGeneration/Models/Records/GenerationRecord.swift#L24) · 채택: Equatable, Sendable  
  GenerationRecord에 중첩된 기록 상태로 inProgress, completed, failed 세 케이스를 가진다. PendingGenerationRepository.finishGeneration의 매개변수이자 ProjectGeneration.phase(of:now:)의 입력이다.  
  단어(단일): `Status` 상태·지위. 여기서는 생성 기록이 진행 중·완료·실패 중 어디에 있는지
- **`GenerationReminder`** `struct` · public · [GenerationReminder.swift:3](../../../sources/Projects/Domain/ProjectGeneration/Models/Records/GenerationReminder.swift#L3) · 채택: Equatable, Sendable  
  예약할 알림의 내용을 담는 값으로 projectID(ProjectID)와 kind(GenerationReminder.Kind)를 보유한다. GenerationReminderScheduler.schedule(_:at:)의 입력이며 ProjectGeneration.scheduleReminderIfRegistered(for:)가 생성한다.  
  단어: `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `Reminder` 상기시키는 것·알림. 여기서는 생성 완료/실패를 사용자에게 알리는 예약 알림 한 건
- **`GenerationReminder.Kind`** `enum` · public · [GenerationReminder.swift:17](../../../sources/Projects/Domain/ProjectGeneration/Models/Records/GenerationReminder.swift#L17) · 채택: CaseIterable, Equatable, Sendable  
  GenerationReminder에 중첩된 알림 종류로 completed와 failed 두 케이스를 가진다. ProjectGeneration이 기록 status에 따라 어느 종류의 알림을 예약할지 결정한다.  
  단어(단일): `Kind` 종류·유형. 여기서는 알림이 완료 알림인지 실패 알림인지
- **`GenerationState`** `struct` · public · [GenerationState.swift:4](../../../sources/Projects/Domain/ProjectGeneration/Models/Records/GenerationState.swift#L4) · 채택: Equatable, Sendable  
  PendingGenerationRepository가 저장·방출하는 내부 영속 상태로 records([GenerationRecord])만 보유하며 activeProjectIDs, isCreating(repositoryURL:), record(projectID:/repositoryURL:) 조회와 beginning, attachingProjectID, finishing, removing, purgingExpired 불변 갱신 메서드를 제공한다. ProjectGeneration 액터가 이를 ProjectGenerationState로 투영한다.  
  단어: `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `State` 상태. 여기서는 모든 생성 기록을 담아 영속 저장소가 관리하는 내부 상태

## ProjectGeneration/UseCases

- **`ProjectGeneration`** `actor` · public · [ProjectGeneration.swift:4](../../../sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGeneration.swift#L4) · 채택: ProjectGenerationUseCase  
  ProjectGenerationUseCase를 구현하는 액터로 ProjectGenerationRepository, PendingGenerationRepository, GenerationOutcomeRepository, GenerationReminderScheduler, signedOutEvents, GenerationWaitPolicy, now, sleep을 생성자 주입받는다. request(_:)는 중복 검사→register→projectID 부착→리마인더 큐 순으로 처리하고, states()는 결과·로그아웃·pending 변경 스트림을 관찰하며 GenerationState를 ProjectGenerationState로 투영해 방출하고 readyAt 시각에 타이머로 재방출하며 알림을 예약한다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Generation` 생성. 여기서는 프로젝트 생성 요청과 진행 상태를 관장하는 유스케이스 구현체 자체를 가리킴
- **`ProjectGenerationUseCase`** `protocol` · public · [ProjectGenerationUseCase.swift:1](../../../sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGenerationUseCase.swift#L1) · 채택: Sendable  
  프로젝트 생성 유스케이스 계약으로 request(_:)(ProjectGenerationRequest→ProjectGenerationReceipt)와 states()(AsyncStream<ProjectGenerationState>) 두 요구사항을 정의한다. ProjectGeneration 액터가 구현하며 Feature 계층이 의존한다.  
  단어: `Project` 기획·과제. 여기서는 Git 저장소 기반 학습 단위(프로젝트) · `Generation` 생성. 여기서는 저장소 URL로 퀴즈 프로젝트를 만드는 작업 · `UseCase` Use + Case, 유스케이스. 여기서는 생성 요청과 상태 관찰 시나리오를 노출하는 응용 계층 계약

## QuizDetail/Contracts

- **`AnswerRepository`** `protocol` · public · [AnswerRepository.swift:1](../../../sources/Projects/Domain/QuizDetail/Contracts/AnswerRepository.swift#L1) · 채택: Sendable  
  선택형 답안(ChoiceAnswer)과 서술형 답안(EssayAnswer)을 submit으로 제출하고 각각 ChoiceGrading·EssayGrading 채점 결과를 돌려받는 저장소 계약이다. QuizDetail 액터가 grade 처리에서 호출하며 Composition의 QuizAnswerRepositoryAdapter가 구현한다.  
  단어: `Answer` 답·답안. 여기서는 퀴즈에 대해 사용자가 제출하는 선택형·서술형 답안 · `Repository` 저장소·보관소. 여기서는 답안 제출과 채점 결과 수신을 추상화한 데이터 접근 계약
- **`BookmarkRepository`** `protocol` · public · [BookmarkRepository.swift:3](../../../sources/Projects/Domain/QuizDetail/Contracts/BookmarkRepository.swift#L3) · 채택: Sendable  
  setBookmark(quizID, in: projectID, isBookmarked:)로 퀴즈의 북마크 여부를 바꿔 QuizBookmarkState를 받고, bookmarks(filter)로 QuizBookmarkFilter에 맞는 QuizBookmarkList를 조회하는 저장소 계약이다. QuizDetail 액터가 사용하며 Composition의 QuizBookmarkRepositoryAdapter가 구현한다.  
  단어: `Bookmark` 책갈피·즐겨찾기. 여기서는 사용자가 나중에 다시 보려고 표시해 둔 퀴즈 · `Repository` 저장소·보관소. 여기서는 북마크 설정·해제와 목록 조회를 추상화한 데이터 접근 계약
- **`QuizSetRepository`** `protocol` · public · [QuizSetRepository.swift:3](../../../sources/Projects/Domain/QuizDetail/Contracts/QuizSetRepository.swift#L3) · 채택: Sendable  
  quizSet(setID, in: projectID)로 프로젝트에 속한 퀴즈 세트(QuizSet)를 조회하는 단일 메서드 저장소 계약이다. QuizDetail 액터가 그대로 위임 호출하며 Composition의 QuizSetRepositoryAdapter가 구현한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 학습 프로젝트에서 생성된 개별 문제 · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(학습 세트) · `Repository` 저장소·보관소. 여기서는 퀴즈 세트 조회를 추상화한 데이터 접근 계약

## QuizDetail/Errors

- **`QuizDetailError`** `enum` · public · [QuizDetailError.swift:1](../../../sources/Projects/Domain/QuizDetail/Errors/QuizDetailError.swift#L1) · 채택: CaseIterable, Equatable, Error, Sendable  
  퀴즈 상세 관심사에서 발생하는 오류를 invalidAnswer, quizSetUnavailable, quizUnavailable, notFound, unauthorized, temporarilyUnavailable, unexpected 일곱 case로 정의한 오류 열거형이다. QuizDetail.grade가 invalidAnswer를 던지고 Composition 어댑터가 나머지를 매핑하며 Feature의 Saved·LearningSetIntro·QuestionSolving·SingleQuestionEntry가 처리한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 학습 프로젝트에서 생성된 개별 문제 · `Detail` 상세·세부. 여기서는 퀴즈 세트 조회·채점·북마크를 다루는 퀴즈 상세 관심사 · `Error` 오류. 여기서는 퀴즈 상세 관심사의 실패 원인을 구분하는 도메인 오류

## QuizDetail/Models/Bookmark

- **`QuizBookmark`** `struct` · public · [QuizBookmark.swift:3](../../../sources/Projects/Domain/QuizDetail/Models/Bookmark/QuizBookmark.swift#L3) · 채택: Equatable, Sendable  
  북마크된 퀴즈 하나를 나타내는 모델로 projectID, projectName, setID, setLabel, problemNumber, quizID, prompt를 보유한다. QuizBookmarkList.bookmarks의 항목으로 쓰인다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 북마크 대상이 된 개별 문제 · `Bookmark` 책갈피·즐겨찾기. 여기서는 사용자가 저장해 둔 퀴즈 항목과 그 소속 정보
- **`QuizBookmarkFilter`** `enum` · public · [QuizBookmarkFilter.swift:3](../../../sources/Projects/Domain/QuizDetail/Models/Bookmark/QuizBookmarkFilter.swift#L3) · 채택: Equatable, Hashable, Sendable  
  북마크 목록 조회 범위를 all(전체)과 project(ProjectID)(특정 프로젝트)로 구분하는 열거형이다. BookmarkRepository.bookmarks와 QuizDetailUseCase.bookmarks의 인자로 쓰이며 Feature의 Saved·LearningSetIntro가 전달한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 북마크 대상이 된 개별 문제 · `Bookmark` 책갈피·즐겨찾기. 여기서는 사용자가 저장해 둔 퀴즈 · `Filter` 여과기·조건. 여기서는 북마크 목록을 전체 또는 특정 프로젝트로 좁히는 조회 조건
- **`QuizBookmarkList`** `struct` · public · [QuizBookmarkList.swift:1](../../../sources/Projects/Domain/QuizDetail/Models/Bookmark/QuizBookmarkList.swift#L1) · 채택: Equatable, Sendable  
  북마크 조회 결과로 totalCount, 필터용 프로젝트 목록 projects([QuizBookmarkProject]), 북마크 항목 bookmarks([QuizBookmark])를 함께 담는 모델이다. BookmarkRepository.bookmarks와 QuizDetailUseCase.bookmarks가 반환하며 Feature의 SavedFeature·LearningSetIntroFeature가 소비한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 북마크 대상이 된 개별 문제 · `Bookmark` 책갈피·즐겨찾기. 여기서는 사용자가 저장해 둔 퀴즈 · `List` 목록. 여기서는 총 개수·프로젝트 목록·북마크 항목을 묶은 조회 결과
- **`QuizBookmarkProject`** `struct` · public · [QuizBookmarkProject.swift:3](../../../sources/Projects/Domain/QuizDetail/Models/Bookmark/QuizBookmarkProject.swift#L3) · 채택: Equatable, Identifiable, Sendable  
  북마크가 존재하는 프로젝트를 id(ProjectID)와 name으로 나타내는 모델이다. QuizBookmarkList.projects의 항목이며 Feature의 SavedScreen+FilterSection이 프로젝트 필터 표시에 사용한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 북마크 대상이 된 개별 문제 · `Bookmark` 책갈피·즐겨찾기. 여기서는 사용자가 저장해 둔 퀴즈 · `Project` 프로젝트. 여기서는 북마크된 퀴즈가 속한 학습 프로젝트의 식별자와 이름
- **`QuizBookmarkState`** `struct` · public · [QuizBookmarkState.swift:3](../../../sources/Projects/Domain/QuizDetail/Models/Bookmark/QuizBookmarkState.swift#L3) · 채택: Equatable, Sendable  
  북마크 변경 후의 결과로 quizID와 isBookmarked를 담는 모델이다. BookmarkRepository.setBookmark와 QuizDetailUseCase.bookmark·unbookmark가 반환하며 Feature의 SavedFeature·QuestionSolvingFeature가 받는다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 북마크 여부가 바뀐 개별 문제 · `Bookmark` 책갈피·즐겨찾기. 여기서는 퀴즈에 대한 저장 표시 · `State` 상태. 여기서는 특정 퀴즈의 현재 북마크 여부

## QuizDetail/Models/Grading

- **`ChoiceAnswer`** `struct` · public · [ChoiceAnswer.swift:3](../../../sources/Projects/Domain/QuizDetail/Models/Grading/ChoiceAnswer.swift#L3) · 채택: Equatable, Sendable  
  선택형 퀴즈 답안으로 projectID, quizID, selectedIndex(고른 보기 인덱스)를 보유한다. QuizDetailUseCase.grade와 AnswerRepository.submit의 입력이며 QuizDetail은 selectedIndex가 0 이상인지 검증한다.  
  단어: `Choice` 선택·선택지. 여기서는 보기 중 하나를 고르는 선택형(객관식) 퀴즈 · `Answer` 답·답안. 여기서는 사용자가 제출하는 선택형 퀴즈 답안
- **`ChoiceGrading`** `struct` · public · [ChoiceGrading.swift:1](../../../sources/Projects/Domain/QuizDetail/Models/Grading/ChoiceGrading.swift#L1) · 채택: Equatable, Sendable  
  선택형 답안의 채점 결과로 isCorrect, correctIndex(정답 보기 인덱스), explanation(해설)을 담는 모델이다. AnswerRepository.submit(ChoiceAnswer)과 QuizDetailUseCase.grade가 반환하며 Feature의 QuestionSolvingFeature·ChoiceOptionDisplay가 사용한다.  
  단어: `Choice` 선택·선택지. 여기서는 선택형(객관식) 퀴즈 · `Grading` 채점·등급 매기기. 여기서는 선택형 답안 제출에 대해 돌아오는 정오·정답·해설 정보
- **`EssayAnswer`** `struct` · public · [EssayAnswer.swift:3](../../../sources/Projects/Domain/QuizDetail/Models/Grading/EssayAnswer.swift#L3) · 채택: Equatable, Sendable  
  서술형 퀴즈 답안으로 projectID, quizID, text를 보유한다. QuizDetailUseCase.grade와 AnswerRepository.submit의 입력이며 QuizDetail은 text를 공백 제거 후 비어 있지 않고 2000자 이하인지 검증해 다시 만들어 제출한다.  
  단어: `Essay` 에세이·서술. 여기서는 자유 텍스트로 답하는 서술형 퀴즈 · `Answer` 답·답안. 여기서는 사용자가 제출하는 서술형 퀴즈 답안
- **`EssayGrading`** `struct` · public · [EssayGrading.swift:1](../../../sources/Projects/Domain/QuizDetail/Models/Grading/EssayGrading.swift#L1) · 채택: Equatable, Sendable  
  서술형 답안의 채점 결과로 explanation(해설)과 rubric([String], 평가 기준 목록)을 담는 모델이다. AnswerRepository.submit(EssayAnswer)과 QuizDetailUseCase.grade가 반환하며 Feature의 QuestionSolvingFeature가 사용한다.  
  단어: `Essay` 에세이·서술. 여기서는 서술형 퀴즈 · `Grading` 채점·등급 매기기. 여기서는 서술형 답안 제출에 대해 돌아오는 해설·루브릭 정보

## QuizDetail/Models/Quiz

- **`ChoiceSubmission`** `struct` · public · [ChoiceSubmission.swift:1](../../../sources/Projects/Domain/QuizDetail/Models/Quiz/ChoiceSubmission.swift#L1) · 채택: Equatable, Sendable  
  이미 제출된 선택형 답안의 기록으로 selectedIndex와 isCorrect를 보유한다. QuizContent.choice의 submitted 연관값으로 쓰이며 Composition의 QuizSetRepositoryAdapter가 생성한다.  
  단어: `Choice` 선택·선택지. 여기서는 선택형(객관식) 퀴즈 · `Submission` 제출·제출물. 여기서는 퀴즈 세트 조회 시 함께 내려오는 과거 제출 답안 기록
- **`EssaySubmission`** `struct` · public · [EssaySubmission.swift:1](../../../sources/Projects/Domain/QuizDetail/Models/Quiz/EssaySubmission.swift#L1) · 채택: Equatable, Sendable  
  이미 제출된 서술형 답안의 기록으로 text 하나를 보유한다. QuizContent.essay의 submitted 연관값으로 쓰이며 Composition의 QuizSetRepositoryAdapter가 생성한다.  
  단어: `Essay` 에세이·서술. 여기서는 서술형 퀴즈 · `Submission` 제출·제출물. 여기서는 퀴즈 세트 조회 시 함께 내려오는 과거 제출 답안 기록
- **`Quiz`** `struct` · public · [Quiz.swift:3](../../../sources/Projects/Domain/QuizDetail/Models/Quiz/Quiz.swift#L3) · 채택: Equatable, Sendable  
  퀴즈 한 문제를 나타내는 모델로 id(QuizID), prompt(문제 지문), content(QuizContent, 유형별 본문과 제출 이력), sources([QuizSource], 근거 자료)를 보유한다. QuizSet.quizzes의 항목이다.  
  단어(단일): `Quiz` 퀴즈·문제. 여기서는 학습 프로젝트에서 생성된 개별 문제 자체
- **`QuizContent`** `enum` · public · [QuizContent.swift:1](../../../sources/Projects/Domain/QuizDetail/Models/Quiz/QuizContent.swift#L1) · 채택: Equatable, Sendable  
  퀴즈 유형별 본문을 choice(options: [String], submitted: ChoiceSubmission?)와 essay(submitted: EssaySubmission?) 두 case로 표현하는 열거형이다. Quiz.content로 보유되며 Composition의 QuizSetRepositoryAdapter가 생성한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 개별 문제 · `Content` 내용·본문. 여기서는 선택형 보기 목록 또는 서술형 여부와 과거 제출 기록을 담는 문제 본문
- **`QuizSet`** `struct` · public · [QuizSet.swift:3](../../../sources/Projects/Domain/QuizDetail/Models/Quiz/QuizSet.swift#L3) · 채택: Equatable, Sendable  
  퀴즈 묶음을 나타내는 모델로 id(QuizSetID), title, description, quizzes([Quiz])를 보유한다. QuizSetRepository.quizSet과 QuizDetailUseCase.quizSet이 반환한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 학습 프로젝트에서 생성된 개별 문제 · `Set` 집합·묶음. 여기서는 제목·설명과 함께 여러 퀴즈를 묶은 학습 세트
- **`QuizSource`** `struct` · public · [QuizSource.swift:1](../../../sources/Projects/Domain/QuizDetail/Models/Quiz/QuizSource.swift#L1) · 채택: Equatable, Sendable  
  퀴즈의 근거가 된 자료를 filePath, startLine, endLine, symbol, summary, referenceURL(모두 옵셔널)로 나타내는 모델이다. Quiz.sources의 항목이며 Feature의 QuestionSourceDisplay가 화면 표시용으로 변환한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 개별 문제 · `Source` 출처·원천. 여기서는 문제가 만들어진 근거인 코드 파일 위치·심볼·요약·참조 링크

## QuizDetail/UseCases

- **`QuizDetail`** `actor` · public · [QuizDetail.swift:4](../../../sources/Projects/Domain/QuizDetail/UseCases/QuizDetail.swift#L4) · 채택: QuizDetailUseCase  
  QuizSetRepository·AnswerRepository·BookmarkRepository를 생성자 주입받아 QuizDetailUseCase를 구현하는 액터로, 선택형 답안은 selectedIndex 0 이상, 서술형 답안은 공백 제거 후 1~2000자를 검증해 위반 시 QuizDetailError.invalidAnswer를 던진다. 북마크 설정·해제는 quizID별 inFlight 사전의 PendingMutation으로 이전 작업 완료를 기다린 뒤 실행해 직렬화하며 Composition의 ConcernUseCaseAssembly가 생성한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 학습 프로젝트에서 생성된 개별 문제 · `Detail` 상세·세부. 여기서는 퀴즈 세트 조회·채점·북마크를 담당하는 퀴즈 상세 관심사의 유스케이스 구현
- **`QuizDetail.PendingMutation`** `struct` · private · [QuizDetail.swift:70](../../../sources/Projects/Domain/QuizDetail/UseCases/QuizDetail.swift#L70)  
  QuizDetail 내부에서 진행 중인 북마크 변경 작업을 식별하는 token(UUID)과 그 완료를 기다리는 awaitCompletion 클로저를 보유하는 비공개 구조체다. inFlight[quizID]의 값으로 저장되어 같은 퀴즈에 대한 다음 setBookmark가 이전 작업을 기다리게 하고, 완료 시 token이 일치할 때만 제거된다.  
  단어: `Pending` 보류 중·진행 중. 여기서는 아직 완료되지 않은 북마크 변경 작업 · `Mutation` 변경·변이. 여기서는 퀴즈 북마크 상태를 바꾸는 쓰기 작업
- **`QuizDetailUseCase`** `protocol` · public · [QuizDetailUseCase.swift:3](../../../sources/Projects/Domain/QuizDetail/UseCases/QuizDetailUseCase.swift#L3) · 채택: Sendable  
  퀴즈 상세 관심사의 유스케이스 계약으로 quizSet(setID, in:), grade(ChoiceAnswer), grade(EssayAnswer), bookmark, unbookmark, bookmarks(filter) 여섯 메서드를 정의한다. QuizDetail 액터가 구현하며 Feature의 Quiz·ProjectDetail·MainShell 라우터와 App의 AppRootFeature가 의존한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 학습 프로젝트에서 생성된 개별 문제 · `Detail` 상세·세부. 여기서는 퀴즈 세트 조회·채점·북마크를 다루는 퀴즈 상세 관심사 · `UseCase` Use + Case, 유스케이스(응용 동작 단위). 여기서는 Feature가 의존하는 퀴즈 상세 도메인 동작 계약

## UserInfo/Contracts

- **`UserInfoRepository`** `protocol` · public · [UserInfoRepository.swift:1](../../../sources/Projects/Domain/UserInfo/Contracts/UserInfoRepository.swift#L1) · 채택: Sendable  
  profile()로 UserProfile을 조회하고 updateCuration·updatePosition·updateCareerLevel로 사용자 설정을 갱신하는 저장소 계약이다. UserInfo 액터가 사용하며 Composition의 UserInfoRepositoryAdapter가 구현한다.  
  단어: `User` 사용자. 여기서는 로그인한 앱 사용자(회원) · `Info` Information의 축약, 정보. 여기서는 사용자의 프로필·큐레이션 정보 · `Repository` 저장소·보관소. 여기서는 프로필 조회와 설정 갱신을 추상화한 데이터 접근 계약

## UserInfo/Errors

- **`UserInfoError`** `enum` · public · [UserInfoError.swift:1](../../../sources/Projects/Domain/UserInfo/Errors/UserInfoError.swift#L1) · 채택: CaseIterable, Equatable, Error, Sendable  
  사용자 정보 관심사의 오류를 invalidRequest, unauthorized, memberUnavailable, temporarilyUnavailable 네 case로 정의한 오류 열거형이다. Composition의 UserInfoRepositoryAdapter가 던지고 Feature의 Settings·Profile·Home·AppEntry Feature가 처리한다.  
  단어: `User` 사용자. 여기서는 로그인한 앱 사용자(회원) · `Info` Information의 축약, 정보. 여기서는 사용자의 프로필·큐레이션 정보 · `Error` 오류. 여기서는 사용자 정보 조회·갱신 실패 원인을 구분하는 도메인 오류

## UserInfo/Models

- **`CareerLevel`** `enum` · public · [CareerLevel.swift:1](../../../sources/Projects/Domain/UserInfo/Models/CareerLevel.swift#L1) · 채택: CaseIterable, Equatable, Sendable  
  사용자의 경력 수준을 entry, junior, middle, senior 네 case로 정의한 열거형이다. Curation.careerLevel로 보유되고 UserInfoRepository·UserInfoUseCase의 updateCareerLevel 인자로 쓰이며 Feature의 Settings 화면이 선택 UI에 사용한다.  
  단어: `Career` 경력·직업 이력. 여기서는 사용자의 개발 경력 · `Level` 수준·단계. 여기서는 경력을 입문·주니어·미들·시니어로 나눈 단계
- **`Curation`** `struct` · public · [Curation.swift:1](../../../sources/Projects/Domain/UserInfo/Models/Curation.swift#L1) · 채택: Equatable, Sendable  
  사용자 맞춤 설정으로 position(MemberPosition)과 careerLevel(CareerLevel)을 보유하는 모델이다. UserProfile.curation(옵셔널)으로 조회되고 UserInfoRepository·UserInfoUseCase의 updateCuration 인자로 쓰이며 Feature의 SettingsFeature와 App의 AppRootFeature가 사용한다.  
  단어(단일): `Curation` 큐레이션·선별. 여기서는 사용자의 직군과 경력 수준으로 이루어진 맞춤 학습 설정
- **`LearningStatistics`** `struct` · public · [LearningStatistics.swift:1](../../../sources/Projects/Domain/UserInfo/Models/LearningStatistics.swift#L1) · 채택: Equatable, Sendable  
  사용자의 학습 통계로 thisWeekSolvedCount, thisMonthSolvedCount, streakDays, weeklyCounts([WeeklyLearningCount])를 보유하는 모델이다. UserDetail.statistics로 보유되며 Composition의 UserInfoRepositoryAdapter가 생성한다.  
  단어: `Learning` 학습. 여기서는 사용자의 퀴즈 풀이 활동 · `Statistics` 통계. 여기서는 주간·월간 풀이 수, 연속 일수, 요일별 개수 집계
- **`MemberPosition`** `enum` · public · [MemberPosition.swift:1](../../../sources/Projects/Domain/UserInfo/Models/MemberPosition.swift#L1) · 채택: CaseIterable, Equatable, Sendable  
  회원의 개발 직군을 ios, android, backend, frontend 네 case로 정의한 열거형이다. Curation.position으로 보유되고 UserInfoRepository·UserInfoUseCase의 updatePosition 인자로 쓰이며 Feature의 Onboarding PositionSelection·Settings·Home이 사용한다.  
  단어: `Member` 구성원·회원. 여기서는 서비스 회원(사용자) · `Position` 위치·직무. 여기서는 iOS·Android·백엔드·프론트엔드 중 하나인 개발 직군
- **`UserDetail`** `struct` · public · [UserDetail.swift:1](../../../sources/Projects/Domain/UserInfo/Models/UserDetail.swift#L1) · 채택: Equatable, Sendable  
  사용자 기본 정보로 name, email, statistics(LearningStatistics)를 보유하는 모델이다. UserProfile.detail로 조회되고 UserInfoUseCase.detail()이 반환하며 Feature의 Settings·Profile·Home 프리뷰와 App의 AppRootView가 사용한다.  
  단어: `User` 사용자. 여기서는 로그인한 앱 사용자(회원) · `Detail` 상세·세부. 여기서는 이름·이메일·학습 통계로 이루어진 사용자 상세 정보
- **`UserProfile`** `struct` · public · [UserProfile.swift:1](../../../sources/Projects/Domain/UserInfo/Models/UserProfile.swift#L1) · 채택: Equatable, Sendable  
  detail(UserDetail)과 curation(Curation?)을 함께 담는 사용자 프로필 모델이다. UserInfoRepository.profile()이 반환하며 UserInfo 액터가 sharedProfile()로 한 번 조회해 detail()·curation() 양쪽에 나눠 준다.  
  단어: `User` 사용자. 여기서는 로그인한 앱 사용자(회원) · `Profile` 프로필·인물 개요. 여기서는 상세 정보와 큐레이션 설정을 합친 사용자 전체 프로필
- **`WeeklyLearningCount`** `struct` · public · [WeeklyLearningCount.swift:1](../../../sources/Projects/Domain/UserInfo/Models/WeeklyLearningCount.swift#L1) · 채택: Equatable, Sendable  
  한 주 안의 특정 날짜 학습량을 dayLabel(요일 표시 문자열)과 count로 나타내는 모델이다. LearningStatistics.weeklyCounts의 항목이며 Feature의 ProfileDisplay가 표시용으로 변환한다.  
  단어: `Weekly` 주간의·매주의. 여기서는 한 주 단위로 집계된 것 · `Learning` 학습. 여기서는 사용자의 퀴즈 풀이 활동 · `Count` 개수·횟수. 여기서는 요일 하나에 해당하는 학습 횟수

## UserInfo/UseCases

- **`UserInfo`** `actor` · public · [UserInfo.swift:1](../../../sources/Projects/Domain/UserInfo/UseCases/UserInfo.swift#L1) · 채택: UserInfoUseCase  
  UserInfoRepository를 생성자 주입받아 UserInfoUseCase를 구현하는 액터로, detail()·curation()은 sharedProfile()이 보관하는 profileTask를 공유해 동시 호출 시 저장소 조회를 한 번만 수행한다. updateCuration·updatePosition·updateCareerLevel은 serialize로 lastMutation 체인을 이어 순차 실행하며 Composition의 ConcernUseCaseAssembly·MemberAssembly가 생성한다.  
  단어: `User` 사용자. 여기서는 로그인한 앱 사용자(회원) · `Info` Information의 축약, 정보. 여기서는 프로필 조회와 큐레이션·직군·경력 갱신을 담당하는 사용자 정보 관심사의 유스케이스 구현
- **`UserInfoUseCase`** `protocol` · public · [UserInfoUseCase.swift:1](../../../sources/Projects/Domain/UserInfo/UseCases/UserInfoUseCase.swift#L1) · 채택: Sendable  
  사용자 정보 관심사의 유스케이스 계약으로 detail(), curation(), updateCuration, updatePosition, updateCareerLevel 다섯 메서드를 정의한다. UserInfo 액터가 구현하며 Feature의 Settings·MainShell 라우터와 App의 AppRootFeature가 의존한다.  
  단어: `User` 사용자. 여기서는 로그인한 앱 사용자(회원) · `Info` Information의 축약, 정보. 여기서는 사용자의 프로필·큐레이션 정보 · `UseCase` Use + Case, 유스케이스(응용 동작 단위). 여기서는 Feature가 의존하는 사용자 정보 도메인 동작 계약
