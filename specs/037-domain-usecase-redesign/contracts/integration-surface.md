# 계약: Infrastructure·Data·Composition·App 연결 표면

Domain 밖에서 바뀌는 공개 선언과 조립 규칙입니다. Domain 선언은 [domain-api.md](./domain-api.md)를 따릅니다.

## 1. Infrastructure — `InfrastructureLocalNotification`

```swift
public enum NotificationAuthorizationSetting: Equatable, Sendable { case notDetermined, authorized, denied }

public protocol NotificationAuthorizationClient: Sendable {
    func authorizationSetting() async -> NotificationAuthorizationSetting   // 추가
    // 기존 requestAuthorization(), isAuthorized(), present(_:), schedule(_:at:), cancel(identifier:) 유지
}
```

`LocalNotificationAuthorizationClient.authorizationSetting()`: `notDetermined → .notDetermined`, `denied → .denied`,
`authorized·provisional·ephemeral → .authorized`, 알 수 없는 값 → `.denied`.

## 2. Data

### `DataShared`

```swift
public enum RequestCredential: Equatable, Sendable {
    case available(String)
    case signedOut
}
```

### `DataAuthentication`

```swift
public final class RequestCredentialProvider: Sendable {
    public init(secureStorage: any SecureValueStorage, now: @escaping @Sendable () -> Date = Date.init)
    public func credential() async -> RequestCredential
    public func credentialRejected() async
    public func invalidations() -> AsyncStream<Void>
}
```

`AuthenticationRemote`의 `accessTokenProvider`를 `credential: @escaping @Sendable () async -> RequestCredential`로 바꾼다.
`verifyAccessToken()`은 `.signedOut`이면 요청 없이 `AuthenticationServiceError.unauthorized`를 던진다.

### `DataLearningProject`, `DataMember`

`ProjectRemote`, `LearningSetRemote`, `AnswerRemote`, `BookmarkRemote`, `MemberRemote`의 `accessTokenProvider` 인자를 다음 두
인자로 바꾼다.

```swift
credential: @escaping @Sendable () async -> RequestCredential,
credentialRejected: @escaping @Sendable () async -> Void,
```

`LearningProjectRequestExecutor`와 `MemberRemote`는 `.signedOut`이면 요청 없이 각 서비스 오류의 `unauthorized`를 던지고,
응답 상태가 401이면 `credentialRejected()`를 호출한 뒤 `unauthorized`를 던진다. 재요청하지 않는다.

### `DataNotification`

```swift
public enum ReminderAuthorizationSetting: Equatable, Sendable { case notDetermined, authorized, denied }

public protocol LocalReminderNotifier: Sendable {
    func authorizationSetting() async -> ReminderAuthorizationSetting   // 추가
    // 기존 동작 유지
}
```

## 3. Composition

### 모듈 구성 (변경 없음)

`CompositionAuthentication`, `CompositionLearningProject`, `CompositionMember`, `CompositionApp`, `CompositionShareExtension`을
유지하고 import·조립만 바꾼다.

| Composition 모듈 | 전환 후 Domain 의존 |
| --- | --- |
| `CompositionAuthentication` | `DomainAccount` |
| `CompositionMember` | `DomainIdentifier`, `DomainAccount`(탈퇴 계약), `DomainUserInfo`, `DomainAppSetting` |
| `CompositionLearningProject` | `DomainIdentifier`, `DomainExternalRepository`, `DomainQuizDetail`, `DomainProject`, `DomainProjectGeneration`, `DomainAppSetting`(알림 권한 계약) |
| `CompositionApp` | 일곱 관심사 타깃 + `DomainIdentifier` |
| `CompositionShareExtension` | `DomainIdentifier`, `DomainAccount`, `DomainExternalRepository`, `DomainProjectGeneration` |

### 어댑터

| 새 계약 | 어댑터 (위치) | 위임 대상 |
| --- | --- | --- |
| `AuthenticationRepository` | `AuthenticationRepositoryAdapter` (Authentication, 기존 수정) | `AppleSignInSource`, `AppleIdentityStore`, `AuthenticationRemote` |
| `SignInRepository` | `SignInRepositoryAdapter` (Authentication, 신규 — `LoginSessionRepositoryAdapter`·`CurrentSessionRepositoryAdapter`·`SharedSignInStateRepositoryAdapter` 대체) | `AuthenticationRemote.appleLogin`, `SessionRecordStorageCoding`, `SharedSessionStateMarkerCoding`, `RequestCredentialProvider` |
| `PolicyConsentRepository` | `PolicyConsentRepositoryAdapter` (Authentication, 기존 수정) | `LocalPolicyConsentStore` |
| `WithdrawalRepository` | `WithdrawalRepositoryAdapter` (Member, 신규) | `MemberRemote.deleteAccount` |
| `UserInfoRepository` | `UserInfoRepositoryAdapter` (Member, 신규 — `MemberRepositoryAdapter` 프로필·큐레이션 부분과 `CurationRepositoryAdapter` 대체) | `MemberRemote`, `SessionRecordStorageCoding`(큐레이션 완료 시 `needsCuration = false`) |
| `DeviceRegistrationRepository` | `DeviceRegistrationRepositoryAdapter` (Member, 신규) | `MemberRemote.registerDevice` |
| `DeviceIdentifierRepository` | `DeviceIdentifierRepositoryAdapter` (Member, 기존 수정) | `LocalDeviceIdentifierStore` |
| `NotificationAuthorization` | `NotificationAuthorizationAdapter` (LearningProject, 기존 수정) | `LocalReminderNotifier` |
| `ExternalRepositoryLookup`·`ExternalRepositoryLocator` | 기존 어댑터 (import만 변경) | 기존 |
| `QuizSetRepository` | `QuizSetRepositoryAdapter` (LearningProject, `LearningSetRepositoryAdapter` 대체) | `LearningSetRemote` |
| `AnswerRepository`·`BookmarkRepository` | 기존 어댑터 수정 | `AnswerRemote`, `BookmarkRemote` |
| `ProjectRepository` | `ProjectRepositoryAdapter` (LearningProject, `LearningProjectRepositoryAdapter`의 목록·상세·삭제) | `ProjectRemote` |
| `ProjectGenerationRepository` | `ProjectGenerationRepositoryAdapter` (LearningProject, `LearningProjectRepositoryAdapter`의 등록) | `ProjectRemote.register` |
| `PendingGenerationRepository`·`GenerationOutcomeRepository`·`GenerationReminderScheduler` | 기존 어댑터 수정 | 기존 Data 저장소·푸시 결과·`LocalReminderNotifier` |

