import CompositionShared
import DataLearningProject
import DataShared
import DomainLearningProject
import Foundation
import InfrastructureNetworkClient

// MARK: - LearningProjectAssembly

public struct LearningProjectAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        accessTokenProvider: @escaping @Sendable () async -> String?,
        transport: (any HTTPTransport)? = nil,
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
        sharedStorage: (any KeyValueStorage)? = nil,
    ) {
        let client = makeHTTPClient(baseURL: baseURL, responseTimeout: responseTimeout, transport: transport)
        let projectRepository = LearningProjectRepositoryAdapter(
            remote: ProjectRemote(client: client, accessTokenProvider: accessTokenProvider)
        )
        let learningSetRepository = LearningSetRepositoryAdapter(
            remote: LearningSetRemote(client: client, accessTokenProvider: accessTokenProvider)
        )
        let answerRepository = AnswerRepositoryAdapter(
            remote: AnswerRemote(client: client, accessTokenProvider: accessTokenProvider)
        )
        let bookmarkRepository = BookmarkRepositoryAdapter(
            remote: BookmarkRemote(client: client, accessTokenProvider: accessTokenProvider)
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
