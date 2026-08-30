import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

// MARK: - OnboardingRouterFeature

/// 온보딩 안내(`OnboardingGuideFeature`)와 큐레이션(`CurationFeature`) 화면 Feature를
/// 조합하고, 실제로 화면이 전환될 때마다 테스트로 조회 가능한 이동 이벤트를 기록하는
/// Router Feature. Router의 화면 값에는 "완료" case를 두지 않으며, 상위(App Root)로
/// 나가야 하는지는 `OnboardingExitFeature`가 판단해 `delegate`로 알린다.
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

    /// Router가 관리하는 화면. 최상위 단위(온보딩 안내/큐레이션)를 나타내며, 각 단위
    /// 내부의 세부 화면을 연관값으로 함께 표현하는 계층형 값이다. "완료"는 이 값의
    /// case가 아니다(FR-005·FR-006).
    public enum ActiveScreen: Equatable, Sendable {
        case guide(OnboardingGuideFeature.Screen)
        case curation(CurationFeature.Screen)
        case curationSplash
    }

    /// Router가 관리하는 화면이 실제로 전환될 때 남는 기록(FR-006).
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
            let resolvedGuide = OnboardingGuideFeature.State(bundleVersion: bundleVersion)
            let resolvedCuration = CurationFeature.State()
            switch entryPoint {
            case .guide:
                activeScreen = .guide(resolvedGuide.screen)

            case .curation:
                activeScreen = .curation(resolvedCuration.screen)
            }
            guide = resolvedGuide
            curation = resolvedCuration
            exit = OnboardingExitFeature.State()
        }

        // MARK: Public

        public internal(set) var activeScreen: ActiveScreen
        public var guide: OnboardingGuideFeature.State
        public var curation: CurationFeature.State
        public var exit: OnboardingExitFeature.State
        public internal(set) var transitionLog = [ScreenTransitionEvent]()

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case guide(OnboardingGuideFeature.Action)
        case curation(CurationFeature.Action)
        case exit(OnboardingExitFeature.Action)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case curationSplashFinished
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case mainShellRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.guide, action: \.guide) {
            OnboardingGuideFeature(
                signIn: signIn,
                policyConsent: policyConsent,
                deleteMemberAccount: deleteMemberAccount,
                deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
            )
        }
        Scope(state: \.curation, action: \.curation) {
            CurationFeature(signOut: signOut, completeCuration: completeCuration)
        }
        Scope(state: \.exit, action: \.exit) {
            OnboardingExitFeature()
        }
        Reduce { state, action in
            let before = state.activeScreen
            var effect = Effect<Action>.none

            switch action {
            case .guide(.delegate(.signInSucceeded(let needsCuration))):
                if needsCuration {
                    state.curation = CurationFeature.State()
                    state.activeScreen = .curation(state.curation.screen)
                } else {
                    effect = .send(.delegate(.mainShellRequested))
                }

            case .curation(.delegate(.exitRequested)):
                state.guide.screen = .tutorial(page: 3)
                state.curation = CurationFeature.State()
                state.activeScreen = .guide(state.guide.screen)

            case .curation(.delegate(.curationSucceeded)):
                effect = .send(.exit(.input(.curationSucceeded)))

            case .exit(.delegate(.shouldExit)):
                state.activeScreen = .curationSplash

            case .view(.curationSplashFinished):
                guard state.activeScreen == .curationSplash else { break }
                effect = .send(.delegate(.mainShellRequested))

            case .guide:
                if case .guide = state.activeScreen {
                    state.activeScreen = .guide(state.guide.screen)
                }

            case .curation:
                if case .curation = state.activeScreen {
                    state.activeScreen = .curation(state.curation.screen)
                }

            case .view,
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

}
