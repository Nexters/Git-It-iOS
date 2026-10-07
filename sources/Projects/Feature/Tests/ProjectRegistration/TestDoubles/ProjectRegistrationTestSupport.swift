import ComposableArchitecture
import DomainLearningProject
import Foundation

@testable import Feature

let sampleRepository = ExternalRepository(
    canonicalURL: "https://github.com/owner/repo",
    ownerName: "owner",
    repositoryName: "repo",
    imageURL: nil,
    starCount: 10,
    techStack: ["Swift"],
)

let sampleReceipt = ProjectRegistrationReceipt(
    projectID: "project-1",
    requestStatus: "ready",
    quizLevel: .l1,
)

func makeRepositoryLinkInputStore(
    fetchExternalRepository: StubFetchExternalRepositoryUseCase = StubFetchExternalRepositoryUseCase(),
    state: RepositoryLinkInputFeature.State = RepositoryLinkInputFeature.State(),
) -> TestStoreOf<RepositoryLinkInputFeature> {
    TestStore(initialState: state) {
        RepositoryLinkInputFeature(fetchExternalRepository: fetchExternalRepository)
    }
}

func makeQuizLevelSelectionStore(
    state: QuizLevelSelectionFeature.State = QuizLevelSelectionFeature.State()
) -> TestStoreOf<QuizLevelSelectionFeature> {
    TestStore(initialState: state) { QuizLevelSelectionFeature() }
}

func makeQuizGenerationProgressStore(
    createLearningProject: StubCreateLearningProjectUseCase = StubCreateLearningProjectUseCase(),
    observeGenerationOutcomes: StubObserveGenerationOutcomesUseCase = StubObserveGenerationOutcomesUseCase(),
    requestGenerationReminder: StubRequestGenerationReminderUseCase =
        StubRequestGenerationReminderUseCase(results: [.authorized]),
    openNotificationSettings: OpenNotificationSettingsSpy = OpenNotificationSettingsSpy(),
    waitPolicy: GenerationWaitPolicy = .standard,
    now: @escaping @Sendable () -> Date = { Date() },
    state: QuizGenerationProgressFeature.State = QuizGenerationProgressFeature.State(),
) -> TestStoreOf<QuizGenerationProgressFeature> {
    TestStore(initialState: state) {
        QuizGenerationProgressFeature(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            requestGenerationReminder: requestGenerationReminder,
            openNotificationSettings: { await openNotificationSettings() },
            waitPolicy: waitPolicy,
            now: now,
        )
    }
}

func makeProjectRegistrationRouterStore(
    fetchExternalRepository: StubFetchExternalRepositoryUseCase = StubFetchExternalRepositoryUseCase(),
    createLearningProject: StubCreateLearningProjectUseCase = StubCreateLearningProjectUseCase(),
    observeGenerationOutcomes: StubObserveGenerationOutcomesUseCase = StubObserveGenerationOutcomesUseCase(),
    requestGenerationReminder: StubRequestGenerationReminderUseCase =
        StubRequestGenerationReminderUseCase(results: [.authorized]),
    openNotificationSettings: OpenNotificationSettingsSpy = OpenNotificationSettingsSpy(),
    waitPolicy: GenerationWaitPolicy = .standard,
    now: @escaping @Sendable () -> Date = { Date() },
    state: ProjectRegistrationRouterFeature.State = ProjectRegistrationRouterFeature.State(),
) -> TestStoreOf<ProjectRegistrationRouterFeature> {
    TestStore(initialState: state) {
        ProjectRegistrationRouterFeature(
            fetchExternalRepository: fetchExternalRepository,
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            requestGenerationReminder: requestGenerationReminder,
            openNotificationSettings: { await openNotificationSettings() },
            waitPolicy: waitPolicy,
            now: now,
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

actor OpenNotificationSettingsSpy {

    private(set) var callCount = 0

    func callAsFunction() {
        callCount += 1
    }

}