### `AppComposition` 공개 표면 (전환 완료 후)

| 속성 | 타입 |
| --- | --- |
| `account` | `any AccountUseCase` |
| `userInfo` | `any UserInfoUseCase` |
| `appSetting` | `any AppSettingUseCase` |
| `externalRepository` | `any ExternalRepositoryUseCase` |
| `quizDetail` | `any QuizDetailUseCase` |
| `project` | `any ProjectUseCase` |
| `projectGeneration` | `any ProjectGenerationUseCase` |
| `recordSharedSessionState` | `@Sendable () async -> Void` (유지 — `RequestCredentialProvider.credential()` 결과로 공유 표시 기록) |
| `activatePushClient` | 유지 |
| `configureAppDelegate` | 유지 |
| `deviceTokenRefreshes` | 유지 |
| `ingestGenerationOutcomePayload` | 유지 |

`Environment`에 `generationFailureReminderTitle: String`, `generationFailureReminderBody: String`을 추가한다.

조립 규칙:
- `RequestCredentialProvider` 하나를 만들어 모든 Remote의 `credential`·`credentialRejected`와 `Account.signInInvalidations`에 연결한다.
- `ProjectGeneration`을 먼저 만들고 `Project.preparingProjectIDs`에 `{ await projectGeneration.states() }`를 `preparingProjectIDs`로
  변환한 스트림을 연결한다.
- `Project`·`ProjectGeneration`의 `signedOutEvents`에 `Account.signInStates()`에서 `.signedOut`만 걸러 `Void`로 변환한 스트림을 연결한다.
- 각 UseCase는 앱에서 인스턴스 하나만 만든다.
- 제거: `signIn`, `signOut`, `restoreSession`, `verifyAuthorization`, `refreshSession`, `policyConsent`, `memberAccount`,
  `fetchLearningProjects`, `learningLibrary`, `createLearningProject`, `submitChoiceAnswer`, `submitEssayAnswer`,
  `setQuestionBookmark`, `deleteMemberAccount`, `fetchExternalRepository`, `requestGenerationReminder`, `trackGeneration`,
  `startObservingGenerationState`, `registerCurrentDevice`.

### `ShareExtensionComposition` 공개 표면 (전환 완료 후)

| 속성 | 타입 |
| --- | --- |
| `parseRepositoryLink` | `any ExternalRepositoryLocator` |
| `externalRepository` | `any ExternalRepositoryUseCase` |
| `projectGeneration` | `any ProjectGenerationUseCase` |
| `signInAvailability` | `@Sendable () async -> SignInAvailability` |

확장 앱 `Account`의 `signInInvalidations`, `ProjectGeneration`의 `signedOutEvents`에는 빈 스트림을 연결한다. 확장 앱
`RequestCredentialProvider`는 앱과 같은 공유 보안 저장소를 쓴다. 제거: `fetchExternalRepository`, `createLearningProject`,
`resolveSessionAvailability`, `isNotificationAuthorized`, `enqueueGenerationReminder`.

## 4. Feature·App

- Router·루트 Feature의 init 인자는 관심사 UseCase 존재 타입으로 바뀐다. 말단 Feature의 클로저 인자는 새 모델·오류 타입을 쓴다.
- `AppRootFeature`
  - 제거: `waitPolicy`, `generationRecord` 상태, `releaseGeneration` 타이머, `generationReleased` 이벤트, `trackGeneration.end` 호출,
    답안 제출마다의 `progressInvalidated` 처리.
  - 퀴즈 닫기(`quiz(.presented(.delegate(.dismissRequested)))`): `project.refresh()`(오류 무시) + 열린 상세 화면에 `refreshRequested`.
  - Home 배너는 `projectGeneration.states()`의 단계로 계산한다(`inProgress`·`preparing` 요청이 있으면 표시).
  - `applicationBecameActive`: `account.verifySignIn()` + 목록 새로고침(기존 경로 유지).
  - 기기 등록: `appSetting.registerDevice()`, 토큰 변경: `appSetting.updateDeviceToken(_:)`.
- `QuizRouterFeature`: `progressInvalidated` delegate 제거.
- `HomeFeature`·`ProjectListFeature`: `project.projects()` 구독으로 목록 표시, 진입 시 `project.refresh()`로 실패 표시.
- `SettingsFeature`: `appSetting.notificationAuthorization()` 기준으로 설정 이동·권한 요청 분기(research R-08).
- `ShareRegistrationFeature`: `signInAvailability`가 `signedIn`일 때만 `projectGeneration.request(_:)` 호출. 알림 대기열 기록과
  권한 조회 클로저 제거.
- App 지역화 문자열: 생성 실패 알림 제목·본문 추가.
