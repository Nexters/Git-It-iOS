# 타입 이름 단어 사전

[인덱스로 돌아가기](README.md)

타입 이름에 쓰인 고유 단어 328개. 각 항목은 분류, 통합 정의, 이 프로젝트에서의 용례, 그리고 다의어·유의어·표기 흔들림 메모다.

| 분류 | 단어 수 |
|---|---|
| 일반 | 169 |
| 아키텍처·패턴 | 53 |
| 플랫폼 | 44 |
| 업무 개념 | 42 |
| 약어 | 11 |
| 관용 표현 | 5 |
| 브랜드 | 4 |

## 메모가 있는 단어

- `Account`: Domain의 Account가 유스케이스 구현체 이름으로도 쓰여 계정 개념(데이터)과 구현체(행위)가 같은 단어를 공유한다. SignIn·Authentication과 관심사가 겹친다.
- `Action`: 다의어: Feature 내부 `.Action`은 TCA 액션 타입이지만 SettingsFeature.AccountAction은 TCA Action이 아닌 계정 조작 상태이고, UI의 ActionButton·ActionMenu·BottomActionBar는 사용자 명령을 뜻한다.
- `Adapter`: Data의 RequestTransportBridge도 두 계약을 잇는 어댑터 역할이지만 Bridge라는 다른 접미어를 쓴다. 대부분 {Domain 프로토콜}Adapter 형식이나 ExternalRepositoryLocatorAdapter·ExternalRepositoryLookupAdapter처럼 Repository 패턴이 아닌 대상에도 붙는다.
- `Agreement`: 유의어 중첩: Feature·UI는 Agreement, Domain·Data·Composition은 Consent(PolicyConsent)로 같은 약관 동의 개념을 표현한다.
- `Answer`: ChoiceAnswerOption에서는 답안이 아니라 답변 후보(보기)를 뜻해 Option·Choice와 의미가 겹친다. 유의어 중첩: 과거 제출 기록은 Submission(ChoiceSubmission)으로도 표현된다.
- `API`: 약어를 전부 대문자(API)로 표기한다. Data의 Authentication·LearningProject·Member 관심사가 같은 이름의 타입을 각각 따로 선언한다(APIResponseDTO·ServerAPIError가 3벌씩).
- `App`: 다의어: 앱 본체 타깃, UIApplication 수명 주기, App Group 명칭 일부, SwiftUI App 프로토콜로 의미가 갈린다. AppEntry(Feature)와 AppRoot(App)가 모두 앱 진입 지점을 가리켜 역할 구분이 이름만으로는 드러나지 않는다.
- `Apple`: 유의어 중첩·표기 흔들림: 같은 로그인 흐름을 Data는 AppleSignIn*, Infrastructure는 AppleAuthorization*/AppleCredential*로, DTO는 AppleLogin*으로 부른다(SignIn/Login/Authorization 혼용).
- `Asset`: Resource와 의미가 겹친다(ResourceImage.Asset처럼 두 단어가 중첩되어 쓰임).
- `Authentication`: SignIn과 유의어 중첩이 크다: Domain에 AuthenticationRepository와 SignInRepository가 공존하고, Feature의 AuthenticationStatus가 가리키는 대상이 세션 복원(AppEntry)과 Apple 로그인(Tutorial)으로 다르다.
- `Authorization`: 다의어: 알림 권한과 Apple 로그인 인가라는 서로 다른 두 의미로 쓰인다. 유의어 중첩: 알림 권한 상태를 NotificationAuthorizationStatus/Setting과 ReminderAuthorizationStatus/Setting으로 계층마다 다르게 부르며, Domain과 Infrastructure에 같은 이름 NotificationAuthorizationStatus가 존재한다.
- `Availability`: Unavailable(UnavailableKeyValueStorage)과 같은 어근이지만 그쪽은 판정이 아닌 무동작 대체 구현을 뜻한다.
- `Backend`: "Backend server"(서버) 의미가 아니라 저장 위임 구현을 가리킨다.
- `Badge`: Chip과 형태가 비슷하나 Chip은 선택 가능한 버튼, Badge는 표시 전용 라벨로 구분된다.
- `Bar`: 다의어: 버튼을 담는 띠 컨테이너, 진행률 막대, 차트 막대 데이터로 쓰인다.
- `Bookmark`: Saved(SavedFeature, SavedQuestionCard)와 같은 대상을 가리키는 유의어 중첩이 있다. Domain은 Quiz 접두어(QuizBookmark), Data는 Question 접두어(BookmarkQuestionRequestDTO, BookmarkedQuestionListResponseDTO)를 써 대상 명칭이 흔들린다.
- `Bookmarked`: 형태 흔들림: 같은 개념을 BookmarkQuestionRequestDTO처럼 원형 Bookmark로도 쓴다(변경 요청은 Bookmark, 조회 결과는 Bookmarked).
- `Bootstrap`: App의 Launch(앱 시작 단계)와 의미가 가깝다.
- `Bridge`: 역할상 Composition의 *Adapter와 같은 변환 구현이지만 다른 접미어를 써 Adapter와 유의어 중첩이 있다.
- `Builder`: 유의어 중첩: 객체 생성 책임을 Builder, Factory, Assembly/Composition이 나누어 쓴다.
- `Cache`: 유의어 중첩: 저장 책임을 Cache, Store, Storage, Repository가 나누어 표현한다.
- `Callbacks`: Data와 Infrastructure에 같은 역할의 콜백 묶음 타입이 각각 있다.
- `Cancel`: 모든 용례가 {Feature}.CancelID 형식으로 통일되어 있다.
- `Career`: 일부 용례는 "코드 이해 수준"·"개발 수준"·"연차"로도 설명되어 같은 개념의 한국어 표현이 흔들린다.
- `Chip`: Badge와 모양이 비슷하나 Chip은 선택 가능, Badge는 표시 전용이다.
- `Choice`: 유의어 중첩: 보기 항목 하나를 Choice와 Option이 함께 가리키고(ChoiceAnswerOption, ChoiceOptionDisplay), 사용자의 고르는 행위는 Selection으로 따로 표현한다.
- `Client`: Data의 Remote(원격 데이터 접근 객체)와 역할이 겹친다. Data에서는 Infrastructure API 호출 객체(ReminderNotificationClient, RemoteMessageClient)에 Client를 쓴다.
- `Composition`: 유의어 중첩: 조립 책임을 Composition(루트)과 Assembly(ConcernUseCaseAssembly, LearningProjectAssembly)가 함께 쓴다. 패키지 이름 Composition과도 같다.
- `Consent`: 유의어 중첩: Feature·UI의 Agreement(LegalAgreementFeature, PolicyAgreementRow)와 같은 개념을 가리킨다.
- `Constant`: 대부분 레이아웃 수치 모음이지만 문구, 메뉴 정의, 그라데이션·스타일 토큰, 진행률 시뮬레이션 설정, 파생 계산 함수까지 담는 경우가 있어 담는 내용의 범위가 타입마다 다르다.
- `Container`: OverlayContainer는 Overlay와 Container가 겹쳐 있으며, Overlay가 다른 타입(ModalOverlay 등)에서는 화면 위에 겹치는 View 자체를 뜻해 의미가 다르다.
- `Content`: 다의어: 알림 문구, 도메인 문제 본문, UI 표시 내용으로 쓰인다. 같은 이름 GenerationReminderContent가 App과 Composition 두 Assembly에 중복 존재한다.
- `Continuous`: UI의 ProgressSegments(구간형 진행 표시)와 대비된다.
- `Control`: 다의어: UI 조작 요소(명사)와 동작 제어 방식(ExpansionControl)으로 의미가 갈린다.
- `Credential`: 다의어: Apple 로그인 자격 증명과 서버 요청용 액세스 토큰 자격을 모두 가리킨다. 유의어 중첩: AppleCredential(Infrastructure)과 AppleSignInCredential(Data)이 계층별로 병존한다.
- `Curation`: CurationSplashView에서는 선택 단계 자체가 아니라 선택 단계가 끝난 뒤를 뜻해 단계 명칭과 시점이 어긋난다.
- `Data`: 패키지 이름 Data와 철자가 같지만 여기서는 응답 필드 이름을 가리킨다. Data의 Authentication·LearningProject·Member 관심사가 같은 이름의 타입을 각각 따로 선언한다(EmptyResponseData 3벌).
- `Delegate`: 다의어: TCA의 부모 전달용 액션 분류와 iOS AppDelegate 관용 표현(App+Delegate)이라는 두 의미로 쓰인다. 유의어 중첩: 비슷한 AppDelegate가 Composition(PushNotificationAppDelegate), Data(NotificationAppDelegate), Infrastructure(FirebaseMessagingAppDelegate, PushMessagingAppDelegate)에 흩어져 있고 Notification/PushNotification/PushMessaging 표기가 섞여 있다.
- `Deletion`: 프로젝트 삭제와 계정 삭제(탈퇴)라는 서로 다른 대상에 쓰인다.
- `DesignSystem`: Tuist의 DesignSystemFontFamily에서는 Design과 System이 별개 단어로 분해되어 집계되어 표기 단위가 흔들린다(System 항목 참고).
- `Detail`: 다의어: ProjectDetail·UserDetail은 상세 데이터 모델이지만 QuizDetail은 조회·채점·북마크까지 포괄하는 관심사(UseCase) 이름이다. Domain QuizDetail은 모델이 아니라 유스케이스 구현체다.
- `Device`: 표기 흔들림: 식별자를 DeviceID(약어)와 DeviceIdentifier(전체 표기)로 함께 쓴다.
- `Display`: 다의어: 표시용 데이터 모델과 도메인 값→문자열 변환기 역할로 갈린다. 최상위 타입(ProfileDisplay)과 Screen 중첩 타입(CareerSelectionScreen.Display)으로 선언 위치도 흔들린다.
- `DTO`: Request/Response 접미 규칙이 섞여 있다: 대부분 RequestDTO/ResponseDTO를 쓰지만 CareerLevelDTO, PositionDTO, QuizLevelDTO, ProjectListItemDTO, ProjectSetSummaryDTO, WeeklyChartItemDTO, FieldErrorDTO는 방향 표기가 없다. 서버 전송이 아닌 로컬 저장·푸시 페이로드에도 DTO를 쓴다. Data의 Authentication·LearningProject·Member 관심사가 같은 이름의 타입을 각각 따로 선언한다(APIResponseDTO·FieldErrorDTO 3벌씩).
- `Effect`: 다의어: TCA 부수 효과와 디자인 시각 효과로 나뉜다. 표기 흔들림: 대부분 Action.EffectEvent이지만 HomeFeature만 Action.Effect를 쓴다.
- `Emphasis`: UI의 ChoiceAnswerOption.State도 선택지의 기본·선택됨·정답·오답 표시 상태를 뜻해 State와 유의어 중첩이 있다.
- `Empty`: 다의어: 빈 응답 페이로드와 빈 상태 UI로 쓰인다.
- `Endpoint`: Data에서는 API 경로 정의, App에서는 서버 호스트 주소라는 서로 다른 수준의 의미로 쓰인다.
- `Entry`: 다의어: '진입'과 '항목(원소)' 두 의미로 쓰인다.
- `Error`: 유의어 중첩: 화면 쪽 실패 표시에 ErrorView와 FailureView/LoadFailureView가 섞여 쓰인다. FieldErrorDTO·ServerAPIError는 Swift Error 타입이 아닌 서버 오류 응답 내용을 가리키기도 한다.
- `Event`: 다의어: TCA Effect 결과 액션과 기록용 사건 값으로 쓰인다.
- `Exit`: 같은 온보딩 이탈이라도 OnboardingExitFeature는 정상 완료, ExitStatus는 닫기·signOut으로 의미가 다르다.
- `Extension`: Swift 언어의 extension 선언과는 다른 의미다.
- `External`: 다의어: 외부 서비스(GitHub)와 외부(서드파티) 의존성으로 갈린다. ExternalRepository는 Repository 패턴이 아니라 Git 저장소를 뜻해 Repository 다의어의 구분자 역할을 한다.
- `Factory`: 유의어 중첩: 생성 책임을 Factory, Builder, Assembly/Composition이 나누어 쓴다.
- `Failure`: 유의어 중첩: 같은 역할의 하위 View에 ErrorView(ProjectDetailScreen, SavedScreen, LearningSetIntroScreen)와 FailureView가 혼용된다.
- `Feature`: 패키지 이름 Feature와 타입 접미어 Feature가 같은 단어라 문맥 구분이 필요하다.
- `Fetch`: 유의어 중첩: 조회 동작에 Fetch 외에 Load(ProfileLoad, InitialLoad, LoadStatus, Loader)가 함께 쓰인다.
- `Field`: Data의 Authentication·LearningProject·Member 관심사가 같은 이름의 타입을 각각 따로 선언한다(FieldErrorDTO 3벌).
- `Fixture`: 같은 미리보기 지원 역할을 다른 Feature에서는 PreviewSupport(ProjectRegistrationPreviewSupport, ShareRegistrationPreviewSupport)로 불러 유의어 중첩이 있다.
- `Generation`: 같은 작업을 ProjectGeneration(프로젝트 생성)과 QuizGeneration(퀴즈 생성)으로 부르는 접두어가 흔들린다. "학습 세트 생성"이라는 설명도 섞인다.
- `Generator`: 퀴즈 '생성'(Generation, 예: QuizGenerationEndpoint)과 어근은 같지만 무관한 난수 생성기다.
- `Glass`: Plain(IconPlainButton)과 대비되는 스타일 명칭이다.
- `Grading`: Feature의 QuestionSolvingFeature.AnswerOutcome도 같은 채점 결과를 Outcome으로 부른다.
- `Group`: 다의어: Apple 공유 컨테이너 명칭과 디자인 토큰 분류로 나뉜다.
- `Guidance`: RepositoryLinkInputScreen.GuideSectionView는 Guide를 써 Guidance/Guide 표기가 흔들린다.
- `Guide`: 다의어: 온보딩 단계 이름과 입력 방법 설명 섹션으로 쓰인다.
- `Header`: HTTP 헤더(AuthorizedRequestHeaders의 Headers)와는 다른 UI 영역 의미다. Home과 Profile에 같은 이름의 ProfileHeaderView가 각각 있다.
- `Headers`: 단어를 복수형 Headers로 사용한다.
- `HTTP`: 유의어 중첩: Infrastructure의 HTTPRequest/HTTPTransportRequest와 Data의 TransportRequest/LearningProjectRequest가 요청 모델을 계층마다 따로 둔다.
- `ID`: 다의어: 도메인 식별자와 Effect 취소 키로 갈린다. 표기 흔들림: DeviceID와 DeviceIdentifierRepository처럼 ID와 Identifier 전체 표기가 혼용된다. 대문자 ID로는 일관되며 Id 표기는 쓰이지 않는다.
- `Identifier`: 표기 흔들림: 같은 개념을 Identifier로 풀어 쓰기도 하고 PolicyDocumentID·ProjectID·DeviceID처럼 ID로 줄여 쓰기도 한다.
- `Identity`: 유의어 중첩: 같은 계층에서 Store와 Storage가 함께 쓰인다(AppleIdentityStore, AppleIdentityStorageLayout).
- `Illust`: 비표준 축약형이며 다른 곳에서는 축약하지 않은 단어를 쓰는 관례와 어긋난다.
- `Info`: 다의어: 사용자 정보 관심사, 저장소 표시 정보, 기기 정보로 쓰인다. Domain UserInfo는 정보 값이 아니라 유스케이스 구현체를 가리켜 이름과 역할이 어긋난다.
- `Input`: 다의어: Action.Input은 사용자 입력이 아닌 부모 주입 액션(사용자 입력은 View 액션)이고, RepositoryLinkInput은 사용자 텍스트 입력을 뜻해 의미가 반대에 가깝다.
- `Judgement`: 표기 흔들림: 영국식 철자 Judgement를 쓰며 미국식은 Judgment다. 유의어 중첩: 도메인의 채점은 Grading(ChoiceGrading)으로 표현한다.
- `Key`: SwiftUI PreferenceKey의 Key와는 별도 항목으로 다룬다.
- `Keychain`: 유의어 중첩: Data는 같은 보안 저장소를 공급자 중립 이름 SecureValueStorage로 부른다.
- `Kind`: 유의어 중첩: 비슷한 분류 의미에 Style, Status, Mode도 쓰인다.
- `Label`: SwiftUI의 Label 타입과 이름이 같아 ActionButton.Label은 플랫폼 타입과 혼동될 수 있다.
- `Launch`: Composition의 Bootstrap(초기 활성화)과 의미가 가깝다.
- `Layout`: 다의어: 저장소 키 구성 규약과 UI 배치라는 두 의미로 쓰인다.
- `Learning`: LearningProject와 LearningSet이 함께 쓰이며, 같은 대상을 퀴즈 세트·학습 세트로 부르는 표현이 섞인다.
- `Legal`: Domain·Data는 같은 대상을 Policy(PolicyDocument, PolicyConsent)로 부르고, 동의도 Agreement(Feature)와 Consent(Domain)로 달라 유의어 중첩이 있다.
- `Level`: 다의어: 퀴즈 난이도와 경력 단계라는 서로 다른 도메인 값으로 쓰인다. 유의어 중첩: CareerSelectionFeature는 Level 없이 경력 선택을 가리킨다.
- `Link`: 유의어 중첩: 같은 저장소 주소를 다른 타입에서는 URL(ExternalRepositoryURL, GitHubRepositoryURLParser)로 부른다.
- `List`: ProjectListDisplay는 목록 전체가 아니라 목록 행 하나에 대응하는 항목을 뜻해 이름과 단위가 어긋난다. ProjectListItemDTO에서는 List가 목록 조회 결과의 원소를 수식한다.
- `Load`: 표기 흔들림: 진행 상태를 XxxLoad(ProjectLoad, SetLoad, InitialLoad)와 LoadStatus(ProjectDetailFeature.LoadStatus, SavedFeature.LoadStatus)로 혼용한다. 유의어 중첩: Fetch/Lookup과 조회 의미가 겹친다.
- `Loader`: 유의어 중첩: 조회 동작에 Load와 Fetch가 함께 쓰인다.
- `Loading`: Load(LearningSetIntroFeature.BookmarkLoad, SetLoad)와 같은 어근이다.
- `Local`: 다의어: 기기 내부 저장과 로컬 알림이라는 두 의미로 쓰인다.
- `Location`: 다의어: 원격 저장소의 식별 좌표와 로컬 저장 영역으로 나뉜다. ExternalRepositoryLocation은 Data와 Domain에 같은 이름으로 존재한다.
- `Locator`: Service Locator 패턴과 이름이 겹쳐 오해 소지가 있다. Data의 GitHubRepositoryURLParser와 같은 역할을 다른 단어(Parser)로 부르고, Location(ExternalRepositoryLocation)·Lookup·Resolver와 유의어가 중첩된다.
- `Log`: 유의어 중첩: 기록을 Record, Log, Event로 나누어 표현한다.
- `Login`: 표기 흔들림: 같은 행위를 Login(DTO)과 SignIn(SignInMethod, SignedInAccount, AppleSignInError, AppleSignInSource)으로 혼용한다.
- `Lookup`: 유의어 중첩: 조회 의미가 Load, Fetch와 겹친다.
- `Member`: 유의어 중첩: 같은 대상을 Domain에서는 주로 User(UserInfo, UserProfile)로, Data에서는 Member로 부른다.
- `Message`: 유의어 중첩: 같은 원격 푸시를 Notification, Push, Message로 부른다.
- `Messaging`: PushMessaging(중립 경계)과 FirebaseMessaging(외부 고정 명칭)이 같은 단어를 공유한다. Data의 RemoteMessageReceiver·LocalReminderNotifier와 역할 명칭(Messaging/Message/Notifier/Notification)이 흩어져 있다.
- `Method`: 다의어: 로그인 방식과 HTTP 메서드로 나뉜다.
- `Mutation`: 표기 흔들림: XxxMutation과 MutationStatus를 혼용한다.
- `Noop`: 유의어 중첩: 같은 프리뷰 대역을 Feature에서는 Preview 접두어(ShareRegistrationPreviewSupport.PreviewExternalRepository)로 부른다.
- `Notification`: 다의어: 로컬 알림과 원격 푸시 알림을 모두 가리킨다. 유의어 중첩: 원격 푸시를 Push·Message로도 부른다. NotificationAuthorizationStatus는 Domain(현재 권한 값)과 Infrastructure(요청 직후 결과)에 같은 이름으로 다른 의미를 가진다.
- `Notifier`: Composition에서는 같은 대상을 GenerationReminderSchedulerAdapter(Scheduler)·NotificationAuthorizationAdapter로 불러 Notifier/Scheduler 유의어 중첩이 있다.
- `Option`: 유의어 중첩: 같은 보기 개념을 Choice와 함께 쓴다.
- `Outcome`: 다의어: 생성 작업 결과와 채점 결과에 쓰인다. 채점 결과는 Domain에서 Grading(ChoiceGrading, EssayGrading)으로 부른다.
- `Overlay`: 다의어: 화면 위에 뜨는 모달·push형 View와 콘텐츠 위에 떠 있는 레이아웃 배치로 갈린다.
- `Page`: 다의어: 데이터 페이지네이션 단위와 화면 페이지로 나뉜다.
- `Parser`: 유의어 중첩: 비슷한 해석 역할에 Resolver(ExternalRepositoryResolver, SharedItemURLResolver)도 쓰인다.
- `Phase`: 유의어 중첩: 진행 단계 의미에 Status와 State(ProjectGenerationState)도 쓰인다.
- `Plain`: Glass(IconGlassButton)와 대비되는 스타일 명칭이다.
- `Policy`: 다의어: 대부분 '약관 문서'지만 GenerationWaitPolicy는 '동작 규칙'을 뜻한다. Feature는 같은 대상을 Legal(LegalAgreementFeature)로, 동의는 Consent/Agreement로 달리 불러 유의어 중첩이 있다.
- `Position`: 일반 의미의 위치(좌표)가 아니라 직군을 뜻하므로 오해 소지가 있다.
- `Preview`: 표기 흔들림: 프리뷰 지원 코드를 PreviewSupport와 PreviewFixture로 혼용한다.
- `Profile`: ProfileLoad가 HomeFeature.State, ProfileFeature.State, SettingsFeature에 각각 정의되어 있다.
- `Progress`: 다의어: 수치적 진척률(비율)과 절차의 단계 상태로 갈린다.
- `Project`: 유의어 중첩: 프로젝트와 GitHub Repository(저장소)가 거의 같은 대상을 가리켜 ProjectRepositoryInfo처럼 한 이름에 함께 나오며, Data에서는 LearningProject로도 부른다. Domain Project는 모델이 아니라 유스케이스 구현체를 가리킨다.
- `Projects`: 표기 흔들림: 목록을 대부분 ProjectList로 부르고 여기만 복수형 Projects를 쓴다.
- `Provider`: 유의어 중첩: 외부 기능 래퍼를 Provider, Client, Source(AppleSignInSource)로 계층마다 다르게 부른다.
- `Push`: 유의어 중첩: 같은 원격 푸시를 Notification, RemoteMessage로도 부른다.
- `Pushed`: Push가 다른 곳(PushMessagingClient, PushQuizGenerationOutcomeSource)에서는 푸시 알림을 뜻해 다의어 혼동 소지가 있다.
- `Question`: 유의어 중첩: 같은 대상을 Domain에서는 Quiz(QuizID, QuizBookmark)로 부르고 Data·Feature 타입 이름에서는 Question으로 부른다.
- `Quiz`: 유의어 중첩: 같은 문제를 Feature·Data 일부는 Question(QuestionSolvingFeature, SavedQuestionDisplay, BookmarkQuestionRequestDTO)으로 부른다. 문제 묶음도 QuizSet(Domain)과 LearningSet(Data·Feature)으로 흔들린다.
- `Register`: 동사 원형을 타입 앞에 쓰는 DTO 명명(Register, Submit)이다.
- `Registration`: 다의어: 프로젝트 등록, 기기 등록, 폰트 등록으로 대상이 다르다. 프로젝트 등록은 실제로 생성 요청이라 ProjectGeneration(ProjectGenerationRepository)과 유의어 중첩이 있다.
- `Reminder`: 유의어 중첩: 같은 알림을 Reminder와 Notification(LocalNotificationRequest, NotificationAuthorization)으로 혼용하며, GenerationReminderSheet는 푸시 알림으로 설명되어 로컬 알림과 의미가 흔들린다.
- `Remote`: 다의어: 데이터 접근 계층 접미어(…Remote)와 원격 푸시 수식어(Remote…)로 나뉜다. 유의어 중첩: 외부 호출 객체에 Client도 쓰인다.
- `Repository`: 다의어: Repository 패턴(데이터 접근 계약)과 Git 코드 저장소가 같은 단어를 공유해 ExternalRepositoryLocatorAdapter처럼 한 이름 안에서 두 의미가 섞이지 않도록 External·GitHub 접두어로 구분한다. ProjectRepository(패턴)와 ProjectRepositoryInfo(Git 저장소)는 접두어가 같아 특히 혼동된다. Store·Storage와 유의어 중첩이 있다.
- `Request`: 다의어: HTTP 요청, 도메인 생성 요청, 로컬 알림 요청으로 쓰인다. 유의어 중첩: 요청 모델이 HTTPRequest, HTTPTransportRequest, TransportRequest, LearningProjectRequest로 계층마다 중복되고 Request가 접두어(RequestTransport)·접미어(TransportRequest) 양쪽에 쓰인다.
- `Resolver`: 유의어 중첩: 비슷한 역할에 Parser(GitHubRepositoryURLParser)가 함께 쓰인다.
- `Resource`: Asset과 유의어 중첩(ResourceImage.Asset). 다른 곳의 Remote·Repository '외부 자원 접근'과는 무관하다.
- `Response`: 유의어 중첩: 응답 모델이 HTTPResponse, HTTPTransportResponse, TransportResponse로 계층마다 중복된다. 표기 흔들림: 대부분 DTO 접미어를 쓰지만 EmptyResponseData는 Data 접미어를 쓴다.
- `Result`: Swift 표준 Result 타입과 이름이 겹친다. 생성 결과에는 Outcome(QuizGenerationOutcomeDTO)을 써 Result/Outcome 유의어가 공존한다.
- `Route`: 유의어 중첩: Feature의 Router 타입들은 ActiveScreen·Step으로 같은 분기 개념을 표현한다.
- `Router`: 리듀서는 {흐름}RouterFeature, View는 {흐름}Router로 짝을 이루지만 QuizRouterOverlay처럼 View가 Overlay 접미어를 추가로 갖는 경우가 있다.
- `Saved`: Bookmark와 같은 대상을 가리키는 유의어 중첩이 있다(Feature 화면은 Saved, Domain·Data는 Bookmark).
- `Scheduler`: 유의어 중첩: 같은 알림 발송 역할을 Data에서는 LocalReminderNotifier(Notifier)로 부른다.
- `Screen`: 다의어: View 타입 접미어와 라우터 상태의 화면 단위로 갈린다. SettingsRouterFeature.State.SettingsStep은 같은 화면 단위를 Step으로도 불러 ActiveScreen과 유의어 중첩이 있다.
- `Section`: SectionView(SettingsScreen.SectionView, GuideSectionView)와 Section(ChoiceSection)으로 View 접미어 사용이 흔들린다.
- `Secure`: 다의어: 보안 저장소와 암호학적 난수라는 두 의미로 쓰인다.
- `Segments`: ContinuousProgressBar(연속형)와 대비되는 구간형 진행 표시다.
- `Selection`: 유의어 중첩: 선택 행위는 Selection, 고를 대상인 보기는 Choice·Option으로 나뉘며, UI에는 Selectable(SelectableSettingRow) 형태도 있다.
- `Sequence`: Swift의 Sequence 프로토콜과는 관계없는 일반 의미다.
- `Server`: Data의 Authentication·LearningProject·Member 관심사가 같은 이름의 타입을 각각 따로 선언한다(ServerAPIError 3벌). 다른 곳에서는 서버 접근을 Remote로 부른다.
- `Service`: 유의어 중첩: 서버 API 경계를 Service, Remote(ProjectRemote), Endpoint, Client로 혼용한다.
- `Set`: 다의어: 학습 세트와 일반 집합(DesignTokenSet)으로 갈린다. 같은 학습 세트를 QuizSet(Domain)·LearningSet(Data·Feature)·ProjectSet(ProjectSetSummaryDTO, ProjectSetProgress)으로 부르는 유의어 중첩이 있다.
- `Setting`: 다의어: 앱 설정 관심사, 권한 설정 값, 설정 화면 항목으로 쓰인다. 표기 흔들림: 화면·Feature는 복수형 Settings(SettingsFeature)를, 항목·유스케이스는 단수 Setting을 쓴다.
- `Settings`: 표기 흔들림: 기능 영역은 복수형 Settings를 쓰지만 UI의 SettingRow, SelectableSettingRow, Domain의 AppSettingError는 단수형 Setting을 쓴다.
- `Share`: 표기 흔들림: 같은 기능을 ShareExtension*, ShareRegistration*, Share*(ShareViewController), Shared*(SharedItemAttachment)로 다르게 부른다.
- `Shared`: 다의어: 공유 시트로 받은 입력과 앱·확장 간 공유 저장 영역으로 나뉜다.
- `Sheet`: SourceSheet는 SwiftUI .sheet가 아니라 ModalOverlay 위에 표시되어 이름과 구현 방식이 다르다.
- `SignedIn`: 표기 흔들림: 같은 개념을 SignIn/SignedIn과 Login(LoginResponseDTO, AppleLoginRequestDTO)으로 혼용한다.
- `SignIn`: Authentication과 유의어 중첩(AuthenticationRepository와 SignInRepository 공존). SignedInAccount처럼 과거분사 형태도 쓰인다.
- `SignOut`: 유의어 중첩: SignIn(SignInRecord)과 짝을 이루지만 다른 곳에서는 Login(AppleLoginRequestDTO)을 쓴다.
- `Source`: 다의어: 문제의 근거 코드(도메인 개념)와 데이터 공급원(설계 역할)으로 나뉜다.
- `Splash`: AppEntryFeature도 스플래시 단계를 뜻해 Entry와 역할이 겹친다.
- `Stage`: 유의어 중첩: 도메인에서는 같은 생성 단계 개념을 Phase(ProjectGenerationPhase)로 표현한다.
- `State`: 다의어가 매우 많다: TCA State, 도메인 스냅샷, 잠금 보호 내부 상태, 표시 상태가 모두 State다. Status(AuthenticationStatus, DeviceRegistrationStatus, PolicyConsentStatus)와 유의어 중첩이 있고, EmptyState는 상태가 아니라 빈 목록 안내 View다.
- `Status`: 다의어: 진행 단계, 최종 결과, 권한 현재 값, 요청 직후 결과 등 의미 폭이 넓다. 유의어 중첩: State(GenerationState, ProjectGenerationState), Phase와 겹친다. NotificationAuthorizationStatus는 Domain과 Infrastructure에서 의미가 다르다.
- `Step`: 다른 라우터는 같은 개념을 ActiveScreen으로 불러 Step/Screen 유의어 중첩이 있다.
- `Stop`: 일반 의미의 멈춤과 다르다.
- `Storage`: 유의어 중첩: 같은 저장 개념에 Store(AppleIdentityStore, KeychainStore, UserDefaultsStore, LocalPendingGenerationStore)와 Repository(Domain 계약)가 함께 쓰인다.
- `Store`: Storage(UnavailableKeyValueStorage, KeyValueStorage)·Repository와 유의어 중첩이 있다. TCA의 Store(Feature Store)와도 이름이 겹쳐 혼동 소지가 있다. AppGroupKeychainStore는 저장 객체가 아니라 KeychainStore를 만드는 팩토리 역할이다.
- `Style`: 표기 흔들림: 대부분 중첩 타입 Component.Style이지만 SelectionCardStyle만 최상위 타입이다.
- `Submission`: 다의어: 도메인의 과거 제출 기록과 Feature의 제출 진행 상태로 쓰인다.
- `Submit`: 동사 원형을 타입 앞에 쓰는 DTO 명명(Register, Submit)이다.
- `Support`: 유의어 중첩: 같은 용도에 PreviewFixture(HomePreviewFixture)도 쓴다.
- `System`: 표기 흔들림: 같은 DesignSystem이 UI에서는 한 단어(DesignSystem 항목), Tuist에서는 System으로 분리되어 집계되었다.
- `Target`: Xcode/Tuist 빌드 target과 이름이 겹친다.
- `TextField`: UI의 TextField가 SwiftUI TextField와 같은 이름이라 모듈 한정 없이 쓰면 이름이 충돌할 수 있다.
- `Thumbnail`: Thumbnail과 ThumbnailView로 View 접미어 사용이 흔들린다.
- `Token`: 다의어: 디자인 토큰과 기기 푸시 토큰으로 나뉜다. 인증 액세스 토큰(Bearer)과도 구분해야 한다.
- `Transition`: 대부분 ScreenTransition이지만 Onboarding만 ScreenTransitionEvent를 써 표기가 흔들린다. SwiftUI transition(애니메이션 전환)과도 이름이 겹친다.
- `Transport`: 유의어 중첩: 전송 계약이 Data(RequestTransport)와 Infrastructure(HTTPTransport) 양쪽에 있고 요청·응답 모델도 이중화되어 있다. 어순도 RequestTransport와 TransportRequest처럼 흔들린다.
- `Tutorial`: 온보딩 흐름의 첫 단계이며, OnboardingEntryPoint에서는 "가이드"로도 불린다.
- `Unavailable`: Availability와 어근이 같지만 판정이 아니라 대체 구현을 뜻한다.
- `URL`: 유의어 중첩: 같은 저장소 주소를 Feature에서는 Link(RepositoryLinkInputFeature)로 부른다.
- `UseCase`: 구현체는 UseCase 접미어 없이 관심사 이름(Project, UserInfo, AppSetting)으로 불려 계약과 구현의 이름 규칙이 다르다.
- `User`: 유의어 중첩: 같은 대상을 Data에서는 Member(MemberRemote, MemberProfileResponseDTO)로 부른다.
- `Validation`: 유의어 중첩: 로그인 유효성 확인은 Verification(SignInVerification)으로 표현한다.
- `Verification`: 유의어 중첩: 입력·토큰 검사는 Validation으로 표현한다.
- `View`: 다의어: SwiftUI View 타입과 TCA Action.View 분류로 나뉜다. 표기 흔들림: 최상위 화면은 …Screen 접미어를 쓰고 하위 조각만 …View를 쓰지만, App의 AppRootView와 UI의 SplashView·RubricView·WebContentView는 최상위에도 View를 쓴다.
- `Withdrawal`: 유의어 중첩: 같은 행위를 설정 화면에서는 계정 삭제(SettingsFeature.AccountAction)로 표현한다.

