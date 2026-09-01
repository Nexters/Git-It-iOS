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
                )

            case .appEntry(.delegate(.destinationDecided(let destination))):
                switch destination {
                case .mainShell:
                    state.route = .mainShell
                    return registerDeviceIfNeeded(&state)

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
                return registerDeviceIfNeeded(&state)

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

    /// 인증 종료 경로의 단일 통로다. 등록 흐름 child와 그 child가 시작한 생성 결과 관찰,
    /// 그리고 진행 중인 기기 등록 Effect를 함께 제거한다.
    private func returnToOnboarding(_ state: inout State) -> Effect<Action> {
        let bundleVersion = state.onboarding.guide.bundleVersion
        state.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: bundleVersion)
        state.mainShell = MainShellFeature.State()
        state.projectRegistration = nil
        state.deviceRegistration = .idle
        state.route = .onboarding
        return .cancel(id: CancelID.deviceRegistration)
    }

}
