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
        generationOutcomeSource: PushQuizGenerationOutcomeSource = PushQuizGenerationOutcomeSource(),
        deliveredRemoteMessageReader: (any DeliveredRemoteMessageReader)? = nil,
        signedOutEvents: @escaping @Sendable () async -> AsyncStream<Void> = { AsyncStream { $0.finish() } },
        transport: (any RequestTransport)? = nil,
        responseTimeout: Duration = RequestClientFactory.defaultResponseTimeout,
        sharedStorage: (any KeyValueStorage)? = nil,
    ) {
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
            outcomes: GenerationOutcomeRepositoryAdapter(
                source: generationOutcomeSource,
                deliveredMessages: deliveredRemoteMessageReader ?? NotificationFactory.deliveredRemoteMessageReader(),
            ),
            signedOutEvents: signedOutEvents,
        )

        ingestGenerationOutcomePayload = { rawPayload in
            await generationOutcomeSource.ingest(
                rawPayload: rawPayload,
                deliveredAt: Date(),
            )
        }
    }

    // MARK: Public

    public let projectGeneration: any ProjectGenerationUseCase
    public let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void

}