## 전체 단어

### `Access`
- 분류: 일반 · 사용 1회 · 패키지: Infrastructure
- 정의: 접근·이용 권한. 대상에 들어가거나 사용할 수 있는 권리를 뜻한다.
  - Keychain 접근 그룹: 여러 앱·확장이 같은 Keychain 항목을 공유하도록 하는 권한 (KeychainAccessGroup)

### `Accessibility`
- 분류: 플랫폼 · 사용 1회 · 패키지: Infrastructure
- 정의: 접근 가능성. Apple Keychain에서는 기기 잠금 상태에 따라 항목을 읽을 수 있는 조건(kSecAttrAccessible)을 뜻한다.
  - Keychain 항목을 읽을 수 있는 기기 잠금 조건: KeychainAccessibility

### `Account`
- 분류: 업무 개념 · 사용 8회 · 패키지: App, Domain, Feature
- 정의: 계정. 서비스 이용자를 식별하는 단위로, 이 프로젝트에서는 Git It 사용자 계정과 그 로그인·복원·동의·탈퇴 관심사를 가리킨다.
  - Git It 사용자 계정 자체와 식별자·표시 정보 (AccountID, SignedInAccount, AccountError)
  - 계정 관심사 전체를 다루는 유스케이스와 그 구현체 (AccountUseCase, Account, AppRootPreviewSupport.NoopAccount)
  - 설정 화면에서 로그아웃·삭제 대상이 되는 로그인 계정 (SettingsFeature.AccountAction, SettingsScreen.AccountDeletionView)
- 메모: Domain의 Account가 유스케이스 구현체 이름으로도 쓰여 계정 개념(데이터)과 구현체(행위)가 같은 단어를 공유한다. SignIn·Authentication과 관심사가 겹친다.

### `Action`
- 분류: 아키텍처·패턴 · 사용 33회 · 패키지: App, Feature, UI
- 정의: 동작·행위. TCA에서는 Reducer에 전달되어 상태 변경이나 Effect를 유발하는 이벤트 열거형을 가리킨다.
  - TCA Reducer가 받는 루트 액션 열거형 (AppRootFeature.Action, HomeFeature.Action, SettingsFeature.Action)
  - 계정에 가하는 로그아웃·삭제 조작과 진행 상태, TCA Action 아님 (SettingsFeature.AccountAction)
  - 사용자가 눌러 명령을 실행하는 UI 요소 (ActionButton, ActionMenu, BottomActionBar)
- 메모: 다의어: Feature 내부 `.Action`은 TCA 액션 타입이지만 SettingsFeature.AccountAction은 TCA Action이 아닌 계정 조작 상태이고, UI의 ActionButton·ActionMenu·BottomActionBar는 사용자 명령을 뜻한다.

### `Active`
- 분류: 일반 · 사용 5회 · 패키지: Feature
- 정의: 활성의, 현재 동작 중인. 여러 후보 중 지금 선택되어 작동하는 것을 가리킨다.
  - Router Feature에서 지금 사용자에게 표시되는 화면: OnboardingRouterFeature.ActiveScreen, QuizRouterFeature.ActiveScreen, SettingsRouterFeature.State.ActiveScreen

### `Adapter`
- 분류: 아키텍처·패턴 · 사용 18회 · 패키지: Composition
- 정의: 어댑터. 한 인터페이스를 다른 인터페이스에 맞게 변환하는 설계 패턴이며, 이 프로젝트에서는 Composition이 Data 계층 구현을 Domain 프로토콜에 맞추는 구현체 접미어다.
  - Data Remote를 Domain Repository 프로토콜에 맞추는 구현체 (ProjectRepositoryAdapter, QuizSetRepositoryAdapter, WithdrawalRepositoryAdapter)
  - 로컬 Store·보안 저장소를 Domain 프로토콜에 맞추는 구현체 (PolicyConsentRepositoryAdapter, PendingGenerationRepositoryAdapter, SignInRepositoryAdapter)
  - Repository가 아닌 Domain 프로토콜(URL 파서·알림 발송기·권한)을 맞추는 구현체 (ExternalRepositoryLocatorAdapter, GenerationReminderSchedulerAdapter, NotificationAuthorizationAdapter)
- 메모: Data의 RequestTransportBridge도 두 계약을 잇는 어댑터 역할이지만 Bridge라는 다른 접미어를 쓴다. 대부분 {Domain 프로토콜}Adapter 형식이나 ExternalRepositoryLocatorAdapter·ExternalRepositoryLookupAdapter처럼 Repository 패턴이 아닌 대상에도 붙는다.

### `Agreement`
- 분류: 업무 개념 · 사용 4회 · 패키지: Feature, UI
- 정의: 동의·합의. 이 프로젝트에서는 사용자가 약관·정책 문서에 동의하는 행위를 가리킨다.
  - 약관·정책 문서 동의 화면과 행 (LegalAgreementFeature, LegalAgreementScreen.AllAgreementRow, PolicyAgreementRow)
- 메모: 유의어 중첩: Feature·UI는 Agreement, Domain·Data·Composition은 Consent(PolicyConsent)로 같은 약관 동의 개념을 표현한다.

### `All`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 전체, 모두. 대상 집합 전부를 한 번에 가리킨다.
  - 필수 정책 문서 전부를 한 번에 선택·해제하는 행: LegalAgreementScreen.AllAgreementRow

### `Animation`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 애니메이션. 시간에 따라 변하는 움직이는 그림으로, 여기서는 Lottie로 재생하는 번들 애니메이션 리소스를 가리킨다.
  - UI 모듈 번들에 담긴 Lottie 애니메이션 리소스 (ResourceAnimation)

### `Answer`
- 분류: 업무 개념 · 사용 14회 · 패키지: Composition, Feature, Domain, Data, UI
- 정의: 답·답안. 문제에 대해 사용자가 제출하는 응답을 뜻한다.
  - 사용자가 퀴즈에 제출하는 객관식·서술형 답안 (ChoiceAnswer, EssayAnswer, AnswerRepository)
  - 답안 제출 API 요청·응답 DTO와 엔드포인트 (SubmitChoiceAnswerRequestDTO, MyAnswerResponseDTO, AnswerEndpoint)
  - 답안 입력·결과 UI (QuestionSolvingScreen.AnswerEditor, QuestionSolvingFeature.AnswerOutcome, ChoiceAnswerOption)
- 메모: ChoiceAnswerOption에서는 답안이 아니라 답변 후보(보기)를 뜻해 Option·Choice와 의미가 겹친다. 유의어 중첩: 과거 제출 기록은 Submission(ChoiceSubmission)으로도 표현된다.

### `API`
- 분류: 약어 · 사용 6회 · 패키지: Data
- 정의: Application Programming Interface의 약어로, 프로그램이 다른 시스템의 기능을 호출하는 인터페이스다. 이 프로젝트에서는 Git It 백엔드 서버의 HTTP API를 가리킨다.
  - Git It 서버 HTTP API의 응답 봉투·오류: APIResponseDTO, ServerAPIError
- 메모: 약어를 전부 대문자(API)로 표기한다. Data의 Authentication·LearningProject·Member 관심사가 같은 이름의 타입을 각각 따로 선언한다(APIResponseDTO·ServerAPIError가 3벌씩).

### `App`
- 분류: 플랫폼 · 사용 22회 · 패키지: App, Composition, Domain, Data, Infrastructure, Feature
- 정의: Application의 축약으로 응용 프로그램(앱)을 뜻한다. 이 프로젝트에서는 주로 Git It iOS 앱 본체를 가리키며 UIApplication·App Group 같은 플랫폼 명칭 일부로도 쓰인다.
  - Git It iOS 앱 본체(메인 앱 타깃, 공유 확장과 구분) (AppRootFeature, AppComposition, AppEndpointHost)
  - 앱 번들·프로세스·앱 단위 설정 (AppBundleMetadata, AppLaunchSequence, AppSettingUseCase)
  - UIApplication 수명 주기·델리게이트 수준의 앱 이벤트 (PushNotificationAppDelegate, NotificationAppCallbacks, FirebaseMessagingAppDelegate)
  - App Group 공유 컨테이너 명칭의 일부 (AppGroupKeychainStore, AppGroupUserDefaults)
  - SwiftUI App 프로토콜을 채택한 앱 진입 타입 (GitItApp)
- 메모: 다의어: 앱 본체 타깃, UIApplication 수명 주기, App Group 명칭 일부, SwiftUI App 프로토콜로 의미가 갈린다. AppEntry(Feature)와 AppRoot(App)가 모두 앱 진입 지점을 가리켜 역할 구분이 이름만으로는 드러나지 않는다.

### `Apple`
- 분류: 브랜드 · 사용 14회 · 패키지: Data, Infrastructure, UI
- 정의: 외부 고정 명칭 Apple. 이 프로젝트에서는 Sign in with Apple과 Apple ID 로그인 관련 플랫폼 기능을 가리킨다.
  - Sign in with Apple 로그인 흐름·자격 증명 (AppleSignInCredential, AppleAuthorizationProvider, AppleCredential)
  - Apple ID 사용자 식별 정보 저장 (AppleIdentityStore, AppleIdentityStorageLayout)
  - Apple 로그인 버튼과 로그인 요청 DTO (AppleSignInButton, AppleLoginRequestDTO)
- 메모: 유의어 중첩·표기 흔들림: 같은 로그인 흐름을 Data는 AppleSignIn*, Infrastructure는 AppleAuthorization*/AppleCredential*로, DTO는 AppleLogin*으로 부른다(SignIn/Login/Authorization 혼용).

### `Assembly`
- 분류: 아키텍처·패턴 · 사용 6회 · 패키지: Composition
- 정의: 조립체. 여러 의존성을 생성·연결해 하나로 묶은 결과물을 뜻하는 설계 용어다.
  - Composition에서 관심사별 의존성을 생성·연결해 묶은 결과 구조체: ConcernUseCaseAssembly, AuthenticationAssembly, LearningProjectAssembly

### `Asset`
- 분류: 플랫폼 · 사용 2회 · 패키지: UI
- 정의: 자산·애셋. 앱 번들에 담긴 이미지·애니메이션 같은 리소스 파일을 뜻하며, 여기서는 그 리소스 식별자 열거형 이름이다.
  - 번들 리소스 파일의 식별자 (ResourceAnimation.Asset, ResourceImage.Asset)
- 메모: Resource와 의미가 겹친다(ResourceImage.Asset처럼 두 단어가 중첩되어 쓰임).

### `Attachment`
- 분류: 플랫폼 · 사용 1회 · 패키지: App
- 정의: 첨부물. 이 프로젝트에서는 공유 항목에 딸린 개별 데이터 제공자(NSItemProvider)를 가리킨다.
  - 공유 확장으로 들어온 항목의 개별 첨부 데이터 제공자 (SharedItemAttachment)

### `Attempt`
- 분류: 일반 · 사용 1회 · 패키지: Infrastructure
- 정의: 시도. 한 번 수행되는 시도의 단위를 뜻한다.
  - nonce·state·만료 시각을 묶은 Apple 인가 시도 한 건: AppleAuthorizationAttempt

### `Authentication`
- 분류: 업무 개념 · 사용 9회 · 패키지: Composition, Domain, Data, Feature
- 정의: 인증. 사용자의 신원을 확인하는 절차이며, 여기서는 Apple 로그인과 서버 로그인·토큰 검증 API, 세션 복원을 포괄한다.
  - Apple 등 외부 제공자로 신원을 확인하는 절차와 그 결과 (AuthenticationRepository, AuthenticationGrant, AuthenticationRepositoryAdapter)
  - 로그인·토큰 검증 서버 API 영역 (AuthenticationEndpoint, AuthenticationRemote, AuthenticationServiceError)
  - 화면 흐름에서 세션 복원·Apple 로그인 진행 상태 (AppEntryFeature.AuthenticationStatus, TutorialFeature.AuthenticationStatus)
  - 세션 자격 증명과 로그인 상태를 조립하는 관심사 (AuthenticationAssembly)
- 메모: SignIn과 유의어 중첩이 크다: Domain에 AuthenticationRepository와 SignInRepository가 공존하고, Feature의 AuthenticationStatus가 가리키는 대상이 세션 복원(AppEntry)과 Apple 로그인(Tutorial)으로 다르다.

### `Authorization`
- 분류: 플랫폼 · 사용 12회 · 패키지: Composition, Domain, Data, Infrastructure
- 정의: 인가·권한 부여. 어떤 동작을 허용받는 과정이나 그 권한 상태를 뜻한다.
  - iOS 알림 표시 권한과 그 요청·조회 (NotificationAuthorization, NotificationAuthorizationClient, ReminderAuthorizationStatus)
  - ASAuthorizationController로 Apple ID 자격 증명 사용을 허가받는 흐름 (AppleAuthorizationProvider, AppleAuthorizationAttempt, AppleAuthorizationError)
- 메모: 다의어: 알림 권한과 Apple 로그인 인가라는 서로 다른 두 의미로 쓰인다. 유의어 중첩: 알림 권한 상태를 NotificationAuthorizationStatus/Setting과 ReminderAuthorizationStatus/Setting으로 계층마다 다르게 부르며, Domain과 Infrastructure에 같은 이름 NotificationAuthorizationStatus가 존재한다.

### `Authorized`
- 분류: 일반 · 사용 1회 · 패키지: Data
- 정의: 권한이 부여된, 인증된. 접근 자격을 갖춘 상태를 나타낸다.
  - Bearer 액세스 토큰이 포함된 요청 헤더: AuthorizedRequestHeaders

### `Availability`
- 분류: 일반 · 사용 2회 · 패키지: Composition, Domain
- 정의: 가용성·이용 가능 여부. 어떤 대상을 지금 쓸 수 있는지에 대한 판정을 뜻한다.
  - 세션·로그인 상태를 바로 쓸 수 있는지, 로그인이나 앱 실행이 필요한지의 판정 (SignInAvailability, SessionAvailabilityAssembly)
- 메모: Unavailable(UnavailableKeyValueStorage)과 같은 어근이지만 그쪽은 판정이 아닌 무동작 대체 구현을 뜻한다.

### `Available`
- 분류: 일반 · 사용 1회 · 패키지: Data
- 정의: 이용 가능한. 선택하거나 사용할 수 있는 상태를 뜻한다.
  - 북마크 목록에서 필터로 선택할 수 있는 프로젝트 (AvailableProjectResponseDTO)

### `Backend`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: Infrastructure
- 정의: 후단. 앞단 인터페이스 뒤에서 실제 처리를 담당하는 구현을 뜻한다.
  - KeychainStore가 저장을 위임하는 메모리 구현체: KeychainStore.InMemoryBackend
- 메모: "Backend server"(서버) 의미가 아니라 저장 위임 구현을 가리킨다.

### `Badge`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 배지. 짧은 정보를 표시하는 작은 표식으로, 여기서는 배경이 있는 알약형 라벨 View다.
  - 배경이 있는 작은 알약형 라벨 컴포넌트 (TagBadge)
