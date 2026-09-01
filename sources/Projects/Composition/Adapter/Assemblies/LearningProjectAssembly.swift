import DataLearningProject
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

        fetchLearningProjects = FetchLearningProjects(repository: projectRepository)
        fetchLearningProjectDetail = FetchLearningProjectDetail(repository: projectRepository)
        createLearningProject = CreateLearningProject(repository: projectRepository)
        deleteLearningProject = DeleteLearningProject(repository: projectRepository)
        fetchLearningSet = FetchLearningSet(repository: learningSetRepository)
        submitChoiceAnswer = SubmitChoiceAnswer(repository: answerRepository)
        submitEssayAnswer = SubmitEssayAnswer(repository: answerRepository)
        setQuestionBookmark = SetQuestionBookmark(repository: bookmarkRepository)
        fetchBookmarkedQuestions = FetchBookmarkedQuestions(repository: bookmarkRepository)

        let generationOutcomeRemote = PushGenerationOutcomeStream()
        learningProjectOutcomes = LearningProjectOutcomes(
            repository: GenerationOutcomeRepositoryAdapter(remote: generationOutcomeRemote)
        )
        ingestGenerationOutcomePayload = { rawPayload in
            await generationOutcomeRemote.ingest(rawPayload: rawPayload)
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
    public let learningProjectOutcomes: any LearningProjectOutcomesUseCase
    public let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void

}
