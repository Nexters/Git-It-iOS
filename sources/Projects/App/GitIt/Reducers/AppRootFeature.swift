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
        learningProjectOutcomes: any LearningProjectOutcomesUseCase,
        openNotificationSettings: @escaping @Sendable () async -> Void = { },
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
        self.learningProjectOutcomes = learningProjectOutcomes
        self.openNotificationSettings = openNotificationSettings
        self.deletesCompletedAccountOnSignIn = deletesCompletedAccountOnSignIn
        self.resetAllForTesting = resetAllForTesting
    }

    // MARK: Internal

    enum Route: Equatable, Sendable {
        case restoring
        case onboarding
        case mainShell
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
        @Presents var projectRegistration: ProjectRegistrationFeature.State?
    }

    enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case appEntry(AppEntryFeature.Action)
        case onboarding(OnboardingRouterFeature.Action)
        case mainShell(MainShellFeature.Action)
        case projectRegistration(PresentationAction<ProjectRegistrationFeature.Action>)

        @CasePathable
        enum View: Sendable, Equatable {
            case task
            case resetAllTapped
        }

        @CasePathable
        enum EffectEvent: Sendable, Equatable {
            case authenticationOutcomeReceived(AuthenticationOutcome)
            case resetAllFinished
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
                learningProjectOutcomes: learningProjectOutcomes,
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
                )

            case .appEntry(.delegate(.destinationDecided(let destination))):
                switch destination {
                case .mainShell:
                    state.route = .mainShell

                case .onboarding(let entryPoint):
                    let bundleVersion = state.onboarding.guide.bundleVersion
                    state.onboarding = OnboardingRouterFeature.State(startingAt: entryPoint, bundleVersion: bundleVersion)
                    state.route = .onboarding
                }
                return .none

            case .appEntry:
                return .none

            case .effect(.authenticationOutcomeReceived(.unauthenticated)):
                guard state.route == .mainShell else { return .none }
                returnToOnboarding(&state)
                return .none

            case .effect(.authenticationOutcomeReceived):
                return .none

            case .onboarding(.delegate(.mainShellRequested)):
                state.route = .mainShell
                return .none

            case .mainShell(.delegate(.loggedOut)):
                returnToOnboarding(&state)
                return .none

            case .view(.resetAllTapped):
                guard let resetAllForTesting else { return .none }
                return .run { send in
                    await resetAllForTesting()
                    await send(.effect(.resetAllFinished))
                }
                .cancellable(id: CancelID.resetAll, cancelInFlight: true)

            case .effect(.resetAllFinished):
                returnToOnboarding(&state)
                return .none

            case .mainShell(.delegate(.projectRegistrationRequested)):
                state.projectRegistration = ProjectRegistrationFeature.State()
                return .none

            case .mainShell(.delegate(.projectSelected)),
                 .mainShell(.delegate(.questionSelected)),
                 .mainShell(.delegate(.projectDetailRequested)),
                 .mainShell(.delegate(.learningRequested)):
                return .none

            case .projectRegistration(.presented(.delegate(.projectRegistered(_)))):
                state.projectRegistration = nil
                return .send(.mainShell(.home(.view(.reloadRequested))))

            case .projectRegistration(.presented(.delegate(.notificationOptionSelected(_)))):
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
                learningProjectOutcomes: learningProjectOutcomes,
                openNotificationSettings: openNotificationSettings,
            )
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case authenticationOutcomes
        case resetAll
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
    private let learningProjectOutcomes: any LearningProjectOutcomesUseCase
    private let openNotificationSettings: @Sendable () async -> Void
    private let deletesCompletedAccountOnSignIn: Bool
    private let resetAllForTesting: (@Sendable () async -> Void)?

    private func returnToOnboarding(_ state: inout State) {
        let bundleVersion = state.onboarding.guide.bundleVersion
        state.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: bundleVersion)
        state.mainShell = MainShellFeature.State()
        state.route = .onboarding
    }

}
