# App 패키지 타입 목록

[인덱스로 돌아가기](README.md) · [단어 사전](glossary.md)

타입 32개, 관심사 폴더 7개. 항목은 파일 경로와 선언 줄 순서다. 각 항목은 `이름` 종류 · 접근 수준 · 파일 링크, 한 줄 설명, 그리고 이름을 이루는 단어와 정의로 구성된다.

| 종류 | 개수 |
|---|---|
| class | 1 |
| enum | 14 |
| protocol | 1 |
| struct | 16 |

## GitIt/Configurations

- **`AppBundleMetadata`** `enum` · internal · [AppBundleMetadata.swift:3](../../../sources/Projects/App/GitIt/Configurations/AppBundleMetadata.swift#L3) · 채택: String  
  메인 번들 Info.plist 키를 rawValue로 갖는 열거형으로, 현재 shortVersion(CFBundleShortVersionString) 하나를 정의하고 value가 Bundle.main에서 그 문자열을 읽어 없으면 "0.0.0"을 돌려준다. GitItApp이 앱 버전(bundleVersion)을 얻을 때 사용한다.  
  단어: `App` 응용 프로그램. 여기서는 GitIt 앱 자신(Bundle.main) · `Bundle` 묶음·번들. 여기서는 앱 실행 파일과 Info.plist를 담은 Foundation Bundle · `Metadata` 데이터를 설명하는 데이터. 여기서는 Info.plist에 기록된 버전 등 앱 설명 정보
- **`AppBundleResource`** `enum` · internal · [AppBundleResource.swift:3](../../../sources/Projects/App/GitIt/Configurations/AppBundleResource.swift#L3) · 채택: String  
  앱 번들에 동봉된 리소스 파일 이름을 rawValue로 갖는 열거형으로, 현재 policyManifest("policy-manifest") 하나만 정의한다. PolicyManifestLoader.loadPolicyDocuments의 기본 resourceName으로 사용된다.  
  단어: `App` 응용 프로그램. 여기서는 GitIt 앱 자신 · `Bundle` 묶음·번들. 여기서는 리소스 파일을 담은 앱 번들 · `Resource` 자원. 여기서는 번들에 포함된 JSON 등 리소스 파일의 이름
- **`AppEndpointHost`** `enum` · internal · [AppEndpointHost.swift:3](../../../sources/Projects/App/GitIt/Configurations/AppEndpointHost.swift#L3) · 채택: String  
  Info.plist 키 GIT_IT_API_HOST·GIT_IT_EXTERNAL_REPOSITORY_HOST를 rawValue로 갖는 열거형(api, externalRepository)으로, url이 호스트 문자열을 읽어 https URL을 만들고 없으면 fatalError로 종료한다. GitItApp이 AppComposition.Environment의 apiBaseURL과 externalRepositoryBaseURL을 만들 때 사용한다.  
  단어: `App` 응용 프로그램. 여기서는 메인 앱 타깃(ShareExtensionEndpointHost와 구분) · `Endpoint` 종단점. 여기서는 API 서버와 외부 저장소 서버의 접속 지점 · `Host` 호스트. 여기서는 URL의 호스트(도메인) 부분, Info.plist에서 읽는 서버 주소

## GitIt

- **`GenerationReminderContent`** `enum` · internal · [GenerationReminderContent.swift:3](../../../sources/Projects/App/GitIt/GenerationReminderContent.swift#L3)  
  학습 세트 생성 완료·실패 알림 문구(title, body, failureTitle, failureBody)를 정적 문자열 상수로 갖는 네임스페이스 열거형이다. GitItApp이 AppComposition.Environment의 generationReminder·generationFailureReminder 제목과 본문으로 넘긴다.  
  단어: `Generation` 생성. 여기서는 프로젝트에서 학습 세트를 만드는 작업 · `Reminder` 알림·상기. 여기서는 생성 결과를 사용자에게 알리는 알림 · `Content` 내용. 여기서는 알림의 제목과 본문 문자열
- **`GitItApp`** `struct` · internal · [GitItApp.swift:10](../../../sources/Projects/App/GitIt/GitItApp.swift#L10) · 채택: App  
  @main 진입점인 SwiftUI App 구조체다. init에서 PolicyManifestLoader·AppBundleMetadata·AppEndpointHost·GenerationReminderContent로 AppComposition.live를 만들고 AppRootFeature Store를 구성하며, body에서 AppRootView를 띄우고 .task로 AppLaunchSequence를 실행하고 scenePhase가 active가 되면 view(.applicationBecameActive)를 보낸다. PushNotificationAppDelegate를 UIApplicationDelegateAdaptor로 연결한다.  
  단어: `GitIt` Git + It, 이 서비스의 제품명(고유 명칭) · `App` 응용 프로그램. 여기서는 SwiftUI App 프로토콜을 채택한 앱 진입 타입

## GitIt/Launch

- **`AppLaunchSequence`** `struct` · internal · [AppLaunchSequence.swift:3](../../../sources/Projects/App/GitIt/Launch/AppLaunchSequence.swift#L3) · 채택: Sendable  
  앱 시작 시 실행할 세 클로저(recordSharedSessionState, activatePushClient, configureAppDelegate)를 생성자로 주입받아 callAsFunction에서 그 순서대로 실행하는 Sendable 구조체다. GitItApp의 .task 안에서 한 번 호출된다.  
  단어: `App` 응용 프로그램. 여기서는 GitIt 앱 프로세스 · `Launch` 시작·기동. 여기서는 앱이 시작된 직후의 초기화 단계 · `Sequence` 순서·연속. 여기서는 정해진 순서로 실행되는 시작 작업 묶음

## GitIt/Loaders

- **`PolicyManifestLoader`** `enum` · internal · [PolicyManifestLoader.swift:6](../../../sources/Projects/App/GitIt/Loaders/PolicyManifestLoader.swift#L6)  
  번들의 policy-manifest JSON을 읽어 각 항목의 approvedURL이 https인지 검증한 뒤 DomainAccount의 PolicyDocument 배열로 변환하는 정적 함수 loadPolicyDocuments(resourceName:bundle:)를 제공하는 네임스페이스 열거형이다. LoadError, Manifest, Entry를 중첩 타입으로 갖고 GitItApp.init에서 호출된다.  
  단어: `Policy` 정책. 여기서는 사용자 동의가 필요한 약관·정책 문서 · `Manifest` 목록·명세서. 여기서는 정책 문서 목록을 기술한 JSON 리소스 · `Loader` 적재기. 여기서는 번들 리소스를 읽어 도메인 모델로 바꾸는 역할
- **`PolicyManifestLoader.LoadError`** `enum` · internal · [PolicyManifestLoader.swift:10](../../../sources/Projects/App/GitIt/Loaders/PolicyManifestLoader.swift#L10) · 채택: Error, Equatable  
  PolicyManifestLoader.loadPolicyDocuments가 던지는 오류로, 번들에 리소스가 없을 때(resourceMissing)와 항목의 approvedURL이 URL이 아니거나 https가 아닐 때(invalidApprovedURL(identifier:))를 구분한다.  
  단어: `Load` 적재·읽기. 여기서는 정책 매니페스트를 읽어 변환하는 작업 · `Error` 오류. 여기서는 그 작업이 실패한 이유
- **`PolicyManifestLoader.Manifest`** `struct` · private · [PolicyManifestLoader.swift:44](../../../sources/Projects/App/GitIt/Loaders/PolicyManifestLoader.swift#L44) · 채택: Decodable  
  policy-manifest JSON의 루트 객체를 나타내는 private Decodable 구조체로, documents: [Entry] 하나만 갖는다. PolicyManifestLoader 내부의 JSONDecoder 디코딩 전용 모델이다.  
  단어(단일): `Manifest` 목록·명세서. 여기서는 정책 문서 목록 JSON의 루트 디코딩 모델
- **`PolicyManifestLoader.Entry`** `struct` · private · [PolicyManifestLoader.swift:48](../../../sources/Projects/App/GitIt/Loaders/PolicyManifestLoader.swift#L48) · 채택: Decodable  
  policy-manifest JSON의 문서 항목 하나를 나타내는 private Decodable 구조체로 identifier, displayName, version, approvedURL(문자열), isRequired를 갖는다. loadPolicyDocuments에서 검증을 거쳐 PolicyDocument로 변환된다.  
  단어(단일): `Entry` 항목. 여기서는 매니페스트 documents 배열의 원소 하나(정책 문서 한 건)

## GitIt/Reducers

- **`AppRootFeature`** `struct` · internal · [AppRootFeature.swift:15](../../../sources/Projects/App/GitIt/Reducers/AppRootFeature.swift#L15) · 채택: Sendable  
  @Reducer를 적용한 앱 최상위 TCA 리듀서(nonisolated struct)다. Account·UserInfo·AppSetting·ExternalRepository·QuizDetail·Project·ProjectGeneration UseCase와 openNotificationSettings·openExternalURL·deviceTokenRefreshes 클로저를 생성자 주입받아 AppEntryFeature·OnboardingRouterFeature·MainShellRouterFeature를 Scope로 합성하고, route 전환, 기기 등록, 디바이스 토큰 갱신, 프로젝트 생성 상태 관찰, ProjectRegistration·ProjectDetail·Quiz 라우터의 present/dismiss를 처리한다.  
  단어: `App` 응용 프로그램. 여기서는 GitIt iOS 앱 자신(메인 앱 타깃) · `Root` 뿌리·최상위. 여기서는 앱 화면 트리와 리듀서 트리의 최상위 노드 · `Feature` 기능. 여기서는 TCA에서 State·Action·Reducer를 묶은 단위(이 프로젝트의 리듀서 접미어)
- **`AppRootFeature.Route`** `enum` · internal · [AppRootFeature.swift:48](../../../sources/Projects/App/GitIt/Reducers/AppRootFeature.swift#L48) · 채택: Equatable, Sendable  
  AppRootFeature.State.route가 갖는 최상위 화면 분기(restoring, onboarding, mainShell)다. AppRootView가 이 값으로 AppEntryScreen·OnboardingRouter·MainShellRouter 중 하나를 선택하고, 리듀서가 route에 따라 effect 처리 여부를 결정한다.  
  단어(단일): `Route` 경로. 여기서는 앱 최상위에서 어느 화면 흐름을 보여줄지 정하는 분기
- **`AppRootFeature.DeviceRegistrationStatus`** `enum` · internal · [AppRootFeature.swift:54](../../../sources/Projects/App/GitIt/Reducers/AppRootFeature.swift#L54) · 채택: Equatable, Sendable  
  AppRootFeature.State.deviceRegistration이 갖는 기기 등록 진행 상태(idle, registering, registered, failed)다. registerDeviceIfNeeded가 registering 중 중복 호출을 막고, applicationBecameActive 시 failed면 재시도하는 판단에 쓰인다.  
  단어: `Device` 기기. 여기서는 푸시 알림을 받을 이 iOS 기기 · `Registration` 등록. 여기서는 appSetting.registerDevice()로 서버에 기기를 등록하는 작업 · `Status` 상태. 여기서는 그 등록 작업의 진행 단계
- **`AppRootFeature.State`** `struct` · internal · [AppRootFeature.swift:61](../../../sources/Projects/App/GitIt/Reducers/AppRootFeature.swift#L61) · 채택: Equatable, Sendable  
  AppRootFeature의 @ObservableState 상태다. route, appEntry, onboarding, mainShell 하위 상태와 deviceRegistration, 그리고 @Presents로 선택적인 projectRegistration·projectDetail·quiz 라우터 상태를 갖고 bundleVersion으로 초기화한다.  
  단어(단일): `State` 상태. 여기서는 TCA 리듀서가 소유하는 앱 최상위 상태 값
- **`AppRootFeature.Action`** `enum` · internal · [AppRootFeature.swift:79](../../../sources/Projects/App/GitIt/Reducers/AppRootFeature.swift#L79) · 채택: ViewAction, Sendable, Equatable  
  AppRootFeature의 액션이다. view(View)·effect(EffectEvent)와 appEntry·onboarding·mainShell 하위 Feature 액션, 그리고 projectRegistration·projectDetail·quiz의 PresentationAction을 감싼다.  
  단어(단일): `Action` 동작. 여기서는 TCA 리듀서에 전달되는 이벤트 열거형
- **`AppRootFeature.Action.View`** `enum` · internal · [AppRootFeature.swift:91](../../../sources/Projects/App/GitIt/Reducers/AppRootFeature.swift#L91) · 채택: Sendable, Equatable  
  뷰에서 보내는 액션 그룹(@CasePathable)으로 task(AppRootView 등장 시 초기 구독 시작)와 applicationBecameActive(scenePhase가 active로 전환) 두 케이스를 갖는다. AppRootView의 send와 GitItApp의 onChange에서 발생한다.  
  단어(단일): `View` 뷰·화면. 여기서는 SwiftUI 뷰의 수명주기 이벤트를 담는 액션 그룹
- **`AppRootFeature.Action.EffectEvent`** `enum` · internal · [AppRootFeature.swift:97](../../../sources/Projects/App/GitIt/Reducers/AppRootFeature.swift#L97) · 채택: Sendable, Equatable  
  비동기 Effect의 결과를 리듀서로 되돌리는 액션 그룹(@CasePathable)이다. signInVerified(SignInVerification), deviceRegistrationSucceeded, deviceRegistrationFailed, deviceTokenRefreshed(String), generationStateChanged(ProjectGenerationState)를 갖는다.  
  단어: `Effect` 효과·부수 효과. 여기서는 TCA Effect(비동기 작업·스트림 구독) · `Event` 사건. 여기서는 그 Effect가 완료되거나 스트림 값이 도착했을 때의 결과
- **`AppRootFeature.CancelID`** `enum` · private · [AppRootFeature.swift:307](../../../sources/Projects/App/GitIt/Reducers/AppRootFeature.swift#L307) · 채택: Hashable  
  AppRootFeature 내부의 취소 가능 Effect 식별자로 deviceRegistration, deviceTokenRefreshes, generationObservation 케이스를 갖는다. .cancellable(id:)와 returnToOnboarding의 .cancel(id:)에 쓰인다.  
  단어: `Cancel` 취소. 여기서는 실행 중인 TCA Effect를 중단하는 행위 · `ID` Identifier, 식별자. 여기서는 취소 대상 Effect를 구별하는 키

## GitIt/Screens

- **`AppRootView`** `struct` · internal · [AppRootView.swift:16](../../../sources/Projects/App/GitIt/Screens/AppRootView.swift#L16) · 채택: View  
  @ViewAction(for: AppRootFeature.self)를 적용한 앱 최상위 SwiftUI View다. store.route에 따라 AppEntryScreen·OnboardingRouter·MainShellRouter를 보여주고, mainShell에서는 projectRegistration·projectDetail을 fullScreenCover로, quiz를 ProjectDetailRouter 위 QuizRouterOverlay로 띄우며 등장 시 view(.task)를 보낸다.  
  단어: `App` 응용 프로그램. 여기서는 GitIt iOS 앱 자신(메인 앱 타깃) · `Root` 뿌리·최상위. 여기서는 앱 화면 트리와 리듀서 트리의 최상위 노드 · `View` 뷰·화면. 여기서는 SwiftUI View 프로토콜을 채택한 화면 타입
- **`AppRootPreviewSupport`** `enum` · private · [AppRootView.swift:76](../../../sources/Projects/App/GitIt/Screens/AppRootView.swift#L76)  
  AppRootView의 #Preview 전용 private 네임스페이스 열거형이다. 7개 UseCase의 Noop 대역 구조체를 중첩 정의하고, store(route:)로 지정한 Route에서 시작하는 AppRootFeature Store를 만든다.  
  단어: `App` 응용 프로그램. 여기서는 GitIt iOS 앱 자신(메인 앱 타깃) · `Root` 뿌리·최상위. 여기서는 앱 화면 트리와 리듀서 트리의 최상위 노드 · `Preview` 미리보기. 여기서는 Xcode SwiftUI #Preview · `Support` 지원·보조. 여기서는 프리뷰 구성에 필요한 대역과 팩터리를 모은 보조 코드
- **`AppRootPreviewSupport.NoopAccount`** `struct` · internal · [AppRootView.swift:78](../../../sources/Projects/App/GitIt/Screens/AppRootView.swift#L78) · 채택: AccountUseCase  
  private enum AppRootPreviewSupport 안의 프리뷰용 AccountUseCase 대역이다. signIn은 retryableFailure, signOut·restoreSignIn은 signedOut, verifySignIn은 valid, signInAvailability는 signInRequired, policyConsentStatus는 빈 문서·isSatisfied true를 돌려주고 consent는 아무것도 하지 않으며 withdraw는 CancellationError를 던진다.  
  단어: `Noop` No + Operation, 아무 동작도 하지 않음. 여기서는 실제 로직 없이 고정값을 돌려주거나 오류를 던지는 프리뷰용 대역 · `Account` 계정. 여기서는 로그인·복원·동의·탈퇴를 다루는 AccountUseCase
- **`AppRootPreviewSupport.NoopUserInfo`** `struct` · internal · [AppRootView.swift:114](../../../sources/Projects/App/GitIt/Screens/AppRootView.swift#L114) · 채택: UserInfoUseCase  
  프리뷰용 UserInfoUseCase 대역이다. detail()은 이름 "미리보기"와 예시 이메일, 0으로 채운 LearningStatistics를 가진 UserDetail을, curation()은 nil을 돌려주고 updateCuration·updatePosition·updateCareerLevel은 CancellationError를 던진다.  
  단어: `Noop` No + Operation, 아무 동작도 하지 않음. 여기서는 실제 로직 없이 고정값을 돌려주거나 오류를 던지는 프리뷰용 대역 · `User` 사용자. 여기서는 로그인한 회원 · `Info` Information, 정보. 여기서는 회원 상세·큐레이션·직무·경력을 다루는 UserInfoUseCase
- **`AppRootPreviewSupport.NoopAppSetting`** `struct` · internal · [AppRootView.swift:145](../../../sources/Projects/App/GitIt/Screens/AppRootView.swift#L145) · 채택: AppSettingUseCase  
  프리뷰용 AppSettingUseCase 대역이다. notificationAuthorization()은 notDetermined, requestNotificationAuthorization()은 denied를 돌려주고 registerDevice·updateDeviceToken은 아무 일도 하지 않는다.  
  단어: `Noop` No + Operation, 아무 동작도 하지 않음. 여기서는 실제 로직 없이 고정값을 돌려주거나 오류를 던지는 프리뷰용 대역 · `App` 응용 프로그램. 여기서는 앱 단위 설정의 대상인 GitIt 앱 · `Setting` 설정. 여기서는 알림 권한·기기 등록·디바이스 토큰을 다루는 AppSettingUseCase
- **`AppRootPreviewSupport.NoopExternalRepository`** `struct` · internal · [AppRootView.swift:159](../../../sources/Projects/App/GitIt/Screens/AppRootView.swift#L159) · 채택: ExternalRepositoryUseCase  
  프리뷰용 ExternalRepositoryUseCase 대역으로, repository(at:)가 항상 CancellationError를 던진다.  
  단어: `Noop` No + Operation, 아무 동작도 하지 않음. 여기서는 실제 로직 없이 고정값을 돌려주거나 오류를 던지는 프리뷰용 대역 · `External` 외부의. 여기서는 앱 밖의 서비스가 호스팅하는 · `Repository` 저장소. 여기서는 URL로 조회하는 외부 코드 저장소(ExternalRepositoryUseCase)
- **`AppRootPreviewSupport.NoopQuizDetail`** `struct` · internal · [AppRootView.swift:165](../../../sources/Projects/App/GitIt/Screens/AppRootView.swift#L165) · 채택: QuizDetailUseCase  
  프리뷰용 QuizDetailUseCase 대역으로, quizSet(_:in:), grade(ChoiceAnswer), grade(EssayAnswer), bookmark·unbookmark(_:in:), bookmarks(_:)가 모두 CancellationError를 던진다.  
  단어: `Noop` No + Operation, 아무 동작도 하지 않음. 여기서는 실제 로직 없이 고정값을 돌려주거나 오류를 던지는 프리뷰용 대역 · `Quiz` 퀴즈. 여기서는 학습 세트 안의 문제 · `Detail` 상세. 여기서는 퀴즈 세트 조회·채점·북마크를 다루는 QuizDetailUseCase
- **`AppRootPreviewSupport.NoopProject`** `struct` · internal · [AppRootView.swift:200](../../../sources/Projects/App/GitIt/Screens/AppRootView.swift#L200) · 채택: ProjectUseCase  
  프리뷰용 ProjectUseCase 대역으로, projects()는 즉시 끝나는 빈 AsyncStream<ProjectList>를 돌려주고 refresh·requestNextPage·detail(of:)·delete는 CancellationError를 던진다.  
  단어: `Noop` No + Operation, 아무 동작도 하지 않음. 여기서는 실제 로직 없이 고정값을 돌려주거나 오류를 던지는 프리뷰용 대역 · `Project` 프로젝트. 여기서는 사용자가 등록한 학습 대상 저장소 프로젝트(ProjectUseCase)
- **`AppRootPreviewSupport.NoopProjectGeneration`** `struct` · internal · [AppRootView.swift:222](../../../sources/Projects/App/GitIt/Screens/AppRootView.swift#L222) · 채택: ProjectGenerationUseCase  
  프리뷰용 ProjectGenerationUseCase 대역으로, request(_:)는 CancellationError를 던지고 states()는 즉시 끝나는 빈 AsyncStream<ProjectGenerationState>를 돌려준다.  
  단어: `Noop` No + Operation, 아무 동작도 하지 않음. 여기서는 실제 로직 없이 고정값을 돌려주거나 오류를 던지는 프리뷰용 대역 · `Project` 프로젝트. 여기서는 학습 세트 생성의 대상 프로젝트 · `Generation` 생성. 여기서는 프로젝트로부터 학습 세트를 만드는 요청과 그 진행 상태(ProjectGenerationUseCase)

## ShareExtension

- **`ShareExtensionEndpointHost`** `enum` · internal · [ShareExtensionEndpointHost.swift:5](../../../sources/Projects/App/ShareExtension/ShareExtensionEndpointHost.swift#L5) · 채택: String  
  Share Extension 타깃용으로 AppEndpointHost와 같은 구조를 가진 열거형이다. Info.plist 키 GIT_IT_API_HOST·GIT_IT_EXTERNAL_REPOSITORY_HOST를 rawValue로 갖고 url이 https URL을 만들며 없으면 fatalError로 종료한다. ShareViewController가 ShareExtensionComposition.Environment를 구성할 때 사용한다.  
  단어: `Share` 공유. 여기서는 iOS 공유 시트(Share Sheet) · `Extension` 확장. 여기서는 iOS App Extension(Share Extension 타깃) · `Endpoint` 종단점. 여기서는 API 서버와 외부 저장소 서버의 접속 지점 · `Host` 호스트. 여기서는 URL의 호스트(도메인) 부분, Info.plist에서 읽는 서버 주소
- **`ShareRegistrationDiagnosticLog`** `struct` · internal · [ShareRegistrationDiagnosticLog.swift:7](../../../sources/Projects/App/ShareExtension/ShareRegistrationDiagnosticLog.swift#L7) · 채택: Sendable  
  Feature의 ShareRegistrationDiagnosticEvent를 받아 os.Logger(subsystem com.nexters.hytime.gitit, category ShareExtension)에 debug 수준으로 기록하는 Sendable 구조체다. 이벤트 케이스를 문자열로 바꾸는 private description(for:)을 갖고, ShareViewController가 ShareRegistrationFeature의 recordDiagnostic 클로저로 넘긴다.  
  단어: `Share` 공유. 여기서는 공유 시트로 들어온 저장소 링크 · `Registration` 등록. 여기서는 공유된 링크를 프로젝트로 등록하는 흐름 · `Diagnostic` 진단. 여기서는 등록 흐름의 진행·실패 원인을 파악하기 위한 정보 · `Log` 기록. 여기서는 os.Logger로 남기는 로그
- **`ShareViewController`** `class` · internal · [ShareViewController.swift:10](../../../sources/Projects/App/ShareExtension/ShareViewController.swift#L10) · 채택: UIViewController  
  Share Extension의 진입 UIViewController(final)다. ShareExtensionComposition.live로 의존성을 만들고 ShareRegistrationFeature Store를 구성해 ShareRegistrationScreen을 UIHostingController로 붙이며, extensionContext의 첨부를 SharedItemURLResolver로 풀어 view(.sharedURLResolved)를 보내고 dismiss 시 completeRequest로 확장을 종료한다.  
  단어: `Share` 공유. 여기서는 iOS 공유 시트로 열리는 확장 화면 · `View` 뷰. 여기서는 UIKit 화면 · `Controller` 제어기. 여기서는 뷰를 관리하는 UIViewController
- **`SharedItemURLResolver`** `struct` · internal · [SharedItemURLResolver.swift:6](../../../sources/Projects/App/ShareExtension/SharedItemURLResolver.swift#L6) · 채택: Sendable  
  공유 시트로 전달된 첨부(SharedItemAttachment 배열)에서 URL 하나를 찾는 Sendable 구조체다. resolve(from:)이 먼저 URL 타입 항목을, 없으면 plain text를 읽어 정적 url(fromText:)로 http/https이며 host가 있는 URL만 통과시킨다. ShareViewController가 사용한다.  
  단어: `Shared` 공유된. 여기서는 사용자가 공유 시트로 넘긴 · `Item` 항목. 여기서는 NSExtensionItem에 딸린 첨부 데이터 · `URL` Uniform Resource Locator, 여기서는 첨부에서 뽑아낼 저장소 링크 주소 · `Resolver` 해석기. 여기서는 여러 첨부 중에서 유효한 URL 하나를 결정하는 역할
- **`SharedItemAttachment`** `protocol` · internal · [SharedItemURLResolver.swift:46](../../../sources/Projects/App/ShareExtension/SharedItemURLResolver.swift#L46) · 채택: Sendable  
  공유 첨부 하나를 추상화한 Sendable 프로토콜로 loadURL()과 loadText() 두 비동기 메서드를 요구한다. 같은 파일에서 NSItemProvider가 UTType.url·plainText 항목 로드로 채택하며, SharedItemURLResolver.resolve(from:)의 입력 타입이다.  
  단어: `Shared` 공유된. 여기서는 사용자가 공유 시트로 넘긴 · `Item` 항목. 여기서는 공유된 NSExtensionItem · `Attachment` 첨부. 여기서는 공유 항목에 딸린 개별 데이터 제공자(NSItemProvider)
