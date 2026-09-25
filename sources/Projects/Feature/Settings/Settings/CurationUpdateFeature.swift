import ComposableArchitecture
import DomainUserInfo

@Reducer
public struct CurationUpdateFeature: Sendable {

    // MARK: Lifecycle

    public init(
        updatePosition: @escaping @Sendable (MemberPosition) async throws -> Void,
        updateCareerLevel: @escaping @Sendable (CareerLevel) async throws -> Void,
    ) {
        self.updatePosition = updatePosition
        self.updateCareerLevel = updateCareerLevel
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            positionMutation: MutationStatus = .idle,
            careerLevelMutation: MutationStatus = .idle,
        ) {
            self.positionMutation = positionMutation
            self.careerLevelMutation = careerLevelMutation
        }

        // MARK: Public

        public enum MutationStatus: Equatable, Sendable {
            case idle
            case committing
            case failed(UserInfoError)
        }

        public var positionMutation: MutationStatus
        public var careerLevelMutation: MutationStatus

    }

    public enum Action: Equatable, Sendable {
        case input(Input)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum Input: Equatable, Sendable {
            case positionSelected(MemberPosition)
            case careerLevelSelected(CareerLevel)
        }

        @CasePathable
        public enum EffectEvent: Equatable, Sendable {
            case positionUpdateFinished(MemberPosition, UserInfoError?)
            case careerLevelUpdateFinished(CareerLevel, UserInfoError?)
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case positionUpdated(MemberPosition)
            case careerLevelUpdated(CareerLevel)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
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
        case positionMutation
        case careerLevelMutation
    }

    private let updatePosition: @Sendable (MemberPosition) async throws -> Void
    private let updateCareerLevel: @Sendable (CareerLevel) async throws -> Void

    private func reduce(
        into state: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .positionSelected(let position):
            guard state.positionMutation != .committing else { return .none }
            state.positionMutation = .committing
            return .run { [updatePosition] send in
                do {
                    try await updatePosition(position)
                    await send(.effect(.positionUpdateFinished(position, nil)))
                } catch {
                    let mapped = error as? UserInfoError ?? .temporarilyUnavailable
                    await send(.effect(.positionUpdateFinished(position, mapped)))
                }
            }
            .cancellable(id: CancelID.positionMutation)

        case .careerLevelSelected(let careerLevel):
            guard state.careerLevelMutation != .committing else { return .none }
            state.careerLevelMutation = .committing
            return .run { [updateCareerLevel] send in
                do {
                    try await updateCareerLevel(careerLevel)
                    await send(.effect(.careerLevelUpdateFinished(careerLevel, nil)))
                } catch {
                    let mapped = error as? UserInfoError ?? .temporarilyUnavailable
                    await send(.effect(.careerLevelUpdateFinished(careerLevel, mapped)))
                }
            }
            .cancellable(id: CancelID.careerLevelMutation)
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .positionUpdateFinished(let position, let error):
            switch error {
            case nil:
                state.positionMutation = .idle
                return .send(.delegate(.positionUpdated(position)))

            case .some(let error):
                state.positionMutation = .failed(error)
                return .none
            }

        case .careerLevelUpdateFinished(let careerLevel, let error):
            switch error {
            case nil:
                state.careerLevelMutation = .idle
                return .send(.delegate(.careerLevelUpdated(careerLevel)))

            case .some(let error):
                state.careerLevelMutation = .failed(error)
                return .none
            }
        }
    }

}
