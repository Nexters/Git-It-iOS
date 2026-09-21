import ComposableArchitecture
import DomainAccount
import DomainUserInfo
import Foundation

// MARK: - AppEntryFeature

@Reducer
public struct AppEntryFeature: Sendable {

    // MARK: Lifecycle

    public init(
        restoreSignIn: @escaping @Sendable () async -> SignInRestoration,
        curation: @escaping @Sendable () async throws -> Curation?,
        signOut: @escaping @Sendable () async -> SignOutResult,
    ) {
        self.restoreSignIn = restoreSignIn
        self.curation = curation
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
            case restoreSignInFinished(requestID: Int, result: SignInRestoration)
            case curationFetchFinished(requestID: Int, result: Result<Curation?, UserInfoError>)
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
                return restoreSignIn(&state)

            case .view(.retryTapped):
                guard state.authentication != .restoring else { return .none }
                state.automaticRetryCount = 0
                return restoreSignIn(&state)

            case .view(.splashAnimationFinished):
                guard !state.isSplashAnimationFinished else { return .none }
                state.isSplashAnimationFinished = true
                guard let destination = state.pendingDestination else { return .none }
                state.pendingDestination = nil
                return .send(.delegate(.destinationDecided(destination)))

            case .effect(.restoreSignInFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .signedIn:
                    return .run { send in
                        do {
                            let curation = try await curation()
                            await send(.effect(.curationFetchFinished(requestID: requestID, result: .success(curation))))
                        } catch {
                            let mapped = error as? UserInfoError ?? .temporarilyUnavailable
                            await send(.effect(.curationFetchFinished(requestID: requestID, result: .failure(mapped))))
                        }
                    }
                    .cancellable(id: CancelID.profile, cancelInFlight: true)

                case .signedOut:
                    state.authentication = .idle
                    return decideDestination(.onboarding(startingAt: .guide), state: &state)

                case .temporarilyUnavailable:
                    return retryAutomaticallyOrFail(&state)
                }

            case .effect(.curationFetchFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .success(let curation):
                    if curation != nil {
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
                case .signedOut:
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

    private let restoreSignIn: @Sendable () async -> SignInRestoration
    private let curation: @Sendable () async throws -> Curation?
    private let signOut: @Sendable () async -> SignOutResult

    private func restoreSignIn(_ state: inout State) -> Effect<Action> {
        state.authentication = .restoring
        state.requestID += 1
        state.pendingDestination = nil
        let requestID = state.requestID
        return .run { send in
            let result = await restoreSignIn()
            await send(.effect(.restoreSignInFinished(requestID: requestID, result: result)))
        }
        .cancellable(id: CancelID.restore, cancelInFlight: true)
    }

    private func retryAutomaticallyOrFail(_ state: inout State) -> Effect<Action> {
        guard state.automaticRetryCount < Constant.maximumAutomaticRetryCount else {
            state.authentication = .retryableFailure
            return .none
        }
        state.automaticRetryCount += 1
        return restoreSignIn(&state)
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
