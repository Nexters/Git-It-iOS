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
        deleteLearningProject: any DeleteLearningProjectUseCase,
        fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase,
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
        self.deleteLearningProject = deleteLearningProject
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
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

    /// 기기 등록의 진행과 실패를 인증 세션 소유자가 관찰 가능한 상태로 보존한다.
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
        var mainShell = MainShellFeature.State()
        var deviceRegistration = DeviceRegistrationStatus.idle
        /// 진행 중인 학습 세트 생성 1건이다. 요청 제출부터 해제 시점까지 App이 수명을 소유한다.
        var generationProgress: GenerationProgress?
        /// 앱 재실행으로 복원한 진행 상태인지 여부다. 복원 경로에서만 학습 프로젝트 목록을
        /// 1차 해소 수단으로 사용한다.
        var isGenerationProgressRestored = false
        /// 아직 소비하지 못한 공유 링크다. 앱 실행 동안만 메모리에 유지한다.
        var pendingSharedLink: SharedRepositoryLink?
        @Presents var projectRegistration: ProjectRegistrationFeature.State?
    }

    enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case appEntry(AppEntryFeature.Action)
        case onboarding(OnboardingRouterFeature.Action)
        case mainShell(MainShellFeature.Action)
        case projectRegistration(PresentationAction<ProjectRegistrationFeature.Action>)

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
            case sharedRepositoryLinkReceived(SharedRepositoryLink)
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
            MainShellFeature(
                fetchLearningProjects: fetchLearningProjects,
                deleteLearningProject: deleteLearningProject,
                fetchBookmarkedQuestions: fetchBookmarkedQuestions,
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
                    return .merge(
                        registerDeviceIfNeeded(&state),
                        consumePendingSharedLink(&state),
                    )

                case .onboarding(let entryPoint):
                    let bundleVersion = state.onboarding.guide.bundleVersion
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
                return .merge(
                    registerDeviceIfNeeded(&state),
                    consumePendingSharedLink(&state),
                )

            case .mainShell(.delegate(.loggedOut)):
                return returnToOnboarding(&state)

            case .view(.applicationBecameActive):
                // 실패한 등록만 재시도한다. 성공했거나 진행 중이면 서버 요청을 늘리지 않는다.
                guard state.deviceRegistration == .failed else { return .none }
                return registerDeviceIfNeeded(&state)

            case .effect(.deviceTokenRefreshed):
                // token이 갱신되면 최신 token으로 재등록한다. 진행 중이면 그 요청이 최신 token을 읽는다.
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
                state.projectRegistration = ProjectRegistrationFeature.State()
                return .none

            case .mainShell(.delegate(.questionSelected)),
                 .mainShell(.delegate(.projectDetailRequested)),
                 .mainShell(.delegate(.learningRequested)):
                return .none

            case .projectRegistration(.presented(.effect(.submissionFinished(.success(let receipt))))):
                // 생성 진행 상태의 수명은 등록 화면이 닫힌 뒤에도 이어지므로 App이 소유한다.
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
                    // 보존 상한을 넘긴 상태는 결과와 무관하게 해제한다.
                    return .run { [trackGenerationProgress] _ in await trackGenerationProgress.end() }
                }
                state.generationProgress = restored
                state.isGenerationProgressRestored = true
                state.mainShell.home.isGenerationInProgress = true
                return releaseGenerationProgress(restored)

            case .effect(.sharedRepositoryLinkReceived(let link)):
                // 생성이 진행 중이면 등록 화면을 열지 않고 버린다. 홈의 진행 중 표기가
                // 등록 화면이 열리지 않은 이유를 설명하는 피드백이 된다.
                guard state.generationProgress == nil else { return .none }
                guard state.route == .mainShell else {
                    // 미인증이면 진입 흐름을 마칠 때까지 메모리에 보관한다.
                    state.pendingSharedLink = link
                    return .none
                }
                state.pendingSharedLink = nil
                state.projectRegistration = ProjectRegistrationFeature.State(initialRepositoryURL: link.url)
                return .none

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
                // 복원된 상태는 결과가 도착하지 않을 수 있으므로, 최소 대기 시간이 지난 뒤
                // 해당 프로젝트가 목록에 나타나면 1차 해소 수단으로 해제한다.
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

            case .projectRegistration:
                return .none

            case .onboarding,
                 .mainShell:
                return .none
            }
        }
        .ifLet(\.$projectRegistration, action: \.projectRegistration) {
            ProjectRegistrationFeature(
                fetchExternalRepository: fetchExternalRepository,
                createLearningProject: createLearningProject,
                observeGenerationOutcomes: observeGenerationOutcomes,
                requestGenerationReminder: requestGenerationReminder,
                openNotificationSettings: openNotificationSettings,
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
    private let deleteLearningProject: any DeleteLearningProjectUseCase
    private let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase
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
    private let registerCurrentDevice: @Sendable () async throws -> Void
    private let deviceTokenRefreshes: @Sendable () -> AsyncStream<Void>
    private let deletesCompletedAccountOnSignIn: Bool
    private let resetAllForTesting: (@Sendable () async -> Void)?

    /// 동시에 도착한 재시도 trigger를 하나의 등록 요청으로 직렬화한다.
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

    /// 보관해 둔 공유 링크를 링크 입력 초기값으로 1회만 소비한다. 소비 여부와 무관하게
    /// 보관을 해제해 같은 링크가 다시 쓰이지 않게 한다.
    private func consumePendingSharedLink(_ state: inout State) -> Effect<Action> {
        guard let link = state.pendingSharedLink else { return .none }
        state.pendingSharedLink = nil
        guard state.generationProgress == nil else { return .none }
        state.projectRegistration = ProjectRegistrationFeature.State(initialRepositoryURL: link.url)
        return .none
    }

    /// 진행 상태를 `max(요청 + 최소 대기 시간, 결과 확정)` 시점에 해제한다. 결과가 끝내
    /// 도착하지 않으면 보존 상한에서 해제해 상태가 영구히 남지 않게 한다.
    private func releaseGenerationProgress(_ progress: GenerationProgress) -> Effect<Action> {
        .run { [observeGenerationOutcomes, waitPolicy, now] send in
            let deadline = progress.requestedAt.addingTimeInterval(waitPolicy.retentionLimit)

            // 결과 도착과 보존 상한 중 먼저 오는 쪽까지 기다린다.
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

            // 결과가 먼저 도착했다면 남은 최소 대기 시간만큼 더 유지한다.
            let remainingMinimum = waitPolicy.readyDate(for: progress).timeIntervalSince(now())
            if remainingMinimum > 0 {
                try? await Task.sleep(for: .seconds(remainingMinimum))
            }
            await send(.effect(.generationProgressReleased(projectID: progress.projectID)))
        }
        .cancellable(id: CancelID.generationProgress, cancelInFlight: true)
    }

    /// 인증 종료 경로의 단일 통로다. 등록 흐름 child와 그 child가 시작한 생성 결과 관찰,
    /// 그리고 진행 중인 기기 등록 Effect를 함께 제거한다.
    private func returnToOnboarding(_ state: inout State) -> Effect<Action> {
        let bundleVersion = state.onboarding.guide.bundleVersion
        state.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: bundleVersion)
        state.mainShell = MainShellFeature.State()
        state.projectRegistration = nil
        state.deviceRegistration = .idle
        state.generationProgress = nil
        state.isGenerationProgressRestored = false
        state.pendingSharedLink = nil
        state.route = .onboarding
        return .merge(
            .cancel(id: CancelID.deviceRegistration),
            .cancel(id: CancelID.generationProgress),
        )
    }

}
