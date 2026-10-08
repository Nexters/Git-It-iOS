import ComposableArchitecture
import DomainProject

@Reducer
public struct ProjectListPaginationFeature: Sendable {

    // MARK: Lifecycle

    public init(requestNextPage: @escaping @Sendable () async throws -> Void) {
        self.requestNextPage = requestNextPage
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            pagination: Pagination = .idle,
            hasNextPage: Bool = false,
        ) {
            self.pagination = pagination
            self.hasNextPage = hasNextPage
        }

        // MARK: Public

        public enum Pagination: Equatable, Sendable {
            case idle
            case loading
            case failed(ProjectError)
            case exhausted
        }

        public var pagination: Pagination
        public var hasNextPage: Bool

    }

    public enum Action: Equatable, Sendable {
        case input(Input)
        case effect(EffectEvent)

        // MARK: Public

        @CasePathable
        public enum Input: Equatable, Sendable {
            case nextPageRequested
            case retry
            case listReplaced(hasNextPage: Bool)
            case refreshStarted
        }

        @CasePathable
        public enum EffectEvent: Equatable, Sendable {
            case nextPageFinished(error: ProjectError?)
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
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case nextPage
    }

    private let requestNextPage: @Sendable () async throws -> Void

    private func reduce(
        into state: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .nextPageRequested:
            guard state.pagination == .idle else { return .none }
            return startNextPageLoad(state: &state)

        case .retry:
            guard case .failed = state.pagination else { return .none }
            return startNextPageLoad(state: &state)

        case .listReplaced(let hasNextPage):
            state.hasNextPage = hasNextPage
            state.pagination = hasNextPage ? .idle : .exhausted
            return .none

        case .refreshStarted:
            return .cancel(id: CancelID.nextPage)
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .nextPageFinished(let error):
            guard case .loading = state.pagination else { return .none }
            if let error {
                state.pagination = .failed(error)
            } else {
                state.pagination = state.hasNextPage ? .idle : .exhausted
            }
            return .none
        }
    }

    private func startNextPageLoad(state: inout State) -> Effect<Action> {
        state.pagination = .loading
        return .run { [requestNextPage] send in
            do {
                try await requestNextPage()
                await send(.effect(.nextPageFinished(error: nil)))
            } catch {
                let mapped = error as? ProjectError ?? .unexpected
                await send(.effect(.nextPageFinished(error: mapped)))
            }
        }
        .cancellable(
            id: CancelID.nextPage,
            cancelInFlight: true,
        )
    }

}
