import CompositionAuthentication
import CompositionLearningProject
import DataAuthentication
import DataNotification
import DataShared
import DomainAccount
import DomainExternalRepository
import DomainProjectGeneration
import Foundation

// MARK: - ShareExtensionComposition

public struct ShareExtensionComposition: Sendable {

    // MARK: Lifecycle

    private init(
        externalRepositoryAssembly: ExternalRepositoryAssembly,
        learningProject: LearningProjectAssembly,
        signInAvailability: @escaping @Sendable () async -> SignInAvailability,
    ) {
        parseRepositoryLink = externalRepositoryAssembly.locator
        externalRepository = externalRepositoryAssembly.externalRepository
        projectGeneration = learningProject.projectGeneration
        self.signInAvailability = signInAvailability
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
    public let externalRepository: any ExternalRepositoryUseCase
    public let projectGeneration: any ProjectGenerationUseCase
    public let signInAvailability: @Sendable () async -> SignInAvailability

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

        return ShareExtensionComposition(
            externalRepositoryAssembly: ExternalRepositoryAssembly(
                baseURL: environment.externalRepositoryBaseURL,
                transport: transport,
            ),
            learningProject: LearningProjectAssembly(
                baseURL: environment.apiBaseURL,
                credential: { await requestCredentialProvider.credential() },
                credentialRejected: { await requestCredentialProvider.credentialRejected() },
                reminderNotifier: reminderNotifier,
                transport: transport,
                sharedStorage: sharedStorage,
            ),
            signInAvailability: sessionAvailability.signInAvailability,
        )
    }

}
