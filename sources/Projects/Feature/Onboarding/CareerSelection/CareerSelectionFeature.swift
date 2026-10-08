import ComposableArchitecture
import DomainUserInfo

@Reducer
public struct CareerSelectionFeature: Sendable {

    // MARK: Lifecycle

    public init(updateCuration: @escaping @Sendable (Curation) async throws -> Void) {
        self.updateCuration = updateCuration
    }

    // MARK: Public

    public enum Submission: Equatable, Sendable {
        case idle
        case submitting
        case failed
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public init(position: MemberPosition? = nil) {
            self.position = position
        }

        public fileprivate(set) var position: MemberPosition?
        public var careerLevel: CareerLevel?
        public var submission = Submission.idle
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case input(Input)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case careerLevelSelected(CareerLevel)
            case submitTapped
            case backTapped
        }

        @CasePathable
        public enum Input: Sendable, Equatable {
            case positionProvided(MemberPosition)
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
            case .view(let action):
                reduce(
                    into: &state,
                    view: action,
                )

            case .input(let action):
                reduce(
                    into: &state,
                    input: action,
                )

            case .effect(let event):
                reduce(
                    into: &state,
                    effect: event,
                )

            case .delegate:
                .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case curation
    }

    private let updateCuration: @Sendable (Curation) async throws -> Void

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .careerLevelSelected(let careerLevel):
            guard state.submission != .submitting else { return .none }
            state.careerLevel = careerLevel
            return .none

        case .submitTapped:
            guard
                let position = state.position,
                let careerLevel = state.careerLevel,
                state.submission != .submitting
            else { return .none }
            state.submission = .submitting
            return .run { send in
                do {
                    try await updateCuration(Curation(
                        position: position,
                        careerLevel: careerLevel,
                    ))
                    await send(.effect(.curationFinished(success: true)))
                } catch {
                    await send(.effect(.curationFinished(success: false)))
                }
            }
            .cancellable(id: CancelID.curation)

        case .backTapped:
            guard state.submission != .submitting else { return .none }
            return .send(.delegate(.backRequested))
        }
    }

    private func reduce(
        into state: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .positionProvided(let position):
            state.position = position
            return .none
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .curationFinished(let success):
            guard success else {
                state.submission = .failed
                return .none
            }
            state.submission = .idle
            return .send(.delegate(.curationSucceeded))
        }
    }

}
