import Testing

@testable import DomainLearningProject

// MARK: - LearningProjectDetailTests

@Suite("학습 프로젝트 상세")
struct LearningProjectDetailTests {
    @Test
    func `완료되지 않은 첫 세트를 다음 세트로 반환한다`() {
        let detail = makeDetail(sets: [
            makeSet(id: "set-1", problemCount: 5, completedCount: 5),
            makeSet(id: "set-2", problemCount: 5, completedCount: 2),
            makeSet(id: "set-3", problemCount: 5, completedCount: 0),
        ])

        #expect(detail.nextSet?.setID == "set-2")
    }

    @Test
    func `모든 세트를 완료했으면 다음 세트가 없다`() {
        let detail = makeDetail(sets: [
            makeSet(id: "set-1", problemCount: 5, completedCount: 5),
            makeSet(id: "set-2", problemCount: 3, completedCount: 3),
        ])

        #expect(detail.nextSet == nil)
    }
}

extension LearningProjectDetailTests {
    private func makeDetail(sets: [LearningProjectSetProgress]) -> LearningProjectDetail {
        LearningProjectDetail(
            projectID: "project-1",
            repositoryURL: "https://github.com/owner/repo",
            repositoryName: "repo",
            repositoryImageURL: nil,
            starCount: 0,
            techStack: [],
            overallProgressPercent: 0,
            nextQuestionID: nil,
            sets: sets,
        )
    }

    private func makeSet(
        id: String,
        problemCount: Int,
        completedCount: Int,
    ) -> LearningProjectSetProgress {
        LearningProjectSetProgress(
            setID: id,
            label: id,
            title: id,
            problemCount: problemCount,
            completedCount: completedCount,
        )
    }
}
