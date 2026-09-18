import ComposableArchitecture
import DomainAccount
import DomainIdentifier
import DomainProject
import DomainProjectGeneration
import DomainQuizDetail
import DomainUserInfo
import Foundation
@testable import GitIt

// MARK: - AppRootTestFixture

enum AppRootTestFixture {

    static let repositoryURL: ExternalRepositoryURL = "https://github.com/owner/repo"
    static let projectID: ProjectID = "project-1"
    static let setID: QuizSetID = "set-1"
    static let quizID: QuizID = "quiz-1"
    static let setLabel = "CHAPTER 1"

    static let signedInAccount = SignedInAccount(id: "member-1", displayName: "테스터", needsCuration: false)

    static let curation = Curation(position: .ios, careerLevel: .junior)

    static let userDetail = UserDetail(
        name: "테스터",
        email: "tester@example.com",
        statistics: LearningStatistics(
            thisWeekSolvedCount: 0,
            thisMonthSolvedCount: 0,
            streakDays: 0,
            weeklyCounts: [],
        ),
    )

    static func mainShellState() -> AppRootFeature.State {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        return state
    }

    static func projectSummary(projectID: ProjectID = AppRootTestFixture.projectID) -> ProjectSummary {
        ProjectSummary(
            id: projectID,
            repositoryName: "owner/repo",
            repositoryImageURL: nil,
            techStack: ["Swift"],
            currentSet: ProjectSetLabel(label: setLabel, title: "모듈 경계"),
            next: ProjectNextQuiz(setID: setID, quizID: quizID),
            progressPercent: 0,
        )
    }

    static func projectList(summaries: [ProjectSummary]) -> ProjectList {
        ProjectList(summaries: summaries, hasNextPage: false, isLoaded: true)
    }

    static func projectDetail(projectID: ProjectID) -> ProjectDetail {
        ProjectDetail(
            id: projectID,
            repository: ProjectRepositoryInfo(
                url: repositoryURL,
                name: "owner/repo",
                imageURL: nil,
                starCount: 10,
                techStack: ["Swift"],
            ),
            progressPercent: 40,
            sets: [
                ProjectSetProgress(
                    setID: setID,
                    label: setLabel,
                    title: "모듈 경계",
                    quizCount: 5,
                    completedCount: 2,
                )
            ],
            next: ProjectNextQuiz(setID: setID, quizID: quizID),
        )
    }

    static func quiz(quizID: QuizID = AppRootTestFixture.quizID) -> Quiz {
        Quiz(
            id: quizID,
            prompt: "모듈 경계는 무엇으로 정하나요?",
            content: .choice(options: ["책임", "파일 수"], submitted: nil),
            sources: [],
        )
    }

    static func generationState(
        phase: ProjectGenerationPhase,
        requestedAt: Date = Date(timeIntervalSince1970: 1_000),
    ) -> ProjectGenerationState {
        ProjectGenerationState(
            requests: [
                ProjectGenerationRequestState(
                    repositoryURL: repositoryURL,
                    projectID: projectID,
                    requestedAt: requestedAt,
                    phase: phase,
                )
            ],
            preparingProjectIDs: [],
        )
    }

}

@MainActor
func makeAppRootStore(
    account: AccountUseCaseMock = AccountUseCaseMock(),
    userInfo: UserInfoUseCaseMock = UserInfoUseCaseMock(),
    appSetting: AppSettingUseCaseMock = AppSettingUseCaseMock(),
    project: ProjectUseCaseMock = ProjectUseCaseMock(),
    projectGeneration: ProjectGenerationUseCaseMock = ProjectGenerationUseCaseMock(),
    deviceTokenRefreshes: DeviceTokenRefreshStream = DeviceTokenRefreshStream(),
    openExternalURL: OpenExternalURLSpy = OpenExternalURLSpy(),
    state: AppRootFeature.State = AppRootFeature.State(bundleVersion: "1.0.0"),
) -> TestStoreOf<AppRootFeature> {
    TestStore(initialState: state) {
        AppRootFeature(
            account: account,
            userInfo: userInfo,
            appSetting: appSetting,
            externalRepository: NoopExternalRepositoryUseCase(),
            quizDetail: NoopQuizDetailUseCase(),
            project: project,
            projectGeneration: projectGeneration,
            openExternalURL: { await openExternalURL($0) },
            deviceTokenRefreshes: { deviceTokenRefreshes.makeStream() },
        )
    }
}
