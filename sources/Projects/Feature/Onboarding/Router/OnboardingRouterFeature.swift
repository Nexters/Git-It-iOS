import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

@Reducer
public struct OnboardingRouterFeature: Sendable {

    // MARK: Lifecycle

    public init(
        signIn: any SignInUseCase,
        signOut: any SignOutUseCase,
        policyConsent: any PolicyConsentUseCase,
        completeCuration: any CompleteCurationUseCase,
        deleteMemberAccount: any DeleteMemberAccountUseCase,
        deletesCompletedAccountOnSignIn: Bool = false,
    ) {
        self.signIn = signIn
        self.signOut = signOut
        self.policyConsent = policyConsent
        self.completeCuration = completeCuration
        self.deleteMemberAccount = deleteMemberAccount
        self.deletesCompletedAccountOnSignIn = deletesCompletedAccountOnSignIn
    }

    // MARK: Public

    public enum ActiveScreen: Hashable, Sendable {
        case guide(Guide)
        case curation(Curation)
        case curationSplash

        public enum Guide: Hashable, Sendable {
            case tutorial
            case legalAgreement
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
        ) {
            switch entryPoint {
            case .guide:
                activeScreen = .guide(.tutorial)

            case .curation:
                activeScreen = .curation(.positionSelection)
            }
            tutorial = TutorialFeature.State(bundleVersion: bundleVersion)
        }

        // MARK: Public

        public internal(set) var activeScreen: ActiveScreen
        public var tutorial: TutorialFeature.State
        public var legalAgreement = LegalAgreementFeature.State()
        public var positionSelection = PositionSelectionFeature.State()
        public var careerSelection = CareerSelectionFeature.State()
        public var exit = OnboardingExitFeature.State()
        public internal(set) var transitionLog = [ScreenTransitionEvent]()

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case tutorial(TutorialFeature.Action)
        case legalAgreement(LegalAgreementFeature.Action)
        case positionSelection(PositionSelectionFeature.Action)
        case careerSelection(CareerSelectionFeature.Action)
        case exit(OnboardingExitFeature.Action)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case curationSplashFinished
            case legalAgreementDismissed
            case legalDocumentSheetDismissed
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case mainShellRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.tutorial, action: \.tutorial) {
            TutorialFeature(
                signIn: signIn,
                deleteMemberAccount: deleteMemberAccount,
                deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
            )
        }
        Scope(state: \.legalAgreement, action: \.legalAgreement) {
            LegalAgreementFeature(policyConsent: policyConsent)
        }
        Scope(state: \.positionSelection, action: \.positionSelection) {
            PositionSelectionFeature(signOut: signOut)
        }
        Scope(state: \.careerSelection, action: \.careerSelection) {
            CareerSelectionFeature(completeCuration: completeCuration)
        }
        Scope(state: \.exit, action: \.exit) {
            OnboardingExitFeature()
        }
        Reduce { state, action in
            let before = state.activeScreen
            var effect = Effect<Action>.none

            switch action {
            case .tutorial(.delegate(.appeared)):
                effect = .send(.legalAgreement(.input(.load)))

            case .tutorial(.delegate(.signInSucceeded(let needsCuration))):
                if state.legalAgreement.isStoredConsentValid {
                    effect = advanceAfterSignIn(needsCuration: needsCuration, state: &state)
                } else {
                    state.activeScreen = .guide(.legalAgreement)
                    effect = .send(.legalAgreement(.input(.prepare(needsCuration: needsCuration))))
                }

            case .legalAgreement(.delegate(.consentCompleted(let needsCuration))):
                state.activeScreen = .guide(.tutorial)
                effect = advanceAfterSignIn(needsCuration: needsCuration, state: &state)

            case .legalAgreement(.delegate(.cancelled)):
                state.activeScreen = .guide(.tutorial)
                effect = .send(.tutorial(.input(.returnToLastPage)))

            case .positionSelection(.delegate(.confirmed(let position))):
                state.careerSelection.position = position
                state.activeScreen = .curation(.careerSelection)

            case .positionSelection(.delegate(.exitRequested)):
                state.positionSelection = PositionSelectionFeature.State()
                state.careerSelection = CareerSelectionFeature.State()
                state.activeScreen = .guide(.tutorial)
                effect = .send(.tutorial(.input(.returnToLastPage)))

            case .careerSelection(.delegate(.backRequested)):
                state.activeScreen = .curation(.positionSelection)

            case .careerSelection(.delegate(.curationSucceeded)):
                effect = .send(.exit(.input(.curationSucceeded)))

            case .exit(.delegate(.shouldExit)):
                state.activeScreen = .curationSplash

            case .view(.legalAgreementDismissed):
                effect = .send(.legalAgreement(.view(.cancelTapped)))

            case .view(.legalDocumentSheetDismissed):
                effect = .send(.legalAgreement(.view(.documentSheetDismissed)))

            case .view(.curationSplashFinished):
                guard state.activeScreen == .curationSplash else { break }
                effect = .send(.delegate(.mainShellRequested))

            case .tutorial,
                 .legalAgreement,
                 .positionSelection,
                 .careerSelection,
                 .exit,
                 .delegate:
                break
            }

            if state.activeScreen != before {
                state.transitionLog.append(
                    ScreenTransitionEvent(from: before, to: state.activeScreen, trigger: String(describing: action))
                )
            }

            return effect
        }
    }

    // MARK: Private

    private let signIn: any SignInUseCase
    private let signOut: any SignOutUseCase
    private let policyConsent: any PolicyConsentUseCase
    private let completeCuration: any CompleteCurationUseCase
    private let deleteMemberAccount: any DeleteMemberAccountUseCase
    private let deletesCompletedAccountOnSignIn: Bool

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
