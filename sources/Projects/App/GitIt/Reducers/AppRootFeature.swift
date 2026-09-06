import ComposableArchitecture
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Feature
import Foundation

// MARK: - AppRootFeature

@Reducer
nonisolated struct AppRootFeature: Sendable {

    // MARK: Lifecycle

    init(
        restoreSession: any RestoreSessionUseCase,
        signIn: any SignInUseCase,
        signOut: any SignOutUseCase,
        authenticationOutcomes: any AuthenticationOutcomesUseCase,
        fetchMemberProfile: any FetchMemberProfileUseCase,
        completeCuration: any CompleteCurationUseCase,
        policyConsent: any PolicyConsentUseCase,
        fetchLearningProjects: any FetchLearningProjectsUseCase,
        fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase,
        deleteLearningProject: any DeleteLearningProjectUseCase,
        fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase,
        fetchLearningSet: any FetchLearningSetUseCase,
        submitChoiceAnswer: any SubmitChoiceAnswerUseCase,
        submitEssayAnswer: any SubmitEssayAnswerUseCase,
        setQuestionBookmark: any SetQuestionBookmarkUseCase,
        updateMemberPosition: any UpdateMemberPositionUseCase,
        updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase,
        deleteMemberAccount: any DeleteMemberAccountUseCase,
        fetchExternalRepository: any FetchExternalRepositoryUseCase,
        createLearningProject: any CreateLearningProjectUseCase,
        observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase,
        requestGenerationReminder: any RequestGenerationReminderUseCase,
        trackGenerationProgress: any TrackGenerationProgressUseCase,
        waitPolicy: GenerationWaitPolicy = .standard,
        now: @escaping @Sendable () -> Date = { Date() },
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
        openExternalURL: @escaping @Sendable (URL) async -> Void = { _ in },
        registerCurrentDevice: @escaping @Sendable () async throws -> Void = { },
        deviceTokenRefreshes: @escaping @Sendable () -> AsyncStream<Void> = { AsyncStream { $0.finish() } },
        deletesCompletedAccountOnSignIn: Bool = false,
        resetAllForTesting: (@Sendable () async -> Void)? = nil,
    ) {
        self.restoreSession = restoreSession
        self.signIn = signIn
        self.signOut = signOut
        self.authenticationOutcomes = authenticationOutcomes
        self.fetchMemberProfile = fetchMemberProfile
        self.completeCuration = completeCuration
        self.policyConsent = policyConsent
        self.fetchLearningProjects = fetchLearningProjects
        self.fetchLearningProjectDetail = fetchLearningProjectDetail
        self.deleteLearningProject = deleteLearningProject
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
        self.fetchLearningSet = fetchLearningSet
        self.submitChoiceAnswer = submitChoiceAnswer
        self.submitEssayAnswer = submitEssayAnswer
        self.setQuestionBookmark = setQuestionBookmark
        self.updateMemberPosition = updateMemberPosition
        self.updateMemberCareerLevel = updateMemberCareerLevel
        self.deleteMemberAccount = deleteMemberAccount
        self.fetchExternalRepository = fetchExternalRepository
        self.createLearningProject = createLearningProject
        self.observeGenerationOutcomes = observeGenerationOutcomes
        self.requestGenerationReminder = requestGenerationReminder
        self.trackGenerationProgress = trackGenerationProgress
        self.waitPolicy = waitPolicy
        self.now = now
        self.openNotificationSettings = openNotificationSettings
        self.openExternalURL = openExternalURL
        self.registerCurrentDevice = registerCurrentDevice
        self.deviceTokenRefreshes = deviceTokenRefreshes
        self.deletesCompletedAccountOnSignIn = deletesCompletedAccountOnSignIn
        self.resetAllForTesting = resetAllForTesting
    }

    // MARK: Internal

    enum Route: Equatable, Sendable {
        case restoring
        case onboarding
        case mainShell
    }

    enum DeviceRegistrationStatus: Equatable, Sendable {
        case idle
        case registering
        case registered
        case failed
    }

    @ObservableState
    struct State: Equatable, Sendable {
        init(bundleVersion: String) {
            appEntry = AppEntryFeature.State()
            onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: bundleVersion)
        }

        var route = Route.restoring
        var appEntry: AppEntryFeature.State
        var onboarding: OnboardingRouterFeature.State
        var mainShell = MainShellRouterFeature.State()
        var deviceRegistration = DeviceRegistrationStatus.idle

        var generationProgress: GenerationProgress?

        var isGenerationProgressRestored = false

        @Presents var projectRegistration: ProjectRegistrationRouterFeature.State?
        @Presents var projectDetail: ProjectDetailRouterFeature.State?
        @Presents var quiz: QuizRouterFeature.State?
    }

    enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case appEntry(AppEntryFeature.Action)
        case onboarding(OnboardingRouterFeature.Action)
        case mainShell(MainShellRouterFeature.Action)
        case projectRegistration(PresentationAction<ProjectRegistrationRouterFeature.Action>)
        case projectDetail(PresentationAction<ProjectDetailRouterFeature.Action>)
        case quiz(PresentationAction<QuizRouterFeature.Action>)

        // MARK: Internal

        @CasePathable
        enum View: Sendable, Equatable {
            case task
            case resetAllTapped
            case applicationBecameActive
        }

        @CasePathable
        enum EffectEvent: Sendable, Equatable {
            case authenticationOutcomeReceived(AuthenticationOutcome)
            case resetAllFinished
            case deviceRegistrationSucceeded
            case deviceRegistrationFailed
            case deviceTokenRefreshed
            case generationProgressRestored(GenerationProgress?)
            case generationProgressReleased(projectID: String)
        }
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.appEntry, action: \.appEntry) {
            AppEntryFeature(
                restoreSession: restoreSession,
                fetchMemberProfile: fetchMemberProfile,
                signOut: signOut,
            )
        }
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingRouterFeature(
                signIn: signIn,
                signOut: signOut,
                policyConsent: policyConsent,
                completeCuration: completeCuration,
                deleteMemberAccount: deleteMemberAccount,
                deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
            )
        }
        Scope(state: \.mainShell, action: \.mainShell) {
            MainShellRouterFeature(
                fetchLearningProjects: fetchLearningProjects,
                deleteLearningProject: deleteLearningProject,
                fetchBookmarkedQuestions: fetchBookmarkedQuestions,
                fetchLearningSet: fetchLearningSet,
                submitChoiceAnswer: submitChoiceAnswer,
                submitEssayAnswer: submitEssayAnswer,
                setQuestionBookmark: setQuestionBookmark,
                signOut: signOut,
                fetchMemberProfile: fetchMemberProfile,
                updateMemberPosition: updateMemberPosition,
                updateMemberCareerLevel: updateMemberCareerLevel,
                deleteMemberAccount: deleteMemberAccount,
                observeGenerationOutcomes: observeGenerationOutcomes,
            )
        }
        Reduce { state, action in
            switch action {
            case .view(.task):
                guard state.route == .restoring else { return .none }
                return .merge(
                    .send(.appEntry(.view(.task))),
                    .run { send in
                        let outcomes = await authenticationOutcomes()
                        for await outcome in outcomes {
                            await send(.effect(.authenticationOutcomeReceived(outcome)))
                        }
                    }
                    .cancellable(id: CancelID.authenticationOutcomes),
                    .run { send in
                        for await _ in deviceTokenRefreshes() {
                            await send(.effect(.deviceTokenRefreshed))
                        }
                    }
                    .cancellable(id: CancelID.deviceTokenRefreshes),
                    .run { [trackGenerationProgress] send in
                        await send(.effect(.generationProgressRestored(trackGenerationProgress.current())))
                    },
                )

            case .appEntry(.delegate(.destinationDecided(let destination))):
                switch destination {
                case .mainShell:
                    state.route = .mainShell
                    return registerDeviceIfNeeded(&state)

                case .onboarding(let entryPoint):
                    let bundleVersion = state.onboarding.tutorial.bundleVersion
                    state.onboarding = OnboardingRouterFeature.State(startingAt: entryPoint, bundleVersion: bundleVersion)
                    state.route = .onboarding
                    return .none
                }

            case .appEntry:
                return .none

            case .effect(.authenticationOutcomeReceived(.unauthenticated)):
                guard state.route == .mainShell else { return .none }
                return returnToOnboarding(&state)

            case .effect(.authenticationOutcomeReceived):
                return .none

            case .onboarding(.delegate(.mainShellRequested)):
                state.route = .mainShell
                return registerDeviceIfNeeded(&state)

            case .mainShell(.delegate(.loggedOut)):
                return returnToOnboarding(&state)

            case .view(.applicationBecameActive):
                // Share Extension이나 다른 기기에서 등록한 프로젝트가 복귀 즉시 보이도록
                // 목록을 다시 불러온다. Extension이 남기는 신호에 의존하지 않는다.
                var effects = [Effect<Action>]()
                if state.route == .mainShell {
                    effects.append(.send(.mainShell(.home(.input(.learningProjectsReloadRequested)))))
                }
                if state.deviceRegistration == .failed {
                    effects.append(registerDeviceIfNeeded(&state))
                }
                return .merge(effects)

            case .effect(.deviceTokenRefreshed):
                guard state.route == .mainShell else { return .none }
                return registerDeviceIfNeeded(&state)

            case .effect(.deviceRegistrationSucceeded):
                state.deviceRegistration = .registered
                return .none

            case .effect(.deviceRegistrationFailed):
                state.deviceRegistration = .failed
                return .none

            case .view(.resetAllTapped):
                guard let resetAllForTesting else { return .none }
                return .run { send in
                    await resetAllForTesting()
                    await send(.effect(.resetAllFinished))
                }
                .cancellable(id: CancelID.resetAll, cancelInFlight: true)

            case .effect(.resetAllFinished):
                return returnToOnboarding(&state)

            case .mainShell(.delegate(.projectRegistrationRequested)):
                state.projectRegistration = ProjectRegistrationRouterFeature.State()
                return .none

            case .mainShell(.delegate(.projectDetailRequested(let projectID))):
                state.projectDetail = ProjectDetailRouterFeature.State(projectID: projectID)
                return .none

            case .mainShell(.delegate(.learningRequested(let projectID, let nextSetID))):
                guard let project = loadedProject(projectID: projectID, state: state) else { return .none }
                state.projectDetail = ProjectDetailRouterFeature.State(projectID: projectID)
                state.quiz = QuizRouterFeature.State(
                    projectID: projectID,
                    setID: nextSetID,
                    setLabel: project.currentSetLabel,
                    autoStartsLearning: true,
                )
                return .none

            case .projectDetail(.presented(.delegate(.learningSetRequested(let projectID, let setID, let label)))):
                state.quiz = QuizRouterFeature.State(projectID: projectID, setID: setID, setLabel: label)
                return .none

            case .mainShell(.delegate(.externalURLRequested(let url))),
                 .projectDetail(.presented(.delegate(.externalURLRequested(let url)))),
                 .quiz(.presented(.delegate(.externalURLRequested(let url)))):
                return .run { [openExternalURL] _ in await openExternalURL(url) }

            case .projectDetail(.presented(.delegate(.projectDeleted))):
                state.projectDetail = nil
                return .send(.mainShell(.home(.input(.learningProjectsReloadRequested))))

            case .projectDetail(.presented(.delegate(.dismissRequested))):
                state.projectDetail = nil
                return .none

            case .quiz(.presented(.delegate(.progressInvalidated(let projectID)))):
                guard state.projectDetail?.projectID == projectID else { return .none }
                return .send(.projectDetail(.presented(.projectDetail(.input(.refreshRequested)))))

            case .quiz(.presented(.delegate(.dismissRequested(let projectID)))):
                state.quiz = nil
                guard state.projectDetail?.projectID == projectID else {
                    state.projectDetail = ProjectDetailRouterFeature.State(projectID: projectID)
                    return .none
                }
                return .send(.projectDetail(.presented(.projectDetail(.input(.refreshRequested)))))

            case .projectDetail,
                 .quiz:
                return .none

            case .projectRegistration(.presented(.quizGenerationProgress(.effect(.submissionFinished(.success(let receipt)))))):
                let progress = GenerationProgress(projectID: receipt.projectID, requestedAt: now())
                state.generationProgress = progress
                state.isGenerationProgressRestored = false
                state.mainShell.home.isGenerationInProgress = true
                return .merge(
                    .run { [trackGenerationProgress] _ in
                        await trackGenerationProgress.begin(
                            projectID: progress.projectID,
                            requestedAt: progress.requestedAt,
                        )
                    },
                    releaseGenerationProgress(progress),
                )

            case .effect(.generationProgressRestored(let restored)):
                guard let restored, state.generationProgress == nil else { return .none }
                guard !waitPolicy.isExpired(restored, now: now()) else {
                    return .run { [trackGenerationProgress] _ in await trackGenerationProgress.end() }
                }
                state.generationProgress = restored
                state.isGenerationProgressRestored = true
                state.mainShell.home.isGenerationInProgress = true
                return releaseGenerationProgress(restored)

            case .effect(.generationProgressReleased(let projectID)):
                guard state.generationProgress?.projectID == projectID else { return .none }
                state.generationProgress = nil
                state.isGenerationProgressRestored = false
                state.mainShell.home.isGenerationInProgress = false
                return .merge(
                    .cancel(id: CancelID.generationProgress),
                    .run { [trackGenerationProgress] _ in await trackGenerationProgress.end() },
                )

            case .mainShell(.home(.effect(.projectsLoadFinished(_, .success(let page))))):
                guard
                    state.isGenerationProgressRestored,
                    let progress = state.generationProgress,
                    waitPolicy.readyDate(for: progress) <= now(),
                    page.items.contains(where: { $0.projectID == progress.projectID })
                else { return .none }
                return .send(.effect(.generationProgressReleased(projectID: progress.projectID)))

            case .projectRegistration(.presented(.delegate(.projectRegistered(_)))):
                state.projectRegistration = nil
                return .send(.mainShell(.home(.input(.learningProjectsReloadRequested))))

            case .projectRegistration(.presented(.delegate(.generationReminderPreferenceSelected(_)))):
                return .none

            case .projectRegistration(.presented(.delegate(.dismissRequested))):
                state.projectRegistration = nil
                return .none

            case .projectRegistration:
                return .none

            case .onboarding,
                 .mainShell:
                return .none
            }
        }
        .ifLet(\.$projectRegistration, action: \.projectRegistration) {
            ProjectRegistrationRouterFeature(
                fetchExternalRepository: fetchExternalRepository,
                createLearningProject: createLearningProject,
                observeGenerationOutcomes: observeGenerationOutcomes,
                requestGenerationReminder: requestGenerationReminder,
                openNotificationSettings: openNotificationSettings,
            )
        }
        .ifLet(\.$projectDetail, action: \.projectDetail) {
            ProjectDetailRouterFeature(
                fetchLearningProjectDetail: fetchLearningProjectDetail,
                deleteLearningProject: deleteLearningProject,
                fetchBookmarkedQuestions: fetchBookmarkedQuestions,
                fetchLearningSet: fetchLearningSet,
                submitChoiceAnswer: submitChoiceAnswer,
                submitEssayAnswer: submitEssayAnswer,
                setQuestionBookmark: setQuestionBookmark,
            )
        }
        .ifLet(\.$quiz, action: \.quiz) {
            QuizRouterFeature(
                fetchLearningSet: fetchLearningSet,
                fetchBookmarkedQuestions: fetchBookmarkedQuestions,
                submitChoiceAnswer: submitChoiceAnswer,
                submitEssayAnswer: submitEssayAnswer,
                setQuestionBookmark: setQuestionBookmark,
            )
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case authenticationOutcomes
        case resetAll
        case deviceRegistration
        case deviceTokenRefreshes
        case generationProgress
    }

    private let restoreSession: any RestoreSessionUseCase
    private let signIn: any SignInUseCase
    private let signOut: any SignOutUseCase
    private let authenticationOutcomes: any AuthenticationOutcomesUseCase
    private let fetchMemberProfile: any FetchMemberProfileUseCase
    private let completeCuration: any CompleteCurationUseCase
    private let policyConsent: any PolicyConsentUseCase
    private let fetchLearningProjects: any FetchLearningProjectsUseCase
    private let fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase
    private let deleteLearningProject: any DeleteLearningProjectUseCase
    private let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase
    private let fetchLearningSet: any FetchLearningSetUseCase
    private let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    private let submitEssayAnswer: any SubmitEssayAnswerUseCase
    private let setQuestionBookmark: any SetQuestionBookmarkUseCase
    private let updateMemberPosition: any UpdateMemberPositionUseCase
    private let updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase
    private let deleteMemberAccount: any DeleteMemberAccountUseCase
    private let fetchExternalRepository: any FetchExternalRepositoryUseCase
    private let createLearningProject: any CreateLearningProjectUseCase
    private let observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase
    private let requestGenerationReminder: any RequestGenerationReminderUseCase
    private let trackGenerationProgress: any TrackGenerationProgressUseCase
    private let waitPolicy: GenerationWaitPolicy
    private let now: @Sendable () -> Date
    private let openNotificationSettings: @MainActor @Sendable () async -> Void
    private let openExternalURL: @Sendable (URL) async -> Void
    private let registerCurrentDevice: @Sendable () async throws -> Void
    private let deviceTokenRefreshes: @Sendable () -> AsyncStream<Void>
    private let deletesCompletedAccountOnSignIn: Bool
    private let resetAllForTesting: (@Sendable () async -> Void)?

    /// 학습 요청을 보낸 탭이 Home일 수도 프로젝트 목록일 수도 있어 두 곳에서 모두 찾습니다.
    private func loadedProject(
        projectID: String,
        state: State,
    ) -> LearningProjectSummary? {
        if
            case .loaded(let page) = state.mainShell.home.projectLoad,
            let project = page.items.first(where: { $0.projectID == projectID })
        {
            return project
        }
        return state.mainShell.projectList.projects.first { $0.projectID == projectID }
    }

    private func registerDeviceIfNeeded(_ state: inout State) -> Effect<Action> {
        guard state.deviceRegistration != .registering else { return .none }
        state.deviceRegistration = .registering
        return .run { send in
            do {
                try await registerCurrentDevice()
                await send(.effect(.deviceRegistrationSucceeded))
            } catch {
                await send(.effect(.deviceRegistrationFailed))
            }
        }
        .cancellable(id: CancelID.deviceRegistration)
    }

    private func releaseGenerationProgress(_ progress: GenerationProgress) -> Effect<Action> {
        .run { [observeGenerationOutcomes, waitPolicy, now] send in
            let deadline = progress.requestedAt.addingTimeInterval(waitPolicy.retentionLimit)

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await outcome in await observeGenerationOutcomes()
                        where outcome.projectID == progress.projectID
                    {
                        return
                    }
                }
                group.addTask {
                    let remaining = deadline.timeIntervalSince(now())
                    guard remaining > 0 else { return }
                    try? await Task.sleep(for: .seconds(remaining))
                }
                await group.next()
                group.cancelAll()
            }

            let remainingMinimum = waitPolicy.readyDate(for: progress).timeIntervalSince(now())
            if remainingMinimum > 0 {
                try? await Task.sleep(for: .seconds(remainingMinimum))
            }
            await send(.effect(.generationProgressReleased(projectID: progress.projectID)))
        }
        .cancellable(id: CancelID.generationProgress, cancelInFlight: true)
    }

    private func returnToOnboarding(_ state: inout State) -> Effect<Action> {
        let bundleVersion = state.onboarding.tutorial.bundleVersion
        state.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: bundleVersion)
        state.mainShell = MainShellRouterFeature.State()
        state.projectRegistration = nil
        state.projectDetail = nil
        state.quiz = nil
        state.deviceRegistration = .idle
        state.generationProgress = nil
        state.isGenerationProgressRestored = false
        state.route = .onboarding
        return .merge(
            .cancel(id: CancelID.deviceRegistration),
            .cancel(id: CancelID.generationProgress),
        )
    }

}
