import Foundation
import Testing

@testable import DomainQuizDetail

@Suite("QuizDetail 채점")
struct QuizDetailGradingTests {

    // MARK: Internal

    @Test
    func `음수 선택지 인덱스는 요청 없이 invalidAnswer를 던진다`() async {
        let answers = SpyAnswerRepository()
        let quizDetail = Self.makeQuizDetail(answers: answers)

        await #expect(throws: QuizDetailError.invalidAnswer) {
            try await quizDetail.grade(ChoiceAnswer(
                projectID: "p1",
                quizID: "q1",
                selectedIndex: -1,
            ))
        }
        #expect(await answers.choiceAnswers.isEmpty)
    }

    @Test
    func `선택지 답안을 제출하고 채점 결과를 반환한다`() async throws {
        let answers = SpyAnswerRepository()
        let quizDetail = Self.makeQuizDetail(answers: answers)
        let answer = ChoiceAnswer(
            projectID: "p1",
            quizID: "q1",
            selectedIndex: 2,
        )

        let grading = try await quizDetail.grade(answer)

        #expect(grading.correctIndex == 2)
        #expect(await answers.choiceAnswers == [answer])
    }

    @Test
    func `공백뿐인 서술형 답안은 요청 없이 invalidAnswer를 던진다`() async {
        let answers = SpyAnswerRepository()
        let quizDetail = Self.makeQuizDetail(answers: answers)

        await #expect(throws: QuizDetailError.invalidAnswer) {
            try await quizDetail.grade(EssayAnswer(
                projectID: "p1",
                quizID: "q1",
                text: " \n\t ",
            ))
        }
        #expect(await answers.essayAnswers.isEmpty)
    }

    @Test
    func `2000자를 넘는 서술형 답안은 요청 없이 invalidAnswer를 던진다`() async {
        let answers = SpyAnswerRepository()
        let quizDetail = Self.makeQuizDetail(answers: answers)

        await #expect(throws: QuizDetailError.invalidAnswer) {
            try await quizDetail.grade(EssayAnswer(
                projectID: "p1",
                quizID: "q1",
                text: String(
                    repeating: "가",
                    count: 2001,
                ),
            ))
        }
        #expect(await answers.essayAnswers.isEmpty)
    }

    @Test
    func `서술형 답안은 앞뒤 공백을 제거해 제출한다`() async throws {
        let answers = SpyAnswerRepository()
        let quizDetail = Self.makeQuizDetail(answers: answers)

        _ = try await quizDetail.grade(EssayAnswer(
            projectID: "p1",
            quizID: "q1",
            text: "  답안  \n",
        ))

        #expect(await answers.essayAnswers == [EssayAnswer(
            projectID: "p1",
            quizID: "q1",
            text: "답안",
        )])
    }

    @Test
    func `퀴즈 세트를 저장소에서 가져온다`() async throws {
        let quizSet = QuizSet(
            id: "s1",
            title: "세트",
            description: "설명",
            quizzes: [],
        )
        let quizDetail = QuizDetail(
            quizSetRepository: StubQuizSetRepository(quizSet: quizSet),
            answerRepository: SpyAnswerRepository(),
            bookmarkRepository: SpyBookmarkRepository(),
        )

        #expect(try await quizDetail.quizSet(
            "s1",
            in: "p1",
        ) == quizSet)
    }

    // MARK: Private

    private static func makeQuizDetail(answers: SpyAnswerRepository) -> QuizDetail {
        QuizDetail(
            quizSetRepository: StubQuizSetRepository(
                quizSet: QuizSet(
                    id: "s1",
                    title: "",
                    description: "",
                    quizzes: [],
                )
            ),
            answerRepository: answers,
            bookmarkRepository: SpyBookmarkRepository(),
        )
    }

}
