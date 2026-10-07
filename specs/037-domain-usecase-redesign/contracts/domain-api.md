# 계약: Domain 공개 API

타깃별 공개 선언의 정본입니다. 모든 모델은 `Equatable, Sendable`(enum은 필요 시 `CaseIterable`), 오류는
`Equatable, Error, Sendable`입니다. 생성자는 모든 저장 속성을 같은 이름·순서로 받는 멤버 생성자를 공개합니다.
동작 규칙은 [data-model.md](../data-model.md)를 따릅니다.

## DomainIdentifier (`Domain/Identifier/`)

```swift
public typealias ProjectID = String
public typealias QuizSetID = String
public typealias QuizID = String
public typealias ExternalRepositoryURL = String
```

이 타깃에는 위 `typealias` 외의 선언을 두지 않습니다. 관심사 타깃은 필요할 때만 이 타깃에 의존합니다.

## DomainAccount (`Domain/Account/`)

```swift
public protocol AccountUseCase: Sendable {
    func signIn(with method: SignInMethod) async -> SignInResult
    func signOut() async -> SignOutResult
    func signInStates() async -> AsyncStream<SignInState>
    func restoreSignIn() async -> SignInRestoration
    func verifySignIn() async -> SignInVerification
    func signInAvailability() async -> SignInAvailability
    func policyConsentStatus() async throws -> PolicyConsentStatus
    func consent(to documentIDs: [PolicyDocumentID]) async throws
    func withdraw() async throws
}

public actor Account: AccountUseCase {
    public init(
        authenticationRepository: any AuthenticationRepository,
        signInRepository: any SignInRepository,
        withdrawalRepository: any WithdrawalRepository,
        policyConsentRepository: any PolicyConsentRepository,
        policyDocuments: [PolicyDocument],
        signInInvalidations: @escaping @Sendable () async -> AsyncStream<Void>,
        now: @escaping @Sendable () -> Date = Date.init,
    )
}
```

| 모델 | 정의 |
| --- | --- |
| `AccountID` | `typealias = String` |
| `SignInMethod` | `enum { apple }` |
| `SignedInAccount` | `id: AccountID`, `displayName: String?`, `needsCuration: Bool` |
| `SignInState` | `enum { unknown, signedIn(AccountID), signedOut }` |
| `SignInResult` | `enum { signedIn(SignedInAccount), cancelled, retryableFailure }` |
| `SignOutResult` | `enum { signedOut, retryableFailure }` |
| `SignInRestoration` | `enum { signedIn(SignedInAccount), signedOut, temporarilyUnavailable }` |
| `SignInVerification` | `enum { valid, reauthenticationRequired, temporarilyUnavailable }` |
| `SignInAvailability` | `enum { signedIn, signInRequired, appLaunchRequired }` |
| `PolicyDocumentID` | `typealias = String` |
| `PolicyDocument` | `id: PolicyDocumentID`, `displayName: String`, `version: String`, `approvedURL: URL`, `isRequired: Bool` |
| `PolicyConsent` | `documentID: PolicyDocumentID`, `version: String`, `consentedAt: Date` |
| `PolicyConsentStatus` | `documents: [PolicyDocument]`, `consents: [PolicyConsent]`, `isSatisfied: Bool` |
| `AccountError` | `signInCancelled`, `policyUnavailable`, `withdrawalUnavailable`, `unauthorized`, `temporarilyUnavailable` |

계약(Composition이 구현):

```swift
public protocol AuthenticationRepository: Sendable {
    func authenticate(using method: SignInMethod) async throws -> AuthenticationGrant
    func authorizationStatus() async throws -> SignInVerification
    func clearAuthentication() async throws
}

public protocol SignInRepository: Sendable {
    func start(with grant: AuthenticationGrant) async throws -> SignInRecord
    func restore() async throws -> SignInRecord?
    func signOut() async throws
    func sharedSignInState() async -> Bool?
    func hasUsableCredential() async -> Bool
}

public protocol WithdrawalRepository: Sendable {
    func withdraw() async throws
}

public protocol PolicyConsentRepository: Sendable {
    func consents() async throws -> [PolicyConsent]
    func record(_ consents: [PolicyConsent]) async throws
    func removeAll() async throws
}
```

