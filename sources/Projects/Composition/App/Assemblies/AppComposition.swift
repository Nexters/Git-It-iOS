import CompositionAdapter
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
        generationReminder: GenerationReminderAssembly,
        keychainStore: KeychainStore,
    ) {
        signIn = authentication.signIn
        signOut = authentication.signOut
        restoreSession = authentication.restoreSession
        verifyAuthorization = authentication.verifyAuthorization
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
        trackGeneration = learningProject.trackGeneration

        fetchMemberProfile = member.fetchMemberProfile
        updateMemberPosition = member.updateMemberPosition
        updateMemberCareerLevel = member.updateMemberCareerLevel
        registerMemberDevice = member.registerMemberDevice
        deleteMemberAccount = member.deleteMemberAccount

        fetchExternalRepository = externalRepository.fetchExternalRepository

        requestGenerationReminder = generationReminder.requestGenerationReminder

        let pushClientBox = PushClientBox()
        let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void = { rawPayload in
            await learningProject.ingestGenerationOutcomePayload(rawPayload)
        }
        self.ingestGenerationOutcomePayload = ingestGenerationOutcomePayload
        let pushNotificationCallbacks = PushNotificationCallbacks(
            forwardAPNsToken: { token in pushClientBox.client?.setAPNsToken(token) },
            ingestGenerationOutcomePayload: ingestGenerationOutcomePayload,
        )

        let trackGeneration = learningProject.trackGeneration
        let startObservingGenerationState = generationReminder.startObservingGenerationState
        let markerCoding = SharedSessionLayout.makeSharedDefaults()
            .map(SharedSessionStateMarkerCoding.init(userDefaults:))
        let hasStoredSession: @Sendable () async -> Bool = {
            await authentication.accessTokenProvider() != nil
        }
        bootstrap = { appDelegate in
            await markerCoding?.save(isSignedIn: hasStoredSession())
            pushClientBox.activate()
            appDelegate.configure(pushNotificationCallbacks)
            await startObservingGenerationState(trackGeneration)
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
            return pushClient.registrationTokenRefreshes()
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
    public let verifyAuthorization: any VerifyAuthorizationUseCase
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

    public let requestGenerationReminder: any RequestGenerationReminderUseCase
    public let trackGeneration: any TrackGenerationUseCase

    public let bootstrap: @MainActor @Sendable (PushNotificationAppDelegate) async -> Void

    public let registerCurrentDevice: @Sendable () async throws -> Void
    public let deviceTokenRefreshes: @Sendable () -> AsyncStream<String>
    public let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void

    public static func live(
        _ environment: Environment,
        keychainStore: KeychainStore = SharedSessionLayout.makeSharedKeychainStore(),
        transport: (any HTTPTransport)? = nil,
    ) -> AppComposition {
        SessionKeychainMigration(
            sharedKeychainStore: keychainStore,
            legacyKeychainStore: SharedSessionLayout.makeLegacyKeychainStore(),
        )()

        let authentication = AuthenticationAssembly(
            baseURL: environment.apiBaseURL,
            policyDocuments: environment.policyDocuments,
            keychainStore: keychainStore,
            transport: transport,
        )
        let accessTokenProvider = authentication.accessTokenProvider
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
                let trackGeneration = learningProject.trackGeneration
                for record in await trackGeneration.current().records {
                    await trackGeneration.end(githubRepoURL: record.githubRepoURL)
                }
            },
            transport: transport,
            responseTimeout: memberResponseTimeout,
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
            generationReminder: GenerationReminderAssembly(),
            keychainStore: keychainStore,
        )
    }

    // MARK: Private

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

    private static let memberResponseTimeout = Duration.seconds(10)
    private static let deviceKeychainNamespace = KeychainNamespace("com.nexters.hytime.gitit.device")
    private static let deviceKeychainKey = "deviceID"
    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "AppComposition")

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
