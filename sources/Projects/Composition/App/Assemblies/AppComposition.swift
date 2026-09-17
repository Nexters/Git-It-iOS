import CompositionAuthentication
import CompositionLearningProject
import CompositionMember
import DataShared
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation
import InfrastructureAuthentication
import InfrastructureNetworkClient
import InfrastructurePushMessaging
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
        secureStorage: (any SecureValueStorage)?,
        appVersion: String,
        osVersion: String,
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
        recordSharedSessionState = authentication.recordSharedSessionState
        activatePushClient = { pushClientBox.activate() }
        configureAppDelegate = { appDelegate in appDelegate.configure(pushNotificationCallbacks) }
        self.startObservingGenerationState = {
            await startObservingGenerationState(trackGeneration)
        }

        registerCurrentDevice = member.makeRegisterCurrentDevice(
            secureStorage: secureStorage,
            appVersion: appVersion,
            osVersion: osVersion,
            deviceTokenProvider: {
                guard let pushClient = pushClientBox.client else {
                    throw PushBootstrapError.notBootstrapped
                }
                return try await pushClient.registrationToken()
            },
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
            policyDocuments: [PolicyDocument] = [],
        ) {
            self.apiBaseURL = apiBaseURL
            self.externalRepositoryBaseURL = externalRepositoryBaseURL
            self.appVersion = appVersion
            self.osVersion = osVersion
            self.generationReminderTitle = generationReminderTitle
            self.generationReminderBody = generationReminderBody
            self.policyDocuments = policyDocuments
        }

        // MARK: Public

        public let apiBaseURL: URL
        public let externalRepositoryBaseURL: URL
        public let appVersion: String
        public let osVersion: String
        public let generationReminderTitle: String
        public let generationReminderBody: String
        public let policyDocuments: [PolicyDocument]

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
        transport: (any HTTPTransport)? = nil,
    ) -> AppComposition {
        let authentication = AuthenticationAssembly(
            baseURL: environment.apiBaseURL,
            policyDocuments: environment.policyDocuments,
            secureStorage: secureStorage,
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
            generationReminder: GenerationReminderAssembly(
                reminderTitle: environment.generationReminderTitle,
                reminderBody: environment.generationReminderBody,
                pendingGenerations: learningProject.pendingGenerations,
            ),
            secureStorage: secureStorage,
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
