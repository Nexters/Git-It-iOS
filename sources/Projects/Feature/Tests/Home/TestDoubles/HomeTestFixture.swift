import DomainLearningProject
import DomainMember

enum HomeTestFixture {
    static func profile(
        position: MemberPosition?,
        careerLevel: CareerLevel?,
        name: String = "프로덕션에 푸시하는 고양이",
    ) -> MemberProfile {
        MemberProfile(
            name: name,
            email: "cat@git-it.dev",
            position: position,
            careerLevel: careerLevel,
            statistics: LearningStatistics(
                totalAnsweredCount: 12,
                totalCorrectCount: 9,
                weeklyCounts: [],
            ),
        )
    }

    static let profileWithBoth = profile(position: .ios, careerLevel: .junior)
    static let profileWithPosition = profile(position: .backend, careerLevel: nil)
    static let profileWithCareer = profile(position: nil, careerLevel: .middle)
    static let profileWithNameOnly = profile(position: nil, careerLevel: nil)

    static let emptyPage = LearningProjectPage(items: [], hasNext: false)
    static let oneProjectPage = LearningProjectPage(items: [project(index: 0)], hasNext: false)
    static let manyProjectsPage = LearningProjectPage(
        items: [project(index: 0), project(index: 1), project(index: 2), project(index: 3)],
        hasNext: true,
    )

    static func project(index: Int, hasLearningIDs: Bool = true) -> LearningProjectSummary {
        LearningProjectSummary(
            projectID: "project-\(index)",
            repositoryName: "Repository \(index)",
            repositoryImageURL: nil,
            techStack: ["Swift", "SwiftUI", "TCA"],
            currentSetLabel: "Sprint Beta \(index)",
            currentSetTitle: "Presentation 구조 \(index)",
            nextSetID: hasLearningIDs ? "set-\(index)" : nil,
            nextQuestionID: hasLearningIDs ? "question-\(index)" : nil,
            overallProgressPercent: index == 3 ? 140 : index * 25,
        )
    }
}
