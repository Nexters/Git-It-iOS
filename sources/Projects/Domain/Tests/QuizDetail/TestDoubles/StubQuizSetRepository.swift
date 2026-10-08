import DomainUseCaseDependency
@testable import DomainUseCaseInterface

struct StubQuizSetRepository: QuizSetRepository {

    // MARK: Internal

    let quizSet: QuizSet

    func quizSet(
        _: String,
        in _: String,
    ) async throws -> QuizSet {
        quizSet
    }

}
