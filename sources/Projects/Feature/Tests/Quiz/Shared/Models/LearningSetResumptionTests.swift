import DomainLearningProject
import Testing

@testable import Feature

@Suite("LearningSetResumption 시작 지점과 카운터 기준선")
struct LearningSetResumptionTests {

    @Test
    func `답변이 없으면 첫 문제에서 시작하고 건너뛴 정답이 없다`() {
        let resumption = LearningSetResumption(set: QuizTestFixture.unansweredSet)

        #expect(resumption.startIndex == 0)
        #expect(resumption.choiceQuestionCount == 2)
        #expect(resumption.skippedCorrectChoiceCount == 0)
    }

    @Test
    func `앞쪽 문제만 답변되어 있으면 첫 미응답 문제에서 시작한다`() {
        let resumption = LearningSetResumption(set: QuizTestFixture.partiallyAnsweredSet)

        #expect(resumption.startIndex == 2)
        #expect(resumption.choiceQuestionCount == 2)
        #expect(resumption.skippedCorrectChoiceCount == 1)
    }

    @Test
    func `모두 답변되어 있으면 처음부터 다시 풀고 건너뛴 정답을 세지 않는다`() {
        let resumption = LearningSetResumption(set: QuizTestFixture.fullyAnsweredSet)

        #expect(resumption.startIndex == 0)
        #expect(resumption.skippedCorrectChoiceCount == 0)
    }

    @Test
    func `문제가 없으면 시작 index와 카운터가 모두 0이다`() {
        let resumption = LearningSetResumption(set: QuizTestFixture.emptySet)

        #expect(resumption.startIndex == 0)
        #expect(resumption.choiceQuestionCount == 0)
        #expect(resumption.skippedCorrectChoiceCount == 0)
    }

    @Test
    func `서술형만 있는 세트는 객관식 분모가 0이다`() {
        let resumption = LearningSetResumption(set: QuizTestFixture.essayOnlySet)

        #expect(resumption.choiceQuestionCount == 0)
    }

}
