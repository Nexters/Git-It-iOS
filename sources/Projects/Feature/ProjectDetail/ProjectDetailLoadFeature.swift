import ComposableArchitecture
import DomainIdentifier
import DomainProject

@Reducer
public struct ProjectDetailLoadFeature: Sendable {

    // MARK: Lifecycle

    public init(projectDetail: @escaping @Sendable (ProjectID) async throws -> ProjectDetail) {
        self.projectDetail = projectDetail
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(projectID: ProjectID) {
            self.projectID = projectID
        }

        // MARK: Public

        public enum LoadStatus: Equatable, Sendable {
            case idle
            case loading
            case loaded
            case failed(ProjectError)
        }

        public let projectID: ProjectID
        public var detail: ProjectDetail?
        public var loadStatus = LoadStatus.idle
        public var requestID = 0

        public var isEmpty: Bool {
            detail?.sets.isEmpty ?? false
        }

        public var firstIncompleteSet: ProjectSetProgress? {
            detail?.sets.first { $0.completedCount < $0.quizCount }
        }

        public var isResumeEnabled: Bool {
            firstIncompleteSet != nil
        }

    }

    public enum Action: Equatable, Sendable {
        case input(Input)
        case effect(EffectEvent)

        // MARK: Public

        @CasePathable
        public enum Input: Equatable, Sendable {
            case load
        }

        @CasePathable
        public enum EffectEvent: Equatable, Sendable {
            case detailLoadFinished(requestID: Int, result: Result<ProjectDetail, ProjectError>)
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
        case load
    }

    private let projectDetail: @Sendable (ProjectID) async throws -> ProjectDetail

    private func reduce(
        into state: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .load:
            state.requestID += 1
            let requestID = state.requestID
            state.loadStatus = .loading
            let projectID = state.projectID
            return .run { [projectDetail] send in
                do {
                    let detail = try await projectDetail(projectID)
                    await send(.effect(.detailLoadFinished(
                        requestID: requestID,
                        result: .success(detail),
                    )))
                } catch {
                    let mapped = error as? ProjectError ?? .unexpected
                    await send(.effect(.detailLoadFinished(
                        requestID: requestID,
                        result: .failure(mapped),
                    )))
                }
            }
            .cancellable(
                id: CancelID.load,
                cancelInFlight: true,
            )
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .detailLoadFinished(let requestID, let result):
            guard requestID == state.requestID else { return .none }
            switch result {
            case .success(let detail):
                state.detail = detail
                state.loadStatus = .loaded

            case .failure(let error):
                state.loadStatus = .failed(error)
            }
            return .none
        }
    }

}
