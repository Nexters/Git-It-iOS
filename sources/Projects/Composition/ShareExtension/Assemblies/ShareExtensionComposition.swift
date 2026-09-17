import CompositionAuthentication
import CompositionLearningProject
import DataAuthentication
import DataNotification
import DataShared
import DataExternalRepository
import DataLearningProject
import DomainAccount
import DomainAuthentication
import DomainExternalRepository
import DomainIdentifier
import DomainLearningProject
import DomainProjectGeneration
import Foundation

// MARK: - ShareExtensionComposition

public struct ShareExtensionComposition: Sendable {

    // MARK: Lifecycle

    private init(
        externalRepositoryAssembly: ExternalRepositoryAssembly,
        learningProject: LearningProjectAssembly,
        resolveSessionAvailability: @escaping @Sendable () async -> SessionAvailability,
        reminderNotifier: any LocalReminderNotifier,
        enqueueGenerationReminder: @escaping @Sendable (String) async -> Void,
        externalRepository: any ExternalRepositoryUseCase,
        projectGeneration: any ProjectGenerationUseCase,
        signInAvailability: @escaping @Sendable () async -> SignInAvailability,
    ) {
        parseRepositoryLink = externalRepositoryAssembly.locator
        fetchExternalRepository = externalRepositoryAssembly.fetchExternalRepository
        createLearningProject = learningProject.createLearningProject
        self.externalRepository = externalRepository
        self.projectGeneration = projectGeneration
        self.signInAvailability = signInAvailability
        self.resolveSessionAvailability = resolveSessionAvailability
        isNotificationAuthorized = { await reminderNotifier.isAuthorized() }
        self.enqueueGenerationReminder = enqueueGenerationReminder
    }

    // MARK: Public

    public struct Environment: Sendable {

        // MARK: Lifecycle

        public init(
            apiBaseURL: URL,
            externalRepositoryBaseURL: URL,
        ) {
            self.apiBaseURL = apiBaseURL
            self.externalRepositoryBaseURL = externalRepositoryBaseURL
        }

        // MARK: Public

        public let apiBaseURL: URL
        public let externalRepositoryBaseURL: URL

    }

    public let parseRepositoryLink: any ExternalRepositoryLocator
    public let fetchExternalRepository: any FetchExternalRepositoryUseCase
    public let createLearningProject: any CreateLearningProjectUseCase
    public let projectGeneration: any ProjectGenerationUseCase
    public let signInAvailability: @Sendable () async -> SignInAvailability
    public let resolveSessionAvailability: @Sendable () async -> SessionAvailability
    public let isNotificationAuthorized: @Sendable () async -> Bool

    public let externalRepository: any ExternalRepositoryUseCase
    public let enqueueGenerationReminder: @Sendable (String) async -> Void

    public static func live(
        _ environment: Environment,
        secureStorage: (any SecureValueStorage)? = nil,
        sharedStorage: (any KeyValueStorage)? = StorageFactory.keyValueStorage(
            namespace: SessionStorageLayout.sharedSessionNamespace,
            location: .appGroup,
        ),
        reminderNotifier: (any LocalReminderNotifier)? = nil,
        transport: (any RequestTransport)? = nil,
    ) -> ShareExtensionComposition {
        let sessionAvailability = SessionAvailabilityAssembly(
            secureStorage: secureStorage,
            sharedStorage: sharedStorage,
        )

        let requestCredentialProvider = sessionAvailability.requestCredentialProvider
        let learningProject = LearningProjectAssembly(
            baseURL: environment.apiBaseURL,
            credential: { await requestCredentialProvider.credential() },
            credentialRejected: { await requestCredentialProvider.credentialRejected() },
            transport: transport,
            sharedStorage: sharedStorage,
        )
        let pendingGenerations = learningProject.pendingGenerations
        let notifier = reminderNotifier ?? NotificationFactory.localReminderNotifier()
        let markerCoding = sharedStorage.map(SharedSessionStateMarkerCoding.init(storage:))
        let credentialProvider = requestCredentialProvider

        return ShareExtensionComposition(
            externalRepositoryAssembly: ExternalRepositoryAssembly(
                baseURL: environment.externalRepositoryBaseURL,
                transport: transport,
            ),
            learningProject: learningProject,
            resolveSessionAvailability: sessionAvailability.resolveSessionAvailability,
            reminderNotifier: reminderNotifier ?? NotificationFactory.localReminderNotifier(),
            enqueueGenerationReminder: { projectID in
                await pendingGenerations.enqueueReminder(projectID: projectID)
            },
            externalRepository: ExternalRepositoryResolver(
                lookup: ResolverExternalRepositoryLookupAdapter(remote: ExternalRepositoryRemote(
                    baseURL: environment.externalRepositoryBaseURL,
                    transport: transport,
                    responseTimeout: RequestClientFactory.defaultResponseTimeout,
                )),
                locator: ResolverExternalRepositoryLocatorAdapter(parser: GitHubRepositoryURLParser()),
            ),
            projectGeneration: ProjectGeneration(
                repository: ProjectGenerationRepositoryAdapter(remote: ProjectRemote(
                    baseURL: environment.apiBaseURL,
                    transport: transport,
                    responseTimeout: RequestClientFactory.defaultResponseTimeout,
                    credential: { await credentialProvider.credential() },
                    credentialRejected: { await credentialProvider.credentialRejected() },
                )),
                pendingGenerations: ProjectGenerationPendingRepositoryAdapter(
                    store: LocalPendingGenerationStore(
                        storage: sharedStorage ?? StorageFactory.keyValueStorage(
                            namespace: LocalPendingGenerationStore.namespace,
                            location: .appGroup,
                        )
                    )
                ),
                outcomes: ProjectGenerationOutcomeRepositoryAdapter(source: PushQuizGenerationOutcomeSource()),
                reminderScheduler: ProjectGenerationReminderSchedulerAdapter(
                    reminderNotifier: notifier,
                    completedTitle: "",
                    completedBody: "",
                    failedTitle: "",
                    failedBody: "",
                ),
                signedOutEvents: { AsyncStream { $0.finish() } },
            ),
            signInAvailability: {
                guard let isSignedIn = await markerCoding?.loadSignedInState() else { return .appLaunchRequired }
                guard isSignedIn, await credentialProvider.credential() != .signedOut else { return .signInRequired }
                return .signedIn
            },
        )
    }


}
