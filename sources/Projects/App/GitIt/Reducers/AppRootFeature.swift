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
        verifyAuthorization: any VerifyAuthorizationUseCase,
        memberAccount: any MemberAccountUseCase,
        policyConsent: any PolicyConsentUseCase,
        fetchLearningProjects: any FetchLearningProjectsUseCase,
        fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase,
        deleteLearningProject: any DeleteLearningProjectUseCase,
        fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase,
        fetchLearningSet: any FetchLearningSetUseCase,
        submitChoiceAnswer: any SubmitChoiceAnswerUseCase,
        submitEssayAnswer: any SubmitEssayAnswerUseCase,
        setQuestionBookmark: any SetQuestionBookmarkUseCase,
        deleteMemberAccount: any DeleteMemberAccountUseCase,
        fetchExternalRepository: any FetchExternalRepositoryUseCase,
        createLearningProject: any CreateLearningProjectUseCase,
        requestGenerationReminder: any RequestGenerationReminderUseCase,
        trackGeneration: any TrackGenerationUseCase,
        waitPolicy: GenerationWaitPolicy = .standard,
        now: @escaping @Sendable () -> Date = { Date() },
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
        openExternalURL: @escaping @Sendable (URL) async -> Void = { _ in },
        registerCurrentDevice: @escaping @Sendable () async throws -> Void = { },
        deviceTokenRefreshes: @escaping @Sendable () -> AsyncStream<String>,
        deletesCompletedAccountOnSignIn: Bool = false,
    ) {
        self.restoreSession = restoreSession
        self.signIn = signIn
        self.signOut = signOut
        self.verifyAuthorization = verifyAuthorization
        self.memberAccount = memberAccount
        self.policyConsent = policyConsent
        self.fetchLearningProjects = fetchLearningProjects
        self.fetchLearningProjectDetail = fetchLearningProjectDetail
        self.deleteLearningProject = deleteLearningProject
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
        self.fetchLearningSet = fetchLearningSet
        self.submitChoiceAnswer = submitChoiceAnswer
        self.submitEssayAnswer = submitEssayAnswer
        self.setQuestionBookmark = setQuestionBookmark
        self.deleteMemberAccount = deleteMemberAccount
        self.fetchExternalRepository = fetchExternalRepository
        self.createLearningProject = createLearningProject
        self.requestGenerationReminder = requestGenerationReminder
        self.trackGeneration = trackGeneration
        self.waitPolicy = waitPolicy
        self.now = now
        self.openNotificationSettings = openNotificationSettings
        self.openExternalURL = openExternalURL
        self.registerCurrentDevice = registerCurrentDevice
        self.deviceTokenRefreshes = deviceTokenRefreshes
        self.deletesCompletedAccountOnSignIn = deletesCompletedAccountOnSignIn
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

        var generationRecord: GenerationRecord?

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
            case applicationBecameActive
        }

        @CasePathable
        enum EffectEvent: Sendable, Equatable {
            case authorizationVerified(AuthorizationStatus)
            case deviceRegistrationSucceeded
            case deviceRegistrationFailed
            case deviceTokenRefreshed
            case generationStateChanged(GenerationState)
            case generationReleased(githubRepoURL: String)
        }
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.appEntry, action: \.appEntry) {
            AppEntryFeature(
                restoreSession: restoreSession,
                fetchMemberProfile: { [memberAccount] in try await memberAccount.profile() },
                signOut: signOut,
            )
        }
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingRouterFeature(
                signIn: signIn,
                signOut: signOut,
                policyConsent: policyConsent,
                memberAccount: memberAccount,
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
                memberAccount: memberAccount,
                deleteMemberAccount: deleteMemberAccount,
                trackGeneration: trackGeneration,
                requestGenerationReminder: requestGenerationReminder,
                openNotificationSettings: openNotificationSettings,
            )
        }
        Reduce { state, action in
            switch action {
            case .view(.task):
                guard state.route == .restoring else { return .none }
                return .merge(
                    .send(.appEntry(.view(.task))),
                    .run { send in
                        for await _ in deviceTokenRefreshes() {
                            await send(.effect(.deviceTokenRefreshed))
                        }
                    }
                    .cancellable(id: CancelID.deviceTokenRefreshes),
                    .run { [trackGeneration] send in
                        for await generationState in await trackGeneration.states() {
                            await send(.effect(.generationStateChanged(generationState)))
                        }
                    }
                    .cancellable(id: CancelID.generationObservation),
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

            case .effect(.authorizationVerified(.reauthenticationRequired)):
                guard state.route == .mainShell else { return .none }
                return returnToOnboarding(&state)

            case .effect(.authorizationVerified):
                return .none

            case .onboarding(.delegate(.mainShellRequested)):
                state.route = .mainShell
                return registerDeviceIfNeeded(&state)

            case .mainShell(.delegate(.loggedOut)):
                return returnToOnboarding(&state)

            case .view(.applicationBecameActive):
                var effects: [Effect<Action>] = [
                    .run { [verifyAuthorization] send in
                        await send(.effect(.authorizationVerified(verifyAuthorization())))
                    },
                ]
                if state.route == .mainShell {
                    effects.append(.send(.mainShell(.input(.learningProjectsReloadRequested))))
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
                return .send(.mainShell(.input(.learningProjectsReloadRequested)))

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

            case .effect(.generationStateChanged(let generationState)):
                return applyGenerationState(generationState, state: &state)

            case .effect(.generationReleased(let githubRepoURL)):
                guard state.generationRecord?.githubRepoURL == githubRepoURL else { return .none }
                state.generationRecord = nil
                state.mainShell.home.isGenerationInProgress = false
                return .merge(
                    .cancel(id: CancelID.generationRelease),
                    .run { [trackGeneration] _ in await trackGeneration.end(githubRepoURL: githubRepoURL) },
                )

            case .projectRegistration(.presented(.delegate(.projectRegistered(_)))):
                state.projectRegistration = nil
                return .send(.mainShell(.input(.learningProjectsReloadRequested)))

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
                trackGeneration: trackGeneration,
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
        case deviceRegistration
        case deviceTokenRefreshes
        case generationObservation
        case generationRelease
    }

    private let restoreSession: any RestoreSessionUseCase
    private let signIn: any SignInUseCase
    private let signOut: any SignOutUseCase
    private let verifyAuthorization: any VerifyAuthorizationUseCase
    private let memberAccount: any MemberAccountUseCase
    private let policyConsent: any PolicyConsentUseCase
    private let fetchLearningProjects: any FetchLearningProjectsUseCase
    private let fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase
    private let deleteLearningProject: any DeleteLearningProjectUseCase
    private let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase
    private let fetchLearningSet: any FetchLearningSetUseCase
    private let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    private let submitEssayAnswer: any SubmitEssayAnswerUseCase
    private let setQuestionBookmark: any SetQuestionBookmarkUseCase
    private let deleteMemberAccount: any DeleteMemberAccountUseCase
    private let fetchExternalRepository: any FetchExternalRepositoryUseCase
    private let createLearningProject: any CreateLearningProjectUseCase
    private let requestGenerationReminder: any RequestGenerationReminderUseCase
    private let trackGeneration: any TrackGenerationUseCase
    private let waitPolicy: GenerationWaitPolicy
    private let now: @Sendable () -> Date
    private let openNotificationSettings: @MainActor @Sendable () async -> Void
    private let openExternalURL: @Sendable (URL) async -> Void
    private let registerCurrentDevice: @Sendable () async throws -> Void
    private let deviceTokenRefreshes: @Sendable () -> AsyncStream<String>
    private let deletesCompletedAccountOnSignIn: Bool

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

    private func applyGenerationState(
        _ generationState: GenerationState,
        state: inout State,
    ) -> Effect<Action> {
        let reference = now()
        let expired = generationState.records.filter { waitPolicy.isExpired($0, now: reference) }
        let endExpired: Effect<Action> = expired.isEmpty
            ? .none
            : .run { [trackGeneration] _ in
                for record in expired {
                    await trackGeneration.end(githubRepoURL: record.githubRepoURL)
                }
            }

        let waiting = generationState.records.first { record in
            guard !waitPolicy.isExpired(record, now: reference) else { return false }
            return record.status == .inProgress || waitPolicy.readyDate(for: record) > reference
        }

        guard let waiting else {
            guard state.generationRecord != nil else { return endExpired }
            state.generationRecord = nil
            state.mainShell.home.isGenerationInProgress = false
            return .merge(.cancel(id: CancelID.generationRelease), endExpired)
        }

        guard state.generationRecord != waiting else { return endExpired }
        state.generationRecord = waiting
        state.mainShell.home.isGenerationInProgress = true
        return .merge(releaseGeneration(waiting), endExpired)
    }

    private func releaseGeneration(_ record: GenerationRecord) -> Effect<Action> {
        .run { [waitPolicy, now] send in
            let remaining = waitPolicy.readyDate(for: record).timeIntervalSince(now())
            if remaining > 0 {
                try? await Task.sleep(for: .seconds(remaining))
            }
            await send(.effect(.generationReleased(githubRepoURL: record.githubRepoURL)))
        }
        .cancellable(id: CancelID.generationRelease, cancelInFlight: true)
    }

    private func returnToOnboarding(_ state: inout State) -> Effect<Action> {
        let bundleVersion = state.onboarding.tutorial.bundleVersion
        state.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: bundleVersion)
        state.mainShell = MainShellRouterFeature.State()
        state.projectRegistration = nil
        state.projectDetail = nil
        state.quiz = nil
        state.deviceRegistration = .idle
        state.generationRecord = nil
        state.route = .onboarding
        return .merge(
            .cancel(id: CancelID.deviceRegistration),
            .cancel(id: CancelID.generationRelease),
        )
    }

}