- 메모: Chip과 형태가 비슷하나 Chip은 선택 가능한 버튼, Badge는 표시 전용 라벨로 구분된다.

### `Bar`
- 분류: 일반 · 사용 5회 · 패키지: Feature, UI
- 정의: 막대·띠. 가로로 긴 형태의 UI 요소나 차트 막대를 뜻한다.
  - 가로 띠 형태의 버튼 컨테이너 (BottomActionBar, ScreenControlBar)
  - 진행률을 나타내는 캡슐형 막대 View (ContinuousProgressBar, LabeledProgressBar)
  - 막대 차트에서 요일 하나의 풀이 수 데이터 (ProfileDisplay.WeeklyBar)
- 메모: 다의어: 버튼을 담는 띠 컨테이너, 진행률 막대, 차트 막대 데이터로 쓰인다.

### `Body`
- 분류: 일반 · 사용 3회 · 패키지: Infrastructure
- 정의: 본문. 메시지에서 헤더를 제외한 내용 부분을 뜻한다.
  - HTTP 메시지 본문 인코딩·디코딩 방식: HTTPBodyCoding, StandardJSONBodyCoding
  - HTTP 응답 본문이 디코딩된 값인지 원본 바이트인지 구분한 표현: HTTPResponse.Body

### `Bookmark`
- 분류: 업무 개념 · 사용 15회 · 패키지: Composition, Domain, Data, Feature, UI
- 정의: 책갈피·즐겨찾기. 나중에 다시 보려고 표시해 두는 것으로, 여기서는 사용자가 저장해 둔 퀴즈 문항과 그 설정·해제 동작을 가리킨다.
  - 사용자가 저장해 둔 퀴즈 항목과 목록·필터·상태 모델 (QuizBookmark, QuizBookmarkList, QuizBookmarkState)
  - 북마크 설정·해제와 목록 조회 서버 API·데이터 접근 계약 (BookmarkEndpoint, BookmarkRemote, BookmarkRepository)
  - 화면에서 현재 문제를 저장 목록에 넣고 빼는 동작과 버튼 (QuestionSolvingFeature.BookmarkMutation, SavedFeature.BookmarkMutation, BookmarkButton)
- 메모: Saved(SavedFeature, SavedQuestionCard)와 같은 대상을 가리키는 유의어 중첩이 있다. Domain은 Quiz 접두어(QuizBookmark), Data는 Question 접두어(BookmarkQuestionRequestDTO, BookmarkedQuestionListResponseDTO)를 써 대상 명칭이 흔들린다.

### `Bookmarked`
- 분류: 업무 개념 · 사용 2회 · 패키지: Data
- 정의: 북마크된. 북마크 표시가 이미 된 상태를 나타내는 과거분사.
  - 북마크 표시된 문제와 그 목록 응답 (BookmarkedQuestionResponseDTO, BookmarkedQuestionListResponseDTO)
- 메모: 형태 흔들림: 같은 개념을 BookmarkQuestionRequestDTO처럼 원형 Bookmark로도 쓴다(변경 요청은 Bookmark, 조회 결과는 Bookmarked).

### `Bootstrap`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: Composition
- 정의: 초기 기동, 부트스트랩. 시스템이나 구성 요소를 처음 활성화하는 과정을 뜻한다.
  - 푸시 클라이언트 최초 활성화 전 토큰 요청 실패: AppComposition.PushBootstrapError
- 메모: App의 Launch(앱 시작 단계)와 의미가 가깝다.

### `Border`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 테두리. 요소 외곽을 두르는 선을 뜻한다.
  - 컴포넌트 외곽선의 두께와 색 토큰 (BorderToken)

### `Bottom`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 아래쪽. 화면이나 요소의 하단 위치를 뜻한다.
  - 화면 하단에 고정되는 동작 버튼 바 (BottomActionBar)

### `Box`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: Composition
- 정의: 상자. 값을 참조 타입으로 감싸 여러 곳에서 공유하게 하는 컨테이너 관용 패턴이다.
  - 여러 클로저가 푸시 클라이언트 참조를 공유하도록 감싼 컨테이너: AppComposition.PushClientBox

### `Bridge`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: Data
- 정의: 다리·연결. 서로 다른 두 인터페이스를 잇는 연결부로, 여기서는 Data의 RequestTransport와 Infrastructure의 HTTPTransport 계약을 잇는 타입이다.
  - 두 전송 계약을 잇는 연결 타입 (RequestTransportBridge)
- 메모: 역할상 Composition의 *Adapter와 같은 변환 구현이지만 다른 접미어를 써 Adapter와 유의어 중첩이 있다.

### `Builder`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: Infrastructure
- 정의: 빌더·조립기. 부분 값을 모아 완성된 객체를 만드는 빌더 패턴 객체.
  - 경로·쿼리 등 부분 값을 합쳐 URL을 만드는 객체 (RequestURLBuilder)
- 메모: 유의어 중첩: 객체 생성 책임을 Builder, Factory, Assembly/Composition이 나누어 쓴다.

### `Bundle`
- 분류: 플랫폼 · 사용 2회 · 패키지: App
- 정의: 묶음, 번들. Apple 플랫폼에서는 실행 파일·Info.plist·리소스를 담은 Foundation Bundle을 뜻한다.
  - 앱 번들의 Info.plist 메타데이터와 리소스 파일: AppBundleMetadata, AppBundleResource

### `Button`
- 분류: 플랫폼 · 사용 5회 · 패키지: UI
- 정의: 버튼. 눌러서 동작을 실행하는 UI 요소로, 여기서는 SwiftUI Button을 감싼 UI 컴포넌트 접미어다.
  - SwiftUI Button을 감싼 범용 버튼 컴포넌트 (ActionButton, IconGlassButton, IconPlainButton)
  - 특정 동작 전용 버튼 컴포넌트 (AppleSignInButton, BookmarkButton)

### `Cache`
- 분류: 일반 · 사용 1회 · 패키지: Infrastructure
- 정의: 캐시. 빠른 재사용을 위해 값을 임시로 저장하는 저장소.
  - 키로 값을 넣고 꺼내는 메모리 임시 저장소 (InMemoryCache)
- 메모: 유의어 중첩: 저장 책임을 Cache, Store, Storage, Repository가 나누어 표현한다.

### `Callbacks`
- 분류: 아키텍처·패턴 · 사용 2회 · 패키지: Data, Infrastructure
- 정의: 콜백 함수들. 특정 사건이 일어날 때 호출되도록 넘겨 둔 함수 묶음이다.
  - 기기 토큰 수신과 원격 메시지 payload 수신 시 호출될 클로저 묶음: NotificationAppCallbacks, PushNotificationCallbacks
- 메모: Data와 Infrastructure에 같은 역할의 콜백 묶음 타입이 각각 있다.

### `Cancel`
- 분류: 아키텍처·패턴 · 사용 17회 · 패키지: App, Feature
- 정의: 취소. 진행 중인 작업을 중단하는 것으로, 여기서는 TCA Effect 취소 식별자(CancelID) 이름에 쓰인다.
  - 실행 중인 TCA Effect를 중단하기 위한 취소 식별자 (AppRootFeature.CancelID, HomeFeature.CancelID, ShareRegistrationFeature.CancelID)
- 메모: 모든 용례가 {Feature}.CancelID 형식으로 통일되어 있다.

### `Card`
- 분류: 일반 · 사용 9회 · 패키지: Feature, UI
- 정의: 카드. 이 프로젝트에서는 모서리가 둥근 박스형 UI 컴포넌트를 뜻한다.
  - 모서리가 둥근 카드형 UI 컴포넌트 (HomeProjectCard, SavedQuestionCard, SelectionCard)
  - 배경과 모서리를 가진 카드형 레이아웃 컨테이너 (LabeledCard, ProfileScreen.StatisticsCardView)
  - 카드 배치·실루엣 계산용 데이터 (HomeCardScrollLayout, HomeScreen.EmptyDeckShape.Card)

### `Career`
- 분류: 업무 개념 · 사용 7회 · 패키지: Feature, Domain, Data
- 정의: 경력, 직업 이력. 이 서비스에서는 사용자의 개발 경력 수준(CareerLevel: 입문·주니어·미들·시니어)을 뜻한다.
  - 사용자 개발 경력 수준 모델과 서버 전송값: CareerLevel, CareerLevelDTO, CareerLevelRequestDTO
  - 경력 수준을 고르고 표시하는 화면: CareerSelectionFeature, SettingsScreen.CareerLevelSelectionView, CareerLevelDisplay
- 메모: 일부 용례는 "코드 이해 수준"·"개발 수준"·"연차"로도 설명되어 같은 개념의 한국어 표현이 흔들린다.

### `Cause`
- 분류: 일반 · 사용 2회 · 패키지: Feature
- 정의: 원인·이유. 어떤 결과를 일으킨 계기를 뜻한다.
  - 라우터 화면 전환을 유발한 자식 delegate·사용자 행위·진행 조건 (ProjectDetailRouterFeature.ScreenTransition.Cause, QuizRouterFeature.ScreenTransition.Cause)

### `Chart`
- 분류: 일반 · 사용 2회 · 패키지: Feature, Data
- 정의: 도표·차트. 데이터를 시각적으로 나타낸 그래프.
  - 요일별 풀이 수 막대 차트와 그 데이터 (ProfileScreen.WeeklyChartView, WeeklyChartItemDTO)

### `Checklist`
- 분류: 일반 · 사용 2회 · 패키지: Feature
- 정의: 점검 목록. 확인할 항목을 차례로 나열한 목록이다.
  - 퀴즈 생성 단계(정보 확인·구조 분석·개념 구성·문제 생성·검증) 목록과 항목 상태: QuizGenerationProgressScreen.ChecklistView, QuizGenerationProgressScreen.ChecklistStatus

### `Chip`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 칩. 작은 조각을 뜻하며 UI에서는 필터·태그를 고르는 작은 알약형 선택 요소를 가리킨다.
  - 필터·태그를 고르는 알약형 선택 버튼 (Chip)
- 메모: Badge와 모양이 비슷하나 Chip은 선택 가능, Badge는 표시 전용이다.

### `Choice`
- 분류: 업무 개념 · 사용 9회 · 패키지: Feature, Domain, Data, UI
- 정의: 선택·선택지. 이 프로젝트에서는 보기 중 하나를 고르는 객관식(선택형) 문제 형식을 뜻한다.
  - 선택형 퀴즈의 답안·채점·제출 기록 (ChoiceAnswer, ChoiceGrading, ChoiceSubmission)
  - 객관식 답안 제출 요청·응답 DTO (SubmitChoiceAnswerRequestDTO, SubmitChoiceAnswerResponseDTO)
  - 객관식 보기 표시 UI (ChoiceAnswerOption, ChoiceResultRow, ChoiceOptionDisplay)
- 메모: 유의어 중첩: 보기 항목 하나를 Choice와 Option이 함께 가리키고(ChoiceAnswerOption, ChoiceOptionDisplay), 사용자의 고르는 행위는 Selection으로 따로 표현한다.

### `Client`
- 분류: 아키텍처·패턴 · 사용 11회 · 패키지: Composition, Data, Infrastructure
- 정의: 클라이언트, 이용 주체. 다른 시스템이나 API를 호출하는 쪽 객체를 뜻한다.
  - HTTP 요청을 조립·전송하고 응답을 해석하는 객체: HTTPClient, HTTPClientError, RequestClientFactory
  - 푸시 서비스에서 등록 토큰을 얻는 접근 객체: PushMessagingClient, FirebaseMessagingPushClient, AppComposition.PushClientBox
  - 로컬 알림 권한·발송 API를 호출하는 객체: NotificationAuthorizationClient, LocalNotificationAuthorizationClient, ReminderNotificationClient
- 메모: Data의 Remote(원격 데이터 접근 객체)와 역할이 겹친다. Data에서는 Infrastructure API 호출 객체(ReminderNotificationClient, RemoteMessageClient)에 Client를 쓴다.

### `Coding`
- 분류: 아키텍처·패턴 · 사용 4회 · 패키지: Data, Infrastructure
- 정의: 부호화. 값을 다른 표현으로 인코딩·디코딩하는 책임을 뜻하며, Swift Codable 관례에서 온 명칭이다.
  - Swift 값과 HTTP 본문 Data 사이의 변환 계약과 JSON 구현 (HTTPBodyCoding, StandardJSONBodyCoding)
  - 레코드·마커를 키-값 저장소에 넣고 꺼내기 위한 변환 (SessionRecordStorageCoding, SharedSessionStateMarkerCoding)

### `CodingKeys`
- 분류: 플랫폼 · 사용 14회 · 패키지: Data
- 정의: Swift Codable 관례의 외부 고정 명칭(Coding + Keys). 프로퍼티 이름과 JSON 키를 대응시키는 열거형이다.
  - DTO 프로퍼티와 서버 JSON 키의 대응 (LearningSetResponseDTO.CodingKeys, ProjectListItemDTO.CodingKeys, DeviceInfoRequestDTO.CodingKeys)
  - GitHub API JSON 최상위·하위 필드 매핑 (GitHubRepositoryResponseDTO.CodingKeys, GitHubRepositoryResponseDTO.OwnerCodingKeys)

### `Color`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 색. 디자인 시스템에서는 hex와 불투명도로 정의한 색 값을 뜻한다.
  - hex·불투명도로 정의된 디자인 색 토큰: ColorToken

### `Completion`
- 분류: 일반 · 사용 2회 · 패키지: Feature
- 정의: 완료·끝마침. 일을 모두 마친 상태를 뜻한다.
  - 학습 세트의 모든 문제를 마친 뒤의 화면·리듀서 (LearningCompletionFeature, LearningCompletionScreen)

### `Composition`
- 분류: 아키텍처·패턴 · 사용 2회 · 패키지: Composition
- 정의: 합성·조립. 이 프로젝트에서는 UseCase와 인프라 의존성을 한데 묶는 조립 루트(Composition Root)를 뜻한다.
  - 앱·공유 확장 타깃별 의존성 조립 루트 (AppComposition, ShareExtensionComposition)
- 메모: 유의어 중첩: 조립 책임을 Composition(루트)과 Assembly(ConcernUseCaseAssembly, LearningProjectAssembly)가 함께 쓴다. 패키지 이름 Composition과도 같다.

### `Concern`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: Composition
- 정의: 관심사. 설계에서 하나의 책임 단위로 분리한 영역을 뜻한다.
  - Account·UserInfo·AppSetting·QuizDetail·Project 등 Domain 관심사 단위로 UseCase를 묶은 조립체: ConcernUseCaseAssembly

### `Confirmation`
- 분류: 일반 · 사용 5회 · 패키지: Feature, UI
- 정의: 확인·확정. 진행 전에 사용자에게 최종 동의를 받는 것을 뜻한다.
  - 등록 흐름에서 저장소가 맞는지, 생성을 시작할지 확인하는 단계 (RepositoryConfirmationFeature, QuizGenerationConfirmationFeature, QuizGenerationConfirmationScreen)
  - 되돌릴 수 없는 동작 전 최종 동의를 받는 시트 컴포넌트 (ConfirmationSheet)

### `Consent`
- 분류: 업무 개념 · 사용 7회 · 패키지: Composition, Domain, Data
- 정의: 동의. 이 프로젝트에서는 사용자가 특정 버전의 약관 문서에 동의한 기록을 뜻한다.
  - 약관 문서 버전별 사용자 동의 기록과 상태 (PolicyConsent, PolicyConsentStatus, PolicyConsentRepository)
  - 동의 기록 저장·DTO (LocalPolicyConsentStore, PolicyConsentRecordDTO, PolicyConsentStorageLayout)
- 메모: 유의어 중첩: Feature·UI의 Agreement(LegalAgreementFeature, PolicyAgreementRow)와 같은 개념을 가리킨다.

### `Constant`
- 분류: 아키텍처·패턴 · 사용 91회 · 패키지: Feature, UI
- 정의: 상수. 변하지 않는 고정 값을 뜻하며, 이 프로젝트에서는 타입 내부에 고정 값을 모아 두는 네임스페이스 enum 관례 이름이다.
  - Feature 화면·하위 View의 레이아웃 수치와 고정 문구 네임스페이스: HomeScreen.Constant, ProjectDetailScreen.Constant, SettingsScreen.AccountDeletionView.Constant
  - Feature Reducer 내부 고정 값(재시도 한도, 약관 URL 등): AppEntryFeature.Constant, SettingsFeature.Constant, TutorialFeature.Constant
  - UI 컴포넌트의 레이아웃 치수·색·시간 고정값: Chip.Constant, SheetSurface.Constant, SplashView.Constant
- 메모: 대부분 레이아웃 수치 모음이지만 문구, 메뉴 정의, 그라데이션·스타일 토큰, 진행률 시뮬레이션 설정, 파생 계산 함수까지 담는 경우가 있어 담는 내용의 범위가 타입마다 다르다.

### `Container`
- 분류: 일반 · 사용 2회 · 패키지: UI
- 정의: 그릇·컨테이너. 다른 요소를 담는 틀로, 여기서는 화면 콘텐츠를 감싸 공통 레이아웃을 입히는 스캐폴드 View다.
  - 화면 전체 레이아웃·공통 배경을 구성하는 스캐폴드 View (ScreenContainer, OverlayContainer)
- 메모: OverlayContainer는 Overlay와 Container가 겹쳐 있으며, Overlay가 다른 타입(ModalOverlay 등)에서는 화면 위에 겹치는 View 자체를 뜻해 의미가 다르다.

### `Content`
- 분류: 일반 · 사용 7회 · 패키지: App, Composition, Feature, Domain, UI
- 정의: 내용·콘텐츠. 어떤 틀 안에 채워지는 실제 내용물.
  - 로컬 알림의 제목·본문 문자열 (GenerationReminderContent, ConcernUseCaseAssembly.GenerationReminderContent)
  - 보기 목록·서술형 여부·과거 제출을 담는 문제 본문 (QuizContent)
  - View 안에 채워지는 표시 내용 (WebContentView, ContentHeightPreferenceKey, SettingsScreen.SettingRowContent)
- 메모: 다의어: 알림 문구, 도메인 문제 본문, UI 표시 내용으로 쓰인다. 같은 이름 GenerationReminderContent가 App과 Composition 두 Assembly에 중복 존재한다.

### `Continuous`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 연속적인. 끊기거나 구간으로 나뉘지 않고 이어지는 것을 뜻한다.
  - 구간 없이 비율로 매끄럽게 채워지는 진행 막대: ContinuousProgressBar
- 메모: UI의 ProgressSegments(구간형 진행 표시)와 대비된다.

### `Control`
- 분류: 플랫폼 · 사용 4회 · 패키지: UI
- 정의: 제어·컨트롤. 사용자가 조작하는 UI 요소 또는 그 제어 방식을 뜻한다.
  - 화면 상단 바의 뒤로 가기·닫기 같은 제어 버튼 (ScreenControlBar, ScreenControlBar.Control)
  - 버튼처럼 누르는 UI 요소의 크기 토큰 (ControlSizeToken)
  - 펼침이 고정인지 토글 가능한지의 제어 방식 (ChoiceAnswerOption.ExpansionControl)
- 메모: 다의어: UI 조작 요소(명사)와 동작 제어 방식(ExpansionControl)으로 의미가 갈린다.

### `Controller`
- 분류: 플랫폼 · 사용 1회 · 패키지: App
- 정의: 제어기. UIKit에서 뷰를 관리하는 UIViewController를 뜻한다.
  - 공유 확장 화면을 관리하는 UIViewController (ShareViewController)

### `Corner`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 모서리. 도형의 꼭짓점 부분을 뜻한다.
  - 사각형 View 모서리 둥글기 디자인 토큰: CornerRadiusToken

### `Count`
- 분류: 일반 · 사용 1회 · 패키지: Domain
- 정의: 개수·횟수.
  - 요일 하나에 해당하는 학습 횟수 (WeeklyLearningCount)

### `Credential`
- 분류: 일반 · 사용 6회 · 패키지: Data, Infrastructure
- 정의: 자격 증명. 신원이나 권한을 증명하는 값.
  - Apple ID 로그인 결과의 사용자 식별자·토큰 묶음과 그 상태 (AppleCredential, AppleSignInCredential, AppleCredentialState)
  - 서버 요청에 첨부할 액세스 토큰 상태 (RequestCredential, RequestCredentialProvider)
- 메모: 다의어: Apple 로그인 자격 증명과 서버 요청용 액세스 토큰 자격을 모두 가리킨다. 유의어 중첩: AppleCredential(Infrastructure)과 AppleSignInCredential(Data)이 계층별로 병존한다.

### `Criterion`
- 분류: 일반 · 사용 1회 · 패키지: Data
- 정의: 기준(단수). 평가나 판단에 쓰는 개별 항목이다.
  - 루브릭을 이루는 개별 채점 기준 한 항목: RubricCriterionResponseDTO

### `Curation`
- 분류: 업무 개념 · 사용 4회 · 패키지: Domain, Data, Feature
- 정의: 큐레이션·선별. 대상에 맞춰 골라 구성하는 것으로, 여기서는 사용자의 직군(position)과 경력 수준(career)으로 이루어진 맞춤 학습 설정이다.
  - 직군·경력으로 이루어진 맞춤 학습 설정 모델과 서버 등록 요청 (Curation, CurationRequestDTO)
  - 온보딩의 직무·경력 선택 단계와 그 완료 후 화면 (OnboardingRouterFeature.ActiveScreen.Curation, OnboardingRouter.CurationSplashView)
- 메모: CurationSplashView에서는 선택 단계 자체가 아니라 선택 단계가 끝난 뒤를 뜻해 단계 명칭과 시점이 어긋난다.

### `Cursor`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 커서. 텍스트 입력·표시 위치를 나타내는 표시.
  - 타자 효과 끝에 표시되는 세로 막대 커서의 표시 상태 (SplashView.Cursor)

### `Data`
- 분류: 일반 · 사용 3회 · 패키지: Data
- 정의: 데이터, 자료. 이 프로젝트 타입 이름에서는 서버 응답 봉투의 data 필드에 담기는 페이로드를 뜻한다.
  - APIResponseDTO의 data 필드가 비어 있는 응답 페이로드: EmptyResponseData
- 메모: 패키지 이름 Data와 철자가 같지만 여기서는 응답 필드 이름을 가리킨다. Data의 Authentication·LearningProject·Member 관심사가 같은 이름의 타입을 각각 따로 선언한다(EmptyResponseData 3벌).

### `Deck`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 카드 한 벌·묶음.
  - 홈 화면 빈 상태에서 겹쳐 놓인 프로젝트 카드 묶음 도형 (HomeScreen.EmptyDeckShape)

### `Delegate`
- 분류: 아키텍처·패턴 · 사용 32회 · 패키지: Composition, Feature, Data, Infrastructure
- 정의: 위임자·대리인. 처리를 다른 객체에 넘기는 위임 패턴의 참여자를 뜻한다.
  - 자식 Reducer가 결과를 부모 Reducer에 넘기는 TCA 위임 액션 묶음 (HomeFeature.Action.Delegate, QuizRouterFeature.Action.Delegate, SettingsFeature.Action.Delegate)
  - UIApplication 생명주기·알림 이벤트를 위임받는 UIApplicationDelegate 객체 (FirebaseMessagingAppDelegate, PushNotificationAppDelegate, NotificationAppDelegate)
- 메모: 다의어: TCA의 부모 전달용 액션 분류와 iOS AppDelegate 관용 표현(App+Delegate)이라는 두 의미로 쓰인다. 유의어 중첩: 비슷한 AppDelegate가 Composition(PushNotificationAppDelegate), Data(NotificationAppDelegate), Infrastructure(FirebaseMessagingAppDelegate, PushMessagingAppDelegate)에 흩어져 있고 Notification/PushNotification/PushMessaging 표기가 섞여 있다.

### `Deletion`
- 분류: 일반 · 사용 3회 · 패키지: Feature
- 정의: 삭제, 제거 행위. 대상을 지우는 절차를 명사로 나타낸다.
  - 프로젝트를 삭제하는 흐름의 진행 단계: ProjectDetailFeature.Deletion, ProjectListFeature.Deletion
  - 계정과 개인정보를 지우는 회원 탈퇴 화면: SettingsScreen.AccountDeletionView
- 메모: 프로젝트 삭제와 계정 삭제(탈퇴)라는 서로 다른 대상에 쓰인다.

### `Delivery`
- 분류: 일반 · 사용 1회 · 패키지: Infrastructure
- 정의: 전달·배송.
  - 콜백으로 넘길 푸시 토큰과 payload의 한 회분 묶음 (FirebaseMessagingAppDelegate.PendingDelivery)

### `Dependencies`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: Tuist
- 정의: 의존성(복수). 대상이 필요로 하는 외부 구성 요소 목록.
  - target이 링크하는 외부 라이브러리 목록의 이름 (ExternalDependenciesName)

