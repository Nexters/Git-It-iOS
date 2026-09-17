import ComposableArchitecture
import DomainExternalRepository
import DomainProjectGeneration

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

func makeRepositoryLinkInputStore(
    externalRepository: StubFetchExternalRepositoryUseCase = StubFetchExternalRepositoryUseCase(),
    state: RepositoryLinkInputFeature.State = RepositoryLinkInputFeature.State(),
) -> TestStoreOf<RepositoryLinkInputFeature> {
    TestStore(initialState: state) {
        RepositoryLinkInputFeature(repository: { try await externalRepository.repository(at: $0) })
    }
}

func makeQuizLevelSelectionStore(
    state: QuizLevelSelectionFeature.State = QuizLevelSelectionFeature.State()
) -> TestStoreOf<QuizLevelSelectionFeature> {
    TestStore(initialState: state) { QuizLevelSelectionFeature() }
}

func makeQuizGenerationProgressStore(
    projectGeneration: StubCreateLearningProjectUseCase = StubCreateLearningProjectUseCase(),
    appSetting: StubRequestGenerationReminderUseCase = StubRequestGenerationReminderUseCase(),
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

func makeProjectRegistrationRouterStore(
    externalRepository: StubFetchExternalRepositoryUseCase = StubFetchExternalRepositoryUseCase(),
    projectGeneration: StubCreateLearningProjectUseCase = StubCreateLearningProjectUseCase(),
    appSetting: StubRequestGenerationReminderUseCase = StubRequestGenerationReminderUseCase(),
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

// MARK: - OpenNotificationSettingsSpy

actor OpenNotificationSettingsSpy {

    private(set) var callCount = 0

    func callAsFunction() {
        callCount += 1
    }

}
