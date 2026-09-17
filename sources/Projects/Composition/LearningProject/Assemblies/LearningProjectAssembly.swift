import DataLearningProject
import DataShared
import DomainLearningProject
import Foundation

// MARK: - LearningProjectAssembly

public struct LearningProjectAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        credential: @escaping @Sendable () async -> RequestCredential,
        credentialRejected: @escaping @Sendable () async -> Void,
        transport: (any RequestTransport)? = nil,
        responseTimeout: Duration = RequestClientFactory.defaultResponseTimeout,
        sharedStorage: (any KeyValueStorage)? = nil,
    ) {
        let projectRepository = LearningProjectRepositoryAdapter(
            remote: ProjectRemote(
                baseURL: baseURL,
                transport: transport,
                responseTimeout: responseTimeout,
                credential: credential,
                credentialRejected: credentialRejected,
            )
        )
        let learningSetRepository = LearningSetRepositoryAdapter(
            remote: LearningSetRemote(
                baseURL: baseURL,
                transport: transport,
                responseTimeout: responseTimeout,
                credential: credential,
                credentialRejected: credentialRejected,
            )
        )
        let answerRepository = AnswerRepositoryAdapter(
            remote: AnswerRemote(
                baseURL: baseURL,
                transport: transport,
                responseTimeout: responseTimeout,
                credential: credential,
                credentialRejected: credentialRejected,
            )
        )
        let bookmarkRepository = BookmarkRepositoryAdapter(
            remote: BookmarkRemote(
                baseURL: baseURL,
                transport: transport,
                responseTimeout: responseTimeout,
                credential: credential,
                credentialRejected: credentialRejected,
            )
        )

        let pendingGenerations = PendingGenerationRepositoryAdapter(
            store: LocalPendingGenerationStore(
                storage: sharedStorage ?? StorageFactory.keyValueStorage(
                    namespace: LocalPendingGenerationStore.namespace,
                    location: .appGroup,
                )
            )
        )
        self.pendingGenerations = pendingGenerations
        let generationOutcomeSource = PushQuizGenerationOutcomeSource()
        trackGeneration = TrackGeneration(
            pendingGenerations: pendingGenerations,
            outcomeRepository: GenerationOutcomeRepositoryAdapter(source: generationOutcomeSource),
        )

        fetchLearningProjects = FetchLearningProjects(
            repository: projectRepository,
            pendingGenerations: pendingGenerations,
        )
        createLearningProject = CreateLearningProject(
            repository: projectRepository,
            pendingGenerations: pendingGenerations,
        )
        learningLibrary = LearningLibrary(
            projectRepository: projectRepository,
            learningSetRepository: learningSetRepository,
            bookmarkRepository: bookmarkRepository,
        )
        submitChoiceAnswer = SubmitChoiceAnswer(repository: answerRepository)
        submitEssayAnswer = SubmitEssayAnswer(repository: answerRepository)
        setQuestionBookmark = SetQuestionBookmark(repository: bookmarkRepository)

        ingestGenerationOutcomePayload = { rawPayload in
            await generationOutcomeSource.ingest(rawPayload: rawPayload)
        }
    }

    // MARK: Public

    public let fetchLearningProjects: any FetchLearningProjectsUseCase
    public let createLearningProject: any CreateLearningProjectUseCase
    public let learningLibrary: any LearningLibraryUseCase
    public let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    public let submitEssayAnswer: any SubmitEssayAnswerUseCase
    public let setQuestionBookmark: any SetQuestionBookmarkUseCase
    public let trackGeneration: any TrackGenerationUseCase
    public let pendingGenerations: any PendingGenerationRepository
    public let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void

}
