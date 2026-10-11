import ComposableArchitecture
import DomainUseCaseInterface
import Feature
import Foundation

// MARK: - AppRootFeature

@Reducer
nonisolated struct AppRootFeature: Sendable {

    // MARK: Lifecycle

    init(
        account: any AccountUseCase,
        userInfo: any UserInfoUseCase,
        appSetting: any AppSettingUseCase,
        externalRepository: any ExternalRepositoryUseCase,
        quizDetail: any QuizDetailUseCase,
        project: any ProjectUseCase,
        projectGeneration: any ProjectGenerationUseCase,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
        openExternalURL: @escaping @Sendable (URL) async -> Void = { _ in },
        deviceTokenRefreshes: @escaping @Sendable () -> AsyncStream<String>,
        deletesCompletedAccountOnSignIn: Bool = false,
    ) {
        self.account = account
        self.userInfo = userInfo
        self.appSetting = appSetting
        self.externalRepository = externalRepository
        self.quizDetail = quizDetail
        self.project = project
        self.projectGeneration = projectGeneration
        self.openNotificationSettings = openNotificationSettings
        self.openExternalURL = openExternalURL
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
            onboarding = OnboardingRouterFeature.State(
                startingAt: .guide,
                bundleVersion: bundleVersion,
            )
        }

        var route = Route.restoring
        var appEntry: AppEntryFeature.State
        var onboarding: OnboardingRouterFeature.State
        var mainShell = MainShellRouterFeature.State()
        var deviceRegistration = DeviceRegistrationStatus.idle
        var isInBackground = false

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
            case applicationEnteredBackground
        }

        @CasePathable
        enum EffectEvent: Sendable, Equatable {
            case signInVerified(SignInVerification)
            case deviceRegistrationSucceeded
            case deviceRegistrationFailed
            case deviceTokenRefreshed(String)
            case generationStateChanged(ProjectGenerationState)
            case generationOutcomeArrived(ProjectID)
            case learningProjectsRefreshFinished(error: ProjectError?)
        }
    }

    var body: some ReducerOf<Self> {
        Scope(
            state: \.appEntry,
            action: \.appEntry,
        ) {
            AppEntryFeature(
                restoreSignIn: { [account] in await account.restoreSignIn() },
                curation: { [userInfo] in try await userInfo.curation() },
                signOut: { [account] in await account.signOut() },
            )
        }
        Scope(
            state: \.onboarding,
            action: \.onboarding,
        ) {
            OnboardingRouterFeature(
                signIn: { [account] in await account.signIn(with: $0) },
                signOut: { [account] in await account.signOut() },
                policyConsentStatus: { [account] in try await account.policyConsentStatus() },
                consent: { [account] in try await account.consent(to: $0) },
                updateCuration: { [userInfo] in try await userInfo.updateCuration($0) },
                withdraw: { [account] in try await account.withdraw() },
                deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
            )
        }
        Scope(
            state: \.mainShell,
            action: \.mainShell,
        ) {
            MainShellRouterFeature(
                project: project,
                quizDetail: quizDetail,
                account: account,
                userInfo: userInfo,
                appSetting: appSetting,
                openNotificationSettings: openNotificationSettings,
            )
        }
        Reduce { state, action in
            switch action {
            case .view(let action):
                reduce(
                    into: &state,
                    view: action,
                )

            case .effect(let event):
                reduce(
                    into: &state,
                    effect: event,
                )

            case .appEntry(let action):
                reduce(
                    into: &state,
                    appEntry: action,
                )

            case .onboarding(let action):
                reduce(
                    into: &state,
                    onboarding: action,
                )

            case .mainShell(let action):
                reduce(
                    into: &state,
                    mainShell: action,
                )

            case .projectRegistration(let action):
                reduce(
                    into: &state,
                    projectRegistration: action,
                )

            case .projectDetail(let action):
                reduce(
                    into: &state,
                    projectDetail: action,
                )

            case .quiz(let action):
                reduce(
                    into: &state,
                    quiz: action,
                )
            }
        }
        .ifLet(
            \.$projectRegistration,
            action: \.projectRegistration,
        ) {
            ProjectRegistrationRouterFeature(
                externalRepository: externalRepository,
                projectGeneration: projectGeneration,
                appSetting: appSetting,
                openNotificationSettings: openNotificationSettings,
            )
        }
        .ifLet(
            \.$projectDetail,
            action: \.projectDetail,
        ) {
            ProjectDetailRouterFeature(
                project: project,
                quizDetail: quizDetail,
            )
        }
        .ifLet(
            \.$quiz,
            action: \.quiz,
        ) {
            QuizRouterFeature(quizDetail: quizDetail)
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case deviceRegistration
        case deviceTokenRefreshes
        case generationObservation
        case generationOutcomeObservation
        case learningProjectsRefresh
    }

    private let account: any AccountUseCase
    private let userInfo: any UserInfoUseCase
    private let appSetting: any AppSettingUseCase
    private let externalRepository: any ExternalRepositoryUseCase
    private let quizDetail: any QuizDetailUseCase
    private let project: any ProjectUseCase
    private let projectGeneration: any ProjectGenerationUseCase
    private let openNotificationSettings: @MainActor @Sendable () async -> Void
    private let openExternalURL: @Sendable (URL) async -> Void
    private let deviceTokenRefreshes: @Sendable () -> AsyncStream<String>
    private let deletesCompletedAccountOnSignIn: Bool

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .task:
            guard state.route == .restoring else { return .none }
            return .merge(
                .send(.appEntry(.view(.task))),
                .run { send in
                    for await token in deviceTokenRefreshes() {
                        await send(.effect(.deviceTokenRefreshed(token)))
                    }
                }
                .cancellable(id: CancelID.deviceTokenRefreshes),
                .run { [projectGeneration] send in
                    for await generationState in await projectGeneration.states() {
                        await send(.effect(.generationStateChanged(generationState)))
                    }
                }
                .cancellable(id: CancelID.generationObservation),
                .run { [projectGeneration] send in
                    for await projectID in await projectGeneration.outcomeArrivals() {
                        await send(.effect(.generationOutcomeArrived(projectID)))
                    }
                }
                .cancellable(id: CancelID.generationOutcomeObservation),
            )

        case .applicationBecameActive:
            let returnedFromBackground = state.isInBackground
            state.isInBackground = false
            guard state.mainShell.access == .member else { return .none }
            var effects: [Effect<Action>] = [
                .run { [account] send in
                    await send(.effect(.signInVerified(account.verifySignIn())))
                },
                .run { [projectGeneration] _ in
                    await projectGeneration.synchronize()
                },
            ]
            if returnedFromBackground, state.route == .mainShell {
                effects.append(refreshLearningProjects())
            }
            if state.deviceRegistration == .failed {
                effects.append(registerDeviceIfNeeded(&state))
            }
            return .merge(effects)

        case .applicationEnteredBackground:
            state.isInBackground = true
            return .none
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .signInVerified(let verification):
            guard
                verification == .reauthenticationRequired,
                state.route == .mainShell,
                state.mainShell.access == .member
            else { return .none }
            return returnToOnboarding(&state)

        case .deviceRegistrationSucceeded:
            state.deviceRegistration = .registered
            return .none

        case .deviceRegistrationFailed:
            state.deviceRegistration = .failed
            return .none

        case .deviceTokenRefreshed(let token):
            guard state.route == .mainShell, state.mainShell.access == .member else { return .none }
            return .merge(
                .run { [appSetting] _ in try? await appSetting.updateDeviceToken(token) },
                registerDeviceIfNeeded(&state),
            )

        case .generationStateChanged(let generationState):
            return applyGenerationState(
                generationState,
                state: &state,
            )

        case .generationOutcomeArrived:
            guard
                !state.isInBackground,
                state.route == .mainShell,
                state.mainShell.access == .member
            else { return .none }
            return refreshLearningProjects()

        case .learningProjectsRefreshFinished:
            return .none
        }
    }

    private func reduce(
        into state: inout State,
        appEntry action: AppEntryFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .destinationDecided(let destination):
            switch destination {
            case .mainShell:
                state.route = .mainShell
                return registerDeviceIfNeeded(&state)

            case .onboarding(let entryPoint):
                let bundleVersion = state.onboarding.tutorial.bundleVersion
                state.onboarding = OnboardingRouterFeature.State(
                    startingAt: entryPoint,
                    bundleVersion: bundleVersion,
                )
                state.route = .onboarding
                return .none
            }
        }
    }

    private func reduce(
        into state: inout State,
        onboarding action: OnboardingRouterFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .mainShellRequested:
            state.route = .mainShell
            guard state.mainShell.access == .guest else { return registerDeviceIfNeeded(&state) }
            return .merge(
                .send(.mainShell(.input(.memberAccessGranted))),
                registerDeviceIfNeeded(&state),
            )

        case .guestAccessRequested:
            state.mainShell = MainShellRouterFeature.State(access: .guest)
            state.route = .mainShell
            return .none

        case .curationAbandoned:
            state.route = .mainShell
            return .none
        }
    }

    private func reduce(
        into state: inout State,
        mainShell action: MainShellRouterFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .onboardingRequested:
            guard state.mainShell.access == .guest else { return .none }
            let bundleVersion = state.onboarding.tutorial.bundleVersion
            state.onboarding = OnboardingRouterFeature.State(
                startingAt: .guide,
                bundleVersion: bundleVersion,
            )
            state.route = .onboarding
            return .none

        case .loggedOut:
            return returnToOnboarding(&state)

        case .projectRegistrationRequested:
            state.projectRegistration = ProjectRegistrationRouterFeature.State()
            return .none

        case .projectDetailRequested(let projectID):
            state.projectDetail = ProjectDetailRouterFeature.State(projectID: projectID)
            return .none

        case .learningRequested(let projectID, let nextSetID):
            guard
                let summary = loadedProject(
                    projectID: projectID,
                    state: state,
                )
            else { return .none }
            state.projectDetail = ProjectDetailRouterFeature.State(projectID: projectID)
            state.quiz = QuizRouterFeature.State(
                projectID: projectID,
                setID: nextSetID,
                setLabel: summary.currentSet.label,
                autoStartsLearning: true,
            )
            return .none

        case .externalURLRequested(let url):
            return .run { [openExternalURL] _ in await openExternalURL(url) }
        }
    }

    private func reduce(
        into state: inout State,
        projectRegistration action: PresentationAction<ProjectRegistrationRouterFeature.Action>,
    ) -> Effect<Action> {
        guard
            case .presented(let action) = action,
            case .delegate(let action) = action
        else {
            return .none
        }
        switch action {
        case .projectRegistered:
            state.projectRegistration = nil
            return .send(.mainShell(.input(.learningProjectsReloadRequested)))

        case .dismissRequested:
            state.projectRegistration = nil
            return .none
        }
    }

    private func reduce(
        into state: inout State,
        projectDetail action: PresentationAction<ProjectDetailRouterFeature.Action>,
    ) -> Effect<Action> {
        guard
            case .presented(let action) = action,
            case .delegate(let action) = action
        else {
            return .none
        }
        switch action {
        case .learningSetRequested(let projectID, let setID, let label):
            state.quiz = QuizRouterFeature.State(
                projectID: projectID,
                setID: setID,
                setLabel: label,
            )
            return .none

        case .externalURLRequested(let url):
            return .run { [openExternalURL] _ in await openExternalURL(url) }

        case .projectDeleted:
            state.projectDetail = nil
            return .send(.mainShell(.input(.learningProjectsReloadRequested)))

        case .dismissRequested:
            state.projectDetail = nil
            return .none
        }
    }

    private func reduce(
        into state: inout State,
        quiz action: PresentationAction<QuizRouterFeature.Action>,
    ) -> Effect<Action> {
        guard
            case .presented(let action) = action,
            case .delegate(let action) = action
        else {
            return .none
        }
        switch action {
        case .externalURLRequested(let url):
            return .run { [openExternalURL] _ in await openExternalURL(url) }

        case .dismissRequested(let projectID):
            state.quiz = nil
            let refreshProjects = Effect<Action>.run { [project] _ in try? await project.refresh() }
            guard state.projectDetail?.projectID == projectID else {
                state.projectDetail = ProjectDetailRouterFeature.State(projectID: projectID)
                return refreshProjects
            }
            return .merge(
                refreshProjects,
                .send(.projectDetail(.presented(.projectDetail(.input(.refreshRequested))))),
            )
        }
    }

    private func loadedProject(
        projectID: ProjectID,
        state: State,
    ) -> ProjectSummary? {
        if
            case .loaded(let list) = state.mainShell.home.projectSummaries.load,
            let summary = list.summaries.first(where: { $0.id == projectID })
        {
            return summary
        }
        return state.mainShell.projectList.projects.first { $0.id == projectID }
    }

    private func registerDeviceIfNeeded(_ state: inout State) -> Effect<Action> {
        guard state.deviceRegistration != .registering else { return .none }
        state.deviceRegistration = .registering
        return .run { [appSetting] send in
            do {
                try await appSetting.registerDevice()
                await send(.effect(.deviceRegistrationSucceeded))
            } catch {
                await send(.effect(.deviceRegistrationFailed))
            }
        }
        .cancellable(id: CancelID.deviceRegistration)
    }

    private func refreshLearningProjects() -> Effect<Action> {
        .run { [project] send in
            do {
                try await project.refreshReplacingInFlightRequest()
                await send(.effect(.learningProjectsRefreshFinished(error: nil)))
            } catch {
                let mapped = error as? ProjectError ?? .unexpected
                await send(.effect(.learningProjectsRefreshFinished(error: mapped)))
            }
        }
        .cancellable(
            id: CancelID.learningProjectsRefresh,
            cancelInFlight: true,
        )
    }

    private func applyGenerationState(
        _ generationState: ProjectGenerationState,
        state: inout State,
    ) -> Effect<Action> {
        let isGenerationInProgress = generationState.hasRequestInProgress
        guard state.mainShell.home.isGenerationInProgress != isGenerationInProgress else { return .none }
        return .send(.mainShell(.home(.input(.generationProgressChanged(isInProgress: isGenerationInProgress)))))
    }

    private func returnToOnboarding(_ state: inout State) -> Effect<Action> {
        let bundleVersion = state.onboarding.tutorial.bundleVersion
        state.onboarding = OnboardingRouterFeature.State(
            startingAt: .guide,
            bundleVersion: bundleVersion,
        )
        state.mainShell = MainShellRouterFeature.State()
        state.projectRegistration = nil
        state.projectDetail = nil
        state.quiz = nil
        state.deviceRegistration = .idle
        state.route = .onboarding
        return .cancel(id: CancelID.deviceRegistration)
    }

}