| 계약 모델 | 정의 |
| --- | --- |
| `AuthenticationGrant` | `id: String`, `method: SignInMethod` |
| `SignInRecord` | `account: SignedInAccount`, `isAccountAvailable: Bool` |

계약 오류: `authenticate`의 사용자 취소는 `AccountError.signInCancelled`, 그 밖의 실패는 `AccountError.temporarilyUnavailable`.
`restore`·`start`는 무효한 로그인 기록이면 `AccountError.unauthorized`, 일시 실패면 `.temporarilyUnavailable`.
`withdraw`는 `.unauthorized`·`.withdrawalUnavailable`·`.temporarilyUnavailable`.

## DomainUserInfo (`Domain/UserInfo/`)

```swift
public protocol UserInfoUseCase: Sendable {
    func detail() async throws -> UserDetail
    func curation() async throws -> Curation?
    func updateCuration(_ curation: Curation) async throws
    func updatePosition(_ position: MemberPosition) async throws
    func updateCareerLevel(_ careerLevel: CareerLevel) async throws
}

public actor UserInfo: UserInfoUseCase {
    public init(repository: any UserInfoRepository)
}

public protocol UserInfoRepository: Sendable {
    func profile() async throws -> UserProfile
    func updateCuration(_ curation: Curation) async throws
    func updatePosition(_ position: MemberPosition) async throws
    func updateCareerLevel(_ careerLevel: CareerLevel) async throws
}
```

| 모델 | 정의 |
| --- | --- |
| `UserDetail` | `name: String`, `email: String`, `statistics: LearningStatistics` |
| `Curation` | `position: MemberPosition`, `careerLevel: CareerLevel` |
| `UserProfile` (계약 모델) | `detail: UserDetail`, `curation: Curation?` — 서버가 포지션·경력 중 하나라도 비워 두면 `curation == nil` |
| `MemberPosition` | `enum { ios, android, backend, frontend }` |
| `CareerLevel` | `enum { entry, junior, middle, senior }` |
| `LearningStatistics` | `thisWeekSolvedCount`, `thisMonthSolvedCount`, `streakDays`, `weeklyCounts: [WeeklyLearningCount]` |
| `WeeklyLearningCount` | `dayLabel: String`, `count: Int` |
| `UserInfoError` | `invalidRequest`, `unauthorized`, `memberUnavailable`, `temporarilyUnavailable` |

`detail()`과 `curation()`은 진행 중인 `profile()` 서버 요청 하나를 공유합니다. 변경 세 동작은 하나의 직렬화 단위입니다.

## DomainAppSetting (`Domain/AppSetting/`)

```swift
public protocol AppSettingUseCase: Sendable {
    func notificationAuthorization() async -> NotificationAuthorizationStatus
    func requestNotificationAuthorization() async -> NotificationAuthorizationStatus
    func registerDevice() async throws
    func updateDeviceToken(_ token: DeviceToken) async throws
}

public struct AppSetting: AppSettingUseCase {
    public init(
        notificationAuthorization: any NotificationAuthorization,
        deviceRegistrationRepository: any DeviceRegistrationRepository,
        deviceIdentifierRepository: any DeviceIdentifierRepository,
        appVersion: String,
        osVersion: String,
        deviceToken: @escaping @Sendable () async throws -> DeviceToken,
    )
}

public protocol NotificationAuthorization: Sendable {
    func status() async -> NotificationAuthorizationStatus
    func requestAuthorization() async -> NotificationAuthorizationStatus
}

public protocol DeviceRegistrationRepository: Sendable {
    func register(_ registration: DeviceRegistration) async throws
}

public protocol DeviceIdentifierRepository: Sendable {
    func currentDeviceID() async -> DeviceID
}
```

