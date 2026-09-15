import CompositionAdapter
import DataAuthentication
import DataExternalRepository
import DataMember
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation
import InfrastructureAuthentication
import InfrastructureNetworkClient
import InfrastructurePushMessaging
import InfrastructureStorage
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
        appVersion: String,
        osVersion: String,
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
        let markerCoding = AppGroupUserDefaults.makeShared()
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

        let registerCurrentDeviceUseCase = RegisterCurrentDevice(
            registerMemberDevice: member.registerMemberDevice,
            deviceIdentifierRepository: DeviceIdentifierRepositoryAdapter(keychainStore: keychainStore),
            appVersion: appVersion,
            osVersion: osVersion,
            deviceTokenProvider: {
                guard let pushClient = pushClientBox.client else {
                    throw PushBootstrapError.notBootstrapped
                }
                return try await pushClient.registrationToken()
            },
        )
        registerCurrentDevice = { try await registerCurrentDeviceUseCase() }

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
            appVersion: String,
            osVersion: String,
            policyDocuments: [PolicyDocument] = [],
        ) {
            self.apiBaseURL = apiBaseURL
            self.externalRepositoryBaseURL = externalRepositoryBaseURL
            self.appVersion = appVersion
            self.osVersion = osVersion
            self.policyDocuments = policyDocuments
        }

        // MARK: Public

        public let apiBaseURL: URL
        public let externalRepositoryBaseURL: URL
        public let appVersion: String
        public let osVersion: String
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
        keychainStore: KeychainStore = AppGroupKeychainStore.makeShared(),
        transport: (any HTTPTransport)? = nil,
    ) -> AppComposition {
        SessionKeychainMigration(
            sharedKeychainStore: keychainStore,
            legacyKeychainStore: AppGroupKeychainStore.makeLegacy(),
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
            appVersion: environment.appVersion,
            osVersion: environment.osVersion,
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
                client = PushMessagingClientFactory.make()
            }
        }

        // MARK: Private

        private let storage = Mutex<(any PushMessagingClient)?>(nil)

    }

    private enum PushBootstrapError: Error {
        case notBootstrapped
    }

    private static let memberResponseTimeout = Duration.seconds(10)

}
