# Composition 패키지 타입 목록

[인덱스로 돌아가기](README.md) · [단어 사전](glossary.md)

타입 33개, 관심사 폴더 9개. 항목은 파일 경로와 선언 줄 순서다. 각 항목은 `이름` 종류 · 접근 수준 · 파일 링크, 한 줄 설명, 그리고 이름을 이루는 단어와 정의로 구성된다.

| 종류 | 개수 |
|---|---|
| actor | 1 |
| class | 1 |
| enum | 1 |
| struct | 29 |
| typealias | 1 |

## App/Assemblies

- **`AppComposition`** `struct` · public · [AppComposition.swift:18](../../../sources/Projects/Composition/App/Assemblies/AppComposition.swift#L18) · 채택: Sendable  
  앱 타깃의 GitItApp이 `AppComposition.live(_:secureStorage:transport:)`로 생성하는 최상위 조립 루트로, AuthenticationAssembly와 ConcernUseCaseAssembly가 만든 account·userInfo·appSetting·quizDetail·project·projectGeneration·externalRepository 7개 UseCase를 보유한다. 그 밖에 PushClientBox를 통해 푸시 클라이언트 활성화, AppDelegate 콜백 구성, 디바이스 토큰 갱신 스트림, 생성 결과 페이로드 수집, 공유 세션 상태 기록 클로저를 공개한다.  
  단어: `App` 응용 프로그램. 여기서는 공유 확장이 아닌 Git It iOS 앱 본체 타깃 · `Composition` 합성·조립. 여기서는 UseCase와 인프라 의존성을 한데 묶어 앱 타깃에 넘기는 조립 루트
- **`AppComposition.Environment`** `struct` · public · [AppComposition.swift:67](../../../sources/Projects/Composition/App/Assemblies/AppComposition.swift#L67) · 채택: Sendable  
  AppComposition.live에 전달하는 외부 설정 값 묶음으로 apiBaseURL, externalRepositoryBaseURL, appVersion, osVersion, 생성 완료·실패 알림의 제목·본문 4개 문자열, policyDocuments를 보유한다. GitItApp이 생성해 넘긴다.  
  단어(단일): `Environment` 환경. 여기서는 앱 실행 환경에서 주입되는 서버 URL·버전·알림 문구·정책 문서 설정 값
- **`AppComposition.PushClientBox`** `class` · private · [AppComposition.swift:161](../../../sources/Projects/Composition/App/Assemblies/AppComposition.swift#L161) · 채택: Sendable  
  Mutex로 보호되는 `RemoteMessageReceiver` 옵셔널을 담는 final class로, `activate()`가 처음 호출될 때만 NotificationFactory.remoteMessageReceiver()를 만들어 보관한다. AppComposition의 deviceToken·activatePushClient·deviceTokenRefreshes·forwardDeviceToken 클로저가 이 상자를 공유해 같은 클라이언트에 접근한다.  
  단어: `Push` 밀어 넣기. 여기서는 서버가 기기로 보내는 원격 푸시 알림 · `Client` 클라이언트. 여기서는 푸시 등록 토큰을 다루는 RemoteMessageReceiver 구현체 · `Box` 상자. 여기서는 여러 클로저가 참조를 공유하도록 값을 감싸는 참조 타입 컨테이너
- **`AppComposition.PushBootstrapError`** `enum` · private · [AppComposition.swift:182](../../../sources/Projects/Composition/App/Assemblies/AppComposition.swift#L182) · 채택: Error  
  PushClientBox가 아직 활성화되지 않은 상태에서 deviceToken 클로저가 호출되면 던지는 오류로, `notBootstrapped` 케이스 하나만 가진다.  
  단어: `Push` 밀어 넣기. 여기서는 원격 푸시 알림 클라이언트 · `Bootstrap` 초기 기동·부트스트랩. 여기서는 푸시 클라이언트의 최초 활성화 · `Error` 오류. 여기서는 활성화 전 토큰 요청이라는 실패 상태
- **`ConcernUseCaseAssembly`** `struct` · public · [ConcernUseCaseAssembly.swift:23](../../../sources/Projects/Composition/App/Assemblies/ConcernUseCaseAssembly.swift#L23) · 채택: Sendable  
  API·외부 저장소 baseURL, 정책 문서, 버전, RequestCredentialProvider, 보안·공유 저장소, 푸시 결과 소스 등을 받아 Remote·Store·Adapter를 조립하고 Account, UserInfo, AppSetting, ExternalRepositoryResolver, QuizDetail, ProjectGeneration, Project 7개 UseCase 구현체를 생성해 보유한다. AppComposition.live가 사용하며, SignInState 스트림을 로그아웃 이벤트로, ProjectGenerationState 스트림을 준비 중 프로젝트 ID 집합으로 바꾸는 정적 함수도 제공한다.  
  단어: `Concern` 관심사. 여기서는 Account·UserInfo·AppSetting·QuizDetail·Project 등 Domain 관심사 단위 · `UseCase` Use + Case, 사용 사례. 여기서는 Domain 패키지가 공개하는 UseCase 프로토콜의 구현체 · `Assembly` 조립체. 여기서는 의존성을 생성·연결해 묶어 둔 결과 구조체
- **`ConcernUseCaseAssembly.GenerationReminderContent`** `struct` · public · [ConcernUseCaseAssembly.swift:185](../../../sources/Projects/Composition/App/Assemblies/ConcernUseCaseAssembly.swift#L185) · 채택: Sendable  
  퀴즈 생성 완료·실패 로컬 알림에 쓸 completedTitle, completedBody, failedTitle, failedBody 네 문자열을 보유한다. AppComposition.live가 Environment 값으로 만들어 ConcernUseCaseAssembly에 넘기고, GenerationReminderSchedulerAdapter 생성에 쓰인다.  
  단어: `Generation` 생성. 여기서는 프로젝트의 퀴즈를 만드는 서버 생성 작업 · `Reminder` 알림·리마인더. 여기서는 생성 결과를 알리는 로컬 알림 · `Content` 내용. 여기서는 알림의 제목·본문 문자열

## App/Factories

- **`PushNotificationAppDelegate`** `typealias` · public · [PushNotificationAppDelegate.swift:5](../../../sources/Projects/Composition/App/Factories/PushNotificationAppDelegate.swift#L5) · 그래프 미수집(grep 보강)  
  DataNotification의 `NotificationAppDelegate`(NSObject, UIApplicationDelegate 클래스)를 가리키는 public typealias다. GitItApp이 `@UIApplicationDelegateAdaptor(PushNotificationAppDelegate.self)`로 사용하고 AppComposition.configureAppDelegate 클로저의 매개변수 타입이다.  
  단어: `Push` 밀어 넣기. 여기서는 원격 푸시 알림 · `Notification` 알림. 여기서는 디바이스 토큰과 원격 메시지를 받는 알림 처리 · `App` 응용 프로그램. 여기서는 UIApplication · `Delegate` 위임자. 여기서는 UIApplicationDelegate 구현 클래스

## Authentication/Adapters

- **`AuthenticationRepositoryAdapter`** `actor` · public · [AuthenticationRepositoryAdapter.swift:8](../../../sources/Projects/Composition/Authentication/Adapters/AuthenticationRepositoryAdapter.swift#L8) · 채택: DomainAccount.AuthenticationRepository  
  `AppleSignInSource`와 보안 저장소 기반 `AppleIdentityStore`를 감싸 Domain의 AuthenticationRepository를 구현하는 actor다. Apple 로그인으로 AuthenticationGrant를 얻으며 사용자 ID를 저장하고, 저장된 ID의 인증 상태를 SignInVerification으로 조회하며, 삭제 시 SecureValueStorageError와 AppleSignInError를 AccountError로 변환한다.  
  단어: `Authentication` 인증. 여기서는 Apple 계정으로 사용자의 신원을 확인하는 절차 · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 AuthenticationRepository · `Adapter` 어댑터. 여기서는 Data 계층 타입을 Domain 프로토콜에 맞게 변환하는 구현체
- **`PolicyConsentRepositoryAdapter`** `struct` · public · [PolicyConsentRepositoryAdapter.swift:7](../../../sources/Projects/Composition/Authentication/Adapters/PolicyConsentRepositoryAdapter.swift#L7) · 채택: PolicyConsentRepository  
  `LocalPolicyConsentStore`를 감싸 PolicyConsentRepository를 구현하며, PolicyConsentRecordDTO와 Domain의 PolicyConsent(documentID, version, consentedAt)를 상호 변환해 동의 기록을 조회·저장·전체 삭제한다. ConcernUseCaseAssembly가 Account UseCase에 주입한다.  
  단어: `Policy` 정책. 여기서는 약관·개인정보 처리방침 같은 법적 정책 문서 · `Consent` 동의. 여기서는 사용자가 정책 문서 버전에 동의한 기록 · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 PolicyConsentRepository · `Adapter` 어댑터. 여기서는 로컬 Store를 Domain 프로토콜에 맞게 변환하는 구현체
- **`SignInRepositoryAdapter`** `struct` · public · [SignInRepositoryAdapter.swift:8](../../../sources/Projects/Composition/Authentication/Adapters/SignInRepositoryAdapter.swift#L8) · 채택: SignInRepository  
  `AuthenticationRemote`, 세션·Apple 신원 보안 저장소, RequestCredentialProvider, SharedSessionStateMarkerCoding을 묶어 SignInRepository를 구현한다. Apple ID 토큰으로 서버 로그인을 시작해 StoredSessionRecord를 저장하고 SignInRecord를 돌려주며, 세션 복원·로그아웃·공유 로그인 상태 조회·자격 증명 유효 여부 확인을 담당하고 AuthenticationServiceError를 AccountError로 변환한다.  
  단어: `SignIn` Sign + In, 로그인. 여기서는 서버 세션을 여는 로그인 절차 · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 SignInRepository · `Adapter` 어댑터. 여기서는 Remote와 보안 저장소를 Domain 프로토콜에 맞게 변환하는 구현체

## Authentication/Assemblies

- **`AuthenticationAssembly`** `struct` · public · [AuthenticationAssembly.swift:7](../../../sources/Projects/Composition/Authentication/Assemblies/AuthenticationAssembly.swift#L7) · 채택: Sendable  
  세션 보안 저장소로 `RequestCredentialProvider`를 만들어 보유하고, 공유 저장소 기반 SharedSessionStateMarkerCoding에 현재 자격 증명의 로그인 여부를 기록하는 `recordSharedSessionState` 클로저를 제공한다. AppComposition.live가 생성해 requestCredentialProvider를 ConcernUseCaseAssembly에 넘긴다.  
  단어: `Authentication` 인증. 여기서는 세션 자격 증명과 로그인 상태를 다루는 관심사 · `Assembly` 조립체. 여기서는 자격 증명 공급자와 상태 기록 클로저를 만들어 묶은 결과 구조체
- **`SessionAvailabilityAssembly`** `struct` · public · [SessionAvailabilityAssembly.swift:8](../../../sources/Projects/Composition/Authentication/Assemblies/SessionAvailabilityAssembly.swift#L8) · 채택: Sendable  
  세션 보안 저장소로 `RequestCredentialProvider`를 만들어 보유하고, 공유 로그인 마커와 자격 증명을 함께 검사해 SignInAvailability(appLaunchRequired·signInRequired·signedIn)를 돌려주는 `signInAvailability` 클로저를 제공한다. ShareExtensionComposition.live가 사용한다.  
  단어: `Session` 세션. 여기서는 로그인 후 보안 저장소에 유지되는 인증 세션 · `Availability` 가용성. 여기서는 공유 확장이 세션을 사용할 수 있는지에 대한 상태 판정 · `Assembly` 조립체. 여기서는 자격 증명 공급자와 가용성 판정 클로저를 묶은 결과 구조체

## LearningProject/Adapters

- **`ExternalRepositoryLocatorAdapter`** `struct` · public · [ExternalRepositoryLocatorAdapter.swift:7](../../../sources/Projects/Composition/LearningProject/Adapters/ExternalRepositoryLocatorAdapter.swift#L7) · 채택: DomainExternalRepository.ExternalRepositoryLocator  
  `GitHubRepositoryURLParser`를 감싸 ExternalRepositoryLocator를 구현하며, ExternalRepositoryURL을 파싱한 결과를 Domain의 ExternalRepositoryLocation(owner, name)으로 변환한다. ConcernUseCaseAssembly와 ExternalRepositoryAssembly가 생성해 ExternalRepositoryResolver에 주입하고, ShareExtensionComposition은 parseRepositoryLink로 공개한다.  
  단어: `External` 외부. 여기서는 앱 서버가 아닌 외부 서비스(GitHub) · `Repository` 저장소. 여기서는 데이터 접근 계약이 아니라 GitHub의 Git 코드 저장소 · `Locator` 위치 탐색기. 여기서는 URL에서 저장소 소유자·이름을 추출하는 역할 · `Adapter` 어댑터. 여기서는 Data의 URL 파서를 Domain 프로토콜에 맞게 변환하는 구현체
- **`ExternalRepositoryLookupAdapter`** `struct` · public · [ExternalRepositoryLookupAdapter.swift:6](../../../sources/Projects/Composition/LearningProject/Adapters/ExternalRepositoryLookupAdapter.swift#L6) · 채택: DomainExternalRepository.ExternalRepositoryLookup  
  `ExternalRepositoryRemote`를 감싸 ExternalRepositoryLookup을 구현하며, owner·name으로 GitHub 저장소 정보를 조회해 Domain ExternalRepository(canonicalURL, ownerName, repositoryName, imageURL, starCount, techStack)로 변환하고 ExternalRepositoryFetchError를 ExternalRepositoryError(offline·other)로 바꾼다.  
  단어: `External` 외부. 여기서는 앱 서버가 아닌 외부 서비스(GitHub) · `Repository` 저장소. 여기서는 GitHub의 Git 코드 저장소 · `Lookup` 조회. 여기서는 원격 API로 저장소 정보를 찾아오는 역할 · `Adapter` 어댑터. 여기서는 Data Remote를 Domain 프로토콜에 맞게 변환하는 구현체
- **`GenerationOutcomeRepositoryAdapter`** `struct` · public · [GenerationOutcomeRepositoryAdapter.swift:6](../../../sources/Projects/Composition/LearningProject/Adapters/GenerationOutcomeRepositoryAdapter.swift#L6) · 채택: GenerationOutcomeRepository  
  `QuizGenerationOutcomeSource`가 내보내는 QuizGenerationOutcomeDTO 스트림을 Domain GenerationOutcome(projectID, completed·failed) AsyncStream으로 변환해 GenerationOutcomeRepository를 구현한다. ConcernUseCaseAssembly와 LearningProjectAssembly가 ProjectGeneration UseCase의 outcomes로 주입한다.  
  단어: `Generation` 생성. 여기서는 프로젝트의 퀴즈를 만드는 서버 생성 작업 · `Outcome` 결과. 여기서는 푸시 페이로드로 전달되는 생성 완료·실패 결과 · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 GenerationOutcomeRepository · `Adapter` 어댑터. 여기서는 Data의 결과 소스를 Domain 프로토콜에 맞게 변환하는 구현체
- **`GenerationReminderSchedulerAdapter`** `struct` · public · [GenerationReminderSchedulerAdapter.swift:7](../../../sources/Projects/Composition/LearningProject/Adapters/GenerationReminderSchedulerAdapter.swift#L7) · 채택: GenerationReminderScheduler  
  `LocalReminderNotifier`와 완료·실패 알림의 제목·본문 문자열을 보유하고 GenerationReminderScheduler를 구현한다. 알림 권한 여부를 조회하고, GenerationReminder를 kind별 식별자(generation-completed-/generation-failed-)와 제목·본문을 가진 ReminderNotification으로 바꿔 지정 시각에 예약한다.  
  단어: `Generation` 생성. 여기서는 프로젝트의 퀴즈 생성 작업 · `Reminder` 알림·리마인더. 여기서는 생성 완료·실패를 알리는 로컬 알림 · `Scheduler` 예약자. 여기서는 로컬 알림을 특정 시각에 예약하는 역할 · `Adapter` 어댑터. 여기서는 Data의 알림 발송기를 Domain 프로토콜에 맞게 변환하는 구현체
- **`NotificationAuthorizationAdapter`** `struct` · public · [NotificationAuthorizationAdapter.swift:6](../../../sources/Projects/Composition/LearningProject/Adapters/NotificationAuthorizationAdapter.swift#L6) · 채택: NotificationAuthorization  
  `LocalReminderNotifier`의 권한 설정 조회와 권한 요청 결과를 Domain NotificationAuthorizationStatus(notDetermined·authorized·denied)로 변환해 NotificationAuthorization을 구현한다. ConcernUseCaseAssembly가 AppSetting UseCase에 주입한다.  
  단어: `Notification` 알림. 여기서는 기기의 로컬 리마인더 알림 · `Authorization` 권한 부여. 여기서는 사용자가 알림을 허용했는지에 대한 권한 상태 · `Adapter` 어댑터. 여기서는 Data의 알림 발송기 권한 API를 Domain 프로토콜에 맞게 변환하는 구현체
- **`PendingGenerationRepositoryAdapter`** `struct` · public · [PendingGenerationRepositoryAdapter.swift:8](../../../sources/Projects/Composition/LearningProject/Adapters/PendingGenerationRepositoryAdapter.swift#L8) · 채택: PendingGenerationRepository  
  `LocalPendingGenerationStore`, GenerationWaitPolicy, 현재 시각 클로저를 보유하고 PendingGenerationRepository를 구현한다. GenerationStateDTO·GenerationRecordDTO와 Domain GenerationState·GenerationRecord를 상호 변환하고 보존 기한이 지난 레코드를 걸러내며, 생성 시작·프로젝트 ID 연결·완료·해제와 리마인더 프로젝트 ID 적재·배출을 store에 위임한다.  
  단어: `Pending` 보류·진행 중. 여기서는 아직 끝나지 않아 기기에 기록해 둔 퀴즈 생성 요청 · `Generation` 생성. 여기서는 프로젝트의 퀴즈 생성 작업 · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 PendingGenerationRepository · `Adapter` 어댑터. 여기서는 로컬 Store를 Domain 프로토콜에 맞게 변환하는 구현체
- **`ProjectGenerationRepositoryAdapter`** `struct` · public · [ProjectGenerationRepositoryAdapter.swift:6](../../../sources/Projects/Composition/LearningProject/Adapters/ProjectGenerationRepositoryAdapter.swift#L6) · 채택: ProjectGenerationRepository  
  `ProjectRemote`를 감싸 ProjectGenerationRepository를 구현하며, ProjectGenerationRequest(repositoryURL, quizLevel)를 RegisterProjectRequestDTO로 바꿔 프로젝트 등록을 요청하고 응답 projectID로 ProjectGenerationReceipt를 만든다. LearningProjectServiceError를 ProjectGenerationError로 변환한다.  
  단어: `Project` 프로젝트. 여기서는 GitHub 저장소 하나로 만든 학습 프로젝트 · `Generation` 생성. 여기서는 프로젝트를 서버에 등록해 퀴즈 생성을 시작하는 작업 · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 ProjectGenerationRepository · `Adapter` 어댑터. 여기서는 Data Remote를 Domain 프로토콜에 맞게 변환하는 구현체
- **`ProjectRepositoryAdapter`** `struct` · public · [ProjectRepositoryAdapter.swift:7](../../../sources/Projects/Composition/LearningProject/Adapters/ProjectRepositoryAdapter.swift#L7) · 채택: ProjectRepository  
  `ProjectRemote`를 감싸 ProjectRepository를 구현하며 프로젝트 목록 페이지·상세·삭제를 요청한다. ProjectListItemDTO를 ProjectSummary로, 상세 응답을 ProjectDetail·ProjectRepositoryInfo·ProjectSetProgress·ProjectNextQuiz로 변환하고 LearningProjectServiceError를 ProjectError로 바꾼다.  
  단어: `Project` 프로젝트. 여기서는 GitHub 저장소 하나로 만든 학습 프로젝트 · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 ProjectRepository · `Adapter` 어댑터. 여기서는 Data Remote를 Domain 프로토콜에 맞게 변환하는 구현체
- **`QuizAnswerRepositoryAdapter`** `struct` · public · [QuizAnswerRepositoryAdapter.swift:6](../../../sources/Projects/Composition/LearningProject/Adapters/QuizAnswerRepositoryAdapter.swift#L6) · 채택: AnswerRepository  
  `AnswerRemote`를 감싸 AnswerRepository를 구현하며, ChoiceAnswer·EssayAnswer를 SubmitChoiceAnswerRequestDTO·SubmitEssayAnswerRequestDTO로 바꿔 제출하고 응답을 ChoiceGrading·EssayGrading으로 변환한다. LearningProjectServiceError를 QuizDetailError로 바꾼다.  
  단어: `Quiz` 퀴즈. 여기서는 학습 세트에 속한 문제 하나 · `Answer` 답변. 여기서는 사용자가 제출한 선택형·서술형 답 · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 AnswerRepository · `Adapter` 어댑터. 여기서는 Data Remote를 Domain 프로토콜에 맞게 변환하는 구현체
- **`QuizBookmarkRepositoryAdapter`** `struct` · public · [QuizBookmarkRepositoryAdapter.swift:7](../../../sources/Projects/Composition/LearningProject/Adapters/QuizBookmarkRepositoryAdapter.swift#L7) · 채택: BookmarkRepository  
  `BookmarkRemote`를 감싸 BookmarkRepository를 구현하며, 퀴즈 북마크 설정 응답을 QuizBookmarkState로, 북마크 목록 응답을 QuizBookmarkList(totalCount, projects, bookmarks)로 변환한다. QuizBookmarkFilter(all·project)를 projectID 옵셔널로 바꾸고 LearningProjectServiceError를 QuizDetailError로 변환한다.  
  단어: `Quiz` 퀴즈. 여기서는 학습 세트에 속한 문제 하나 · `Bookmark` 북마크. 여기서는 다시 볼 퀴즈에 남기는 표시 · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 BookmarkRepository · `Adapter` 어댑터. 여기서는 Data Remote를 Domain 프로토콜에 맞게 변환하는 구현체
- **`QuizSetRepositoryAdapter`** `struct` · public · [QuizSetRepositoryAdapter.swift:7](../../../sources/Projects/Composition/LearningProject/Adapters/QuizSetRepositoryAdapter.swift#L7) · 채택: QuizSetRepository  
  `LearningSetRemote`를 감싸 QuizSetRepository를 구현하며 학습 세트 응답을 Domain QuizSet으로 변환한다. QuestionResponseDTO의 format에 따라 essay·choice QuizContent와 제출 기록(EssaySubmission·ChoiceSubmission), SourceResponseDTO의 QuizSource를 만들고 LearningProjectServiceError를 QuizDetailError로 바꾼다.  
  단어: `Quiz` 퀴즈. 여기서는 학습 세트에 속한 문제 하나 · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(학습 세트) · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 QuizSetRepository · `Adapter` 어댑터. 여기서는 Data Remote를 Domain 프로토콜에 맞게 변환하는 구현체

## LearningProject/Assemblies

- **`ExternalRepositoryAssembly`** `struct` · public · [ExternalRepositoryAssembly.swift:8](../../../sources/Projects/Composition/LearningProject/Assemblies/ExternalRepositoryAssembly.swift#L8) · 채택: Sendable  
  외부 저장소 API baseURL·transport·responseTimeout으로 ExternalRepositoryRemote, ExternalRepositoryLookupAdapter, ExternalRepositoryLocatorAdapter를 조립해 ExternalRepositoryResolver(ExternalRepositoryUseCase)와 locator를 보유한다. ShareExtensionComposition.live가 사용한다.  
  단어: `External` 외부. 여기서는 앱 서버가 아닌 외부 서비스(GitHub) · `Repository` 저장소. 여기서는 GitHub의 Git 코드 저장소 · `Assembly` 조립체. 여기서는 외부 저장소 조회·URL 파싱 의존성을 묶은 결과 구조체
- **`LearningProjectAssembly`** `struct` · public · [LearningProjectAssembly.swift:9](../../../sources/Projects/Composition/LearningProject/Assemblies/LearningProjectAssembly.swift#L9) · 채택: Sendable  
  API baseURL·자격 증명 클로저·알림 문구·알림 발송기·푸시 결과 소스·공유 저장소로 ProjectRemote, PendingGenerationRepositoryAdapter, GenerationOutcomeRepositoryAdapter, GenerationReminderSchedulerAdapter를 조립해 ProjectGeneration UseCase와 푸시 페이로드 수집 클로저 `ingestGenerationOutcomePayload`를 보유한다. ShareExtensionComposition.live가 사용한다.  
  단어: `Learning` 학습. 여기서는 저장소 코드를 퀴즈로 학습하는 활동 · `Project` 프로젝트. 여기서는 GitHub 저장소 하나로 만든 학습 프로젝트 · `Assembly` 조립체. 여기서는 프로젝트 생성 관련 의존성을 묶은 결과 구조체
- **`LearningProjectAssembly.GenerationReminderContent`** `struct` · public · [LearningProjectAssembly.swift:60](../../../sources/Projects/Composition/LearningProject/Assemblies/LearningProjectAssembly.swift#L60) · 채택: Sendable  
  생성 완료·실패 알림의 completedTitle, completedBody, failedTitle, failedBody를 보유하며 모두 빈 문자열 기본값을 가진다. LearningProjectAssembly의 reminderContent 매개변수 타입이며 ConcernUseCaseAssembly.GenerationReminderContent와 같은 필드 구성이다.  
  단어: `Generation` 생성. 여기서는 프로젝트의 퀴즈를 만드는 서버 생성 작업 · `Reminder` 알림·리마인더. 여기서는 생성 결과를 알리는 로컬 알림 · `Content` 내용. 여기서는 알림의 제목·본문 문자열

## Member/Adapters

- **`DeviceIdentifierRepositoryAdapter`** `struct` · public · [DeviceIdentifierRepositoryAdapter.swift:7](../../../sources/Projects/Composition/Member/Adapters/DeviceIdentifierRepositoryAdapter.swift#L7) · 채택: DeviceIdentifierRepository  
  보안 저장소로 `LocalDeviceIdentifierStore`를 만들어 DeviceIdentifierRepository를 구현하며, 저장된 DeviceID를 읽거나 없으면 새로 만들어 돌려준다. ConcernUseCaseAssembly가 AppSetting UseCase에 주입한다.  
  단어: `Device` 기기. 여기서는 앱이 설치된 iOS 기기 · `Identifier` 식별자. 여기서는 기기를 구분하는 DeviceID · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 DeviceIdentifierRepository · `Adapter` 어댑터. 여기서는 로컬 Store를 Domain 프로토콜에 맞게 변환하는 구현체
- **`DeviceRegistrationRepositoryAdapter`** `struct` · public · [DeviceRegistrationRepositoryAdapter.swift:6](../../../sources/Projects/Composition/Member/Adapters/DeviceRegistrationRepositoryAdapter.swift#L6) · 채택: DeviceRegistrationRepository  
  `MemberRemote`를 감싸 DeviceRegistrationRepository를 구현하며, DeviceRegistration을 DeviceInfoRequestDTO(deviceID, deviceType "ios", appVersion, osVersion, deviceToken)로 바꿔 서버에 등록하고 MemberServiceError를 AppSettingError로 변환한다. ConcernUseCaseAssembly가 AppSetting UseCase에 주입한다.  
  단어: `Device` 기기. 여기서는 앱이 설치된 iOS 기기 · `Registration` 등록. 여기서는 기기 정보와 푸시 토큰을 서버 회원에 등록하는 것 · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 DeviceRegistrationRepository · `Adapter` 어댑터. 여기서는 Data Remote를 Domain 프로토콜에 맞게 변환하는 구현체
- **`UserInfoRepositoryAdapter`** `struct` · public · [UserInfoRepositoryAdapter.swift:8](../../../sources/Projects/Composition/Member/Adapters/UserInfoRepositoryAdapter.swift#L8) · 채택: UserInfoRepository  
  `MemberRemote`와 세션 보안 저장소 기반 SessionRecordStorageCoding을 보유하고 UserInfoRepository를 구현한다. 프로필 응답을 UserProfile(UserDetail·LearningStatistics·Curation)로 변환하고 큐레이션·포지션·경력 갱신을 요청하며, 큐레이션 완료 시 세션 레코드의 needsCuration을 false로 갱신하고 MemberServiceError를 UserInfoError로 바꾼다.  
  단어: `User` 사용자. 여기서는 로그인한 회원 · `Info` Information의 축약, 정보. 여기서는 회원의 프로필·학습 통계·큐레이션 정보 · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 UserInfoRepository · `Adapter` 어댑터. 여기서는 Data Remote와 세션 저장소를 Domain 프로토콜에 맞게 변환하는 구현체
- **`WithdrawalRepositoryAdapter`** `struct` · public · [WithdrawalRepositoryAdapter.swift:6](../../../sources/Projects/Composition/Member/Adapters/WithdrawalRepositoryAdapter.swift#L6) · 채택: WithdrawalRepository  
  `MemberRemote`를 감싸 WithdrawalRepository를 구현하며 회원 탈퇴를 요청하고 MemberServiceError를 AccountError(unauthorized·withdrawalUnavailable·temporarilyUnavailable)로 변환한다. ConcernUseCaseAssembly가 Account UseCase에 주입한다.  
  단어: `Withdrawal` 탈퇴·철회. 여기서는 서버 회원 탈퇴 · `Repository` 저장소. 여기서는 Domain이 정의한 데이터 접근 계약 WithdrawalRepository · `Adapter` 어댑터. 여기서는 Data Remote를 Domain 프로토콜에 맞게 변환하는 구현체

## Member/Assemblies

- **`MemberAssembly`** `struct` · public · [MemberAssembly.swift:9](../../../sources/Projects/Composition/Member/Assemblies/MemberAssembly.swift#L9) · 채택: Sendable  
  API baseURL·자격 증명 클로저·보안 저장소·transport로 MemberRemote와 UserInfoRepositoryAdapter를 조립해 UserInfo UseCase를 보유한다. 저장소 내 다른 소스나 테스트에서 이 타입을 참조하는 곳은 없다.  
  단어: `Member` 회원. 여기서는 서버의 회원(member) API 관심사 · `Assembly` 조립체. 여기서는 회원 정보 의존성을 묶은 결과 구조체

## ShareExtension/Assemblies

- **`ShareExtensionComposition`** `struct` · public · [ShareExtensionComposition.swift:13](../../../sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift#L13) · 채택: Sendable  
  공유 확장 타깃의 ShareViewController가 `live(_:secureStorage:sharedStorage:reminderNotifier:transport:)`로 생성하는 조립 루트로, SessionAvailabilityAssembly·ExternalRepositoryAssembly·LearningProjectAssembly를 조합한다. parseRepositoryLink(ExternalRepositoryLocator), externalRepository·projectGeneration UseCase, signInAvailability 클로저를 보유한다.  
  단어: `Share` 공유. 여기서는 iOS 공유 시트로 URL을 넘겨받는 기능 · `Extension` 확장. 여기서는 iOS App Extension(Share Extension) 타깃 · `Composition` 합성·조립. 여기서는 공유 확장 타깃용 의존성 조립 루트
- **`ShareExtensionComposition.Environment`** `struct` · public · [ShareExtensionComposition.swift:30](../../../sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift#L30) · 채택: Sendable  
  ShareExtensionComposition.live에 전달하는 설정 값으로 apiBaseURL과 externalRepositoryBaseURL 두 URL을 보유한다. ShareViewController가 생성해 넘긴다.  
  단어(단일): `Environment` 환경. 여기서는 공유 확장 실행 환경에서 주입되는 서버 URL 설정 값
