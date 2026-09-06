import CompositionAdapter
import DomainLearningProject
import Foundation
import InfrastructureAuthentication
import InfrastructureLocalNotification
import InfrastructureNetworkClient

// MARK: - ShareExtensionComposition

public struct ShareExtensionComposition: Sendable {

    // MARK: Lifecycle

    private init(
        externalRepository: ExternalRepositoryAssembly,
        learningProject: LearningProjectAssembly,
        resolveSessionAvailability: @escaping @Sendable () async -> SessionAvailability,
        localNotificationClient: any NotificationAuthorizationClient,
        pendingReminderCoding: PendingGenerationReminderCoding?,
    ) {
        parseRepositoryLink = externalRepository.urlParser
        fetchExternalRepository = externalRepository.fetchExternalRepository
        createLearningProject = learningProject.createLearningProject
        self.resolveSessionAvailability = resolveSessionAvailability
        isNotificationAuthorized = { await localNotificationClient.isAuthorized() }
        enqueueGenerationReminder = { projectID in
            await pendingReminderCoding?.append(projectID: projectID)
        }
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

    public let parseRepositoryLink: any ExternalRepositoryURLParser
    public let fetchExternalRepository: any FetchExternalRepositoryUseCase
    public let createLearningProject: any CreateLearningProjectUseCase
    public let resolveSessionAvailability: @Sendable () async -> SessionAvailability
    public let isNotificationAuthorized: @Sendable () async -> Bool
    public let enqueueGenerationReminder: @Sendable (String) async -> Void

    public static func live(
        _ environment: Environment,
        keychainStore: KeychainStore = SharedSessionLayout.makeSharedKeychainStore(),
        sharedDefaults: UserDefaults? = SharedSessionLayout.makeSharedDefaults(),
        localNotificationClient: any NotificationAuthorizationClient = LocalNotificationAuthorizationClient(),
        transport: (any HTTPTransport)? = nil,
    ) -> ShareExtensionComposition {
        let markerCoding = sharedDefaults.map(SharedSessionStateMarkerCoding.init(userDefaults:))
        let resolveSessionAvailability: @Sendable () async -> SessionAvailability = {
            guard let markerCoding else { return .appLaunchRequired }
            return await SessionAvailabilityResolver(
                markerCoding: markerCoding,
                keychainStore: keychainStore,
            )()
        }
        let accessTokenProvider: @Sendable () async -> String? = {
            guard case .available(let accessToken) = await resolveSessionAvailability() else { return nil }
            return accessToken
        }

        return ShareExtensionComposition(
            externalRepository: ExternalRepositoryAssembly(
                baseURL: environment.externalRepositoryBaseURL,
                transport: transport,
            ),
            learningProject: LearningProjectAssembly(
                baseURL: environment.apiBaseURL,
                accessTokenProvider: accessTokenProvider,
                transport: transport,
            ),
            resolveSessionAvailability: resolveSessionAvailability,
            localNotificationClient: localNotificationClient,
            pendingReminderCoding: sharedDefaults.map(PendingGenerationReminderCoding.init(userDefaults:)),
        )
    }

}
