import DomainUseCaseDependency
@testable import DomainUseCaseInterface

actor SpyAnswerRepository: AnswerRepository {

    private(set) var choiceAnswers = [ChoiceAnswer]()
    private(set) var essayAnswers = [EssayAnswer]()

    func submit(_ answer: ChoiceAnswer) async throws -> ChoiceGrading {
        choiceAnswers.append(answer)
        return ChoiceGrading(
            isCorrect: true,
            correctIndex: answer.selectedIndex,
            explanation: "정답",
        )
    }

    func submit(_ answer: EssayAnswer) async throws -> EssayGrading {
        essayAnswers.append(answer)
        return EssayGrading(
            explanation: "해설",
            rubric: ["기준"],
        )
    }

}
