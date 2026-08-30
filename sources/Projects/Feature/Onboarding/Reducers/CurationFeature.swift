import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

// MARK: - CurationFeature

@Reducer
public struct CurationFeature: Sendable {

    // MARK: Lifecycle

    public init(
        signOut: any SignOutUseCase,
        completeCuration: any CompleteCurationUseCase,
    ) {
        self.signOut = signOut
        self.completeCuration = completeCuration
    }

    // MARK: Public

    public enum Screen: Equatable, Sendable {
        case position
        case career
    }

    public enum ExitStatus: Equatable, Sendable {
        case idle
        case inProgress
        case failed
    }

    public struct Selection: Equatable, Sendable {

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public enum Submission: Equatable, Sendable {
            case idle
            case submitting
            case failed
        }

        public var position: MemberPosition?
        public var careerLevel: CareerLevel?
        public var submission = Submission.idle

    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public var screen = Screen.position
        public var selection = Selection()
        public var exitStatus = ExitStatus.idle

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case positionSelected(MemberPosition)
            case positionNextTapped
            case positionBackTapped
            case careerLevelSelected(CareerLevel)
            case careerBackTapped
            case curationSubmitTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case positionExitSignOutFinished(SignOutResult)
            case curationFinished(success: Bool)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case curationSucceeded
            case exitRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.positionSelected(let position)):
                guard state.selection.submission != .submitting else { return .none }
                state.selection.position = position
                return .none

            case .view(.positionNextTapped):
                guard
                    state.selection.submission != .submitting,
                    state.selection.position != nil
                else { return .none }
                state.screen = .career
                return .none

            case .view(.positionBackTapped):
                guard
                    state.selection.submission != .submitting,
                    state.exitStatus != .inProgress
                else { return .none }
                state.exitStatus = .inProgress
                return .run { send in
                    let result = await signOut()
                    await send(.effect(.positionExitSignOutFinished(result)))
                }
                .cancellable(id: CancelID.positionExit, cancelInFlight: true)

            case .view(.careerLevelSelected(let careerLevel)):
                guard state.selection.submission != .submitting else { return .none }
                state.selection.careerLevel = careerLevel
                return .none

            case .view(.careerBackTapped):
                guard state.selection.submission != .submitting else { return .none }
                state.screen = .position
                return .none

            case .view(.curationSubmitTapped):
                guard
                    let position = state.selection.position,
                    let careerLevel = state.selection.careerLevel,
                    state.selection.submission != .submitting
                else { return .none }
                state.selection.submission = .submitting
                return .run { send in
                    do {
                        try await completeCuration(position: position, careerLevel: careerLevel)
                        await send(.effect(.curationFinished(success: true)))
                    } catch {
                        await send(.effect(.curationFinished(success: false)))
                    }
                }
                .cancellable(id: CancelID.curation)

            case .effect(.positionExitSignOutFinished(let result)):
                switch result {
                case .success:
                    state.exitStatus = .idle
                    return .send(.delegate(.exitRequested))

                case .retryableFailure:
                    state.exitStatus = .failed
                    return .none
                }

            case .effect(.curationFinished(true)):
                state.selection.submission = .idle
                return .send(.delegate(.curationSucceeded))

            case .effect(.curationFinished(false)):
                state.selection.submission = .failed
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case curation
        case positionExit
    }

    private let signOut: any SignOutUseCase
    private let completeCuration: any CompleteCurationUseCase

}