| 모델 | 정의 |
| --- | --- |
| `NotificationAuthorizationStatus` | `enum { notDetermined, authorized, denied }` |
| `DeviceID` | `typealias = String` |
| `DeviceToken` | `typealias = String` |
| `DevicePlatform` | `enum { ios }` |
| `DeviceRegistration` | `deviceID: DeviceID`, `platform: DevicePlatform`, `appVersion: String`, `osVersion: String`, `token: DeviceToken?` |
| `AppSettingError` | `invalidRequest`, `unauthorized`, `temporarilyUnavailable` |

## DomainExternalRepository (`Domain/ExternalRepository/`)

```swift
public protocol ExternalRepositoryUseCase: Sendable {
    func repository(at url: ExternalRepositoryURL) async throws -> ExternalRepository
}

public struct ExternalRepositoryResolver: ExternalRepositoryUseCase {
    public init(lookup: any ExternalRepositoryLookup, locator: any ExternalRepositoryLocator)
}

public protocol ExternalRepositoryLocator: Sendable {
    func location(from url: ExternalRepositoryURL) -> ExternalRepositoryLocation?
}

public protocol ExternalRepositoryLookup: Sendable {
    func repository(owner: String, name: String) async throws -> ExternalRepository
}
```

| 모델 | 정의 |
| --- | --- |
| `ExternalRepository` | `canonicalURL: ExternalRepositoryURL`, `ownerName`, `repositoryName`, `imageURL: String?`, `starCount: Int`, `techStack: [String]` |
| `ExternalRepositoryLocation` | `owner: String`, `name: String` |
| `ExternalRepositoryError` | `invalidURLFormat`, `offline`, `other` |

## DomainQuizDetail (`Domain/QuizDetail/`)

```swift
public protocol QuizDetailUseCase: Sendable {
    func quizSet(_ setID: QuizSetID, in projectID: ProjectID) async throws -> QuizSet
    func grade(_ answer: ChoiceAnswer) async throws -> ChoiceGrading
    func grade(_ answer: EssayAnswer) async throws -> EssayGrading
    func bookmark(_ quizID: QuizID, in projectID: ProjectID) async throws -> QuizBookmarkState
    func unbookmark(_ quizID: QuizID, in projectID: ProjectID) async throws -> QuizBookmarkState
    func bookmarks(_ filter: QuizBookmarkFilter) async throws -> QuizBookmarkList
}

public actor QuizDetail: QuizDetailUseCase {
    public init(
        quizSetRepository: any QuizSetRepository,
        answerRepository: any AnswerRepository,
        bookmarkRepository: any BookmarkRepository,
    )
}

public protocol QuizSetRepository: Sendable {
    func quizSet(_ setID: QuizSetID, in projectID: ProjectID) async throws -> QuizSet
}

public protocol AnswerRepository: Sendable {
    func submit(_ answer: ChoiceAnswer) async throws -> ChoiceGrading
    func submit(_ answer: EssayAnswer) async throws -> EssayGrading
}

public protocol BookmarkRepository: Sendable {
    func setBookmark(_ quizID: QuizID, in projectID: ProjectID, isBookmarked: Bool) async throws -> QuizBookmarkState
    func bookmarks(_ filter: QuizBookmarkFilter) async throws -> QuizBookmarkList
}
```

