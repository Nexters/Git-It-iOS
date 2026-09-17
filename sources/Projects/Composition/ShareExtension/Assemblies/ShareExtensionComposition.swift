import CompositionAuthentication
import CompositionLearningProject
import DataAuthentication
import DataNotification
import DataShared
import DomainAuthentication
import DomainLearningProject
import Foundation

// MARK: - ShareExtensionComposition

public struct ShareExtensionComposition: Sendable {

    // MARK: Lifecycle

    private init(
        externalRepository: ExternalRepositoryAssembly,
        learningProject: LearningProjectAssembly,
        resolveSessionAvailability: @escaping @Sendable () async -> SessionAvailability,
        reminderNotifier: any LocalReminderNotifier,
        enqueueGenerationReminder: @escaping @Sendable (String) async -> Void,
    ) {
        parseRepositoryLink = externalRepository.locator
        fetchExternalRepository = externalRepository.fetchExternalRepository
        createLearningProject = learningProject.createLearningProject
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
    public let resolveSessionAvailability: @Sendable () async -> SessionAvailability
    public let isNotificationAuthorized: @Sendable () async -> Bool
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

        return ShareExtensionComposition(
            externalRepository: ExternalRepositoryAssembly(
                baseURL: environment.externalRepositoryBaseURL,
                transport: transport,
            ),
            learningProject: learningProject,
            resolveSessionAvailability: sessionAvailability.resolveSessionAvailability,
            reminderNotifier: reminderNotifier ?? NotificationFactory.localReminderNotifier(),
            enqueueGenerationReminder: { projectID in
                await pendingGenerations.enqueueReminder(projectID: projectID)
            },
        )
    }

}
