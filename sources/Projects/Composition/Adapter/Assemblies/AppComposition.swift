import DataExternalRepository
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation
import InfrastructureAuthentication
import InfrastructureNetworkClient
import InfrastructurePushMessaging
import os
import Synchronization

// MARK: - AppComposition

public struct AppComposition: Sendable {

    // MARK: Lifecycle

    private init(
        authentication: AuthenticationAssembly,
        learningProject: LearningProjectAssembly,
        member: MemberAssembly,
        externalRepository: ExternalRepositoryAssembly,
        keychainStore: KeychainStore,
    ) {
        signIn = authentication.signIn
        signOut = authentication.signOut
        restoreSession = authentication.restoreSession
        authenticationOutcomes = authentication.authenticationOutcomes
        refreshSession = authentication.refreshSession
        verifyAccessToken = authentication.verifyAccessToken
        policyConsent = authentication.policyConsent
        completeCuration = member.completeCuration

        fetchLearningProjects = learningProject.fetchLearningProjects
        fetchLearningProjectDetail = learningProject.fetchLearningProjectDetail
        createLearningProject = learningProject.createLearningProject
        deleteLearningProject = learningProject.deleteLearningProject
        fetchLearningSet = learningProject.fetchLearningSet
        submitChoiceAnswer = learningProject.submitChoiceAnswer
        submitEssayAnswer = learningProject.submitEssayAnswer
        setQuestionBookmark = learningProject.setQuestionBookmark
        fetchBookmarkedQuestions = learningProject.fetchBookmarkedQuestions
        observeGenerationOutcomes = learningProject.observeGenerationOutcomes
        trackGenerationProgress = learningProject.trackGenerationProgress

        fetchMemberProfile = member.fetchMemberProfile
        updateMemberPosition = member.updateMemberPosition
        updateMemberCareerLevel = member.updateMemberCareerLevel
        registerMemberDevice = member.registerMemberDevice
        deleteMemberAccount = member.deleteMemberAccount

        fetchExternalRepository = externalRepository.fetchExternalRepository

        let localNotificationClient = UserNotificationCenterLocalClient()
        let reminderCoordinator = GenerationCompletionReminderCoordinator(
            localNotificationClient: localNotificationClient,
            progressRepository: learningProject.generationProgressRepository,
        )
        requestGenerationReminder = RequestGenerationReminder(
            authorizationGateway: NotificationAuthorizationGatewayAdapter(localNotificationClient: localNotificationClient),
            reminderRegistry: GenerationReminderRegistryAdapter(coordinator: reminderCoordinator),
        )

        // 조립 시점에는 외부 푸시 SDK를 만들지 않는다. client 생성은 bootstrap이 소유하고,
        // 콜백은 이 상자를 통해 늦게 바인딩되므로 주입 시점이 client 생성보다 앞서도 안전하다.
        let pushClientBox = PushClientBox()
        let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void = { rawPayload in
            await learningProject.ingestGenerationOutcomePayload(rawPayload)
        }
        self.ingestGenerationOutcomePayload = ingestGenerationOutcomePayload
        let pushNotificationCallbacks = PushNotificationCallbacks(
            forwardAPNsToken: { token in pushClientBox.client?.setAPNsToken(token) },
            ingestGenerationOutcomePayload: ingestGenerationOutcomePayload,
        )

        // App은 Infrastructure에 의존할 수 없으므로 콜백 주입도 이 경계 안에서 수행한다.
        let observeGenerationOutcomes = learningProject.observeGenerationOutcomes
        bootstrap = { appDelegate in
            pushClientBox.activate()
            appDelegate.configure(pushNotificationCallbacks)
            await reminderCoordinator.start(observeGenerationOutcomes: observeGenerationOutcomes)
        }

        let registerMemberDevice = member.registerMemberDevice
        registerCurrentDevice = {
            guard let pushClient = pushClientBox.client else {
                throw PushBootstrapError.notBootstrapped
            }
            let token = try await pushClient.registrationToken()
            let deviceID = AppComposition.loadOrCreateDeviceID(keychainStore: keychainStore)
            try await registerMemberDevice(MemberDeviceInfo(
                deviceID: deviceID,
                deviceType: .ios,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
                osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                deviceToken: token,
            ))
            AppComposition.logger.debug("기기 등록 성공: deviceID=\(deviceID, privacy: .public)")
        }

        deviceTokenRefreshes = {
            guard let pushClient = pushClientBox.client else {
                return AsyncStream { $0.finish() }
            }
            let refreshes = pushClient.registrationTokenRefreshes()
            return AsyncStream { continuation in
                let task = Task {
                    for await _ in refreshes {
                        continuation.yield(())
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }

    // MARK: Public

    public struct Environment: Sendable {

        // MARK: Lifecycle

        public init(
            apiBaseURL: URL,
            externalRepositoryBaseURL: URL,
            policyDocuments: [PolicyDocument] = [],
        ) {
            self.apiBaseURL = apiBaseURL
            self.externalRepositoryBaseURL = externalRepositoryBaseURL
            self.policyDocuments = policyDocuments
        }

        // MARK: Public

        public let apiBaseURL: URL
        public let externalRepositoryBaseURL: URL
        public let policyDocuments: [PolicyDocument]

    }

    public let signIn: any SignInUseCase
    public let signOut: any SignOutUseCase
    public let restoreSession: any RestoreSessionUseCase
    public let authenticationOutcomes: any AuthenticationOutcomesUseCase
    public let refreshSession: any RefreshSessionUseCase
    public let verifyAccessToken: any VerifyAccessTokenUseCase
    public let policyConsent: any PolicyConsentUseCase
    public let completeCuration: any CompleteCurationUseCase

    public let fetchLearningProjects: any FetchLearningProjectsUseCase
    public let fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase
    public let createLearningProject: any CreateLearningProjectUseCase
    public let deleteLearningProject: any DeleteLearningProjectUseCase
    public let fetchLearningSet: any FetchLearningSetUseCase
    public let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    public let submitEssayAnswer: any SubmitEssayAnswerUseCase
    public let setQuestionBookmark: any SetQuestionBookmarkUseCase
    public let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase

    public let fetchMemberProfile: any FetchMemberProfileUseCase
    public let updateMemberPosition: any UpdateMemberPositionUseCase
    public let updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase
    public let registerMemberDevice: any RegisterMemberDeviceUseCase
    public let deleteMemberAccount: any DeleteMemberAccountUseCase

    public let fetchExternalRepository: any FetchExternalRepositoryUseCase

    public let observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase
    public let requestGenerationReminder: any RequestGenerationReminderUseCase
    public let trackGenerationProgress: any TrackGenerationProgressUseCase

    /// 푸시 client 생성과 콜백 주입, 리마인드 구독 확립을 순서대로 수행하는 명시적 시작 단계다.
    /// 반환 시점에는 리마인드 구독이 확립돼 있다.
    public let bootstrap: @MainActor @Sendable (PushNotificationAppDelegate) async -> Void
    /// 호출 시점은 App이 결정한다. 실패는 삼키지 않고 던지며 멱등하지 않다.
    public let registerCurrentDevice: @Sendable () async throws -> Void
    public let deviceTokenRefreshes: @Sendable () -> AsyncStream<Void>
    public let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void

    public static func live(
        _ environment: Environment,
        keychainStore: KeychainStore = KeychainStore(),
        transport: (any HTTPTransport)? = nil,
    ) -> AppComposition {
        let authentication = AuthenticationAssembly(
            baseURL: environment.apiBaseURL,
            policyDocuments: environment.policyDocuments,
            keychainStore: keychainStore,
            transport: transport,
        )
        let sessionCoding = SessionRecordKeychainCoding(keychainStore: keychainStore)
        let accessTokenProvider: @Sendable () async -> String? = {
            (try? sessionCoding.load())?.tokens.accessToken
        }
        let learningProject = LearningProjectAssembly(
            baseURL: environment.apiBaseURL,
            accessTokenProvider: accessTokenProvider,
            transport: transport,
        )
        let member = MemberAssembly(
            baseURL: environment.apiBaseURL,
            loginSessionRepository: authentication.loginSessionRepository,
            accessTokenProvider: accessTokenProvider,
            clearLocalStateAfterAccountDeletion: {
                await learningProject.trackGenerationProgress.end()
            },
            transport: transport,
        )
        let externalRepository = ExternalRepositoryAssembly(
            baseURL: environment.externalRepositoryBaseURL,
            transport: transport,
        )

        return AppComposition(
            authentication: authentication,
            learningProject: learningProject,
            member: member,
            externalRepository: externalRepository,
            keychainStore: keychainStore,
        )
    }

    // MARK: Private

    /// `bootstrap()` 이전에는 비어 있고, 그 이후에만 실제 푸시 client를 소유한다.
    /// 콜백이 client보다 먼저 주입돼도 안전하도록 늦은 바인딩 지점을 제공한다.
    private final class PushClientBox: Sendable {

        // MARK: Internal

        var client: (any PushMessagingClient)? {
            storage.withLock { $0 }
        }

        func activate() {
            storage.withLock { client in
                guard client == nil else { return }
                client = FirebaseMessagingPushClient()
            }
        }

        // MARK: Private

        private let storage = Mutex<(any PushMessagingClient)?>(nil)

    }

    private enum PushBootstrapError: Error {
        case notBootstrapped
    }

    private static let deviceKeychainNamespace = KeychainNamespace("com.nexters.hytime.gitit.device")
    private static let deviceKeychainKey = "deviceID"
    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "AppComposition")

    /// 조회에 실패하면 새 식별자를 만들어 저장한다. 이름이 그 부수효과를 드러낸다.
    private static func loadOrCreateDeviceID(keychainStore: KeychainStore) -> String {
        if
            let data = try? keychainStore.load(for: deviceKeychainKey, in: deviceKeychainNamespace),
            let existing = String(data: data, encoding: .utf8)
        {
            return existing
        }
        let newDeviceID = UUID().uuidString
        if let data = newDeviceID.data(using: .utf8) {
            try? keychainStore.save(data, for: deviceKeychainKey, in: deviceKeychainNamespace)
        }
        return newDeviceID
    }

}
