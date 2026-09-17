import CompositionAuthentication
import CompositionLearningProject
import CompositionMember
import DataAuthentication
import DataNotification
import DataShared
import DomainAccount
import DomainAppSetting
import DomainAuthentication
import DomainExternalRepository
import DomainIdentifier
import DomainLearningProject
import DomainMember
import DomainProject
import DomainProjectGeneration
import DomainQuizDetail
import DomainUserInfo
import Foundation
import Synchronization

// MARK: - AppComposition

public struct AppComposition: Sendable {

    // MARK: Lifecycle

    private init(
        authentication: AuthenticationAssembly,
        learningProject: LearningProjectAssembly,
        member: MemberAssembly,
        externalRepositoryAssembly: ExternalRepositoryAssembly,
        generationReminder: GenerationReminderAssembly,
        secureStorage: (any SecureValueStorage)?,
        appVersion: String,
        osVersion: String,
        makeConcerns: (PushQuizGenerationOutcomeSource, @escaping @Sendable () async throws -> DeviceToken)
            -> ConcernUseCaseAssembly,
    ) {
        signIn = authentication.signIn
        signOut = authentication.signOut
        restoreSession = authentication.restoreSession
        verifyAuthorization = authentication.verifyAuthorization
        refreshSession = authentication.refreshSession
        policyConsent = authentication.policyConsent
        memberAccount = member.memberAccount

        fetchLearningProjects = learningProject.fetchLearningProjects
        learningLibrary = learningProject.learningLibrary
        createLearningProject = learningProject.createLearningProject
        submitChoiceAnswer = learningProject.submitChoiceAnswer
        submitEssayAnswer = learningProject.submitEssayAnswer
        setQuestionBookmark = learningProject.setQuestionBookmark
        trackGeneration = learningProject.trackGeneration

        deleteMemberAccount = member.deleteMemberAccount

        fetchExternalRepository = externalRepositoryAssembly.fetchExternalRepository

        requestGenerationReminder = generationReminder.requestGenerationReminder

        let pushClientBox = PushClientBox()
        let deviceToken: @Sendable () async throws -> DeviceToken = {
            guard let pushClient = pushClientBox.client else {
                throw PushBootstrapError.notBootstrapped
            }
            return try await pushClient.registrationToken()
        }
        let concernOutcomeSource = PushQuizGenerationOutcomeSource()
        let concerns = makeConcerns(concernOutcomeSource, deviceToken)
        account = concerns.account
        userInfo = concerns.userInfo
        appSetting = concerns.appSetting
        externalRepository = concerns.externalRepository
        quizDetail = concerns.quizDetail
        project = concerns.project
        projectGeneration = concerns.projectGeneration
        let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void = { rawPayload in
            await learningProject.ingestGenerationOutcomePayload(rawPayload)
            await concernOutcomeSource.ingest(rawPayload: rawPayload)
        }
        self.ingestGenerationOutcomePayload = ingestGenerationOutcomePayload
        let notificationAppCallbacks = NotificationAppCallbacks(
            forwardDeviceToken: { token in pushClientBox.client?.setDeviceToken(token) },
            ingestRemoteMessagePayload: ingestGenerationOutcomePayload,
        )

        let trackGeneration = learningProject.trackGeneration
        let startObservingGenerationState = generationReminder.startObservingGenerationState
        recordSharedSessionState = authentication.recordSharedSessionState
        activatePushClient = { pushClientBox.activate() }
        configureAppDelegate = { appDelegate in appDelegate.configure(notificationAppCallbacks) }
        self.startObservingGenerationState = {
            await startObservingGenerationState(trackGeneration)
        }

        registerCurrentDevice = member.makeRegisterCurrentDevice(
            secureStorage: secureStorage,
            appVersion: appVersion,
            osVersion: osVersion,
            deviceTokenProvider: deviceToken,
        )

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
            generationReminderTitle: String,
            generationReminderBody: String,
            generationFailureReminderTitle: String,
            generationFailureReminderBody: String,
            policyDocuments: [DomainAuthentication.PolicyDocument] = [],
        ) {
            self.apiBaseURL = apiBaseURL
            self.externalRepositoryBaseURL = externalRepositoryBaseURL
            self.appVersion = appVersion
            self.osVersion = osVersion
            self.generationReminderTitle = generationReminderTitle
            self.generationReminderBody = generationReminderBody
            self.generationFailureReminderTitle = generationFailureReminderTitle
            self.generationFailureReminderBody = generationFailureReminderBody
            self.policyDocuments = policyDocuments
        }

        // MARK: Public