### `Design`
- 분류: 일반 · 사용 2회 · 패키지: UI, Tuist
- 정의: 디자인, 설계. 이 프로젝트에서는 앱의 시각 디자인 체계(DesignSystem)를 뜻한다.
  - 시각 디자인 규칙을 담는 DesignSystem 모듈·토큰 집합: DesignSystemFontFamily, DesignTokenSet

### `DesignSystem`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: UI
- 정의: 디자인 시스템. 색·타이포·효과 등 토큰 기반 디자인 규칙의 모음이며, 여기서는 그 규칙을 담은 모듈명이기도 하다.
  - 토큰 기반 디자인 규칙과 DesignSystem 모듈명 (DesignSystemEffectModifier)
- 메모: Tuist의 DesignSystemFontFamily에서는 Design과 System이 별개 단어로 분해되어 집계되어 표기 단위가 흔들린다(System 항목 참고).

### `Destination`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: Feature
- 정의: 목적지·행선지. 내비게이션에서 이동할 대상 화면을 뜻한다.
  - 앱 진입 판정 후 이동할 화면(메인 셸 또는 온보딩) (AppEntryFeature.Destination)

### `Detail`
- 분류: 일반 · 사용 12회 · 패키지: App, Feature, Domain, Data
- 정의: 상세, 세부. 요약보다 많은 정보를 담은 상세 정보나 상세 화면을 뜻한다.
  - 프로젝트 한 건의 저장소 정보·학습 세트 진행 현황 상세 모델과 화면: ProjectDetail, ProjectDetailResponseDTO, ProjectDetailFeature
  - 퀴즈 세트 조회·채점·북마크를 다루는 퀴즈 상세 관심사: QuizDetailUseCase, QuizDetail, QuizDetailError
  - 이름·이메일·학습 통계로 이루어진 사용자 상세 정보: UserDetail
- 메모: 다의어: ProjectDetail·UserDetail은 상세 데이터 모델이지만 QuizDetail은 조회·채점·북마크까지 포괄하는 관심사(UseCase) 이름이다. Domain QuizDetail은 모델이 아니라 유스케이스 구현체다.

### `Device`
- 분류: 업무 개념 · 사용 11회 · 패키지: App, Composition, Domain, Data
- 정의: 기기·장치. 여기서는 앱이 설치·실행되는 iOS 기기로, 푸시 알림 수신을 위한 식별자·토큰·서버 등록 대상이다.
  - 기기 식별자와 그 로컬 저장·접근 계약 (DeviceID, DeviceIdentifierRepository, LocalDeviceIdentifierStore)
  - 기기 정보·푸시 토큰의 서버 등록 (DeviceRegistration, DeviceRegistrationRepositoryAdapter, AppRootFeature.DeviceRegistrationStatus)
  - 등록 대상 기기의 플랫폼·푸시 토큰·요청 DTO (DevicePlatform, DeviceToken, DeviceInfoRequestDTO)
- 메모: 표기 흔들림: 식별자를 DeviceID(약어)와 DeviceIdentifier(전체 표기)로 함께 쓴다.

### `Diagnostic`
- 분류: 일반 · 사용 2회 · 패키지: App, Feature
- 정의: 진단의. 문제 원인 파악을 위한 정보나 기록을 뜻한다.
  - 공유 등록 흐름의 진행·실패 원인 추적용 로그와 이벤트 (ShareRegistrationDiagnosticLog, ShareRegistrationDiagnosticEvent)

### `Dismiss`
- 분류: 플랫폼 · 사용 1회 · 패키지: Feature
- 정의: 해제, 닫기. Apple UI에서는 표시된 화면·키보드를 내리는 동작을 뜻한다.
  - 포커스를 풀어 키보드를 내리는 레이어: RepositoryLinkInputScreen.KeyboardDismissLayer

### `Display`
- 분류: 아키텍처·패턴 · 사용 12회 · 패키지: Feature
- 정의: 표시. 화면에 보여 주는 것으로, 여기서는 Domain 값을 View가 바로 그릴 수 있게 가공한 표시 전용 모델 접미어다.
  - Domain 모델을 카드·행·화면 표시 형태로 가공한 표시용 모델 (HomeProjectDisplay, ProjectListDisplay, SavedQuestionDisplay)
  - 도메인 값을 문자열·이미지로 바꾸는 변환 역할 (CareerLevelDisplay, PositionDisplay)
  - 화면 내부에 중첩된 표시 모델 (CareerSelectionScreen.Display, PositionSelectionScreen.Display)
- 메모: 다의어: 표시용 데이터 모델과 도메인 값→문자열 변환기 역할로 갈린다. 최상위 타입(ProfileDisplay)과 Screen 중첩 타입(CareerSelectionScreen.Display)으로 선언 위치도 흔들린다.

### `Document`
- 분류: 업무 개념 · 사용 2회 · 패키지: Domain
- 정의: 문서. 이 프로젝트에서는 버전과 URL을 가진 약관 문서 한 건을 뜻한다.
  - 약관 문서와 그 식별자 (PolicyDocument, PolicyDocumentID)

### `DTO`
- 분류: 약어 · 사용 44회 · 패키지: Data
- 정의: Data Transfer Object의 약어로, 계층이나 시스템 사이에서 데이터를 옮기는 전송 전용 구조체다.
  - 서버 JSON을 디코딩하는 응답 전송 객체: APIResponseDTO, LoginResponseDTO, ProjectListResponseDTO
  - 서버로 보낼 JSON을 인코딩하는 요청 전송 객체: AppleLoginRequestDTO, SubmitEssayAnswerRequestDTO, RegisterProjectRequestDTO
  - 로컬 저장소나 푸시 페이로드를 Codable로 옮기는 전송·저장 구조: GenerationRecordDTO, PolicyConsentRecordDTO, QuizGenerationOutcomeDTO
- 메모: Request/Response 접미 규칙이 섞여 있다: 대부분 RequestDTO/ResponseDTO를 쓰지만 CareerLevelDTO, PositionDTO, QuizLevelDTO, ProjectListItemDTO, ProjectSetSummaryDTO, WeeklyChartItemDTO, FieldErrorDTO는 방향 표기가 없다. 서버 전송이 아닌 로컬 저장·푸시 페이로드에도 DTO를 쓴다. Data의 Authentication·LearningProject·Member 관심사가 같은 이름의 타입을 각각 따로 선언한다(APIResponseDTO·FieldErrorDTO 3벌씩).

### `Edge`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 가장자리.
  - 스크림이 붙는 화면 상단·하단 경계 (ScreenEdgeScrim)

### `Editor`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 편집기. 텍스트를 입력·수정하는 영역.
  - 서술형 답안을 입력·수정하는 TextEditor 기반 영역 (QuestionSolvingScreen.AnswerEditor)

### `Effect`
- 분류: 아키텍처·패턴 · 사용 20회 · 패키지: App, Feature, UI
- 정의: 효과, 부수 효과. TCA에서는 Reducer 밖에서 실행되는 비동기 작업(Effect)을, 디자인 시스템에서는 그림자 같은 시각 효과를 뜻한다.
  - TCA 비동기 Effect(.run)의 결과를 Reducer로 전달하는 액션 분류: AppRootFeature.Action.EffectEvent, ProjectListFeature.Action.EffectEvent, HomeFeature.Action.Effect
  - 그림자 같은 시각 효과 디자인 토큰과 적용 modifier: EffectToken, DesignSystemEffectModifier
- 메모: 다의어: TCA 부수 효과와 디자인 시각 효과로 나뉜다. 표기 흔들림: 대부분 Action.EffectEvent이지만 HomeFeature만 Action.Effect를 쓴다.

### `Emphasis`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 강조.
  - 선택지를 선택됨·정답·오답 중 어떤 스타일로 강조할지의 상태 (ChoiceOptionDisplay.Emphasis)
- 메모: UI의 ChoiceAnswerOption.State도 선택지의 기본·선택됨·정답·오답 표시 상태를 뜻해 State와 유의어 중첩이 있다.

### `Empty`
- 분류: 일반 · 사용 6회 · 패키지: Feature, Data, UI
- 정의: 비어 있는. 표시하거나 담을 데이터가 없는 상태.
  - data 필드가 없는 서버 응답 페이로드 (EmptyResponseData)
  - 등록된 프로젝트나 표시 데이터가 없는 빈 상태 화면 (EmptyState, ProjectListScreen.EmptyProjectsView, HomeScreen.EmptyDeckShape)
- 메모: 다의어: 빈 응답 페이로드와 빈 상태 UI로 쓰인다.

### `Endpoint`
- 분류: 아키텍처·패턴 · 사용 9회 · 패키지: App, Data
- 정의: 엔드포인트, 종단점. 네트워크 통신에서 요청이 도달하는 주소나 접속 지점을 뜻한다.
  - HTTP 메서드와 경로 조합으로 정의된 서버 API 주소: AuthenticationEndpoint, ProjectEndpoint, MemberEndpoint
  - API 서버와 외부 저장소 서버의 접속 호스트: AppEndpointHost, ShareExtensionEndpointHost
- 메모: Data에서는 API 경로 정의, App에서는 서버 호스트 주소라는 서로 다른 수준의 의미로 쓰인다.

### `Entry`
- 분류: 일반 · 사용 6회 · 패키지: App, Data, Feature
- 정의: 진입·항목. 들어가는 입구 또는 목록의 원소 한 건을 뜻한다.
  - 앱·기능으로 들어가는 진입 단계 (AppEntryFeature, AppEntryScreen, SingleQuestionEntryFeature)
  - 흐름에 들어가는 행위 (OnboardingEntryPoint)
  - 배열·목록의 원소 한 건 (PolicyManifestLoader.Entry, LocalPendingGenerationStore.ReminderEntry)
- 메모: 다의어: '진입'과 '항목(원소)' 두 의미로 쓰인다.

### `Environment`
- 분류: 아키텍처·패턴 · 사용 2회 · 패키지: Composition
- 정의: 환경. 실행 환경에서 주입되는 설정 값 묶음.
  - 앱·공유 확장 실행 환경에서 주입되는 서버 URL·버전·알림 문구 등 설정 (AppComposition.Environment, ShareExtensionComposition.Environment)

### `Error`
- 분류: 플랫폼 · 사용 30회 · 패키지: App, Composition, Feature, Domain, Data, Infrastructure, UI
- 정의: 오류. Swift에서는 Error 프로토콜을 채택해 실패 원인을 나타내는 타입의 관례 접미어다.
  - Domain 관심사의 실패 유형: AccountError, ProjectError, QuizDetailError
  - Data의 서버 응답·전송·저장소 실패 분류: ServerAPIError, MemberServiceError, RequestTransportError
  - Infrastructure 플랫폼 연산 실패: HTTPClientError, KeychainStoreError, AppleAuthorizationError
  - 오류 상태를 표시하는 하위 View와 검증 위반: ProjectDetailScreen.ErrorView, SavedScreen.ErrorView, DesignTokenSet.ValidationError
- 메모: 유의어 중첩: 화면 쪽 실패 표시에 ErrorView와 FailureView/LoadFailureView가 섞여 쓰인다. FieldErrorDTO·ServerAPIError는 Swift Error 타입이 아닌 서버 오류 응답 내용을 가리키기도 한다.

### `Essay`
- 분류: 업무 개념 · 사용 6회 · 패키지: Domain, Data, Feature
- 정의: 에세이·서술. 여기서는 자유 텍스트로 답하는 서술형 퀴즈 형식을 가리킨다.
  - 서술형 답안·채점·제출 모델 (EssayAnswer, EssayGrading, EssaySubmission)
  - 서술형 답안 제출 요청·응답 DTO (SubmitEssayAnswerRequestDTO, SubmitEssayAnswerResponseDTO)
  - 서술형 채점 결과 화면 영역 (QuestionSolvingScreen.EssayResultSection)

### `Event`
- 분류: 아키텍처·패턴 · 사용 19회 · 패키지: App, Feature
- 정의: 사건·이벤트. 발생한 일이나 그 결과 통지를 뜻한다.
  - Effect가 끝나거나 값을 방출했을 때 Reducer로 되돌아오는 결과 액션 (AppRootFeature.Action.EffectEvent, ProjectListFeature.Action.EffectEvent, SettingsFeature.Action.EffectEvent)
  - 흐름 중 발생한 사건을 기록하는 값 (OnboardingRouterFeature.ScreenTransitionEvent, ShareRegistrationDiagnosticEvent)
- 메모: 다의어: TCA Effect 결과 액션과 기록용 사건 값으로 쓰인다.

### `Executor`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: Data
- 정의: 실행자. 작업을 실제로 수행하는 객체를 뜻한다.
  - 요청 전송·응답 봉투 해석·오류 변환을 수행하는 객체: LearningProjectRequestExecutor

### `Exit`
- 분류: 일반 · 사용 2회 · 패키지: Feature
- 정의: 나가기·종료.
  - 큐레이션 완료 뒤 온보딩을 빠져나가는 단계 (OnboardingExitFeature)
  - 닫기 버튼으로 온보딩을 벗어나며 로그아웃하는 동작의 상태 (PositionSelectionFeature.ExitStatus)
- 메모: 같은 온보딩 이탈이라도 OnboardingExitFeature는 정상 완료, ExitStatus는 닫기·signOut으로 의미가 다르다.

### `Expansion`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 펼침·확장. 접힌 내용을 펼치는 동작.
  - 선택지 본문을 펼치거나 접는 제어 (ChoiceAnswerOption.ExpansionControl)

### `Extension`
- 분류: 플랫폼 · 사용 2회 · 패키지: App, Composition
- 정의: 확장. Apple 플랫폼에서는 앱과 별도로 실행되는 App Extension 타깃을 뜻한다.
  - iOS Share Extension 타깃용 호스트·조립 코드: ShareExtensionEndpointHost, ShareExtensionComposition
- 메모: Swift 언어의 extension 선언과는 다른 의미다.

### `External`
- 분류: 일반 · 사용 17회 · 패키지: App, Composition, Domain, Data, Feature, Tuist
- 정의: 외부의. 앱 서버나 프로젝트 내부가 아닌 바깥에 있는 것을 뜻한다.
  - 앱 서버가 아닌 외부 코드 호스팅 서비스(GitHub)의 저장소 (ExternalRepository, ExternalRepositoryUseCase, ExternalRepositoryRemote)
  - 외부 저장소를 조립·변환·미리보기 하는 타입 (ExternalRepositoryAssembly, ExternalRepositoryLookupAdapter, ShareRegistrationPreviewSupport.PreviewExternalRepository)
  - Tuist에서 프로젝트 내부 패키지가 아닌 서드파티 의존성 (ExternalDependenciesName)
- 메모: 다의어: 외부 서비스(GitHub)와 외부(서드파티) 의존성으로 갈린다. ExternalRepository는 Repository 패턴이 아니라 Git 저장소를 뜻해 Repository 다의어의 구분자 역할을 한다.

### `Factory`
- 분류: 아키텍처·패턴 · 사용 4회 · 패키지: Data, Infrastructure
- 정의: 공장. 구현을 숨기고 인스턴스를 만들어 주는 팩토리 패턴의 생성 지점.
  - 정적 메서드로 구현체를 만들어 프로토콜 타입으로 돌려주는 생성 지점 (StorageFactory, RequestClientFactory, PushMessagingClientFactory)
  - Infrastructure 구현을 숨기고 알림 역할 계약 구현체를 만드는 진입점 (NotificationFactory)
- 메모: 유의어 중첩: 생성 책임을 Factory, Builder, Assembly/Composition이 나누어 쓴다.

### `Failure`
- 분류: 일반 · 사용 3회 · 패키지: Feature
- 정의: 실패. 작업이 원하는 결과 없이 끝난 상태를 뜻한다.
  - 로드·생성 실패 상태를 표시하는 하위 View: ProjectListScreen.FailureView, QuizGenerationProgressScreen.FailureView, ProfileScreen.LoadFailureView
- 메모: 유의어 중첩: 같은 역할의 하위 View에 ErrorView(ProjectDetailScreen, SavedScreen, LearningSetIntroScreen)와 FailureView가 혼용된다.

### `Family`
- 분류: 플랫폼 · 사용 2회 · 패키지: UI, Tuist
- 정의: 가족·계열. 타이포그래피에서 여러 굵기 변형을 묶은 서체 집합(font family)을 뜻한다.
  - 굵기 변형을 묶은 글꼴 패밀리 (DesignSystemFontFamily, FontFamilyToken)

### `Feature`
- 분류: 아키텍처·패턴 · 사용 29회 · 패키지: App, Feature
- 정의: 기능. 이 프로젝트에서는 TCA에서 State·Action·Reducer(body)를 묶은 리듀서 타입의 관례 접미어다.
  - 화면·시트 하나의 로직을 담당하는 TCA Reducer (HomeFeature, QuestionSolvingFeature, SettingsFeature)
  - 하위 화면 전환을 관리하는 라우터 Reducer (MainShellRouterFeature, QuizRouterFeature, OnboardingRouterFeature)
  - 앱 최상위 Reducer (AppRootFeature)
- 메모: 패키지 이름 Feature와 타입 접미어 Feature가 같은 단어라 문맥 구분이 필요하다.

### `Fetch`
- 분류: 일반 · 사용 1회 · 패키지: Data
- 정의: 가져오기. 원격이나 저장소에서 데이터를 조회해 가져오는 동작이다.
  - 네트워크로 외부 저장소 정보를 조회하다 실패한 원인: ExternalRepositoryFetchError
- 메모: 유의어 중첩: 조회 동작에 Fetch 외에 Load(ProfileLoad, InitialLoad, LoadStatus, Loader)가 함께 쓰인다.

### `Field`
- 분류: 일반 · 사용 3회 · 패키지: Data
- 정의: 필드·항목. 데이터 구조의 개별 칸을 뜻한다.
  - 서버가 유효성 오류를 지적한 요청 본문의 필드 이름 (FieldErrorDTO)
- 메모: Data의 Authentication·LearningProject·Member 관심사가 같은 이름의 타입을 각각 따로 선언한다(FieldErrorDTO 3벌).

### `Filter`
- 분류: 일반 · 사용 2회 · 패키지: Feature, Domain
- 정의: 필터·거름. 목록을 조건으로 좁히는 것.
  - 북마크 목록을 전체 또는 특정 프로젝트로 좁히는 조회 조건 (QuizBookmarkFilter, SavedScreen.FilterSection)

### `Firebase`
- 분류: 브랜드 · 사용 2회 · 패키지: Infrastructure
- 정의: Google의 모바일 백엔드 플랫폼 이름(외부 고정 명칭)이다.
  - FirebaseCore·FirebaseMessaging SDK 기반 푸시 구현: FirebaseMessagingAppDelegate, FirebaseMessagingPushClient

### `Fixture`
- 분류: 아키텍처·패턴 · 사용 3회 · 패키지: Feature
- 정의: 고정 장치·테스트 픽스처. 테스트나 미리보기에 쓰는 미리 정해진 데이터를 뜻한다.
  - SwiftUI 미리보기에 주입하는 샘플 데이터와 Store 묶음 (HomePreviewFixture, ProfilePreviewFixture, SettingsPreviewFixture)
- 메모: 같은 미리보기 지원 역할을 다른 Feature에서는 PreviewSupport(ProjectRegistrationPreviewSupport, ShareRegistrationPreviewSupport)로 불러 유의어 중첩이 있다.

### `Flow`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 흐름. 여러 화면을 순서대로 거치는 진행.
  - 온보딩처럼 순차 화면 진행을 담는 내비게이션 스택 (FlowNavigationStack)

### `Font`
- 분류: 일반 · 사용 4회 · 패키지: UI, Tuist
- 정의: 글꼴. 텍스트 렌더링에 쓰는 서체를 뜻한다.
  - 번들에 포함된 사용자 정의 ttf 글꼴 파일과 등록: DesignSystemFontFamily, FontRegistration
  - 디자인 시스템 서체 토큰: FontFamilyToken, FontFamilyToken.FontSelectionRole

### `Footer`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 바닥글·하단부.
  - 목록 끝에서 다음 페이지 로딩·재시도 UI를 보이는 영역 (ProjectListScreen.NextPageFooter)

### `Generating`
- 분류: 업무 개념 · 사용 1회 · 패키지: Feature
- 정의: 생성 중. 무언가를 만드는 작업이 진행 중인 상태.
  - 학습 세트 생성이 진행 중인 동안의 화면 상태 (QuizGenerationProgressScreen.GeneratingView)

### `Generation`
- 분류: 업무 개념 · 사용 39회 · 패키지: App, Composition, Feature, Domain, Data
- 정의: 생성. 이 서비스에서는 GitHub 저장소 URL로 서버가 퀴즈(학습 세트)를 만드는 비동기 작업을 뜻한다.
  - 퀴즈 생성 요청·진행 상태·결과를 다루는 Domain 모델·유스케이스: ProjectGenerationUseCase, GenerationOutcome, GenerationRecord
  - 생성 작업의 저장·결과·리마인더 저장소와 어댑터: PendingGenerationRepository, GenerationOutcomeRepositoryAdapter, LocalPendingGenerationStore
  - 생성 서버 API·전송 객체: QuizGenerationEndpoint, QuizGenerationStatusResponseDTO, PushQuizGenerationOutcomeSource
  - 생성 확인·진행 화면: QuizGenerationConfirmationFeature, QuizGenerationProgressScreen, QuizGenerationProgressScreen.GenerationReminderSheet
- 메모: 같은 작업을 ProjectGeneration(프로젝트 생성)과 QuizGeneration(퀴즈 생성)으로 부르는 접두어가 흔들린다. "학습 세트 생성"이라는 설명도 섞인다.

### `Generator`
- 분류: 일반 · 사용 2회 · 패키지: Infrastructure
- 정의: 생성기. 무언가를 만들어 내는 객체를 뜻한다.
  - 지정 길이의 난수 문자열을 만드는 객체와 그 오류 (SecureRandomGenerator, SecureRandomGeneratorError)
- 메모: 퀴즈 '생성'(Generation, 예: QuizGenerationEndpoint)과 어근은 같지만 무관한 난수 생성기다.

### `GitHub`
- 분류: 브랜드 · 사용 3회 · 패키지: Data
- 정의: 외부 고정 명칭 GitHub. 코드 저장소 호스팅 서비스와 그 REST API를 가리킨다.
  - GitHub REST API 저장소 조회 요청·응답 (GitHubRepositoryRequest, GitHubRepositoryResponseDTO)
  - github.com 저장소 URL 해석 (GitHubRepositoryURLParser)

### `GitIt`
- 분류: 브랜드 · 사용 1회 · 패키지: App
- 정의: Git과 It을 합친 이 서비스의 제품명(고유 명칭)이다.
  - 앱 진입점: GitItApp

### `Glass`
- 분류: 플랫폼 · 사용 1회 · 패키지: UI
- 정의: 유리. 여기서는 iOS glassEffect(리퀴드 글래스) 배경 스타일을 가리킨다.
  - glassEffect 배경을 쓰는 아이콘 버튼 (IconGlassButton)
- 메모: Plain(IconPlainButton)과 대비되는 스타일 명칭이다.

### `Gradient`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 그라데이션. 여러 색이 이어지며 변하는 색 표현.
  - 색 정지점을 잇는 선형 색 변화 디자인 토큰 (GradientToken)

### `Grading`
- 분류: 업무 개념 · 사용 2회 · 패키지: Domain
- 정의: 채점. 제출한 답안을 평가해 결과를 매기는 일이다.
  - 객관식·서술형 답안 제출 후 돌아오는 정오·해설·루브릭 채점 결과: ChoiceGrading, EssayGrading
- 메모: Feature의 QuestionSolvingFeature.AnswerOutcome도 같은 채점 결과를 Outcome으로 부른다.

### `Grant`
- 분류: 일반 · 사용 1회 · 패키지: Domain
- 정의: 부여·승인. 권한이나 자격이 발급된 것을 뜻한다.
  - 인증 성공으로 발급된 식별자와 방식의 묶음 (AuthenticationGrant)

### `Greeting`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 인사·인사말.
  - 홈 상단의 환영 문구 View (HomeScreen.GreetingView)

### `Group`
- 분류: 일반 · 사용 4회 · 패키지: Infrastructure, UI
- 정의: 그룹, 묶음. 여러 대상을 하나로 묶은 단위다. Apple 플랫폼에서는 App Group·Keychain Access Group 같은 고정 명칭에 쓰인다.
  - 앱과 확장이 데이터를 공유하는 Apple App Group·Keychain 접근 그룹: AppGroupKeychainStore, AppGroupUserDefaults, KeychainAccessGroup
  - 색 토큰이 속한 색상 계열 분류: ColorToken.Group
- 메모: 다의어: Apple 공유 컨테이너 명칭과 디자인 토큰 분류로 나뉜다.

### `Guidance`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 안내·지도.
  - 현재 결과와 다음 행동을 알려 주는 안내 문구 화면 (ShareRegistrationScreen.GuidanceView)
