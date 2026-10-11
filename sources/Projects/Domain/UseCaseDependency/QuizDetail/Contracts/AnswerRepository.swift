import DomainUseCaseInterface

public protocol AnswerRepository: Sendable {
    func submit(_ answer: ChoiceAnswer) async throws -> ChoiceGrading
    func submit(_ answer: EssayAnswer) async throws -> EssayGrading
}
