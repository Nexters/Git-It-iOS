import Testing

@testable import DomainLearningProject

// MARK: - LearningProjectSummaryTests

@Suite("LearningProjectSummary")
struct LearningProjectSummaryTests {
    @Test
    func `다음 세트와 다음 문제 ID가 없으면 nil을 그대로 보존한다`() {
        let summary = LearningProjectSummary(
            projectID: "project-1",
            repositoryName: "repo",
            repositoryImageURL: nil,
            techStack: [],
            currentSetLabel: "Set 1",
            currentSetTitle: "title",
            nextSetID: nil,
            nextQuestionID: nil,
            overallProgressPercent: 0,
        )

        #expect(summary.nextSetID == nil)
        #expect(summary.nextQuestionID == nil)
    }

    @Test
    func `값이 있으면 손실 없이 보존한다`() {
        let summary = LearningProjectSummary(
            projectID: "project-1",
            repositoryName: "repo",
            repositoryImageURL: nil,
            techStack: [],
            currentSetLabel: "Set 1",
            currentSetTitle: "title",
            nextSetID: "set-2",
            nextQuestionID: "question-3",
            overallProgressPercent: 40,
        )

        #expect(summary.nextSetID == "set-2")
        #expect(summary.nextQuestionID == "question-3")
    }
}