| 모델 | 정의 |
| --- | --- |
| `QuizSet` | `id: QuizSetID`, `title`, `description`, `quizzes: [Quiz]` |
| `Quiz` | `id: QuizID`, `prompt: String`, `content: QuizContent`, `sources: [QuizSource]` |
| `QuizContent` | `enum { choice(options: [String], submitted: ChoiceSubmission?), essay(submitted: EssaySubmission?) }` |
| `ChoiceSubmission` | `selectedIndex: Int`, `isCorrect: Bool` |
| `EssaySubmission` | `text: String` |
| `QuizSource` | `filePath: String?`, `startLine: Int?`, `endLine: Int?`, `symbol: String?`, `summary: String?`, `referenceURL: String?` |
| `ChoiceAnswer` | `projectID: ProjectID`, `quizID: QuizID`, `selectedIndex: Int` |
| `ChoiceGrading` | `isCorrect: Bool`, `correctIndex: Int`, `explanation: String` |
| `EssayAnswer` | `projectID: ProjectID`, `quizID: QuizID`, `text: String` |
| `EssayGrading` | `explanation: String`, `rubric: [String]` |
| `QuizBookmarkState` | `quizID: QuizID`, `isBookmarked: Bool` |
| `QuizBookmarkFilter` | `enum { all, project(ProjectID) }` |
| `QuizBookmark` | `projectID`, `projectName`, `setID: QuizSetID`, `setLabel`, `problemNumber: Int`, `quizID: QuizID`, `prompt` |
| `QuizBookmarkProject` | `id: ProjectID`, `name: String` |
| `QuizBookmarkList` | `totalCount: Int`, `projects: [QuizBookmarkProject]`, `bookmarks: [QuizBookmark]` |
| `QuizDetailError` | `invalidAnswer`, `quizSetUnavailable`, `quizUnavailable`, `notFound`, `unauthorized`, `temporarilyUnavailable`, `unexpected` |

## DomainProject (`Domain/Project/`)

```swift
public protocol ProjectUseCase: Sendable {
    func projects() async -> AsyncStream<ProjectList>
    func refresh() async throws
    func requestNextPage() async throws
    func detail(of projectID: ProjectID) async throws -> ProjectDetail
    func delete(_ projectID: ProjectID) async throws
}

public actor Project: ProjectUseCase {
    public init(
        repository: any ProjectRepository,
        preparingProjectIDs: @escaping @Sendable () async -> AsyncStream<Set<ProjectID>>,
        signedOutEvents: @escaping @Sendable () async -> AsyncStream<Void>,
        pageSize: Int = 20,
    )
}

public protocol ProjectRepository: Sendable {
    func page(_ index: Int, size: Int) async throws -> ProjectPage
    func detail(of projectID: ProjectID) async throws -> ProjectDetail
    func delete(_ projectID: ProjectID) async throws
}
```

| 모델 | 정의 |
| --- | --- |
| `ProjectList` | `summaries: [ProjectSummary]`, `hasNextPage: Bool`, `isLoaded: Bool` |
| `ProjectPage` (계약 모델) | `summaries: [ProjectSummary]`, `hasNextPage: Bool` |
| `ProjectSummary` | `id: ProjectID`, `repositoryName`, `repositoryImageURL: String?`, `techStack: [String]`, `currentSet: ProjectSetLabel`, `next: ProjectNextQuiz?`, `progressPercent: Int` |
| `ProjectSetLabel` | `label: String`, `title: String` |
| `ProjectNextQuiz` | `setID: QuizSetID`, `quizID: QuizID?` |
| `ProjectDetail` | `id: ProjectID`, `repository: ProjectRepositoryInfo`, `progressPercent: Int`, `sets: [ProjectSetProgress]`, `next: ProjectNextQuiz?` |
| `ProjectRepositoryInfo` | `url: String`, `name: String`, `imageURL: String?`, `starCount: Int`, `techStack: [String]` |
| `ProjectSetProgress` | `setID: QuizSetID`, `label`, `title`, `quizCount: Int`, `completedCount: Int` |
| `ProjectError` | `invalidRequest`, `notFound`, `unauthorized`, `temporarilyUnavailable`, `unexpected` |