- 메모: RepositoryLinkInputScreen.GuideSectionView는 Guide를 써 Guidance/Guide 표기가 흔들린다.

### `Guide`
- 분류: 일반 · 사용 2회 · 패키지: Feature
- 정의: 안내·지침. 사용자에게 방법이나 단계를 알려 주는 것.
  - 로그인 전 튜토리얼·약관 동의로 이루어진 온보딩 안내 단계 (OnboardingRouterFeature.ActiveScreen.Guide)
  - GitHub 저장소 주소를 입력하는 방법 설명 영역 (RepositoryLinkInputScreen.GuideSectionView)
- 메모: 다의어: 온보딩 단계 이름과 입력 방법 설명 섹션으로 쓰인다.

### `Header`
- 분류: 일반 · 사용 3회 · 패키지: Feature, UI
- 정의: 머리글, 상단부. 화면이나 영역의 맨 위 부분을 뜻한다.
  - 화면 최상단 프로필 요약 영역: HomeScreen.ProfileHeaderView, ProfileScreen.ProfileHeaderView
  - 화면 맨 위 제목 영역: ScreenHeaderTitle
- 메모: HTTP 헤더(AuthorizedRequestHeaders의 Headers)와는 다른 UI 영역 의미다. Home과 Profile에 같은 이름의 ProfileHeaderView가 각각 있다.

### `Headers`
- 분류: 플랫폼 · 사용 2회 · 패키지: Data, Infrastructure
- 정의: 헤더들. HTTP 요청·응답의 이름-값 쌍 헤더 필드 집합을 뜻한다.
  - HTTP 헤더 필드 집합과 인증 헤더 사전 (HTTPHeaders, AuthorizedRequestHeaders)
- 메모: 단어를 복수형 Headers로 사용한다.

### `Height`
- 분류: 일반 · 사용 2회 · 패키지: UI
- 정의: 높이. 요소의 세로 크기.
  - 진행률 막대의 세로 두께 단계 (ContinuousProgressBar.Height)
  - 측정된 스크롤 콘텐츠의 세로 크기 전달 키 (ContentHeightPreferenceKey)

### `Home`
- 분류: 업무 개념 · 사용 8회 · 패키지: Feature, UI
- 정의: 홈. 이 앱에서는 메인 셸의 첫 번째 탭인 홈 화면을 뜻한다.
  - 홈 탭 화면과 그 표시 모델·레이아웃: HomeFeature, HomeScreen, HomeProjectDisplay
  - 홈 탭에 쓰는 UI 카드: HomeProjectCard

### `Host`
- 분류: 플랫폼 · 사용 2회 · 패키지: App
- 정의: 호스트. URL의 도메인 부분 또는 서버 주소를 뜻한다.
  - Info.plist에서 읽는 API 서버 주소(앱·공유 확장별) (AppEndpointHost, ShareExtensionEndpointHost)

### `HTTP`
- 분류: 약어 · 사용 10회 · 패키지: Infrastructure
- 정의: HyperText Transfer Protocol의 약어. 웹 요청·응답 통신 규약이다.
  - HTTP 요청·응답 모델과 클라이언트 계약 (HTTPClient, HTTPRequest, HTTPResponse)
  - 저수준 HTTP 전송 계층 (HTTPTransport, HTTPTransportRequest, HTTPTransportResponse)
  - HTTP 메서드·헤더·본문 인코딩 (HTTPMethod, HTTPHeaders, HTTPBodyCoding)
- 메모: 유의어 중첩: Infrastructure의 HTTPRequest/HTTPTransportRequest와 Data의 TransportRequest/LearningProjectRequest가 요청 모델을 계층마다 따로 둔다.

### `Icon`
- 분류: 일반 · 사용 7회 · 패키지: Feature, UI
- 정의: 아이콘. 작은 픽토그램 이미지를 뜻한다.
  - 디자인 시스템 리소스 아이콘 에셋 식별자와 그 별칭: ResourceImage.Asset.Icon, IconGlassButton.Icon, SettingsScreen.SettingRowContent.Icon
  - 텍스트 없이 아이콘만 표시하는 버튼: IconGlassButton, IconPlainButton

### `ID`
- 분류: 약어 · 사용 24회 · 패키지: App, Domain, Feature
- 정의: Identifier(식별자)의 약어. 대상을 서로 구별하는 키를 뜻한다.
  - 도메인 엔티티를 구분하는 문자열 키 (AccountID, ProjectID, QuizSetID)
  - TCA Effect 취소 대상을 구분하는 Hashable 키 (AppRootFeature.CancelID, HomeFeature.CancelID, SettingsFeature.CancelID)
  - 화면 메뉴 항목을 구분하는 문자열 키 (ProjectDetailScreen.Constant.MenuItemID)
- 메모: 다의어: 도메인 식별자와 Effect 취소 키로 갈린다. 표기 흔들림: DeviceID와 DeviceIdentifierRepository처럼 ID와 Identifier 전체 표기가 혼용된다. 대문자 ID로는 일관되며 Id 표기는 쓰이지 않는다.

### `Identifier`
- 분류: 일반 · 사용 3회 · 패키지: Composition, Domain, Data
- 정의: 식별자. 대상을 구분하는 고유 값.
  - 기기를 구분하는 고유 문자열(UUID)과 그 저장소 (DeviceIdentifierRepository, LocalDeviceIdentifierStore, DeviceIdentifierRepositoryAdapter)
- 메모: 표기 흔들림: 같은 개념을 Identifier로 풀어 쓰기도 하고 PolicyDocumentID·ProjectID·DeviceID처럼 ID로 줄여 쓰기도 한다.

### `Identity`
- 분류: 일반 · 사용 2회 · 패키지: Data
- 정의: 신원, 식별. 대상을 식별하는 정보를 뜻한다.
  - 보안 저장소에 두는 Apple 사용자 ID: AppleIdentityStore, AppleIdentityStorageLayout
- 메모: 유의어 중첩: 같은 계층에서 Store와 Storage가 함께 쓰인다(AppleIdentityStore, AppleIdentityStorageLayout).

### `Illust`
- 분류: 약어 · 사용 1회 · 패키지: UI
- 정의: Illustration(삽화)의 축약.
  - 지식·레벨 단계를 나타내는 일러스트 이미지 리소스 식별자 (ResourceImage.Asset.Illust)
- 메모: 비표준 축약형이며 다른 곳에서는 축약하지 않은 단어를 쓰는 관례와 어긋난다.

### `Image`
- 분류: 플랫폼 · 사용 1회 · 패키지: UI
- 정의: 이미지. SwiftUI Image로 그려지는 그림.
  - 리소스에서 불러오는 정적 그림 (ResourceImage)

### `In`
- 분류: 관용 표현 · 사용 2회 · 패키지: Infrastructure
- 정의: 안에. 이 프로젝트에서는 InMemory(메모리 내)라는 관용 표현의 첫 부분으로만 쓰인다.
  - 메모리 안에 두는 저장·캐시 구현: KeychainStore.InMemoryBackend, InMemoryCache

### `Indicator`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 표시기.
  - 현재 페이지 위치를 점으로 나타내는 View (PageIndicator)

### `Info`
- 분류: 약어 · 사용 8회 · 패키지: App, Composition, Domain, Data
- 정의: Information의 축약. 정보.
  - 회원 프로필·큐레이션·직군·경력 정보와 그 유스케이스 (UserInfo, UserInfoUseCase, UserInfoRepository)
  - 저장소 이름·주소·별 수·기술 스택 표시 속성 (ProjectRepositoryInfo)
  - 기기 식별자·종류·앱/OS 버전·푸시 토큰 (DeviceInfoRequestDTO)
- 메모: 다의어: 사용자 정보 관심사, 저장소 표시 정보, 기기 정보로 쓰인다. Domain UserInfo는 정보 값이 아니라 유스케이스 구현체를 가리켜 이름과 역할이 어긋난다.

### `Initial`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 최초의, 처음의. 순서상 첫 번째를 뜻한다.
  - 화면 진입 후 처음 수행하는 프로젝트 목록 로드: ProjectListFeature.InitialLoad

### `Input`
- 분류: 아키텍처·패턴 · 사용 11회 · 패키지: Feature
- 정의: 입력. 들어오는 값이나 신호를 뜻하며, 이 프로젝트에서는 TCA Action의 외부 주입 분류와 사용자 입력 단계로 쓰인다.
  - 부모 리듀서 등 외부에서 이 기능으로 주입되는 TCA 액션 묶음 (HomeFeature.Action.Input, TutorialFeature.Action.Input, ProjectListFeature.Action.Input)
  - 사용자가 저장소 링크를 입력하는 단계·화면 (RepositoryLinkInputFeature, RepositoryLinkInputScreen)
- 메모: 다의어: Action.Input은 사용자 입력이 아닌 부모 주입 액션(사용자 입력은 View 액션)이고, RepositoryLinkInput은 사용자 텍스트 입력을 뜻해 의미가 반대에 가깝다.

### `Intro`
- 분류: 약어 · 사용 2회 · 패키지: Feature
- 정의: Introduction의 축약. 소개·도입.
  - 세트 풀이 전 제목·설명을 보여 주고 시작을 받는 진입 화면 (LearningSetIntroFeature, LearningSetIntroScreen)

### `Item`
- 분류: 일반 · 사용 10회 · 패키지: App, Feature, Data, Infrastructure, UI
- 정의: 항목. 목록이나 묶음을 이루는 하나의 원소다.
  - 목록·메뉴·탭의 한 줄 데이터: SelectionCardList.Item, ActionMenu.Item, TabShellItem
  - 서버 응답 목록의 한 건: ProjectListItemDTO, WeeklyChartItemDTO
  - Apple NSExtensionItem 공유 항목과 HTTP 쿼리 항목: SharedItemAttachment, SharedItemURLResolver, HTTPRequest.QueryItem

### `JSON`
- 분류: 약어 · 사용 1회 · 패키지: Infrastructure
- 정의: JavaScript Object Notation의 약어. 텍스트 기반 데이터 직렬화 형식이다.
  - HTTP 본문 직렬화 형식 (StandardJSONBodyCoding)

### `Judgement`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 판정·판단.
  - 선택지가 정답인지 오답인지에 대한 판정 (ChoiceResultRow.Judgement)
- 메모: 표기 흔들림: 영국식 철자 Judgement를 쓰며 미국식은 Judgment다. 유의어 중첩: 도메인의 채점은 Grading(ChoiceGrading)으로 표현한다.

### `Key`
- 분류: 일반 · 사용 5회 · 패키지: Data
- 정의: 키, 식별자. 저장된 값을 찾는 데 쓰는 식별 문자열이다.
  - 키-값 저장소에서 값을 찾는 문자열 키: KeyValueStorage, LocalKeyValueStorage, UnavailableKeyValueStorage
  - 보안 저장소 레코드용 키 정의: AppleIdentityStorageLayout.Key, SessionStorageLayout.Key
- 메모: SwiftUI PreferenceKey의 Key와는 별도 항목으로 다룬다.

### `Keyboard`
- 분류: 플랫폼 · 사용 1회 · 패키지: Feature
- 정의: 키보드. 여기서는 텍스트 필드에 뜨는 iOS 소프트웨어 키보드다.
  - 키보드를 내리기 위한 탭 감지 레이어 (RepositoryLinkInputScreen.KeyboardDismissLayer)

### `Keychain`
- 분류: 플랫폼 · 사용 6회 · 패키지: Infrastructure
- 정의: 외부 고정 명칭 Apple Keychain. Security 프레임워크의 보안 저장소다.
  - SecItem API로 접근하는 보안 저장소와 오류 (KeychainStore, AppGroupKeychainStore, KeychainStoreError)
  - Keychain 항목 속성(접근 그룹·접근성·서비스 이름) (KeychainAccessGroup, KeychainAccessibility, KeychainNamespace)
- 메모: 유의어 중첩: Data는 같은 보안 저장소를 공급자 중립 이름 SecureValueStorage로 부른다.

### `Kind`
- 분류: 일반 · 사용 2회 · 패키지: Domain, UI
- 정의: 종류, 유형. 대상을 분류하는 구분을 뜻한다.
  - 생성 리마인더가 완료 알림인지 실패 알림인지: GenerationReminder.Kind
  - 그림자가 바깥(drop)인지 안쪽(inner)인지: EffectToken.Kind
- 메모: 유의어 중첩: 비슷한 분류 의미에 Style, Status, Mode도 쓰인다.

### `Label`
- 분류: 일반 · 사용 2회 · 패키지: Domain, UI
- 정의: 라벨·표지. 대상을 식별하거나 설명하는 짧은 문구를 뜻한다.
  - 학습 세트를 식별해 보여 주는 짧은 표기와 제목 (ProjectSetLabel)
  - 버튼 안에 표시할 텍스트 내용의 종류 (ActionButton.Label)
- 메모: SwiftUI의 Label 타입과 이름이 같아 ActionButton.Label은 플랫폼 타입과 혼동될 수 있다.

### `Labeled`
- 분류: 일반 · 사용 3회 · 패키지: UI
- 정의: 라벨이 붙은. 이름 라벨이 함께 표시되는 형태.
  - 이름 라벨이 붙은 입력 필드·카드·진행 막대 (LabeledTextField, LabeledCard, LabeledProgressBar)

### `Launch`
- 분류: 일반 · 사용 2회 · 패키지: App, UI
- 정의: 시작, 기동. 앱이 처음 켜지는 시점을 뜻한다.
  - 앱 시작 직후의 초기화 단계 묶음: AppLaunchSequence
  - 앱 실행 화면의 로고: LaunchLogo
- 메모: Composition의 Bootstrap(초기 활성화)과 의미가 가깝다.

### `Layer`
- 분류: 일반 · 사용 2회 · 패키지: Feature, UI
- 정의: 층·레이어. 겹쳐 쌓이는 한 겹을 뜻한다.
  - 화면 뒤에 깔리는 투명한 탭 감지 영역 (RepositoryLinkInputScreen.KeyboardDismissLayer)
  - 여러 겹 그림자 효과 중 한 겹 (EffectToken.Layer)

### `Layout`
- 분류: 일반 · 사용 5회 · 패키지: Feature, Data, UI
- 정의: 배치·구성.
  - 저장소 namespace와 키 이름의 정의 (SessionStorageLayout, AppleIdentityStorageLayout, PolicyConsentStorageLayout)
  - 화면 요소의 배치·간격 계산과 토큰 (HomeCardScrollLayout, LayoutToken)
- 메모: 다의어: 저장소 키 구성 규약과 UI 배치라는 두 의미로 쓰인다.

### `Learning`
- 분류: 업무 개념 · 사용 15회 · 패키지: Composition, Feature, Domain, Data, UI
- 정의: 학습. 이 서비스에서는 GitHub 저장소로 만든 퀴즈 세트를 풀며 코드를 이해하는 활동을 뜻한다.
  - 퀴즈 생성·풀이 학습 기능 영역의 서버 접근·조립: LearningProjectAssembly, LearningProjectRequestExecutor, LearningSetRemote
  - 학습 세트 소개·완료·재개 화면: LearningSetIntroFeature, LearningCompletionScreen, LearningSetResumption
  - 사용자의 퀴즈 풀이 활동 통계: LearningStatistics, WeeklyLearningCount
- 메모: LearningProject와 LearningSet이 함께 쓰이며, 같은 대상을 퀴즈 세트·학습 세트로 부르는 표현이 섞인다.

### `Legal`
- 분류: 업무 개념 · 사용 2회 · 패키지: Feature
- 정의: 법적·법률상의. 여기서는 개인정보 처리방침·이용약관 같은 법적 정책 문서를 가리킨다.
  - 법적 정책 문서 동의 화면·리듀서 (LegalAgreementFeature, LegalAgreementScreen)
- 메모: Domain·Data는 같은 대상을 Policy(PolicyDocument, PolicyConsent)로 부르고, 동의도 Agreement(Feature)와 Consent(Domain)로 달라 유의어 중첩이 있다.

### `Level`
- 분류: 업무 개념 · 사용 10회 · 패키지: Feature, Domain, Data
- 정의: 수준·단계.
  - L1~L3 퀴즈 난이도 (QuizLevel, QuizLevelDTO, QuizLevelSelectionFeature)
  - 입문·주니어·미들·시니어 경력 연차 구간 (CareerLevel, CareerLevelRequestDTO, CareerLevelDisplay)
- 메모: 다의어: 퀴즈 난이도와 경력 단계라는 서로 다른 도메인 값으로 쓰인다. 유의어 중첩: CareerSelectionFeature는 Level 없이 경력 선택을 가리킨다.

### `Link`
- 분류: 일반 · 사용 2회 · 패키지: Feature
- 정의: 링크, 연결 주소. 다른 자원을 가리키는 URL을 뜻한다.
  - 사용자가 입력하는 저장소 URL 문자열: RepositoryLinkInputFeature, RepositoryLinkInputScreen
- 메모: 유의어 중첩: 같은 저장소 주소를 다른 타입에서는 URL(ExternalRepositoryURL, GitHubRepositoryURLParser)로 부른다.

### `List`
- 분류: 일반 · 사용 10회 · 패키지: Domain, Data, Feature, UI
- 정의: 목록. 여러 항목을 나열한 묶음을 뜻한다.
  - 페이지네이션된 프로젝트·북마크 목록 모델과 응답 DTO (ProjectList, QuizBookmarkList, ProjectListResponseDTO)
  - 프로젝트 목록 화면과 그 행 표시 모델 (ProjectListFeature, ProjectListScreen, ProjectListDisplay)
  - 항목을 세로로 나열한 UI 영역·컴포넌트 (ProjectDetailScreen.SetListSection, SelectionCardList)
- 메모: ProjectListDisplay는 목록 전체가 아니라 목록 행 하나에 대응하는 항목을 뜻해 이름과 단위가 어긋난다. ProjectListItemDTO에서는 List가 목록 조회 결과의 원소를 수식한다.

### `Load`
- 분류: 일반 · 사용 11회 · 패키지: App, Feature
- 정의: 적재·불러오기. 데이터를 가져오는 작업과 그 진행 상태.
  - 화면 데이터를 비동기로 불러오는 작업과 진행 상태(대기·로딩·완료·실패) (HomeFeature.State.ProjectLoad, ProfileFeature.State.ProfileLoad, SavedFeature.LoadStatus)
  - 정책 매니페스트 읽기 오류 (PolicyManifestLoader.LoadError)
  - 프로필 조회 실패 화면 (ProfileScreen.LoadFailureView)
- 메모: 표기 흔들림: 진행 상태를 XxxLoad(ProjectLoad, SetLoad, InitialLoad)와 LoadStatus(ProjectDetailFeature.LoadStatus, SavedFeature.LoadStatus)로 혼용한다. 유의어 중첩: Fetch/Lookup과 조회 의미가 겹친다.

### `Loader`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: App
- 정의: 적재기. 원본 자원을 읽어 사용할 수 있는 형태로 올리는 객체다.
  - 번들 리소스를 읽어 정책 매니페스트 도메인 모델로 바꾸는 객체: PolicyManifestLoader
- 메모: 유의어 중첩: 조회 동작에 Load와 Fetch가 함께 쓰인다.

### `Loading`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 불러오는 중.
  - 저장소 조회·생성 요청 진행 중 상태 View (ShareRegistrationScreen.LoadingView)
- 메모: Load(LearningSetIntroFeature.BookmarkLoad, SetLoad)와 같은 어근이다.

### `Local`
- 분류: 일반 · 사용 8회 · 패키지: Data, Infrastructure
- 정의: 로컬·기기 내부. 서버가 아닌 기기 안에서 처리·저장되는 것.
  - 기기 내부 저장소에 보관하는 Store·Storage 구현 (LocalPendingGenerationStore, LocalKeyValueStorage, LocalSecureValueStorage)
  - 서버 푸시가 아닌 앱이 직접 예약하는 로컬 알림 (LocalReminderNotifier, LocalNotificationRequest, LocalNotificationAuthorizationClient)
- 메모: 다의어: 기기 내부 저장과 로컬 알림이라는 두 의미로 쓰인다.

### `Location`
- 분류: 일반 · 사용 3회 · 패키지: Domain, Data
- 정의: 위치. 대상이 놓인 곳이나 대상을 특정하는 좌표를 뜻한다.
  - 소유자와 이름으로 특정되는 외부 저장소 좌표: ExternalRepositoryLocation(Data·Domain)
  - 저장 영역(App Group 공유 컨테이너 또는 앱 기본 영역): StorageLocation
- 메모: 다의어: 원격 저장소의 식별 좌표와 로컬 저장 영역으로 나뉜다. ExternalRepositoryLocation은 Data와 Domain에 같은 이름으로 존재한다.

### `Locator`
- 분류: 아키텍처·패턴 · 사용 3회 · 패키지: Composition, Domain, Feature
- 정의: 위치 지정자. 여기서는 URL에서 저장소 소유자·이름을 찾아내는 파서 역할이며 Service Locator 패턴이 아니다.
  - URL에서 외부 저장소 위치 정보를 파싱하는 계약·어댑터·미리보기 대역 (ExternalRepositoryLocator, ExternalRepositoryLocatorAdapter, ShareRegistrationPreviewSupport.PreviewRepositoryLocator)
- 메모: Service Locator 패턴과 이름이 겹쳐 오해 소지가 있다. Data의 GitHubRepositoryURLParser와 같은 역할을 다른 단어(Parser)로 부르고, Location(ExternalRepositoryLocation)·Lookup·Resolver와 유의어가 중첩된다.

### `Log`
- 분류: 일반 · 사용 1회 · 패키지: App
- 정의: 기록·로그.
  - os.Logger로 남기는 공유 등록 진단 로그 (ShareRegistrationDiagnosticLog)
- 메모: 유의어 중첩: 기록을 Record, Log, Event로 나누어 표현한다.

### `Login`
- 분류: 관용 표현 · 사용 2회 · 패키지: Data
- 정의: 로그인. 서비스에 자격을 제시해 접속하는 행위다.
  - 서버에 Apple 자격으로 로그인하는 요청·응답: AppleLoginRequestDTO, LoginResponseDTO
- 메모: 표기 흔들림: 같은 행위를 Login(DTO)과 SignIn(SignInMethod, SignedInAccount, AppleSignInError, AppleSignInSource)으로 혼용한다.

### `Logo`
- 분류: 일반 · 사용 2회 · 패키지: UI
- 정의: 로고.
  - 앱 로고 이미지 리소스와 실행 화면 로고 (LaunchLogo, ResourceImage.Asset.Logo)

### `Lookup`
- 분류: 아키텍처·패턴 · 사용 2회 · 패키지: Composition, Domain
- 정의: 조회·찾아보기. 키로 대상을 찾아오는 동작.
  - 소유자·이름으로 원격 저장소 메타데이터를 가져오는 계약과 어댑터 (ExternalRepositoryLookup, ExternalRepositoryLookupAdapter)
- 메모: 유의어 중첩: 조회 의미가 Load, Fetch와 겹친다.

### `Main`
- 분류: 일반 · 사용 3회 · 패키지: Feature
- 정의: 주요, 메인. 중심이 되는 영역을 뜻한다.
  - 로그인 후 사용하는 주 화면 탭 셸: MainShellRouter, MainShellRouterFeature, MainShellTab

### `Manifest`
- 분류: 일반 · 사용 2회 · 패키지: App
- 정의: 명세서·목록. 포함된 항목을 기술한 문서를 뜻한다.
  - 정책 문서 목록을 기술한 JSON 리소스와 그 디코딩 모델 (PolicyManifestLoader, PolicyManifestLoader.Manifest)

### `Marker`
- 분류: 일반 · 사용 2회 · 패키지: Data
- 정의: 표식·마커. 상태만 알리는 가벼운 표시 값.
  - 공유 저장소에 기록되는 로그인 상태 표식 (SharedSessionStateMarkerCoding, SharedSessionStateMarkerCoding.Marker)

### `Member`
- 분류: 업무 개념 · 사용 6회 · 패키지: Composition, Domain, Data
- 정의: 회원, 구성원. 이 서비스에서는 로그인한 Git It 회원과 그 서버 자원을 뜻한다.
  - 서버 회원 API 접근·조립: MemberRemote, MemberEndpoint, MemberAssembly
  - 회원 프로필 응답과 직군: MemberProfileResponseDTO, MemberPosition
- 메모: 유의어 중첩: 같은 대상을 Domain에서는 주로 User(UserInfo, UserProfile)로, Data에서는 Member로 부른다.

### `Memory`
- 분류: 일반 · 사용 2회 · 패키지: Infrastructure
- 정의: 메모리. 여기서는 디스크나 Keychain이 아닌 프로세스 메모리에 값을 두는 방식을 뜻한다.
  - 프로세스 메모리에 값을 보관하는 백엔드·캐시 (KeychainStore.InMemoryBackend, InMemoryCache)

