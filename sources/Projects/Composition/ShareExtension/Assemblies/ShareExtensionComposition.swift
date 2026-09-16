import CompositionAuthentication
import CompositionLearningProject
import DomainAuthentication
import DomainLearningProject
import Foundation
import InfrastructureAuthentication
import InfrastructureLocalNotification
import InfrastructureNetworkClient
import InfrastructureStorage

// MARK: - ShareExtensionComposition

public struct ShareExtensionComposition: Sendable {

    // MARK: Lifecycle

    private init(
        externalRepository: ExternalRepositoryAssembly,
        learningProject: LearningProjectAssembly,
        resolveSessionAvailability: @escaping @Sendable () async -> SessionAvailability,
        localNotificationClient: any NotificationAuthorizationClient,
        enqueueGenerationReminder: @escaping @Sendable (String) async -> Void,
    ) {
        parseRepositoryLink = externalRepository.locator
        fetchExternalRepository = externalRepository.fetchExternalRepository
        createLearningProject = learningProject.createLearningProject
        self.resolveSessionAvailability = resolveSessionAvailability
        isNotificationAuthorized = { await localNotificationClient.isAuthorized() }
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
        keychainStore: KeychainStore = AppGroupKeychainStore.makeShared(),
        sharedDefaults: UserDefaults? = AppGroupUserDefaults.makeShared(),
        localNotificationClient: any NotificationAuthorizationClient = LocalNotificationAuthorizationClient(),
        transport: (any HTTPTransport)? = nil,
    ) -> ShareExtensionComposition {
        let sessionAvailability = SessionAvailabilityAssembly(
            keychainStore: keychainStore,
            sharedDefaults: sharedDefaults,
        )

        return ShareExtensionComposition(
            externalRepository: ExternalRepositoryAssembly(
                baseURL: environment.externalRepositoryBaseURL,
                transport: transport,
            ),
            learningProject: LearningProjectAssembly(
                baseURL: environment.apiBaseURL,
                accessTokenProvider: sessionAvailability.accessTokenProvider,
                transport: transport,
            ),
            resolveSessionAvailability: sessionAvailability.resolveSessionAvailability,
            localNotificationClient: localNotificationClient,
            enqueueGenerationReminder: GenerationReminderAssembly.makePendingReminderEnqueue(sharedDefaults: sharedDefaults),
        )
    }

}
