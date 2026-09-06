import DataLearningProject
import DomainLearningProject
import Foundation
import InfrastructureNetworkClient
import InfrastructureStorage

// MARK: - LearningProjectAssembly

public struct LearningProjectAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        accessTokenProvider: @escaping @Sendable () async -> String?,
        transport: (any HTTPTransport)? = nil,
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
        sharedDefaults: UserDefaults? = SharedSessionLayout.makeSharedDefaults(),
    ) {
        let client = makeHTTPClient(baseURL: baseURL, responseTimeout: responseTimeout, transport: transport)
        let projectRepository = LearningProjectRepositoryAdapter(
            remote: HTTPProjectRemote(client: client, accessTokenProvider: accessTokenProvider)
        )
        let learningSetRepository = LearningSetRepositoryAdapter(
            remote: HTTPLearningSetRemote(client: client, accessTokenProvider: accessTokenProvider)
        )
        let answerRepository = AnswerRepositoryAdapter(
            remote: HTTPAnswerRemote(client: client, accessTokenProvider: accessTokenProvider)
        )
        let bookmarkRepository = BookmarkRepositoryAdapter(
            remote: HTTPBookmarkRemote(client: client, accessTokenProvider: accessTokenProvider)
        )

        let creationStateRepositoryAdapter = RepositoryCreationStateRepositoryAdapter(
            userDefaults: sharedDefaults ?? .standard
        )
        self.creationStateRepositoryAdapter = creationStateRepositoryAdapter
        startObservingRepositoryCreationState = { observeGenerationOutcomes in
            await creationStateRepositoryAdapter.start(observeGenerationOutcomes: observeGenerationOutcomes)
        }

        fetchLearningProjects = FetchLearningProjects(
            repository: projectRepository,
            creationStateRepository: creationStateRepositoryAdapter,
        )
        fetchLearningProjectDetail = FetchLearningProjectDetail(repository: projectRepository)
        createLearningProject = CreateLearningProject(
            repository: projectRepository,
            creationStateRepository: creationStateRepositoryAdapter,
        )
        deleteLearningProject = DeleteLearningProject(repository: projectRepository)
        fetchLearningSet = FetchLearningSet(repository: learningSetRepository)
        submitChoiceAnswer = SubmitChoiceAnswer(repository: answerRepository)
        submitEssayAnswer = SubmitEssayAnswer(repository: answerRepository)
        setQuestionBookmark = SetQuestionBookmark(repository: bookmarkRepository)
        fetchBookmarkedQuestions = FetchBookmarkedQuestions(repository: bookmarkRepository)

        let progressRepository = GenerationProgressRepositoryAdapter(
            store: LocalGenerationProgressStore(store: UserDefaultsStore(namespace: Self.progressNamespace))
        )
        generationProgressRepository = progressRepository
        trackGenerationProgress = TrackGenerationProgress(progressRepository: progressRepository)

        let generationOutcomeSource = PushQuizGenerationOutcomeSource()
        observeGenerationOutcomes = ObserveGenerationOutcomes(
            repository: GenerationOutcomeRepositoryAdapter(source: generationOutcomeSource)
        )
        ingestGenerationOutcomePayload = { rawPayload in
            await generationOutcomeSource.ingest(rawPayload: rawPayload)
        }
    }

    // MARK: Public

    public let fetchLearningProjects: any FetchLearningProjectsUseCase
    public let fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase
    public let createLearningProject: any CreateLearningProjectUseCase
    public let deleteLearningProject: any DeleteLearningProjectUseCase
    public let fetchLearningSet: any FetchLearningSetUseCase
    public let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    public let submitEssayAnswer: any SubmitEssayAnswerUseCase
    public let setQuestionBookmark: any SetQuestionBookmarkUseCase
    public let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase
    public let observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase
    public let trackGenerationProgress: any TrackGenerationProgressUseCase
    public let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void
    public let startObservingRepositoryCreationState: @Sendable (any ObserveGenerationOutcomesUseCase) async -> Void

    // MARK: Internal

    let generationProgressRepository: any GenerationProgressRepository
    let creationStateRepositoryAdapter: RepositoryCreationStateRepositoryAdapter

    // MARK: Private

    private static let progressNamespace = "com.nexters.hytime.gitit.generationProgress"

}