### `Menu`
- 분류: 일반 · 사용 2회 · 패키지: Feature, UI
- 정의: 메뉴. 선택할 동작 항목을 나열한 목록.
  - 동작 항목을 세로로 나열한 선택 목록 View와 항목 ID (ActionMenu, ProjectDetailScreen.Constant.MenuItemID)

### `Message`
- 분류: 일반 · 사용 2회 · 패키지: Data
- 정의: 메시지. 주고받는 통신 단위를 뜻하며, 여기서는 푸시 메시징 서비스의 원격 메시지다.
  - 푸시 메시징 등록 토큰과 수신 메시지를 다루는 객체: RemoteMessageClient, RemoteMessageReceiver
- 메모: 유의어 중첩: 같은 원격 푸시를 Notification, Push, Message로 부른다.

### `Messaging`
- 분류: 플랫폼 · 사용 5회 · 패키지: Infrastructure
- 정의: 메시징. 메시지를 전달하는 기능을 뜻하며, 여기서는 푸시 메시지 전달 영역과 Firebase Cloud Messaging(FCM)을 가리킨다.
  - 공급자 중립 푸시 메시지 전달 기능 영역 (PushMessagingClient, PushMessagingClientFactory, PushMessagingAppDelegate)
  - Firebase Cloud Messaging 모듈 연동 (FirebaseMessagingAppDelegate, FirebaseMessagingPushClient)
- 메모: PushMessaging(중립 경계)과 FirebaseMessaging(외부 고정 명칭)이 같은 단어를 공유한다. Data의 RemoteMessageReceiver·LocalReminderNotifier와 역할 명칭(Messaging/Message/Notifier/Notification)이 흩어져 있다.

### `Metadata`
- 분류: 일반 · 사용 1회 · 패키지: App
- 정의: 메타데이터. 데이터를 설명하는 데이터.
  - Info.plist에 기록된 앱 버전 등 번들 정보 (AppBundleMetadata)

### `Method`
- 분류: 일반 · 사용 2회 · 패키지: Domain, Infrastructure
- 정의: 방법, 방식. 무언가를 수행하는 방식을 뜻한다.
  - 로그인에 쓰는 인증 제공자 종류: SignInMethod
  - GET·POST 등 HTTP 요청 메서드: HTTPMethod
- 메모: 다의어: 로그인 방식과 HTTP 메서드로 나뉜다.

### `Mockup`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 실물 모형·시안.
  - 온보딩 화면에 보여 주는 앱 화면 목업 이미지 (OnboardingMockup)

### `Modal`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 모달. 뒤 화면 상호작용을 막고 앞에 띄우는 표시 방식.
  - 앞에 띄우는 모달 오버레이 View (ModalOverlay)

### `Mode`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 모드, 동작 방식. 대상이 현재 어떤 상호작용 방식에 있는지를 뜻한다.
  - 프로젝트 목록이 탐색·메뉴 표시·삭제 중 어느 상태인지: ProjectListFeature.Mode

### `Modifier`
- 분류: 플랫폼 · 사용 1회 · 패키지: UI
- 정의: 수정자. SwiftUI ViewModifier 프로토콜에서 온 외부 고정 명칭이다.
  - 디자인 시스템 효과를 적용하는 ViewModifier (DesignSystemEffectModifier)

### `Mutation`
- 분류: 아키텍처·패턴 · 사용 4회 · 패키지: Feature, Domain
- 정의: 변경·변이. 서버 상태를 바꾸는 쓰기 작업.
  - 북마크 상태를 바꾸는 쓰기 요청과 진행 상태 (QuizDetail.PendingMutation, QuestionSolvingFeature.BookmarkMutation, SavedFeature.BookmarkMutation)
  - 프로필 직군·연차 갱신 요청의 진행 상태 (SettingsFeature.MutationStatus)
- 메모: 표기 흔들림: XxxMutation과 MutationStatus를 혼용한다.

### `My`
- 분류: 일반 · 사용 1회 · 패키지: Data
- 정의: 나의. 현재 사용자 본인의 것을 뜻한다.
  - 로그인한 사용자 본인이 제출한 답안 응답: MyAnswerResponseDTO

### `Name`
- 분류: 일반 · 사용 1회 · 패키지: Tuist
- 정의: 이름.
  - Tuist .external(name:)에 넘기는 외부 의존성 식별 문자열 (ExternalDependenciesName)

### `Namespace`
- 분류: 일반 · 사용 1회 · 패키지: Infrastructure
- 정의: 이름 공간. 이름 충돌을 막기 위해 항목을 묶는 범위.
  - Keychain 항목을 묶는 서비스 이름(kSecAttrService) (KeychainNamespace)

### `NavigationStack`
- 분류: 플랫폼 · 사용 1회 · 패키지: UI
- 정의: SwiftUI의 경로 기반 push 내비게이션 컨테이너 타입 이름(외부 고정 명칭)이다.
  - 흐름 단위 push 내비게이션 컨테이너: FlowNavigationStack

### `Next`
- 분류: 일반 · 사용 2회 · 패키지: Domain, Feature
- 정의: 다음.
  - 사용자가 이어서 풀어야 할 다음 퀴즈 (ProjectNextQuiz)
  - 현재 목록 뒤에 이어질 다음 페이지 (ProjectListScreen.NextPageFooter)

### `Noop`
- 분류: 약어 · 사용 7회 · 패키지: App
- 정의: No + Operation의 축약. 아무 동작도 하지 않음.
  - 실제 로직 없이 고정값을 돌려주거나 오류를 던지는 프리뷰용 대역 (AppRootPreviewSupport.NoopAccount, AppRootPreviewSupport.NoopProject, AppRootPreviewSupport.NoopUserInfo)
- 메모: 유의어 중첩: 같은 프리뷰 대역을 Feature에서는 Preview 접두어(ShareRegistrationPreviewSupport.PreviewExternalRepository)로 부른다.

### `Notification`
- 분류: 플랫폼 · 사용 17회 · 패키지: Composition, Feature, Domain, Data, Infrastructure
- 정의: 알림, 통지. Apple 플랫폼에서는 사용자에게 표시되는 로컬 알림과 APNs 원격 푸시 알림을 뜻한다.
  - iOS 로컬 리마인더 알림과 그 권한: ReminderNotification, NotificationAuthorizationClient, NotificationAuthorizationAdapter
  - APNs 원격 푸시 알림 수신: NotificationAppDelegate, PushNotificationAppDelegate, RemoteNotificationPayload
  - 알림 권한 상태: NotificationAuthorizationStatus(Domain·Infrastructure), SettingsFeature.NotificationStatus
- 메모: 다의어: 로컬 알림과 원격 푸시 알림을 모두 가리킨다. 유의어 중첩: 원격 푸시를 Push·Message로도 부른다. NotificationAuthorizationStatus는 Domain(현재 권한 값)과 Infrastructure(요청 직후 결과)에 같은 이름으로 다른 의미를 가진다.

### `Notifier`
- 분류: 일반 · 사용 1회 · 패키지: Data
- 정의: 알리는 것·통지자.
  - 로컬 알림 권한과 예약·취소를 담당하는 역할 (LocalReminderNotifier)
- 메모: Composition에서는 같은 대상을 GenerationReminderSchedulerAdapter(Scheduler)·NotificationAuthorizationAdapter로 불러 Notifier/Scheduler 유의어 중첩이 있다.

### `Offset`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 오프셋·이동량. 원래 위치에서 밀린 거리.
  - 그림자가 원래 위치에서 밀려나는 x·y 거리 (EffectToken.Offset)

### `Onboarding`
- 분류: 업무 개념 · 사용 7회 · 패키지: Feature, UI
- 정의: 온보딩. 신규 사용자를 서비스에 안내하고 가입시키는 절차다.
  - 튜토리얼·약관 동의·직군/경력 선택으로 이어지는 앱 최초 진입 흐름: OnboardingRouterFeature, OnboardingEntryPoint, OnboardingExitFeature
  - 온보딩 화면용 UI 목업·이미지 리소스: OnboardingMockup, ResourceImage.Asset.Onboarding

### `Opacity`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 불투명도.
  - 백분율로 정의한 투명도 토큰 (OpacityToken)

### `Option`
- 분류: 일반 · 사용 2회 · 패키지: Feature, UI
- 정의: 선택 항목·보기.
  - 객관식 보기 목록 중 항목 하나 (ChoiceAnswerOption, ChoiceOptionDisplay)
- 메모: 유의어 중첩: 같은 보기 개념을 Choice와 함께 쓴다.

### `Outcome`
- 분류: 일반 · 사용 7회 · 패키지: Composition, Feature, Domain, Data
- 정의: 결과, 귀결. 작업이 끝났을 때의 최종 결과를 뜻한다.
  - 퀴즈 생성 작업의 완료·실패 결과와 공급원: GenerationOutcome, QuizGenerationOutcomeDTO, PushQuizGenerationOutcomeSource
  - 답안 채점 결과: QuestionSolvingFeature.AnswerOutcome
- 메모: 다의어: 생성 작업 결과와 채점 결과에 쓰인다. 채점 결과는 Domain에서 Grading(ChoiceGrading, EssayGrading)으로 부른다.

### `Overlay`
- 분류: 플랫폼 · 사용 4회 · 패키지: Feature, UI
- 정의: 오버레이. 기존 화면 위에 겹쳐 올리는 층을 뜻하며 SwiftUI overlay 개념과 맞닿아 있다.
  - 기존 화면 위에 scrim·콘텐츠를 겹쳐 올리는 View (ModalOverlay, PushedScreenOverlay, QuizRouterOverlay)
  - header·footer가 스크롤 콘텐츠 위에 떠 있는 레이아웃 컨테이너 (OverlayContainer)
- 메모: 다의어: 화면 위에 뜨는 모달·push형 View와 콘텐츠 위에 떠 있는 레이아웃 배치로 갈린다.

### `Owner`
- 분류: 일반 · 사용 1회 · 패키지: Data
- 정의: 소유자.
  - GitHub 저장소 소유자 객체의 JSON 필드 매핑 (GitHubRepositoryResponseDTO.OwnerCodingKeys)

### `Page`
- 분류: 일반 · 사용 5회 · 패키지: Feature, Domain, UI
- 정의: 페이지, 쪽. 나뉜 내용의 한 단위를 뜻한다.
  - 페이지네이션 조회의 한 번 응답 단위: ProjectPage, ProjectListScreen.NextPageFooter
  - 가로로 넘기는 튜토리얼·온보딩 화면의 한 장: TutorialScreen.PageView, TutorialFeature.PageProgress, PageIndicator
- 메모: 다의어: 데이터 페이지네이션 단위와 화면 페이지로 나뉜다.

### `Pagination`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 페이지 나눔.
  - 프로젝트 목록의 다음 페이지 요청 진행 상태 (ProjectListFeature.Pagination)

### `Panel`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 패널·판. 배경이 있는 구획 영역.
  - 배경이 있는 카드형 등록 안내 영역 (HomeScreen.RegistrationPanelView)

### `Parser`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: Data
- 정의: 파서, 해석기. 문자열을 구조화된 값으로 분석하는 객체다.
  - URL에서 owner/name을 추출하는 객체: GitHubRepositoryURLParser
- 메모: 유의어 중첩: 비슷한 해석 역할에 Resolver(ExternalRepositoryResolver, SharedItemURLResolver)도 쓰인다.

### `Payload`
- 분류: 일반 · 사용 1회 · 패키지: Infrastructure
- 정의: 적재물·실린 데이터.
  - 알림 userInfo를 문자열 사전으로 정규화한 데이터 (RemoteNotificationPayload)

### `Pending`
- 분류: 일반 · 사용 5회 · 패키지: Composition, Domain, Data, Infrastructure
- 정의: 보류 중·처리 대기 중. 아직 완료되지 않은 상태.
  - 아직 끝나지 않아 기기에 기록해 둔 퀴즈 생성 요청 (PendingGenerationRepository, LocalPendingGenerationStore, PendingGenerationRepositoryAdapter)
  - 완료되지 않은 북마크 변경 작업 (QuizDetail.PendingMutation)
  - 콜백 설정 전에 도착해 전달을 기다리는 항목 (FirebaseMessagingAppDelegate.PendingDelivery)

### `Phase`
- 분류: 일반 · 사용 1회 · 패키지: Domain
- 정의: 국면, 단계. 진행 과정의 한 단계다.
  - 진행 중·준비 중·준비 완료·실패로 이어지는 생성 화면용 단계: ProjectGenerationPhase
- 메모: 유의어 중첩: 진행 단계 의미에 Status와 State(ProjectGenerationState)도 쓰인다.

### `Plain`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 평범한·장식 없는.
  - glass 효과 없이 단색 원형 배경을 쓰는 아이콘 버튼 (IconPlainButton)
- 메모: Glass(IconGlassButton)와 대비되는 스타일 명칭이다.

### `Platform`
- 분류: 플랫폼 · 사용 2회 · 패키지: Domain, Infrastructure
- 정의: 플랫폼. 운영체제 등 실행 기반.
  - 기기의 운영체제 종류(iOS) (DevicePlatform)
  - AuthenticationServices가 돌려주는 Apple 플랫폼 원본 상태 (AppleCredentialStateProvider.PlatformState)

### `Point`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 지점, 위치. 흐름이 시작되는 자리를 뜻한다.
  - 온보딩이 시작되는 단계(가이드 또는 큐레이션): OnboardingEntryPoint

### `Policy`
- 분류: 업무 개념 · 사용 12회 · 패키지: App, Composition, Domain, Data, UI
- 정의: 정책. 따라야 할 규칙이나 약관을 뜻하며, 이 프로젝트에서는 주로 사용자 동의가 필요한 이용약관·개인정보 처리방침 문서를 가리킨다.
  - 동의가 필요한 약관·정책 문서와 식별자 (PolicyDocument, PolicyDocumentID, PolicyManifestLoader)
  - 정책 문서 동의 기록·상태와 그 저장·접근 계약 (PolicyConsent, PolicyConsentRepository, LocalPolicyConsentStore)
  - 정책 문서 동의 행 UI (PolicyAgreementRow)
  - 대기·보존 시간을 정하는 규칙 값 묶음 (GenerationWaitPolicy)
- 메모: 다의어: 대부분 '약관 문서'지만 GenerationWaitPolicy는 '동작 규칙'을 뜻한다. Feature는 같은 대상을 Legal(LegalAgreementFeature)로, 동의는 Consent/Agreement로 달리 불러 유의어 중첩이 있다.

### `Position`
- 분류: 업무 개념 · 사용 7회 · 패키지: Feature, Domain, Data
- 정의: 직위·직군. 이 프로젝트에서는 회원의 개발 직군(iOS·Android·백엔드·프론트엔드)을 뜻한다.
  - 회원의 개발 직군 도메인 값과 DTO (MemberPosition, PositionDTO, PositionRequestDTO)
  - 직군 선택·표시 화면 (PositionSelectionFeature, SettingsScreen.PositionSelectionView, PositionDisplay)
- 메모: 일반 의미의 위치(좌표)가 아니라 직군을 뜻하므로 오해 소지가 있다.

### `PreferenceKey`
- 분류: 플랫폼 · 사용 1회 · 패키지: UI
- 정의: SwiftUI 프로토콜 이름(외부 고정 명칭)으로, 하위 View 값을 상위 View로 전달하는 키다.
  - 하위 콘텐츠 높이를 상위로 전달하는 키: ContentHeightPreferenceKey

### `Preparation`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 준비.
  - 풀이 화면에 넘길 Quiz를 QuizSet에서 찾는 진행 단계 (SingleQuestionEntryFeature.Preparation)

### `Preview`
- 분류: 플랫폼 · 사용 11회 · 패키지: App, Feature, UI
- 정의: 미리보기. 이 프로젝트에서는 Xcode SwiftUI #Preview 렌더링을 뜻한다.
  - #Preview 구성용 대역·샘플 데이터 모음 (AppRootPreviewSupport, OnboardingPreviewSupport, ShareRegistrationPreviewSupport)
  - #Preview용 고정 데이터 (HomePreviewFixture, ProfilePreviewFixture, SettingsPreviewFixture)
  - #Preview 전용 대역·항목 (ShareRegistrationPreviewSupport.PreviewRepositoryLocator, TabShellPreviewItem)
- 메모: 표기 흔들림: 프리뷰 지원 코드를 PreviewSupport와 PreviewFixture로 혼용한다.

### `Profile`
- 분류: 업무 개념 · 사용 12회 · 패키지: Feature, Domain, Data
- 정의: 프로필. 사람의 개요 정보를 뜻하며, 이 서비스에서는 사용자 이름·이메일·직군·연차·학습 통계를 담은 UserProfile과 그 화면을 가리킨다.
  - 사용자 프로필 모델과 서버 응답: UserProfile, MemberProfileResponseDTO
  - 프로필을 조회해 보여주는 마이 화면: ProfileFeature, ProfileScreen, ProfileDisplay
  - 각 화면의 프로필 조회 상태와 상단 프로필 영역: HomeFeature.State.ProfileLoad, SettingsFeature.ProfileLoad, HomeScreen.ProfileHeaderView
- 메모: ProfileLoad가 HomeFeature.State, ProfileFeature.State, SettingsFeature에 각각 정의되어 있다.

### `Progress`
- 분류: 일반 · 사용 8회 · 패키지: Domain, Feature, UI
- 정의: 진행·진척. 전체 대비 현재 위치나 완료 정도를 뜻한다.
  - 학습 세트·퀴즈 완료 정도와 그 표시 컴포넌트 (ProjectSetProgress, LabeledProgressBar, ProgressSegments)
  - 퀴즈 생성·등록 요청의 진행 단계 상태와 화면 (QuizGenerationProgressFeature, QuizGenerationProgressFeature.RegistrationProgress)
  - 튜토리얼 페이지의 현재 위치 (TutorialFeature.PageProgress)
- 메모: 다의어: 수치적 진척률(비율)과 절차의 단계 상태로 갈린다.

### `Project`
- 분류: 업무 개념 · 사용 58회 · 패키지: App, Composition, Feature, Domain, Data, UI
- 정의: 프로젝트·과제. 이 프로젝트에서는 GitHub 저장소 하나를 등록해 만든 학습 단위를 뜻한다.
  - 저장소 기반 학습 프로젝트 도메인 모델과 유스케이스 (Project, ProjectDetail, ProjectUseCase)
  - 프로젝트 학습 세트 생성 요청·상태 (ProjectGeneration, ProjectGenerationRequest, ProjectGenerationUseCase)
  - 프로젝트 API 요청·응답 DTO와 원격 계약 (ProjectListResponseDTO, RegisterProjectRequestDTO, ProjectRemote)
  - 프로젝트 목록·상세·등록 화면과 UI 컴포넌트 (ProjectListFeature, ProjectDetailFeature, HomeProjectCard)
- 메모: 유의어 중첩: 프로젝트와 GitHub Repository(저장소)가 거의 같은 대상을 가리켜 ProjectRepositoryInfo처럼 한 이름에 함께 나오며, Data에서는 LearningProject로도 부른다. Domain Project는 모델이 아니라 유스케이스 구현체를 가리킨다.

### `Projects`
- 분류: 업무 개념 · 사용 1회 · 패키지: Feature
- 정의: 프로젝트들(복수). 사용자가 등록한 학습 프로젝트의 목록을 뜻한다.
  - 등록한 프로젝트가 없을 때의 빈 상태 View: ProjectListScreen.EmptyProjectsView
- 메모: 표기 흔들림: 목록을 대부분 ProjectList로 부르고 여기만 복수형 Projects를 쓴다.

### `Prompt`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 지문·질문 문구.
  - 문제 본문 텍스트와 번호를 보여 주는 영역 (QuestionSolvingScreen.QuestionPrompt)

### `Provider`
- 분류: 아키텍처·패턴 · 사용 3회 · 패키지: Data, Infrastructure
- 정의: 제공자. 값이나 상태를 만들어 돌려주는 객체.
  - 저장된 세션에서 요청 자격을 읽어 제공하는 객체 (RequestCredentialProvider)
  - Apple 인가 흐름과 자격 증명 상태를 플랫폼 API로 제공하는 객체 (AppleAuthorizationProvider, AppleCredentialStateProvider)
- 메모: 유의어 중첩: 외부 기능 래퍼를 Provider, Client, Source(AppleSignInSource)로 계층마다 다르게 부른다.

### `Push`
- 분류: 플랫폼 · 사용 9회 · 패키지: Composition, Data, Infrastructure
- 정의: 푸시. 서버가 기기로 능동적으로 보내는 원격 알림을 뜻한다.
  - 원격 푸시 알림 클라이언트와 콜백: PushMessagingClient, FirebaseMessagingPushClient, PushNotificationCallbacks
  - 푸시 수신 앱 델리게이트와 조립: PushNotificationAppDelegate, PushMessagingAppDelegate, AppComposition.PushClientBox
  - 푸시로 전달되는 생성 결과 공급원: PushQuizGenerationOutcomeSource
- 메모: 유의어 중첩: 같은 원격 푸시를 Notification, RemoteMessage로도 부른다.

### `Pushed`
- 분류: 플랫폼 · 사용 1회 · 패키지: UI
- 정의: 밀어 넣어진. 여기서는 내비게이션 push처럼 오른쪽에서 들어오는 전환을 뜻한다.
  - push형 전환으로 올라오는 오버레이 View (PushedScreenOverlay)
- 메모: Push가 다른 곳(PushMessagingClient, PushQuizGenerationOutcomeSource)에서는 푸시 알림을 뜻해 다의어 혼동 소지가 있다.

### `Query`
- 분류: 약어 · 사용 1회 · 패키지: Infrastructure
- 정의: 질의. URL의 ? 뒤 쿼리 문자열.
  - URL 쿼리 항목 하나 (HTTPRequest.QueryItem)

### `Question`
- 분류: 업무 개념 · 사용 12회 · 패키지: Feature, Data, UI
- 정의: 문제, 질문. 이 서비스에서는 학습 세트에 속한 퀴즈 문제 하나를 뜻한다.
  - 서버 문제·북마크 응답: QuestionResponseDTO, BookmarkQuestionRequestDTO, BookmarkedQuestionListResponseDTO
  - 문제 풀이·단일 문제 진입 화면: QuestionSolvingFeature, SingleQuestionEntryFeature, QuestionSolvingScreen.QuestionPrompt
  - 저장한 문제와 문제 출처 표시: SavedQuestionDisplay, SavedQuestionCard, QuestionSourceDisplay
- 메모: 유의어 중첩: 같은 대상을 Domain에서는 Quiz(QuizID, QuizBookmark)로 부르고 Data·Feature 타입 이름에서는 Question으로 부른다.

### `Quiz`
- 분류: 업무 개념 · 사용 36회 · 패키지: App, Composition, Domain, Data, Feature
- 정의: 퀴즈·문제. 이 프로젝트의 핵심 학습 단위로, GitHub 저장소(프로젝트)를 분석해 생성되는 개별 문제와 그 흐름을 가리킨다.
  - 학습 세트에 속한 개별 문제와 식별자·내용·상세 (Quiz, QuizID, QuizDetail)
  - 북마크 대상이 된 문제 (QuizBookmark, QuizBookmarkList, QuizBookmarkRepositoryAdapter)
  - 저장소로부터 생성되는 퀴즈의 생성 요청·결과·난이도 (QuizGenerationOutcomeDTO, QuizLevel, QuizGenerationProgressFeature)
  - 학습 세트 문제를 푸는 화면 흐름 라우터 (QuizRouter, QuizRouterFeature, QuizRouterOverlay)
- 메모: 유의어 중첩: 같은 문제를 Feature·Data 일부는 Question(QuestionSolvingFeature, SavedQuestionDisplay, BookmarkQuestionRequestDTO)으로 부른다. 문제 묶음도 QuizSet(Domain)과 LearningSet(Data·Feature)으로 흔들린다.

### `Radius`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 반경·반지름.
  - 모서리를 둥글게 깎는 반지름 토큰 (CornerRadiusToken)

### `Random`
- 분류: 일반 · 사용 2회 · 패키지: Infrastructure
- 정의: 무작위. 예측할 수 없는 값을 뜻한다.
  - nonce·state에 쓰는 보안 난수 생성기와 오류: SecureRandomGenerator, SecureRandomGeneratorError

### `Ratio`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 비율.
  - UnitPoint로 변환될 x·y 비율 값 (GradientToken.UnitPointRatio)

### `Raw`
- 분류: 일반 · 사용 1회 · 패키지: Data
- 정의: 가공되지 않은·원시.
  - 서버·푸시가 보낸 상태 문자열을 변환 없이 담은 값 (QuizGenerationOutcomeDTO.RawStatus)

### `Receipt`
- 분류: 일반 · 사용 1회 · 패키지: Domain
- 정의: 영수증, 접수증. 요청이 접수됐음을 증명하는 기록이다.
  - 생성 요청 접수 후 발급된 프로젝트 ID를 담는 값: ProjectGenerationReceipt

