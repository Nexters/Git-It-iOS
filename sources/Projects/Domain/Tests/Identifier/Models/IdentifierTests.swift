import Testing

@testable import DomainUseCaseInterface

@Suite("Identifier")
struct IdentifierTests {

    // MARK: Internal

    @Test
    func `식별자는 같은 String 값으로 서로 대입된다`() {
        let projectID: ProjectID = "identifier-1"
        let quizSetID: QuizSetID = projectID
        let quizID: QuizID = quizSetID
        let repositoryURL: ExternalRepositoryURL = quizID

        #expect(repositoryURL == "identifier-1")
    }

}
