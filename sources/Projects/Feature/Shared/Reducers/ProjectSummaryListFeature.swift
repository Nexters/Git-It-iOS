import ComposableArchitecture
import DomainIdentifier
import DomainProject
import Foundation

@Reducer
public struct ProjectSummaryListFeature: Sendable {

    // MARK: Lifecycle

    public init(
        projects: @escaping @Sendable () async -> AsyncStream<ProjectList>,
        refreshProjects: @escaping @Sendable () async throws -> Void,
    ) {
        self.projects = projects
        self.refreshProjects = refreshProjects
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(load: Load = .idle) {
            self.load = load
        }

        // MARK: Public

        public enum Load: Equatable, Sendable {
            case idle
            case loading
            case loaded(ProjectList)
            case failed(ProjectError)

            // MARK: Public

            public var isLoaded: Bool {
                if case .loaded = self {
                    return true
                }
                return false
            }
        }

        public var load: Load
        public var requestID = 0

        public var list: ProjectList? {
            guard case .loaded(let list) = load else { return nil }
            return list
        }

        public static func ==(
            lhs: Self,
            rhs: Self,
        ) -> Bool {
            lhs.load == rhs.load && lhs.requestID == rhs.requestID
        }

        // MARK: Fileprivate

        fileprivate let instanceID = UUID()

    }

    public enum Action: Equatable, Sendable {
        case input(Input)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum Input: Equatable, Sendable {
            case start
            case refresh
            case projectRemoved(ProjectID)
        }

        @CasePathable
        public enum EffectEvent: Equatable, Sendable {
            case projectsReceived(ProjectList)
            case refreshFinished(requestID: Int, error: ProjectError?)
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case listUpdated(ProjectList)
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
        case projects(UUID)
        case refresh(UUID)
    }

    private let projects: @Sendable () async -> AsyncStream<ProjectList>
    private let refreshProjects: @Sendable () async throws -> Void

    private func reduce(
        into state: inout State,
        input action: Action.Input,
    ) -> ComposableArchitecture.Effect<Action> {
        switch action {
        case .start:
            return .merge(
                observeProjects(state: state),
                startRefresh(state: &state),
            )

        case .refresh:
            return startRefresh(state: &state)

        case .projectRemoved(let projectID):
            guard case .loaded(let list) = state.load else { return .none }
            let updated = ProjectList(
                summaries: list.summaries.filter { $0.id != projectID },
                hasNextPage: list.hasNextPage,
                isLoaded: list.isLoaded,
            )
            state.load = .loaded(updated)
            return .send(.delegate(.listUpdated(updated)))
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> ComposableArchitecture.Effect<Action> {
        switch event {
        case .projectsReceived(let list):
            guard list.isLoaded else { return .none }
            state.load = .loaded(list)
            return .send(.delegate(.listUpdated(list)))

        case .refreshFinished(let requestID, let error):
            guard requestID == state.requestID else { return .none }
            guard let error, !state.load.isLoaded else { return .none }
            state.load = .failed(error)
            return .none
        }
    }

    private func observeProjects(state: State) -> ComposableArchitecture.Effect<Action> {
        let projects = projects
        return .run { send in
            for await list in await projects() {
                await send(.effect(.projectsReceived(list)))
            }
        }
        .cancellable(
            id: CancelID.projects(state.instanceID),
            cancelInFlight: true,
        )
    }

    private func startRefresh(state: inout State) -> ComposableArchitecture.Effect<Action> {
        state.requestID += 1
        if !state.load.isLoaded {
            state.load = .loading
        }
        let requestID = state.requestID
        let refreshProjects = refreshProjects

        return .run { send in
            do {
                try await refreshProjects()
                await send(.effect(.refreshFinished(
                    requestID: requestID,
                    error: nil,
                )))
            } catch {
                let mapped = error as? ProjectError ?? .unexpected
                await send(.effect(.refreshFinished(
                    requestID: requestID,
                    error: mapped,
                )))
            }
        }
        .cancellable(
            id: CancelID.refresh(state.instanceID),
            cancelInFlight: true,
        )
    }

}
