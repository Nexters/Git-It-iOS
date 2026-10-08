import ComposableArchitecture
import DomainAccount
import DomainAppSetting
import DomainExternalRepository
import DomainIdentifier
import DomainProject
import DomainProjectGeneration
import DomainQuizDetail
import DomainUserInfo
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
            case signInVerified(SignInVerification)
            case deviceRegistrationSucceeded
            case deviceRegistrationFailed
            case deviceTokenRefreshed(String)
            case generationStateChanged(ProjectGenerationState)
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
            case .view(.task):
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
                )

            case .appEntry(.delegate(.destinationDecided(let destination))):
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

            case .appEntry:
                return .none

            case .effect(.signInVerified(.reauthenticationRequired)):
                guard state.route == .mainShell, state.mainShell.access == .member else { return .none }
                return returnToOnboarding(&state)

            case .effect(.signInVerified):
                return .none

            case .onboarding(.delegate(.mainShellRequested)):
                state.route = .mainShell
                guard state.mainShell.access == .guest else { return registerDeviceIfNeeded(&state) }
                return .merge(
                    .send(.mainShell(.input(.memberAccessGranted))),
                    registerDeviceIfNeeded(&state),
                )

            case .onboarding(.delegate(.guestAccessRequested)):
                state.mainShell = MainShellRouterFeature.State(access: .guest)
                state.route = .mainShell
                return .none

            case .onboarding(.delegate(.curationAbandoned)):
                state.route = .mainShell
                return .none

            case .mainShell(.delegate(.signInSucceeded(let needsCuration))):
                guard needsCuration else {
                    return .merge(
                        .send(.mainShell(.input(.memberAccessGranted))),
                        registerDeviceIfNeeded(&state),
                    )
                }
                let bundleVersion = state.onboarding.tutorial.bundleVersion
                state.onboarding = OnboardingRouterFeature.State(
                    startingAt: .curation,
                    bundleVersion: bundleVersion,
                    curationExit: .returnToCaller,
                )
                state.route = .onboarding
                return .none

            case .mainShell(.delegate(.loggedOut)):
                return returnToOnboarding(&state)

            case .view(.applicationBecameActive):
                guard state.mainShell.access == .member else { return .none }
                var effects: [Effect<Action>] = [
                    .run { [account] send in
                        await send(.effect(.signInVerified(account.verifySignIn())))
                    }
                ]
                if state.route == .mainShell {
                    effects.append(.send(.mainShell(.input(.learningProjectsReloadRequested))))
                }
                if state.deviceRegistration == .failed {
                    effects.append(registerDeviceIfNeeded(&state))
                }
                return .merge(effects)

            case .effect(.deviceTokenRefreshed(let token)):
                guard state.route == .mainShell, state.mainShell.access == .member else { return .none }
                return .merge(
                    .run { [appSetting] _ in try? await appSetting.updateDeviceToken(token) },
                    registerDeviceIfNeeded(&state),
                )

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

            case .projectDetail(.presented(.delegate(.learningSetRequested(let projectID, let setID, let label)))):
                state.quiz = QuizRouterFeature.State(
                    projectID: projectID,
                    setID: setID,
                    setLabel: label,
                )
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

            case .quiz(.presented(.delegate(.dismissRequested(let projectID)))):
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

            case .projectDetail,
                 .quiz:
                return .none

            case .effect(.generationStateChanged(let generationState)):
                return applyGenerationState(
                    generationState,
                    state: &state,
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

    private func applyGenerationState(
        _ generationState: ProjectGenerationState,
        state: inout State,
    ) -> Effect<Action> {
        let isGenerationInProgress = generationState.requests.contains { request in
            switch request.phase {
            case .inProgress,
                 .preparing:
                true

            case .ready,
                 .failed:
                false
            }
        }
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
