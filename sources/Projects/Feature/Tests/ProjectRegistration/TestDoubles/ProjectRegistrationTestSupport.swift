import ComposableArchitecture
import DomainUseCaseInterface

@testable import Feature

let sampleRepository = ExternalRepository(
    canonicalURL: "https://github.com/owner/repo",
    ownerName: "owner",
    repositoryName: "repo",
    imageURL: nil,
    starCount: 10,
    techStack: ["Swift"],
)

let sampleReceipt = ProjectGenerationReceipt(
    projectID: "project-1",
    quizLevel: .l1,
)

@MainActor
func makeRepositoryLinkInputStore(
    externalRepository: ExternalRepositoryUseCaseStub = ExternalRepositoryUseCaseStub(),
    state: RepositoryLinkInputFeature.State = RepositoryLinkInputFeature.State(),
) -> TestStoreOf<RepositoryLinkInputFeature> {
    TestStore(initialState: state) {
        RepositoryLinkInputFeature(repository: { try await externalRepository.repository(at: $0) })
    }
}

@MainActor
func makeQuizLevelSelectionStore(
    state: QuizLevelSelectionFeature.State = QuizLevelSelectionFeature.State()
) -> TestStoreOf<QuizLevelSelectionFeature> {
    TestStore(initialState: state) { QuizLevelSelectionFeature() }
}

@MainActor
func makeQuizGenerationProgressStore(
    projectGeneration: ProjectGenerationUseCaseStub = ProjectGenerationUseCaseStub(),
    appSetting: AppSettingUseCaseStub = AppSettingUseCaseStub(),
    openNotificationSettings: OpenNotificationSettingsSpy = OpenNotificationSettingsSpy(),
    state: QuizGenerationProgressFeature.State = QuizGenerationProgressFeature.State(),
) -> TestStoreOf<QuizGenerationProgressFeature> {
    TestStore(initialState: state) {
        QuizGenerationProgressFeature(
            requestGeneration: { try await projectGeneration.request($0) },
            generationStates: { await projectGeneration.states() },
            notificationAuthorization: { await appSetting.notificationAuthorization() },
            requestNotificationAuthorization: { await appSetting.requestNotificationAuthorization() },
            openNotificationSettings: { await openNotificationSettings() },
        )
    }
}

@MainActor
func makeProjectRegistrationRouterStore(
    externalRepository: ExternalRepositoryUseCaseStub = ExternalRepositoryUseCaseStub(),
    projectGeneration: ProjectGenerationUseCaseStub = ProjectGenerationUseCaseStub(),
    appSetting: AppSettingUseCaseStub = AppSettingUseCaseStub(),
    openNotificationSettings: OpenNotificationSettingsSpy = OpenNotificationSettingsSpy(),
    state: ProjectRegistrationRouterFeature.State = ProjectRegistrationRouterFeature.State(),
) -> TestStoreOf<ProjectRegistrationRouterFeature> {
    TestStore(initialState: state) {
        ProjectRegistrationRouterFeature(
            externalRepository: externalRepository,
            projectGeneration: projectGeneration,
            appSetting: appSetting,
            openNotificationSettings: { await openNotificationSettings() },
        )
    }
}

func waitUntil(
    timeout: Duration = .seconds(2),
    _ condition: @Sendable () async -> Bool,
) async {
    let deadline = ContinuousClock.now.advanced(by: timeout)
    while ContinuousClock.now < deadline {
        if await condition() {
            return
        }
        try? await Task.sleep(for: .milliseconds(1))
    }
}
