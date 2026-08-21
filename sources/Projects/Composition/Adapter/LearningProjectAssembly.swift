import DataLearningProject
import DomainLearningProject
import Foundation
import InfrastructureNetworkClient

// MARK: - LearningProjectAssembly

public struct LearningProjectAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
    ) {
        let client = HTTPClient(
            baseURL: baseURL,
            bodyCoding: StandardJSONBodyCoding(),
            responseTimeout: responseTimeout,
        )
        let repository = LearningProjectRepositoryAdapter(remote: HTTPProjectRemote(client: client))

        fetchLearningProjects = FetchLearningProjects(repository: repository)
        fetchLearningProjectDetail = FetchLearningProjectDetail(repository: repository)
        createLearningProject = CreateLearningProject(repository: repository)
        deleteLearningProject = DeleteLearningProject(repository: repository)
    }

    // MARK: Public

    public let fetchLearningProjects: any FetchLearningProjectsUseCase
    public let fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase
    public let createLearningProject: any CreateLearningProjectUseCase
    public let deleteLearningProject: any DeleteLearningProjectUseCase

}