### `Receiver`
- 분류: 일반 · 사용 1회 · 패키지: Data
- 정의: 수신자.
  - 등록 토큰을 제공하고 APNs 기기 토큰을 받아들이는 역할 (RemoteMessageReceiver)

### `Record`
- 분류: 일반 · 사용 6회 · 패키지: Domain, Data
- 정의: 기록·레코드. 저장해 두는 데이터 한 건.
  - 토큰·만료·약관 동의를 묶은 세션 저장 값 (StoredSessionRecord, SessionRecordStorageCoding)
  - 생성 요청 한 건의 진행 상태 기록 (GenerationRecord, GenerationRecordDTO)
  - 로그인 세션·약관 동의 기록 한 건 (SignInRecord, PolicyConsentRecordDTO)

### `Register`
- 분류: 일반 · 사용 2회 · 패키지: Data
- 정의: 등록하다. 대상을 시스템에 올려 관리 대상으로 만드는 동작이다.
  - GitHub 저장소를 학습 프로젝트로 등록하는 요청·응답: RegisterProjectRequestDTO, RegisterProjectResponseDTO
- 메모: 동사 원형을 타입 앞에 쓰는 DTO 명명(Register, Submit)이다.

### `Registration`
- 분류: 업무 개념 · 사용 15회 · 패키지: App, Composition, Domain, Feature, UI
- 정의: 등록. 대상을 시스템에 올려 두는 행위로, 이 프로젝트에서는 저장소 링크를 학습 프로젝트로 등록하는 흐름과 기기 등록을 주로 가리킨다.
  - 저장소 링크 입력부터 퀴즈 생성 요청까지의 프로젝트 등록 흐름 (ProjectRegistrationRouterFeature, HomeScreen.RegistrationPanelView)
  - 공유 확장으로 받은 GitHub 링크를 프로젝트로 등록하는 흐름 (ShareRegistrationFeature, ShareRegistrationScreen, ShareRegistrationDiagnosticLog)
  - 기기 정보·푸시 토큰의 서버 등록 (DeviceRegistration, DeviceRegistrationRepository, AppRootFeature.DeviceRegistrationStatus)
  - 폰트 파일을 시스템 폰트 관리자에 등록 (FontRegistration)
- 메모: 다의어: 프로젝트 등록, 기기 등록, 폰트 등록으로 대상이 다르다. 프로젝트 등록은 실제로 생성 요청이라 ProjectGeneration(ProjectGenerationRepository)과 유의어 중첩이 있다.

### `Reminder`
- 분류: 업무 개념 · 사용 13회 · 패키지: App, Composition, Feature, Domain, Data
- 정의: 리마인더·상기 알림. 나중에 사용자에게 알려 주는 알림.
  - 퀴즈 생성 완료·실패를 알리는 예약 로컬 알림 (GenerationReminder, GenerationReminderScheduler, ReminderNotification)
  - 알림 문구와 권한 상태 (GenerationReminderContent, ReminderAuthorizationStatus, ReminderAuthorizationSetting)
  - 리마인더 선택 시트 (QuizGenerationProgressScreen.GenerationReminderSheet)
- 메모: 유의어 중첩: 같은 알림을 Reminder와 Notification(LocalNotificationRequest, NotificationAuthorization)으로 혼용하며, GenerationReminderSheet는 푸시 알림으로 설명되어 로컬 알림과 의미가 흔들린다.

### `Remote`
- 분류: 아키텍처·패턴 · 사용 10회 · 패키지: Data, Infrastructure
- 정의: 원격. 네트워크 너머의 서버나 기기 밖에서 오는 것을 뜻한다.
  - 서버 API를 호출하는 원격 데이터 접근 객체: AnswerRemote, ProjectRemote, MemberRemote
  - 서버에서 기기로 오는 원격 푸시 메시지·알림: RemoteMessageClient, RemoteMessageReceiver, RemoteNotificationPayload
- 메모: 다의어: 데이터 접근 계층 접미어(…Remote)와 원격 푸시 수식어(Remote…)로 나뉜다. 유의어 중첩: 외부 호출 객체에 Client도 쓰인다.

### `Repository`
- 분류: 아키텍처·패턴 · 사용 54회 · 패키지: App, Composition, Domain, Data, Feature
- 정의: 저장소. 일반적으로 보관소를 뜻하며, 이 프로젝트에서는 데이터 접근을 추상화하는 Repository 패턴 계약과 GitHub의 Git 코드 저장소라는 두 의미로 쓰인다.
  - Data 계층이 구현하는 Domain의 데이터 접근 계약 (ProjectRepository, QuizSetRepository, UserInfoRepository)
  - 그 계약을 Data 구현에 맞추는 Composition 어댑터 (ProjectRepositoryAdapter, SignInRepositoryAdapter, WithdrawalRepositoryAdapter)
  - GitHub 등 외부 서비스의 Git 코드 저장소와 그 조회·파싱 (ExternalRepository, GitHubRepositoryURLParser, ExternalRepositoryRemote)
  - 등록 흐름·상세 화면에서 다루는 GitHub 저장소 (RepositoryLinkInputFeature, RepositoryConfirmationScreen, ProjectDetailScreen.RepositorySummaryView)
- 메모: 다의어: Repository 패턴(데이터 접근 계약)과 Git 코드 저장소가 같은 단어를 공유해 ExternalRepositoryLocatorAdapter처럼 한 이름 안에서 두 의미가 섞이지 않도록 External·GitHub 접두어로 구분한다. ProjectRepository(패턴)와 ProjectRepositoryInfo(Git 저장소)는 접두어가 같아 특히 혼동된다. Store·Storage와 유의어 중첩이 있다.

### `Request`
- 분류: 일반 · 사용 26회 · 패키지: Domain, Data, Infrastructure
- 정의: 요청. 서버나 시스템에 보내는 요구와 그 데이터.
  - 서버로 보내는 HTTP 요청 본문 DTO (SubmitChoiceAnswerRequestDTO, RegisterProjectRequestDTO, DeviceInfoRequestDTO)
  - 전송 계층의 요청 모델·전송 계약 (HTTPRequest, TransportRequest, RequestTransport)
  - 도메인 생성 요청과 알림 발송 요청 (ProjectGenerationRequest, LocalNotificationRequest)
- 메모: 다의어: HTTP 요청, 도메인 생성 요청, 로컬 알림 요청으로 쓰인다. 유의어 중첩: 요청 모델이 HTTPRequest, HTTPTransportRequest, TransportRequest, LearningProjectRequest로 계층마다 중복되고 Request가 접두어(RequestTransport)·접미어(TransportRequest) 양쪽에 쓰인다.

### `Resolver`
- 분류: 아키텍처·패턴 · 사용 3회 · 패키지: App, Domain, UI
- 정의: 해석기, 해결자. 입력을 분석해 실제 값이나 대상으로 풀어내는 객체다.
  - 여러 첨부 중 유효한 URL 하나를 결정: SharedItemURLResolver
  - URL 문자열을 실제 저장소 정보로 풀어내는 유스케이스 구현체: ExternalRepositoryResolver
  - 토큰과 문자를 실제 Font·행간 값으로 변환: TextStyleResolver
- 메모: 유의어 중첩: 비슷한 역할에 Parser(GitHubRepositoryURLParser)가 함께 쓰인다.

### `Resource`
- 분류: 플랫폼 · 사용 3회 · 패키지: App, UI
- 정의: 자원·리소스. 앱 번들에 포함된 파일(이미지·애니메이션·JSON 등)을 뜻한다.
  - UI 모듈 번들의 이미지·애니메이션 자원 (ResourceImage, ResourceAnimation)
  - 앱 번들에 포함된 JSON 등 리소스 파일 이름 (AppBundleResource)
- 메모: Asset과 유의어 중첩(ResourceImage.Asset). 다른 곳의 Remote·Repository '외부 자원 접근'과는 무관하다.

### `Response`
- 분류: 일반 · 사용 28회 · 패키지: Data, Infrastructure
- 정의: 응답. 요청에 대해 돌려받는 결과와 데이터.
  - 서버 API 응답 본문 DTO (ProjectListResponseDTO, LearningSetResponseDTO, MemberProfileResponseDTO)
  - 공통 응답 봉투와 빈 data (APIResponseDTO, EmptyResponseData)
  - 전송 계층의 응답 모델 (HTTPResponse, HTTPTransportResponse, TransportResponse)
- 메모: 유의어 중첩: 응답 모델이 HTTPResponse, HTTPTransportResponse, TransportResponse로 계층마다 중복된다. 표기 흔들림: 대부분 DTO 접미어를 쓰지만 EmptyResponseData는 Data 접미어를 쓴다.

### `Restoration`
- 분류: 일반 · 사용 1회 · 패키지: Domain
- 정의: 복원. 이전 상태를 되살리는 일이다.
  - 이전에 저장된 로그인 세션을 되살리는 시도의 결과: SignInRestoration

### `Result`
- 분류: 일반 · 사용 4회 · 패키지: Domain, Feature, UI
- 정의: 결과. 시도나 판정의 결과를 뜻한다.
  - 로그인·로그아웃 시도의 성공·취소·실패 결과 (SignInResult, SignOutResult)
  - 답안의 채점·정오 판정 결과 표시 (QuestionSolvingScreen.EssayResultSection, ChoiceResultRow)
- 메모: Swift 표준 Result 타입과 이름이 겹친다. 생성 결과에는 Outcome(QuizGenerationOutcomeDTO)을 써 Result/Outcome 유의어가 공존한다.

### `Resumption`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 재개·이어하기.
  - 이미 답한 문제를 건너뛰고 이어 풀 위치와 누적 통계 (LearningSetResumption)

### `Retry`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 재시도. 실패한 작업을 다시 실행하는 일이다.
  - 공유 등록에서 다시 실행할 대상 작업: ShareRegistrationFeature.RetryTarget

### `Role`
- 분류: 일반 · 사용 2회 · 패키지: UI
- 정의: 역할. 대상이 담당하는 의미 분류를 뜻한다.
  - 메뉴 행이 일반·파괴적 동작인지 구분 (ActionMenu.Item.Role)
  - 폰트 패밀리가 담당하는 문자 범위 분류 (FontFamilyToken.FontSelectionRole)

### `Root`
- 분류: 아키텍처·패턴 · 사용 3회 · 패키지: App
- 정의: 뿌리·최상위. 트리 구조의 최상위 노드.
  - 앱 화면 트리와 리듀서 트리의 최상위 (AppRootFeature, AppRootView, AppRootPreviewSupport)

### `Route`
- 분류: 아키텍처·패턴 · 사용 1회 · 패키지: App
- 정의: 경로. 어느 화면 흐름으로 갈지 정하는 분기를 뜻한다.
  - 앱 최상위에서 보여줄 화면 흐름 분기: AppRootFeature.Route
- 메모: 유의어 중첩: Feature의 Router 타입들은 ActiveScreen·Step으로 같은 분기 개념을 표현한다.

### `Router`
- 분류: 아키텍처·패턴 · 사용 13회 · 패키지: Feature
- 정의: 라우터·경로 지정자. 여러 화면 사이의 전환을 결정하는 역할로, 여기서는 하위 Feature 간 화면 전환을 소유하는 상위 리듀서와 그 View다.
  - 자식 리듀서 사이 화면 전환 규칙을 결정하는 상위 리듀서 (OnboardingRouterFeature, QuizRouterFeature, SettingsRouterFeature)
  - 활성 화면 상태를 내비게이션 스택·오버레이로 배치하는 View (MainShellRouter, ProjectDetailRouter, QuizRouterOverlay)
- 메모: 리듀서는 {흐름}RouterFeature, View는 {흐름}Router로 짝을 이루지만 QuizRouterOverlay처럼 View가 Overlay 접미어를 추가로 갖는 경우가 있다.

### `Row`
- 분류: 일반 · 사용 8회 · 패키지: Feature, UI
- 정의: 행·줄. 목록에서 한 줄을 차지하는 항목.
  - 목록에 세로로 쌓이는 한 줄짜리 UI 컴포넌트 (ProjectRow, SettingRow, ChoiceResultRow)
  - 화면 내부의 한 줄짜리 토글·셀 뷰 (LegalAgreementScreen.AllAgreementRow, SettingsScreen.SettingRowContent)

### `Rubric`
- 분류: 업무 개념 · 사용 3회 · 패키지: Data, UI
- 정의: 루브릭, 채점 기준표. 서술형 답안을 평가하는 기준 체계다.
  - 서술형 답안 채점 기준·핵심 포인트·예시 답안 응답: RubricResponseDTO, RubricCriterionResponseDTO
  - 평가 기준 항목과 총평을 그리는 View: RubricView

### `Saved`
- 분류: 업무 개념 · 사용 4회 · 패키지: Feature, UI
- 정의: 저장된. 여기서는 사용자가 북마크해 둔 문제를 가리킨다.
  - 북마크한 문제 목록 탭 화면과 표시 모델·카드 (SavedFeature, SavedScreen, SavedQuestionCard)
- 메모: Bookmark와 같은 대상을 가리키는 유의어 중첩이 있다(Feature 화면은 Saved, Domain·Data는 Bookmark).

### `Scheduler`
- 분류: 아키텍처·패턴 · 사용 2회 · 패키지: Composition, Domain
- 정의: 예약자·일정 관리자. 작업을 지정 시각에 등록하는 역할.
  - 로컬 알림을 특정 시각에 예약하는 계약과 어댑터 (GenerationReminderScheduler, GenerationReminderSchedulerAdapter)
- 메모: 유의어 중첩: 같은 알림 발송 역할을 Data에서는 LocalReminderNotifier(Notifier)로 부른다.

### `Scope`
- 분류: 플랫폼 · 사용 1회 · 패키지: Infrastructure
- 정의: 범위, 권한 범위. Apple 로그인에서 요청하는 사용자 정보 항목을 뜻한다.
  - Apple 로그인에서 요청하는 이메일·전체 이름 항목: AppleCredential.Scope

### `Screen`
- 분류: 아키텍처·패턴 · 사용 34회 · 패키지: Feature, UI
- 정의: 화면. 앱의 한 페이지를 뜻하며, 이 프로젝트 View 컨벤션에서는 Feature Store를 받아 한 화면 전체를 그리는 SwiftUI View 접미어다.
  - Feature Store를 받아 한 화면을 그리는 최상위 SwiftUI View (HomeScreen, ProjectDetailScreen, SettingsScreen)
  - 라우터가 관리하는 활성 화면 단위와 전환 기록 (OnboardingRouterFeature.ActiveScreen, QuizRouterFeature.ScreenTransition, SettingsRouterFeature.State.ActiveScreen)
  - UI 컴포넌트가 적용되는 앱 화면 전체 (ScreenContainer, ScreenControlBar, ScreenEdgeScrim)
- 메모: 다의어: View 타입 접미어와 라우터 상태의 화면 단위로 갈린다. SettingsRouterFeature.State.SettingsStep은 같은 화면 단위를 Step으로도 불러 ActiveScreen과 유의어 중첩이 있다.

### `Scrim`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 스크림. 콘텐츠를 흐리게 가리는 반투명 막.
  - 가장자리 콘텐츠를 어둡게 덮는 그라데이션 층 (ScreenEdgeScrim)

### `Scroll`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 스크롤. 화면 내용을 밀어 이동하는 동작이다.
  - 홈 카드 목록의 가로 스크롤 레이아웃: HomeCardScrollLayout

### `Section`
- 분류: 일반 · 사용 9회 · 패키지: Feature
- 정의: 구획·섹션. 화면 안의 한 영역을 뜻한다.
  - 화면 안의 영역 View (HomeScreen.ProjectSection, QuestionSolvingScreen.ChoiceSection, SavedScreen.FilterSection)
  - 섹션의 표시 상태 (HomeProjectSectionState)
- 메모: SectionView(SettingsScreen.SectionView, GuideSectionView)와 Section(ChoiceSection)으로 View 접미어 사용이 흔들린다.

### `Secure`
- 분류: 일반 · 사용 5회 · 패키지: Data, Infrastructure
- 정의: 안전한·보안의.
  - Keychain 같은 보안 영역의 저장소 (SecureValueStorage, LocalSecureValueStorage, SecureValueStorageError)
  - 암호학적으로 안전한 난수 생성 (SecureRandomGenerator, SecureRandomGeneratorError)
- 메모: 다의어: 보안 저장소와 암호학적 난수라는 두 의미로 쓰인다.

### `Segments`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 구간, 조각들. 전체를 나눈 부분들을 뜻한다.
  - 문항 하나당 하나씩 나뉜 진행 막대 조각: ProgressSegments
- 메모: ContinuousProgressBar(연속형)와 대비되는 구간형 진행 표시다.

### `Selectable`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 선택 가능한.
  - 탭으로 고를 수 있는 설정 행 (SelectableSettingRow)

### `Selection`
- 분류: 일반 · 사용 12회 · 패키지: Feature, UI
- 정의: 선택·고르기. 여러 항목 중 하나를 고르는 사용자 행위.
  - 온보딩·설정에서 직군·경력을 고르는 화면 (PositionSelectionFeature, CareerSelectionScreen, SettingsScreen.CareerLevelSelectionView)
  - 퀴즈 난이도를 고르는 화면 (QuizLevelSelectionFeature, QuizLevelSelectionScreen)
  - 고르는 동작을 담는 카드 UI (SelectionCard, SelectionCardList, SelectionCardStyle)
  - 문자별 폰트 패밀리 선택 규칙 (FontFamilyToken.FontSelectionRole)
- 메모: 유의어 중첩: 선택 행위는 Selection, 고를 대상인 보기는 Choice·Option으로 나뉘며, UI에는 Selectable(SelectableSettingRow) 형태도 있다.

### `Sequence`
- 분류: 일반 · 사용 1회 · 패키지: App
- 정의: 순서, 연속. 정해진 순서로 이어지는 일련의 작업이다.
  - 정해진 순서로 실행되는 앱 시작 작업 묶음: AppLaunchSequence
- 메모: Swift의 Sequence 프로토콜과는 관계없는 일반 의미다.

### `Server`
- 분류: 일반 · 사용 3회 · 패키지: Data
- 정의: 서버. 여기서는 Git It 백엔드 API 서버를 뜻한다.
  - 백엔드 API 서버 오류 (ServerAPIError)
- 메모: Data의 Authentication·LearningProject·Member 관심사가 같은 이름의 타입을 각각 따로 선언한다(ServerAPIError 3벌). 다른 곳에서는 서버 접근을 Remote로 부른다.

### `Service`
- 분류: 아키텍처·패턴 · 사용 3회 · 패키지: Data
- 정의: 서비스. 원격 서버가 제공하는 기능.
  - 인증·학습 프로젝트·회원 서버 API 서비스의 오류 (AuthenticationServiceError, LearningProjectServiceError, MemberServiceError)
- 메모: 유의어 중첩: 서버 API 경계를 Service, Remote(ProjectRemote), Endpoint, Client로 혼용한다.

### `Session`
- 분류: 업무 개념 · 사용 5회 · 패키지: Composition, Data
- 정의: 세션. 이 프로젝트에서는 로그인 후 보안 저장소에 유지되는 인증 토큰 세션을 뜻한다.
  - 로그인 세션 레코드와 저장 형식: StoredSessionRecord, SessionRecordStorageCoding, SessionStorageLayout
  - 세션 존재 여부 공유 표식과 가용성 판정 조립: SharedSessionStateMarkerCoding, SessionAvailabilityAssembly

### `Set`
- 분류: 업무 개념 · 사용 18회 · 패키지: Composition, Domain, Data, Feature, UI
- 정의: 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(학습 세트)을 주로 가리킨다.
  - 프로젝트에서 생성된 퀴즈 묶음과 그 식별자·진행률·라벨 (QuizSet, QuizSetID, ProjectSetProgress)
  - 학습 세트 조회 서버 API·응답과 화면 (LearningSetRemote, LearningSetResponseDTO, LearningSetIntroFeature)
  - 모든 디자인 토큰을 모은 집합 (DesignTokenSet)
- 메모: 다의어: 학습 세트와 일반 집합(DesignTokenSet)으로 갈린다. 같은 학습 세트를 QuizSet(Domain)·LearningSet(Data·Feature)·ProjectSet(ProjectSetSummaryDTO, ProjectSetProgress)으로 부르는 유의어 중첩이 있다.

### `Setting`
- 분류: 일반 · 사용 9회 · 패키지: App, Feature, Domain, Data, Infrastructure, UI
- 정의: 설정. 사용자가 정해 둔 값이나 설정 항목.
  - 알림 권한·기기 등록을 다루는 앱 설정 유스케이스 (AppSetting, AppSettingUseCase, AppSettingError)
  - 시스템에 저장된 알림 권한 값 (NotificationAuthorizationSetting, ReminderAuthorizationSetting)
  - 설정 화면의 항목 UI (SettingRow, SelectableSettingRow, SettingsScreen.SettingRowContent)
- 메모: 다의어: 앱 설정 관심사, 권한 설정 값, 설정 화면 항목으로 쓰인다. 표기 흔들림: 화면·Feature는 복수형 Settings(SettingsFeature)를, 항목·유스케이스는 단수 Setting을 쓴다.

### `Settings`
- 분류: 업무 개념 · 사용 6회 · 패키지: Feature
- 정의: 설정. 이 앱에서는 직군·연차·알림·약관·로그아웃·계정 삭제를 다루는 설정 탭 기능 영역이다.
  - 설정 화면과 그 Feature: SettingsFeature, SettingsScreen, SettingsPreviewFixture
  - 설정 탭 흐름 라우팅과 단계: SettingsRouter, SettingsRouterFeature, SettingsRouterFeature.State.SettingsStep
- 메모: 표기 흔들림: 기능 영역은 복수형 Settings를 쓰지만 UI의 SettingRow, SelectableSettingRow, Domain의 AppSettingError는 단수형 Setting을 쓴다.

### `Shape`
- 분류: 플랫폼 · 사용 1회 · 패키지: Feature
- 정의: 도형. 여기서는 SwiftUI Shape 프로토콜을 채택한 경로 도형이다.
  - 겹친 카드 묶음을 그리는 Shape (HomeScreen.EmptyDeckShape)

### `Share`
- 분류: 플랫폼 · 사용 8회 · 패키지: App, Composition, Feature
- 정의: 공유. 이 프로젝트에서는 iOS 공유 시트(Share Extension)로 링크를 앱에 넘기는 기능을 뜻한다.
  - 공유 확장 화면과 의존성 조립 (ShareViewController, ShareExtensionComposition, ShareExtensionEndpointHost)
  - 공유 시트로 들어온 저장소 링크 등록 흐름 (ShareRegistrationFeature, ShareRegistrationScreen, ShareRegistrationDiagnosticLog)
- 메모: 표기 흔들림: 같은 기능을 ShareExtension*, ShareRegistration*, Share*(ShareViewController), Shared*(SharedItemAttachment)로 다르게 부른다.

### `Shared`
- 분류: 일반 · 사용 3회 · 패키지: App, Data
- 정의: 공유된. 다른 주체와 함께 쓰거나 넘겨받은 것을 뜻한다.
  - 사용자가 공유 시트로 넘긴 항목: SharedItemURLResolver, SharedItemAttachment
  - 앱과 Share Extension이 함께 읽는 공유 저장 영역: SharedSessionStateMarkerCoding
- 메모: 다의어: 공유 시트로 받은 입력과 앱·확장 간 공유 저장 영역으로 나뉜다.

### `Sheet`
- 분류: 플랫폼 · 사용 5회 · 패키지: Feature, UI
- 정의: 시트. 화면 하단에서 올라오는 모달 패널로, SwiftUI .sheet 개념에서 왔다.
  - 하단에서 올라오는 모달 패널 컴포넌트 (ConfirmationSheet, SheetSurface, WebSheet)
  - 화면 전용 시트 View (QuizGenerationProgressScreen.GenerationReminderSheet, QuestionSolvingScreen.SourceSheet)
- 메모: SourceSheet는 SwiftUI .sheet가 아니라 ModalOverlay 위에 표시되어 이름과 구현 방식이 다르다.

### `Shell`
- 분류: 아키텍처·패턴 · 사용 6회 · 패키지: Feature, UI
- 정의: 껍데기·외곽. 하위 화면을 감싸는 최상위 틀.
  - 탭 바로 하위 화면을 감싸는 메인 컨테이너와 라우터 (MainShellRouter, MainShellRouterFeature, MainShellTab)
  - 탭별 화면을 담는 UI 틀 (TabShell, TabShellItem, TabShellPreviewItem)

### `SignedIn`
- 분류: 관용 표현 · 사용 1회 · 패키지: Domain
- 정의: Signed In, 로그인된. 로그인이 완료된 상태를 나타내는 관용 표현이다.
  - 로그인이 완료된 계정: SignedInAccount
- 메모: 표기 흔들림: 같은 개념을 SignIn/SignedIn과 Login(LoginResponseDTO, AppleLoginRequestDTO)으로 혼용한다.

