import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

struct NoopFetchBookmarkedQuestionsUseCase: FetchBookmarkedQuestionsUseCase {
    func callAsFunction(projectID _: String?) async throws -> BookmarkedQuestionCollection {
        throw CancellationError()
    }
}
