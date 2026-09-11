import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

// MARK: - OnboardingEntryPoint

public enum OnboardingEntryPoint: Equatable, Sendable {
    case guide
    case curation
}

// MARK: - AppEntryFeature

@Reducer
public struct AppEntryFeature: Sendable {

    // MARK: Lifecycle

    public init(
        restoreSession: any RestoreSessionUseCase,
        fetchMemberProfile: any FetchMemberProfileUseCase,
        signOut: any SignOutUseCase,
    ) {
        self.restoreSession = restoreSession
        self.fetchMemberProfile = fetchMemberProfile
        self.signOut = signOut
    }

    // MARK: Public

    public enum AuthenticationStatus: Equatable, Sendable {
        case idle
        case restoring
        case retryableFailure
    }

    public enum Destination: Equatable, Sendable {
        case mainShell
        case onboarding(startingAt: OnboardingEntryPoint)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public var authentication = AuthenticationStatus.idle
        public var requestID = 0
        public var isSplashAnimationFinished = false
        public var pendingDestination: Destination?
        public var automaticRetryCount = 0

        public var isShowingRecoverableError: Bool {
            authentication == .retryableFailure
        }

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case retryTapped
            case splashAnimationFinished
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case restoreSessionFinished(requestID: Int, result: RestoreSessionResult)
            case memberProfileFetchFinished(requestID: Int, result: Result<MemberProfile, MemberError>)
            case localCleanupFinished(requestID: Int, result: SignOutResult)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case destinationDecided(Destination)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task):
                guard state.authentication == .idle else { return .none }
                state.automaticRetryCount = 0
                return restoreSession(&state)

            case .view(.retryTapped):
                guard state.authentication != .restoring else { return .none }
                state.automaticRetryCount = 0
                return restoreSession(&state)

            case .view(.splashAnimationFinished):
                guard !state.isSplashAnimationFinished else { return .none }
                state.isSplashAnimationFinished = true
                guard let destination = state.pendingDestination else { return .none }
                state.pendingDestination = nil
                return .send(.delegate(.destinationDecided(destination)))

            case .effect(.restoreSessionFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .authenticated:
                    return .run { send in
                        do {
                            let profile = try await fetchMemberProfile()
                            await send(.effect(.memberProfileFetchFinished(requestID: requestID, result: .success(profile))))
                        } catch {
                            let mapped = error as? MemberError ?? .temporarilyUnavailable
                            await send(.effect(.memberProfileFetchFinished(requestID: requestID, result: .failure(mapped))))
                        }
                    }
                    .cancellable(id: CancelID.profile, cancelInFlight: true)

                case .unauthenticated:
                    state.authentication = .idle
                    return decideDestination(.onboarding(startingAt: .guide), state: &state)

                case .recoverableFailure:
                    return retryAutomaticallyOrFail(&state)
                }

            case .effect(.memberProfileFetchFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .success(let profile):
                    if profile.position != nil, profile.careerLevel != nil {
                        return decideDestination(.mainShell, state: &state)
                    } else {
                        return decideDestination(.onboarding(startingAt: .curation), state: &state)
                    }

                case .failure(.memberUnavailable):
                    return .run { send in
                        let result = await signOut()
                        await send(.effect(.localCleanupFinished(requestID: requestID, result: result)))
                    }
                    .cancellable(id: CancelID.cleanup, cancelInFlight: true)

                case .failure(.unauthorized):
                    state.authentication = .retryableFailure
                    return .none

                case .failure:
                    return retryAutomaticallyOrFail(&state)
                }

            case .effect(.localCleanupFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .success:
                    state.authentication = .idle
                    return decideDestination(.onboarding(startingAt: .guide), state: &state)

                case .retryableFailure:
                    return retryAutomaticallyOrFail(&state)
                }

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum Constant {
        static let maximumAutomaticRetryCount = 1
    }

    private enum CancelID: Hashable {
        case restore
        case profile
        case cleanup
    }

    private let restoreSession: any RestoreSessionUseCase
    private let fetchMemberProfile: any FetchMemberProfileUseCase
    private let signOut: any SignOutUseCase

    private func restoreSession(_ state: inout State) -> Effect<Action> {
        state.authentication = .restoring
        state.requestID += 1
        state.pendingDestination = nil
        let requestID = state.requestID
        return .run { send in
            let result = await restoreSession()
            await send(.effect(.restoreSessionFinished(requestID: requestID, result: result)))
        }
        .cancellable(id: CancelID.restore, cancelInFlight: true)
    }

    private func retryAutomaticallyOrFail(_ state: inout State) -> Effect<Action> {
        guard state.automaticRetryCount < Constant.maximumAutomaticRetryCount else {
            state.authentication = .retryableFailure
            return .none
        }
        state.automaticRetryCount += 1
        return restoreSession(&state)
    }

    private func decideDestination(
        _ destination: Destination,
        state: inout State,
    ) -> Effect<Action> {
        guard state.isSplashAnimationFinished else {
            state.pendingDestination = destination
            return .none
        }
        return .send(.delegate(.destinationDecided(destination)))
    }

}