### `SignIn`
- 분류: 관용 표현 · 사용 15회 · 패키지: Composition, Domain, Data, Feature, UI
- 정의: Sign + In, 로그인. 계정에 접속하는 행위를 뜻하는 관용 표현이며, 여기서는 Apple 인증으로 Git It 계정에 로그인하는 것이다.
  - Apple 인증으로 Git It 계정에 로그인하는 행위의 상태·결과·기록·복원 (SignInState, SignInResult, SignInRestoration)
  - 로그인 데이터 접근 계약과 어댑터 (SignInRepository, SignInRepositoryAdapter)
  - Apple 인증 창 로그인 자격·소스·오류 (AppleSignInCredential, AppleSignInSource, AppleSignInError)
  - 로그인 버튼과 화면 영역 (AppleSignInButton, TutorialScreen.SignInSection)
- 메모: Authentication과 유의어 중첩(AuthenticationRepository와 SignInRepository 공존). SignedInAccount처럼 과거분사 형태도 쓰인다.

### `SignOut`
- 분류: 관용 표현 · 사용 1회 · 패키지: Domain
- 정의: Sign + Out 관용 표현. 로그아웃을 뜻한다.
  - 로그인 세션과 인증 정보를 지우는 행위의 결과 (SignOutResult)
- 메모: 유의어 중첩: SignIn(SignInRecord)과 짝을 이루지만 다른 곳에서는 Login(AppleLoginRequestDTO)을 쓴다.

### `Single`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 단일, 하나의. 여러 개가 아닌 하나만을 대상으로 함을 뜻한다.
  - 세트 전체가 아닌 문제 한 개만 여는 진입 Feature: SingleQuestionEntryFeature

### `Size`
- 분류: 일반 · 사용 4회 · 패키지: UI
- 정의: 크기.
  - 버튼·배지의 크기 단계 (ActionButton.Size, IconGlassButton.Size, TagBadge.Size)
  - 컨트롤 높이·터치 영역 치수 토큰 (ControlSizeToken)

### `Solving`
- 분류: 업무 개념 · 사용 2회 · 패키지: Feature
- 정의: 풀이·해결. 문제를 푸는 행위.
  - 답안을 작성해 제출하고 채점 결과를 보는 풀이 화면 (QuestionSolvingFeature, QuestionSolvingScreen)

### `Source`
- 분류: 일반 · 사용 7회 · 패키지: Feature, Domain, Data
- 정의: 출처, 원천. 무언가가 비롯된 근거나 데이터를 공급하는 주체를 뜻한다.
  - 퀴즈 문제가 만들어진 근거 코드 파일·심볼·참조 링크: QuizSource, SourceResponseDTO, QuestionSolvingScreen.SourceSheet
  - 결과 이벤트나 인증 결과를 공급하는 데이터 소스: QuizGenerationOutcomeSource, PushQuizGenerationOutcomeSource, AppleSignInSource
- 메모: 다의어: 문제의 근거 코드(도메인 개념)와 데이터 공급원(설계 역할)으로 나뉜다.

### `Splash`
- 분류: 플랫폼 · 사용 2회 · 패키지: Feature, UI
- 정의: 스플래시. 짧게 보여 주는 첫 화면·전환 화면을 뜻한다.
  - 앱 시작 시 잠시 보여 주는 화면 (SplashView)
  - 큐레이션 완료 뒤 메인 진입 전 잠시 표시되는 화면 (OnboardingRouter.CurationSplashView)
- 메모: AppEntryFeature도 스플래시 단계를 뜻해 Entry와 역할이 겹친다.

### `Stage`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 단계·국면.
  - 학습 세트 생성 체크리스트의 한 단계 (QuizGenerationProgressScreen.Stage)
- 메모: 유의어 중첩: 도메인에서는 같은 생성 단계 개념을 Phase(ProjectGenerationPhase)로 표현한다.

### `Standard`
- 분류: 일반 · 사용 1회 · 패키지: Infrastructure
- 정의: 표준, 기본. 별도 조정 없는 기본 방식을 뜻한다.
  - 커스터마이징 없는 기본 JSON 본문 코딩: StandardJSONBodyCoding

### `State`
- 분류: 아키텍처·패턴 · 사용 49회 · 패키지: App, Domain, Data, Infrastructure, Feature, UI
- 정의: 상태. 시간에 따라 바뀌는 현재 값을 뜻하며, 이 프로젝트에서는 TCA 리듀서 상태, 도메인 상태 스냅샷, 내부 가변 상태, UI 표시 상태로 폭넓게 쓰인다.
  - TCA Reducer가 소유하는 관찰 가능한 상태 구조체 (AppRootFeature.State, HomeFeature.State, SettingsFeature.State)
  - 도메인의 로그인·북마크·생성 요청 상태와 스냅샷 (SignInState, QuizBookmarkState, ProjectGenerationState)
  - 동시성 보호를 위해 잠금 아래 묶은 내부 가변 상태 (FirebaseMessagingPushClient.State, AppleAuthorizationProvider.State, KeychainStore.InMemoryBackend.State)
  - 자격 증명 유효·철회 상태 (AppleCredentialState, AppleSignInState, AppleCredentialStateProvider.PlatformState)
  - UI 컴포넌트의 표시 상태 (ChoiceAnswerOption.State, TextField.State, EmptyState)
- 메모: 다의어가 매우 많다: TCA State, 도메인 스냅샷, 잠금 보호 내부 상태, 표시 상태가 모두 State다. Status(AuthenticationStatus, DeviceRegistrationStatus, PolicyConsentStatus)와 유의어 중첩이 있고, EmptyState는 상태가 아니라 빈 목록 안내 View다.

### `Statistics`
- 분류: 업무 개념 · 사용 2회 · 패키지: Feature, Domain
- 정의: 통계. 수치를 집계한 결과.
  - 주간·월간 풀이 수, 연속 일수, 요일별 개수 집계와 그 표시 카드 (LearningStatistics, ProfileScreen.StatisticsCardView)

### `Status`
- 분류: 일반 · 사용 19회 · 패키지: App, Feature, Domain, Data, Infrastructure
- 정의: 상태. 대상이 현재 어느 단계나 값에 있는지를 뜻한다.
  - 비동기 작업 진행 단계(대기·진행·완료·실패): ProjectDetailFeature.LoadStatus, SettingsFeature.MutationStatus, ShareRegistrationFeature.Status
  - 생성 작업의 진행·종료 상태: GenerationRecord.Status, GenerationOutcome.Status, QuizGenerationStatusResponseDTO
  - 권한·동의의 현재 값이나 요청 결과: NotificationAuthorizationStatus, ReminderAuthorizationStatus, PolicyConsentStatus
- 메모: 다의어: 진행 단계, 최종 결과, 권한 현재 값, 요청 직후 결과 등 의미 폭이 넓다. 유의어 중첩: State(GenerationState, ProjectGenerationState), Phase와 겹친다. NotificationAuthorizationStatus는 Domain과 Infrastructure에서 의미가 다르다.

### `Step`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 단계.
  - 설정 흐름 안의 목록·직군 선택·연차 선택·탈퇴 화면 구분 (SettingsRouterFeature.State.SettingsStep)
- 메모: 다른 라우터는 같은 개념을 ActiveScreen으로 불러 Step/Screen 유의어 중첩이 있다.

### `Stop`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 정지점. 그라데이션에서 특정 위치의 색을 지정하는 지점.
  - 그라데이션 색 정지점 (GradientToken.Stop)
- 메모: 일반 의미의 멈춤과 다르다.

### `Storage`
- 분류: 아키텍처·패턴 · 사용 12회 · 패키지: Data
- 정의: 저장소, 저장 공간. 데이터를 보관·조회·삭제하는 계약이나 그 구현을 뜻한다.
  - 키-값·보안 값 저장 계약과 구현: KeyValueStorage, SecureValueStorage, LocalKeyValueStorage
  - 저장소 구현 생성과 저장 영역: StorageFactory, StorageLocation
  - 보안 저장소 레코드 배치·코딩 규칙: SessionStorageLayout, AppleIdentityStorageLayout, SessionRecordStorageCoding
- 메모: 유의어 중첩: 같은 저장 개념에 Store(AppleIdentityStore, KeychainStore, UserDefaultsStore, LocalPendingGenerationStore)와 Repository(Domain 계약)가 함께 쓰인다.

### `Store`
- 분류: 아키텍처·패턴 · 사용 8회 · 패키지: Data, Infrastructure
- 정의: 저장소·보관하는 것. 값을 넣고 꺼내는 저장 객체를 뜻한다.
  - Keychain·UserDefaults 위에서 key로 Data를 저장·조회·삭제하는 인프라 객체 (KeychainStore, UserDefaultsStore, AppGroupKeychainStore)
  - 특정 기록(동의·기기 식별자·생성 상태)을 읽고 쓰는 로컬 저장 객체 (LocalPolicyConsentStore, LocalDeviceIdentifierStore, LocalPendingGenerationStore)
  - 보안 저장소 접근 객체 (AppleIdentityStore)
- 메모: Storage(UnavailableKeyValueStorage, KeyValueStorage)·Repository와 유의어 중첩이 있다. TCA의 Store(Feature Store)와도 이름이 겹쳐 혼동 소지가 있다. AppGroupKeychainStore는 저장 객체가 아니라 KeychainStore를 만드는 팩토리 역할이다.

### `Stored`
- 분류: 일반 · 사용 1회 · 패키지: Data
- 정의: 저장된. 영속 저장소에 보관된 형태.
  - 보안 저장소에 영속된 세션 기록 (StoredSessionRecord)

### `Style`
- 분류: 일반 · 사용 7회 · 패키지: UI
- 정의: 스타일, 양식. 시각적 표현 방식이나 규칙을 뜻한다.
  - 컴포넌트의 배경·글자색 조합 시각 변형: ActionButton.Style, TagBadge.Style, LabeledCard.Style
  - 글자 굵기·크기·행간 규칙 토큰과 해석: TextStyleToken, TextStyleResolver
  - 카드의 상세/간결 표시 형태: SelectionCardStyle
- 메모: 표기 흔들림: 대부분 중첩 타입 Component.Style이지만 SelectionCardStyle만 최상위 타입이다.

### `Styled`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 스타일이 적용된.
  - TextStyleToken이 적용된 텍스트 View (StyledText)

### `Submission`
- 분류: 업무 개념 · 사용 4회 · 패키지: Feature, Domain
- 정의: 제출·제출물.
  - 퀴즈 세트 조회 시 함께 내려오는 과거 제출 답안 기록 (ChoiceSubmission, EssaySubmission)
  - 답안·큐레이션을 보내는 제출 작업의 진행 상태 (QuestionSolvingFeature.Submission, CareerSelectionFeature.Submission)
- 메모: 다의어: 도메인의 과거 제출 기록과 Feature의 제출 진행 상태로 쓰인다.

### `Submit`
- 분류: 일반 · 사용 4회 · 패키지: Data
- 정의: 제출하다. 작성한 것을 받아 처리할 곳으로 보내는 동작이다.
  - 객관식·서술형 답안 제출 요청·응답: SubmitChoiceAnswerRequestDTO, SubmitEssayAnswerResponseDTO
- 메모: 동사 원형을 타입 앞에 쓰는 DTO 명명(Register, Submit)이다.

### `Summary`
- 분류: 일반 · 사용 3회 · 패키지: Domain, Data, Feature
- 정의: 요약. 핵심 속성만 추린 정보를 뜻한다.
  - 목록·세트용 요약 모델과 DTO (ProjectSummary, ProjectSetSummaryDTO)
  - 상세 화면의 저장소 요약 영역 (ProjectDetailScreen.RepositorySummaryView)

### `Support`
- 분류: 아키텍처·패턴 · 사용 4회 · 패키지: App, Feature
- 정의: 지원·보조. 주 기능을 돕는 보조 코드.
  - 프리뷰 구성용 대역·샘플 데이터를 모은 보조 네임스페이스 (AppRootPreviewSupport, OnboardingPreviewSupport, ShareRegistrationPreviewSupport)
- 메모: 유의어 중첩: 같은 용도에 PreviewFixture(HomePreviewFixture)도 쓴다.

### `Surface`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 표면, 바탕. 콘텐츠를 얹는 배경 판을 뜻한다.
  - 배경·모서리·그림자가 적용된 시트 콘텐츠 판: SheetSurface

### `System`
- 분류: 일반 · 사용 1회 · 패키지: Tuist
- 정의: 체계·시스템. 여기서는 Design과 결합한 DesignSystem(디자인 토큰 모음 target) 명칭의 일부다.
  - DesignSystem target의 글꼴 패밀리 정의 (DesignSystemFontFamily)
- 메모: 표기 흔들림: 같은 DesignSystem이 UI에서는 한 단어(DesignSystem 항목), Tuist에서는 System으로 분리되어 집계되었다.

### `Tab`
- 분류: 플랫폼 · 사용 4회 · 패키지: Feature, UI
- 정의: 탭. 탭 바의 항목.
  - 하단 탭 바의 탭과 탭 항목 (MainShellTab, TabShell, TabShellItem)

### `Tag`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 태그, 꼬리표. 항목을 분류하는 짧은 키워드다.
  - 분류 키워드를 표시하는 배지: TagBadge

### `Target`
- 분류: 일반 · 사용 1회 · 패키지: Feature
- 정의: 대상·목표.
  - 재시도로 다시 실행할 단계 (ShareRegistrationFeature.RetryTarget)
- 메모: Xcode/Tuist 빌드 target과 이름이 겹친다.

### `Text`
- 분류: 플랫폼 · 사용 3회 · 패키지: UI
- 정의: 텍스트·글자. 화면에 표시되는 문자열.
  - SwiftUI Text로 그려지는 스타일 문자열과 텍스트 스타일 토큰 (StyledText, TextStyleToken, TextStyleResolver)

### `TextField`
- 분류: 플랫폼 · 사용 2회 · 패키지: UI
- 정의: SwiftUI TextField 타입 이름(외부 고정 명칭)으로, 문자열을 입력받는 필드다.
  - UI 패키지 고유의 텍스트 입력 컴포넌트: TextField, LabeledTextField
- 메모: UI의 TextField가 SwiftUI TextField와 같은 이름이라 모듈 한정 없이 쓰면 이름이 충돌할 수 있다.

### `Thumbnail`
- 분류: 일반 · 사용 2회 · 패키지: Feature
- 정의: 축소 이미지.
  - 프로젝트 행의 저장소 이미지와 저장소 소유자 아바타 (ProjectListScreen.Thumbnail, RepositoryConfirmationScreen.ThumbnailView)
- 메모: Thumbnail과 ThumbnailView로 View 접미어 사용이 흔들린다.

### `Title`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 제목.
  - 헤더에 표시되는 제목·부제목 텍스트 (ScreenHeaderTitle)

### `Token`
- 분류: 아키텍처·패턴 · 사용 12회 · 패키지: Domain, UI
- 정의: 토큰. 디자인 시스템에서는 이름 붙여 정의한 디자인 값 단위를, 푸시 알림에서는 기기에 발급된 식별 문자열을 뜻한다.
  - 디자인 값을 이름 붙여 정의한 디자인 시스템 단위: ColorToken, LayoutToken, DesignTokenSet
  - APNs가 기기에 발급한 푸시 알림 토큰: DeviceToken
- 메모: 다의어: 디자인 토큰과 기기 푸시 토큰으로 나뉜다. 인증 액세스 토큰(Bearer)과도 구분해야 한다.

### `Transition`
- 분류: 아키텍처·패턴 · 사용 4회 · 패키지: Feature
- 정의: 전환·이행. 한 상태에서 다른 상태로 넘어가는 것으로, 여기서는 라우터의 화면 전환 기록이다.
  - 라우터의 activeScreen이 바뀐 사건 기록 (ProjectDetailRouterFeature.ScreenTransition, QuizRouterFeature.ScreenTransition, OnboardingRouterFeature.ScreenTransitionEvent)
- 메모: 대부분 ScreenTransition이지만 Onboarding만 ScreenTransitionEvent를 써 표기가 흔들린다. SwiftUI transition(애니메이션 전환)과도 이름이 겹친다.

### `Transport`
- 분류: 아키텍처·패턴 · 사용 9회 · 패키지: Data, Infrastructure
- 정의: 전송·운반. 요청을 보내고 응답을 받는 전송 계층.
  - Data의 전송 계층 계약과 요청·응답 모델 (RequestTransport, TransportRequest, TransportResponse)
  - Infrastructure의 저수준 HTTP 전송 계약과 URLSession 구현 (HTTPTransport, URLSessionTransport, HTTPTransportRequest)
  - 두 계층 전송 계약을 잇는 브리지 (RequestTransportBridge)
- 메모: 유의어 중첩: 전송 계약이 Data(RequestTransport)와 Infrastructure(HTTPTransport) 양쪽에 있고 요청·응답 모델도 이중화되어 있다. 어순도 RequestTransport와 TransportRequest처럼 흔들린다.

### `Tutorial`
- 분류: 업무 개념 · 사용 2회 · 패키지: Feature
- 정의: 튜토리얼, 안내 학습. 앱 기능을 소개하는 안내 화면이다.
  - 앱 기능을 소개하는 3페이지 안내 화면: TutorialFeature, TutorialScreen
- 메모: 온보딩 흐름의 첫 단계이며, OnboardingEntryPoint에서는 "가이드"로도 불린다.

### `Unavailable`
- 분류: 일반 · 사용 1회 · 패키지: Data
- 정의: 사용 불가한.
  - 실제 저장소를 만들 수 없을 때 대신하는 무동작 구현 (UnavailableKeyValueStorage)
- 메모: Availability와 어근이 같지만 판정이 아니라 대체 구현을 뜻한다.

### `UnitPoint`
- 분류: 플랫폼 · 사용 1회 · 패키지: UI
- 정의: SwiftUI 타입 이름(외부 고정 명칭). View 내부의 정규화 좌표.
  - 그라데이션 시작·끝 위치를 나타내는 정규화 좌표 비율 (GradientToken.UnitPointRatio)

### `URL`
- 분류: 약어 · 사용 4회 · 패키지: App, Domain, Data, Infrastructure
- 정의: Uniform Resource Locator의 약어로, 자원의 위치를 나타내는 주소 문자열이다.
  - 저장소 링크 주소 문자열과 해석: ExternalRepositoryURL, GitHubRepositoryURLParser, SharedItemURLResolver
  - base·path·query를 합친 최종 요청 주소 조립: RequestURLBuilder
- 메모: 유의어 중첩: 같은 저장소 주소를 Feature에서는 Link(RepositoryLinkInputFeature)로 부른다.

### `URLSession`
- 분류: 플랫폼 · 사용 1회 · 패키지: Infrastructure
- 정의: Foundation의 URLSession 네트워킹 API 외부 고정 명칭이다.
  - URLSession으로 실제 HTTP 요청을 보내는 전송 구현 (URLSessionTransport)

### `UseCase`
- 분류: 아키텍처·패턴 · 사용 8회 · 패키지: Composition, Domain
- 정의: Use + Case, 유스케이스. Feature가 호출하는 Domain 응용 동작 단위의 공개 계약.
  - Feature가 의존하는 Domain 동작 계약 (ProjectUseCase, QuizDetailUseCase, UserInfoUseCase)
  - UseCase 프로토콜 구현체를 조립하는 Composition 어셈블리 (ConcernUseCaseAssembly)
- 메모: 구현체는 UseCase 접미어 없이 관심사 이름(Project, UserInfo, AppSetting)으로 불려 계약과 구현의 이름 규칙이 다르다.

### `User`
- 분류: 업무 개념 · 사용 8회 · 패키지: App, Composition, Domain
- 정의: 사용자. 이 서비스에서는 로그인한 앱 사용자(회원)를 뜻한다.
  - 로그인 사용자 정보 모델·유스케이스·저장소: UserInfo, UserInfoUseCase, UserInfoRepository
  - 사용자 상세·전체 프로필: UserDetail, UserProfile
  - 조립·프리뷰의 사용자 정보 대역·어댑터: UserInfoRepositoryAdapter, AppRootPreviewSupport.NoopUserInfo
- 메모: 유의어 중첩: 같은 대상을 Data에서는 Member(MemberRemote, MemberProfileResponseDTO)로 부른다.

### `UserDefaults`
- 분류: 플랫폼 · 사용 2회 · 패키지: Infrastructure
- 정의: Foundation의 키-값 기본 설정 저장소 외부 고정 명칭이다.
  - UserDefaults를 백엔드로 쓰는 저장 객체와 App Group suite 구성 (UserDefaultsStore, AppGroupUserDefaults)

### `Validation`
- 분류: 일반 · 사용 2회 · 패키지: Feature, UI
- 정의: 검증·유효성 확인.
  - 입력한 링크가 실제 GitHub 저장소인지의 검사 상태 (RepositoryLinkInputFeature.ValidationStatus)
  - 디자인 토큰 집합의 이름 중복·값 범위·참조 무결성 검사 오류 (DesignTokenSet.ValidationError)
- 메모: 유의어 중첩: 로그인 유효성 확인은 Verification(SignInVerification)으로 표현한다.

### `Value`
- 분류: 일반 · 사용 6회 · 패키지: Data
- 정의: 값. 저장소에 키와 대응해 보관되는 데이터를 뜻한다.
  - 키에 대응해 저장되는 Codable 값 저장 계약·구현: KeyValueStorage, LocalKeyValueStorage, UnavailableKeyValueStorage
  - Keychain에 보관되는 Data 값 보안 저장 계약·구현: SecureValueStorage, LocalSecureValueStorage, SecureValueStorageError

### `Variant`
- 분류: 일반 · 사용 1회 · 패키지: UI
- 정의: 변형.
  - 같은 카드 레이아웃의 색상 테마 변형 (HomeProjectCard.Variant)

### `Verification`
- 분류: 일반 · 사용 1회 · 패키지: Domain
- 정의: 검증·확인.
  - 기존 로그인 인증이 여전히 유효한지 확인한 판정 (SignInVerification)
- 메모: 유의어 중첩: 입력·토큰 검사는 Validation으로 표현한다.

### `View`
- 분류: 플랫폼 · 사용 54회 · 패키지: App, Feature, UI
- 정의: 뷰, 화면. SwiftUI에서는 View 프로토콜을 채택한 화면 구성 요소를, TCA에서는 화면에서 올라오는 사용자 입력 액션 그룹(ViewAction)을 뜻한다.
  - SwiftUI View를 채택한 화면·하위 화면 조각: AppRootView, ProfileScreen.StatisticsCardView, RubricView
  - TCA ViewAction 규약의 화면 사용자 입력·생명주기 액션 묶음: AppRootFeature.Action.View, HomeFeature.Action.View, SettingsFeature.Action.View
  - UIKit 화면 컨트롤러: ShareViewController
- 메모: 다의어: SwiftUI View 타입과 TCA Action.View 분류로 나뉜다. 표기 흔들림: 최상위 화면은 …Screen 접미어를 쓰고 하위 조각만 …View를 쓰지만, App의 AppRootView와 UI의 SplashView·RubricView·WebContentView는 최상위에도 View를 쓴다.

### `Wait`
- 분류: 일반 · 사용 1회 · 패키지: Domain
- 정의: 대기.
  - 요청 시각부터 준비 완료로 보기까지 기다리는 시간 규칙 (GenerationWaitPolicy)

### `Web`
- 분류: 일반 · 사용 2회 · 패키지: UI
- 정의: 웹. URL로 불러오는 웹 페이지.
  - URL로 불러오는 웹 페이지 표시 View와 시트 (WebContentView, WebSheet)

### `Weekly`
- 분류: 일반 · 사용 4회 · 패키지: Feature, Domain, Data
- 정의: 주간의, 매주의. 한 주 단위로 묶은 것을 뜻한다.
  - 한 주 단위로 집계한 풀이·학습 기록: WeeklyLearningCount, WeeklyChartItemDTO
  - 월~일 요일 단위 학습 기록 차트: ProfileScreen.WeeklyChartView, ProfileDisplay.WeeklyBar

### `Weight`
- 분류: 플랫폼 · 사용 2회 · 패키지: UI, Tuist
- 정의: 무게·굵기. 타이포그래피에서 글꼴 획 굵기를 뜻한다.
  - 디자인 토큰의 글꼴 굵기 단계와 번들할 글꼴 파일 굵기 (TextStyleToken.Weight, DesignSystemFontFamily.Weight)

### `Withdrawal`
- 분류: 업무 개념 · 사용 2회 · 패키지: Composition, Domain
- 정의: 탈퇴·철회. 이 프로젝트에서는 Git It 회원 탈퇴(계정 삭제)를 뜻한다.
  - 서버 회원 탈퇴 계약과 어댑터 (WithdrawalRepository, WithdrawalRepositoryAdapter)
- 메모: 유의어 중첩: 같은 행위를 설정 화면에서는 계정 삭제(SettingsFeature.AccountAction)로 표현한다.
