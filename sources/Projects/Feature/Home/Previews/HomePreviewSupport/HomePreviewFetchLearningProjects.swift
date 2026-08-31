import DomainLearningProject
import Foundation

struct HomePreviewFetchLearningProjects: FetchLearningProjectsUseCase {
    enum Behavior: Sendable {
        case loading
        case success(LearningProjectPage)
        case failure(LearningProjectError)
    }

    let behavior: Behavior

    func callAsFunction() async throws -> LearningProjectPage {
        switch behavior {
        case .loading:
            try await Task.sleep(for: .seconds(3_600))
            throw CancellationError()
        case .success(let page):
            return page
        case .failure(let error):
            throw error
        }
    }
}
