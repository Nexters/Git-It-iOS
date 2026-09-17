import DataLearningProject
import DataNotification
import DataShared
import DomainProjectGeneration
import Foundation

// MARK: - LearningProjectAssembly

public struct LearningProjectAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        credential: @escaping @Sendable () async -> RequestCredential,
        credentialRejected: @escaping @Sendable () async -> Void,
        reminderContent: GenerationReminderContent = GenerationReminderContent(),
        reminderNotifier: (any LocalReminderNotifier)? = nil,
        generationOutcomeSource: PushQuizGenerationOutcomeSource = PushQuizGenerationOutcomeSource(),
        signedOutEvents: @escaping @Sendable () async -> AsyncStream<Void> = { AsyncStream { $0.finish() } },
        transport: (any RequestTransport)? = nil,
        responseTimeout: Duration = RequestClientFactory.defaultResponseTimeout,
        sharedStorage: (any KeyValueStorage)? = nil,
    ) {
        let notifier = reminderNotifier ?? NotificationFactory.localReminderNotifier()
        projectGeneration = ProjectGeneration(
            repository: ProjectGenerationRepositoryAdapter(remote: ProjectRemote(
                baseURL: baseURL,
                transport: transport,
                responseTimeout: responseTimeout,
                credential: credential,
                credentialRejected: credentialRejected,
            )),
            pendingGenerations: PendingGenerationRepositoryAdapter(
                store: LocalPendingGenerationStore(
                    storage: sharedStorage ?? StorageFactory.keyValueStorage(
                        namespace: LocalPendingGenerationStore.namespace,
                        location: .appGroup,
                    )
                )
            ),
            outcomes: GenerationOutcomeRepositoryAdapter(source: generationOutcomeSource),
            reminderScheduler: GenerationReminderSchedulerAdapter(
                reminderNotifier: notifier,
                completedTitle: reminderContent.completedTitle,
                completedBody: reminderContent.completedBody,
                failedTitle: reminderContent.failedTitle,
                failedBody: reminderContent.failedBody,
            ),
            signedOutEvents: signedOutEvents,
        )

        ingestGenerationOutcomePayload = { rawPayload in
            await generationOutcomeSource.ingest(rawPayload: rawPayload)
        }
    }

    // MARK: Public

    public struct GenerationReminderContent: Sendable {

        // MARK: Lifecycle

        public init(
            completedTitle: String = "",
            completedBody: String = "",
            failedTitle: String = "",
            failedBody: String = "",
        ) {
            self.completedTitle = completedTitle
            self.completedBody = completedBody
            self.failedTitle = failedTitle
            self.failedBody = failedBody
        }

        // MARK: Public

        public let completedTitle: String
        public let completedBody: String
        public let failedTitle: String
        public let failedBody: String

    }

    public let projectGeneration: any ProjectGenerationUseCase
    public let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void

}
