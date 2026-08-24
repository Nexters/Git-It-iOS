import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

// MARK: - OnboardingFeature

/// U01 — Apple 로그인, 법적 동의(로컬 전용), position/career curation을 순서대로 진행한다.
/// legal 단계는 서버 UseCase가 없어(`INT-LEGAL-001`) 로컬 State로만 관리한다.
@Reducer
public struct OnboardingFeature: Sendable {

    // MARK: Lifecycle

    public init(
        signIn: any SignInUseCase,
        restoreSession: any RestoreSessionUseCase,
        completeCuration: any CompleteCurationUseCase,
    ) {
        self.signIn = signIn
        self.restoreSession = restoreSession
        self.completeCuration = completeCuration
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var legalAccepted = false
        public var signInStatus: SignInStatus = .idle
        public var isAuthenticated = false
        public var position: MemberPosition?
        public var careerLevel: CareerLevel?
        public var curationStatus: CurationStatus = .idle
    }

    public enum SignInStatus: Equatable, Sendable {
        case idle
        case inProgress
        case failed(AuthenticationError)
    }

    public enum CurationStatus: Equatable, Sendable {
        case idle
        case committing
        case failed(MemberError)
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case legalAcceptTapped
            case appleSignInTapped
            case positionSelected(MemberPosition)
            case careerLevelSelected(CareerLevel)
            case curationSubmitTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case restoreSessionFinished(AuthenticationOutcome)
            case signInFinished(AuthenticationOutcome)
            case curationFinished(Result<FeatureUnit, MemberError>)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case authenticated(AuthenticatedUser)
            case curationCompleted
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task):
                return .run { send in
                    let outcome = await restoreSession()
                    await send(.effect(.restoreSessionFinished(outcome)))
                }

            case .view(.legalAcceptTapped):
                state.legalAccepted = true
                return .none

            case .view(.appleSignInTapped):
                guard state.legalAccepted, state.signInStatus != .inProgress else { return .none }
                state.signInStatus = .inProgress
                return .run { send in
                    let outcome = await signIn(.apple)
                    await send(.effect(.signInFinished(outcome)))
                }
                .cancellable(id: CancelID.signIn, cancelInFlight: true)

            case .view(.positionSelected(let position)):
                guard state.curationStatus != .committing else { return .none }
                state.position = position
                return .none

            case .view(.careerLevelSelected(let careerLevel)):
                guard state.curationStatus != .committing else { return .none }
                state.careerLevel = careerLevel
                return .none

            case .view(.curationSubmitTapped):
                guard
                    let position = state.position,
                    let careerLevel = state.careerLevel,
                    state.curationStatus != .committing
                else { return .none }
                state.curationStatus = .committing
                return .run { send in
                    do {
                        try await completeCuration(position: position, careerLevel: careerLevel)
                        await send(.effect(.curationFinished(.success(FeatureUnit()))))
                    } catch {
                        let mapped = error as? MemberError ?? .temporarilyUnavailable
                        await send(.effect(.curationFinished(.failure(mapped))))
                    }
                }
                .cancellable(id: CancelID.curation)

            case .effect(.restoreSessionFinished(let outcome)):
                switch outcome {
                case .authenticated(let user):
                    state.signInStatus = .idle
                    state.isAuthenticated = true
                    return .send(.delegate(.authenticated(user)))

                case .unauthenticated, .recoverableFailure:
                    return .none
                }

            case .effect(.signInFinished(let outcome)):
                switch outcome {
                case .authenticated(let user):
                    state.signInStatus = .idle
                    state.isAuthenticated = true
                    return .send(.delegate(.authenticated(user)))

                case .unauthenticated:
                    state.signInStatus = .failed(.cancelled)
                    return .none

                case .recoverableFailure:
                    state.signInStatus = .failed(.temporarilyUnavailable)
                    return .none
                }

            case .effect(.curationFinished(.success)):
                state.curationStatus = .idle
                return .send(.delegate(.curationCompleted))

            case .effect(.curationFinished(.failure(let error))):
                state.curationStatus = .failed(error)
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case signIn
        case curation
    }

    private let signIn: any SignInUseCase
    private let restoreSession: any RestoreSessionUseCase
    private let completeCuration: any CompleteCurationUseCase

}
