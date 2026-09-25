import ComposableArchitecture
import DomainAccount
import DomainUserInfo
import Foundation

@Reducer
public struct OnboardingRouterFeature: Sendable {

    // MARK: Lifecycle

    public init(
        signIn: @escaping @Sendable (SignInMethod) async -> SignInResult,
        signOut: @escaping @Sendable () async -> SignOutResult,
        policyConsentStatus: @escaping @Sendable () async throws -> PolicyConsentStatus,
        consent: @escaping @Sendable ([PolicyDocumentID]) async throws -> Void,
        updateCuration: @escaping @Sendable (Curation) async throws -> Void,
        withdraw: @escaping @Sendable () async throws -> Void,
        deletesCompletedAccountOnSignIn: Bool = false,
    ) {
        self.signIn = signIn
        self.signOut = signOut
        self.policyConsentStatus = policyConsentStatus
        self.consent = consent
        self.updateCuration = updateCuration
        self.withdraw = withdraw
        self.deletesCompletedAccountOnSignIn = deletesCompletedAccountOnSignIn
    }

    // MARK: Public

    public enum ActiveScreen: Hashable, Sendable {
        case guide(Guide)
        case curation(Curation)
        case curationSplash

        public enum Guide: Hashable, Sendable {
            case tutorial
        }

        public enum Curation: Hashable, Sendable {
            case positionSelection
            case careerSelection
        }
    }

    public struct ScreenTransitionEvent: Equatable, Sendable {
        public let from: ActiveScreen
        public let to: ActiveScreen
        public let trigger: String
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            startingAt entryPoint: OnboardingEntryPoint,
            bundleVersion: String,
            curationExit: CurationExit = .returnToTutorial,
        ) {
            switch entryPoint {
            case .guide:
                activeScreen = .guide(.tutorial)

            case .curation:
                activeScreen = .curation(.positionSelection)
            }
            tutorial = TutorialFeature.State(bundleVersion: bundleVersion)
            self.curationExit = curationExit
        }

        // MARK: Public

        public internal(set) var activeScreen: ActiveScreen
        public var tutorial: TutorialFeature.State
        public var positionSelection = PositionSelectionFeature.State()
        public var careerSelection = CareerSelectionFeature.State()
        public var exit = OnboardingExitFeature.State()
        public let curationExit: CurationExit
        public internal(set) var transitionLog = [ScreenTransitionEvent]()

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case tutorial(TutorialFeature.Action)
        case positionSelection(PositionSelectionFeature.Action)
        case careerSelection(CareerSelectionFeature.Action)
        case exit(OnboardingExitFeature.Action)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case curationSplashFinished
            case legalAgreementDismissed
            case legalDocumentSheetDismissed
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case mainShellRequested
            case guestAccessRequested
            case curationAbandoned
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(
            state: \.tutorial,
            action: \.tutorial,
        ) {
            TutorialFeature(
                signIn: signIn,
                policyConsentStatus: policyConsentStatus,
                consent: consent,
                withdraw: withdraw,
                deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
            )
        }
        Scope(
            state: \.positionSelection,
            action: \.positionSelection,
        ) {
            PositionSelectionFeature(signOut: signOut)
        }
        Scope(
            state: \.careerSelection,
            action: \.careerSelection,
        ) {
            CareerSelectionFeature(updateCuration: updateCuration)
        }
        Scope(
            state: \.exit,
            action: \.exit,
        ) {
            OnboardingExitFeature()
        }
        Reduce { state, action in
            let before = state.activeScreen

            let effect: Effect<Action> =
                switch action {
                case .view(let action):
                    reduce(
                        into: &state,
                        view: action,
                    )

                case .tutorial(let action):
                    reduce(
                        into: &state,
                        tutorial: action,
                    )

                case .positionSelection(let action):
                    reduce(
                        into: &state,
                        positionSelection: action,
                    )

                case .careerSelection(let action):
                    reduce(
                        into: &state,
                        careerSelection: action,
                    )

                case .exit(let action):
                    reduce(
                        into: &state,
                        exit: action,
                    )

                case .delegate:
                    .none
                }

            if state.activeScreen != before {
                state.transitionLog.append(
                    ScreenTransitionEvent(
                        from: before,
                        to: state.activeScreen,
                        trigger: String(describing: action),
                    )
                )
            }

            return effect
        }
    }

    // MARK: Private

    private let signIn: @Sendable (SignInMethod) async -> SignInResult
    private let signOut: @Sendable () async -> SignOutResult
    private let policyConsentStatus: @Sendable () async throws -> PolicyConsentStatus
    private let consent: @Sendable ([PolicyDocumentID]) async throws -> Void
    private let updateCuration: @Sendable (Curation) async throws -> Void
    private let withdraw: @Sendable () async throws -> Void
    private let deletesCompletedAccountOnSignIn: Bool

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .curationSplashFinished:
            guard state.activeScreen == .curationSplash else { return .none }
            return .send(.delegate(.mainShellRequested))

        case .legalAgreementDismissed:
            return .send(.tutorial(.signIn(.view(.legalAgreementDismissed))))

        case .legalDocumentSheetDismissed:
            return .send(.tutorial(.signIn(.view(.legalDocumentSheetDismissed))))
        }
    }

    private func reduce(
        into state: inout State,
        tutorial action: TutorialFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .guestAccessRequested:
            return .send(.delegate(.guestAccessRequested))

        case .signInSucceeded(let needsCuration):
            return advanceAfterSignIn(
                needsCuration: needsCuration,
                state: &state,
            )
        }
    }

    private func reduce(
        into state: inout State,
        positionSelection action: PositionSelectionFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .confirmed(let position):
            state.activeScreen = .curation(.careerSelection)
            return .send(.careerSelection(.input(.positionProvided(position))))

        case .exitRequested:
            state.positionSelection = PositionSelectionFeature.State()
            state.careerSelection = CareerSelectionFeature.State()
            switch state.curationExit {
            case .returnToTutorial:
                state.activeScreen = .guide(.tutorial)
                return .send(.tutorial(.input(.returnToLastPage)))

            case .returnToCaller:
                return .send(.delegate(.curationAbandoned))
            }
        }
    }

    private func reduce(
        into state: inout State,
        careerSelection action: CareerSelectionFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .backRequested:
            state.activeScreen = .curation(.positionSelection)
            return .none

        case .curationSucceeded:
            return .send(.exit(.input(.curationSucceeded)))
        }
    }

    private func reduce(
        into state: inout State,
        exit action: OnboardingExitFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .shouldExit:
            state.activeScreen = .curationSplash
            return .none
        }
    }

    private func advanceAfterSignIn(
        needsCuration: Bool,
        state: inout State,
    ) -> Effect<Action> {
        guard needsCuration else { return .send(.delegate(.mainShellRequested)) }
        state.positionSelection = PositionSelectionFeature.State()
        state.careerSelection = CareerSelectionFeature.State()
        state.activeScreen = .curation(.positionSelection)
        return .none
    }

}
