import ComposableArchitecture
import DomainMember

@Reducer
public struct CareerSelectionFeature: Sendable {

    public init(completeCuration: any CompleteCurationUseCase) {
        self.completeCuration = completeCuration
    }

    public enum Submission: Equatable, Sendable {
        case idle
        case submitting
        case failed
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var careerLevel: CareerLevel?
        public var submission = Submission.idle

        var position: MemberPosition?
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case careerLevelSelected(CareerLevel)
            case submitTapped
            case backTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case curationFinished(success: Bool)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case curationSucceeded
            case backRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.careerLevelSelected(let careerLevel)):
                guard state.submission != .submitting else { return .none }
                state.careerLevel = careerLevel
                return .none

            case .view(.backTapped):
                guard state.submission != .submitting else { return .none }
                return .send(.delegate(.backRequested))

            case .view(.submitTapped):
                guard
                    let position = state.position,
                    let careerLevel = state.careerLevel,
                    state.submission != .submitting
                else { return .none }
                state.submission = .submitting
                return .run { send in
                    do {
                        try await completeCuration(position: position, careerLevel: careerLevel)
                        await send(.effect(.curationFinished(success: true)))
                    } catch {
                        await send(.effect(.curationFinished(success: false)))
                    }
                }
                .cancellable(id: CancelID.curation)

            case .effect(.curationFinished(true)):
                state.submission = .idle
                return .send(.delegate(.curationSucceeded))

            case .effect(.curationFinished(false)):
                state.submission = .failed
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private enum CancelID: Hashable {
        case curation
    }

    private let completeCuration: any CompleteCurationUseCase

}