        public let apiBaseURL: URL
        public let externalRepositoryBaseURL: URL
        public let appVersion: String
        public let osVersion: String
        public let generationReminderTitle: String
        public let generationReminderBody: String
        public let generationFailureReminderTitle: String
        public let generationFailureReminderBody: String
        public let policyDocuments: [DomainAuthentication.PolicyDocument]

    }

    public let signIn: any SignInUseCase
    public let signOut: any SignOutUseCase
    public let restoreSession: any RestoreSessionUseCase
    public let verifyAuthorization: any VerifyAuthorizationUseCase
    public let refreshSession: any RefreshSessionUseCase
    public let policyConsent: any PolicyConsentUseCase
    public let memberAccount: any MemberAccountUseCase

    public let fetchLearningProjects: any FetchLearningProjectsUseCase
    public let learningLibrary: any LearningLibraryUseCase
    public let createLearningProject: any CreateLearningProjectUseCase
    public let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    public let submitEssayAnswer: any SubmitEssayAnswerUseCase
    public let setQuestionBookmark: any SetQuestionBookmarkUseCase

    public let deleteMemberAccount: any DeleteMemberAccountUseCase

    public let fetchExternalRepository: any FetchExternalRepositoryUseCase

    public let requestGenerationReminder: any RequestGenerationReminderUseCase
    public let trackGeneration: any TrackGenerationUseCase

    public let account: any AccountUseCase
    public let userInfo: any UserInfoUseCase
    public let appSetting: any AppSettingUseCase
    public let quizDetail: any QuizDetailUseCase
    public let project: any ProjectUseCase
    public let projectGeneration: any ProjectGenerationUseCase
    public let externalRepository: any ExternalRepositoryUseCase

    public let recordSharedSessionState: @Sendable () async -> Void
    public let activatePushClient: @Sendable () -> Void
    public let configureAppDelegate: @MainActor @Sendable (PushNotificationAppDelegate) -> Void
    public let startObservingGenerationState: @Sendable () async -> Void

    public let registerCurrentDevice: @Sendable () async throws -> Void
    public let deviceTokenRefreshes: @Sendable () -> AsyncStream<String>
    public let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void

    public static func live(
        _ environment: Environment,
        secureStorage: (any SecureValueStorage)? = nil,
        transport: (any RequestTransport)? = nil,
    ) -> AppComposition {
        let authentication = AuthenticationAssembly(
            baseURL: environment.apiBaseURL,
            policyDocuments: environment.policyDocuments,
            secureStorage: secureStorage,
            transport: transport,
        )
        let requestCredentialProvider = authentication.requestCredentialProvider
        let credential: @Sendable () async -> RequestCredential = {
            await requestCredentialProvider.credential()
        }
        let credentialRejected: @Sendable () async -> Void = {
            await requestCredentialProvider.credentialRejected()
        }
        let learningProject = LearningProjectAssembly(
            baseURL: environment.apiBaseURL,
            credential: credential,
            credentialRejected: credentialRejected,
            transport: transport,
        )
        let member = MemberAssembly(
            baseURL: environment.apiBaseURL,
            loginSessionRepository: authentication.loginSessionRepository,
            credential: credential,
            credentialRejected: credentialRejected,
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

        let requestCredentialProvider = authentication.requestCredentialProvider
        return AppComposition(
            authentication: authentication,
            learningProject: learningProject,
            member: member,
            externalRepositoryAssembly: externalRepository,
            generationReminder: GenerationReminderAssembly(
                reminderTitle: environment.generationReminderTitle,
                reminderBody: environment.generationReminderBody,
                pendingGenerations: learningProject.pendingGenerations,
            ),
            secureStorage: secureStorage,
            appVersion: environment.appVersion,
            osVersion: environment.osVersion,
            makeConcerns: { generationOutcomeSource, deviceToken in
                ConcernUseCaseAssembly(
                    apiBaseURL: environment.apiBaseURL,
                    externalRepositoryBaseURL: environment.externalRepositoryBaseURL,
                    policyDocuments: environment.policyDocuments.map(Self.policyDocument(from:)),
                    appVersion: environment.appVersion,
                    osVersion: environment.osVersion,
                    generationReminder: ConcernUseCaseAssembly.GenerationReminderContent(
                        completedTitle: environment.generationReminderTitle,
                        completedBody: environment.generationReminderBody,
                        failedTitle: environment.generationFailureReminderTitle,
                        failedBody: environment.generationFailureReminderBody,
                    ),
                    requestCredentialProvider: requestCredentialProvider,
                    secureStorage: secureStorage,
                    sharedStorage: StorageFactory.keyValueStorage(
                        namespace: SessionStorageLayout.sharedSessionNamespace,
                        location: .appGroup,
                    ),
                    generationOutcomeSource: generationOutcomeSource,
                    transport: transport,
                    memberResponseTimeout: memberResponseTimeout,
                    deviceToken: deviceToken,
                )
            },
        )
    }

    // MARK: Private

    private final class PushClientBox: Sendable {

        // MARK: Internal

        var client: (any RemoteMessageReceiver)? {
            storage.withLock { $0 }
        }

        func activate() {
            storage.withLock { client in
                guard client == nil else { return }
                client = NotificationFactory.remoteMessageReceiver()
            }
        }

        // MARK: Private

        private let storage = Mutex<(any RemoteMessageReceiver)?>(nil)

    }

    private enum PushBootstrapError: Error {
        case notBootstrapped
    }

    private static let memberResponseTimeout = Duration.seconds(10)

    private static func policyDocument(
        from document: DomainAuthentication.PolicyDocument
    ) -> DomainAccount.PolicyDocument {
        DomainAccount.PolicyDocument(
            id: document.identifier,
            displayName: document.displayName,
            version: document.version,
            approvedURL: document.approvedURL,
            isRequired: document.isRequired,
        )
    }

}
