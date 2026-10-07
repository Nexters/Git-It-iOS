import DomainLearningProject

/// 세트 하나에서 이어 풀 시작 지점과 완료 카운터 기준선을 계산합니다.
public struct LearningSetResumption: Equatable, Sendable {

    // MARK: Lifecycle

    public init(set: LearningSet) {
        let questions = set.questions
        let firstUnanswered = questions.firstIndex { $0.myAnswer == nil }

        startIndex = firstUnanswered ?? 0
        choiceQuestionCount = questions.count(where: { $0.format == .multipleChoice })
        skippedCorrectChoiceCount = questions.prefix(startIndex).count(where: {
            $0.format == .multipleChoice && $0.myAnswer?.correct == true
        })
    }

    // MARK: Public

    /// 첫 미응답 문제의 index입니다. 모두 응답했거나 문제가 없으면 `0`입니다.
    public let startIndex: Int
    /// 세트 전체의 객관식 수로, 완료 카운터의 분모입니다.
    public let choiceQuestionCount: Int
    /// `startIndex` 앞에서 이미 정답으로 채점된 객관식 수입니다.
    public let skippedCorrectChoiceCount: Int

}