`ProjectDetail.next`는 어댑터가 현재 `LearningProjectDetail.nextSet`(미완료 첫 세트, 없으면 첫 세트)과 `nextQuestionID`로 만듭니다.

## DomainProjectGeneration (`Domain/ProjectGeneration/`)

```swift
public protocol ProjectGenerationUseCase: Sendable {
    func request(_ request: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt
    func states() async -> AsyncStream<ProjectGenerationState>
}

public actor ProjectGeneration: ProjectGenerationUseCase {
    public init(
        repository: any ProjectGenerationRepository,
        pendingGenerations: any PendingGenerationRepository,
        outcomes: any GenerationOutcomeRepository,
        reminderScheduler: any GenerationReminderScheduler,
        signedOutEvents: @escaping @Sendable () async -> AsyncStream<Void>,
        waitPolicy: GenerationWaitPolicy = .standard,
        now: @escaping @Sendable () -> Date = Date.init,
        sleep: @escaping @Sendable (TimeInterval) async throws -> Void = { try await Task.sleep(for: .seconds($0)) },
    )
}

public protocol ProjectGenerationRepository: Sendable {
    func register(_ request: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt
}

public protocol PendingGenerationRepository: Sendable {
    func pendingState() async -> GenerationState
    func pendingStateChanges() async -> AsyncStream<GenerationState>
    func beginGeneration(repositoryURL: ExternalRepositoryURL, requestedAt: Date) async -> Bool
    func attachProjectID(_ projectID: ProjectID, toRepositoryURL repositoryURL: ExternalRepositoryURL) async
    func finishGeneration(projectID: ProjectID, status: GenerationRecord.Status, finishedAt: Date) async
    func releaseGeneration(repositoryURL: ExternalRepositoryURL) async
    func releaseGeneration(projectID: ProjectID) async
    func releaseAll() async
    func enqueueReminder(projectID: ProjectID) async
    func drainReminderProjectIDs() async -> [ProjectID]
}

public protocol GenerationOutcomeRepository: Sendable {
    func outcomes() async -> AsyncStream<GenerationOutcome>
}

public protocol GenerationReminderScheduler: Sendable {
    func isAuthorized() async -> Bool
    func schedule(_ reminder: GenerationReminder, at date: Date) async
}
```

| 모델 | 정의 |
| --- | --- |
| `QuizLevel` | `enum { l1, l2, l3 }` |
| `ProjectGenerationRequest` | `repositoryURL: ExternalRepositoryURL`, `quizLevel: QuizLevel` |
| `ProjectGenerationReceipt` | `projectID: ProjectID`, `quizLevel: QuizLevel` |
| `ProjectGenerationPhase` | `enum { inProgress(readyAt: Date), preparing(readyAt: Date), ready, failed }` |
| `ProjectGenerationRequestState` | `repositoryURL: ExternalRepositoryURL`, `projectID: ProjectID?`, `requestedAt: Date`, `phase: ProjectGenerationPhase` |
| `ProjectGenerationState` | `requests: [ProjectGenerationRequestState]`, `preparingProjectIDs: Set<ProjectID>` |
| `GenerationWaitPolicy` | `minimumWait: TimeInterval`(300), `retentionLimit: TimeInterval`(3600), `static standard` |
| `GenerationRecord` (계약 모델) | 현재 타입과 같음 — `repositoryURL`(정규화), `projectID?`, `requestedAt`, `status: Status { inProgress, completed, failed }`, `finishedAt?` |
| `GenerationState` (계약 모델) | 현재 타입과 같음 — `records`와 상태 변환 함수 |
| `GenerationOutcome` (계약 모델) | `projectID: ProjectID`, `status: { completed, failed }` |
| `GenerationReminder` (계약 모델) | `projectID: ProjectID`, `kind: { completed, failed }` |
| `ProjectGenerationError` | `duplicateRequest`, `invalidRequest`, `unauthorized`, `temporarilyUnavailable`, `unexpected` |
