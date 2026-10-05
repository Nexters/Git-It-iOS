import DomainUseCaseInterface

enum HomeTestFixture {

    // MARK: Internal

    static let profileWithBoth = profile(
        position: .ios,
        careerLevel: .junior,
    )
    static let profileWithPosition = profile(
        position: .backend,
        careerLevel: nil,
    )
    static let profileWithCareer = profile(
        position: nil,
        careerLevel: .middle,
    )
    static let profileWithNameOnly = profile(
        position: nil,
        careerLevel: nil,
    )

    static let emptyPage = ProjectList(
        summaries: [],
        hasNextPage: false,
        isLoaded: true,
    )
    static let oneProjectPage = ProjectList(
        summaries: [project(index: 0)],
        hasNextPage: false,
        isLoaded: true,
    )
    static let manyProjectsPage = ProjectList(
        summaries: [project(index: 0), project(index: 1), project(index: 2), project(index: 3)],
        hasNextPage: true,
        isLoaded: true,
    )

    static func profile(
        position: MemberPosition?,
        careerLevel: CareerLevel?,
        name: String = "프로덕션에 푸시하는 고양이",
    ) -> UserProfile {
        UserProfile(
            detail: UserDetail(
                name: name,
                email: "cat@git-it.dev",
                statistics: LearningStatistics(
                    thisWeekSolvedCount: 12,
                    thisMonthSolvedCount: 9,
                    streakDays: 3,
                    weeklyCounts: [],
                ),
            ),
            curation: curation(
                position: position,
                careerLevel: careerLevel,
            ),
        )
    }

    static func project(
        index: Int,
        hasLearningIDs: Bool = true,
    ) -> ProjectSummary {
        ProjectSummary(
            id: "project-\(index)",
            repositoryName: "Repository \(index)",
            repositoryImageURL: nil,
            techStack: ["Swift", "SwiftUI", "TCA"],
            currentSet: ProjectSetLabel(
                label: "Sprint Beta \(index)",
                title: "Presentation 구조 \(index)",
            ),
            next: hasLearningIDs
                ? ProjectNextQuiz(
                    setID: "set-\(index)",
                    quizID: "quiz-\(index)",
                )
                : nil,
            progressPercent: index == 3 ? 140 : index * 25,
        )
    }

    // MARK: Private

    private static func curation(
        position: MemberPosition?,
        careerLevel: CareerLevel?,
    ) -> Curation? {
        guard let position, let careerLevel else { return nil }
        return Curation(
            position: position,
            careerLevel: careerLevel,
        )
    }

}
