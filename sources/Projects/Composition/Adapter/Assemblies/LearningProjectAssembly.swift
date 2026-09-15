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
        sharedDefaults: UserDefaults? = AppGroupUserDefaults.makeShared(),
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

        let defaults = sharedDefaults ?? .standard
        let generationOutcomeSource = PushQuizGenerationOutcomeSource()
        let trackGeneration = TrackGeneration(
            stateRepository: GenerationStateRepositoryAdapter(
                store: LocalGenerationStateStore(
                    store: UserDefaultsStore(namespace: AppGroupUserDefaults.sharedSessionNamespace, userDefaults: defaults),
                    migration: GenerationStateMigration(
                        legacyProgressStore: UserDefaultsStore(namespace: GenerationStateMigration.legacyProgressNamespace),
                        legacyCreationStateStore: UserDefaultsStore(
                            namespace: AppGroupUserDefaults.sharedSessionNamespace,
                            userDefaults: defaults,
                        ),
                    ),
                )
            ),
            outcomeRepository: GenerationOutcomeRepositoryAdapter(source: generationOutcomeSource),
        )
        self.trackGeneration = trackGeneration

        fetchLearningProjects = FetchLearningProjects(
            repository: projectRepository,
            trackGeneration: trackGeneration,
        )
        fetchLearningProjectDetail = FetchLearningProjectDetail(repository: projectRepository)
        createLearningProject = CreateLearningProject(
            repository: projectRepository,
            trackGeneration: trackGeneration,
        )
        deleteLearningProject = DeleteLearningProject(repository: projectRepository)
        fetchLearningSet = FetchLearningSet(repository: learningSetRepository)
        submitChoiceAnswer = SubmitChoiceAnswer(repository: answerRepository)
        submitEssayAnswer = SubmitEssayAnswer(repository: answerRepository)
        setQuestionBookmark = SetQuestionBookmark(repository: bookmarkRepository)
        fetchBookmarkedQuestions = FetchBookmarkedQuestions(repository: bookmarkRepository)

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
    public let trackGeneration: any TrackGenerationUseCase
    public let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void

}
