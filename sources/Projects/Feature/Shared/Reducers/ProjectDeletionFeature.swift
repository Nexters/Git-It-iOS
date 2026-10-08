import ComposableArchitecture
import DomainIdentifier
import DomainProject
import Foundation

@Reducer
public struct ProjectDeletionFeature: Sendable {

    // MARK: Lifecycle

    public init(deleteProject: @escaping @Sendable (ProjectID) async throws -> Void) {
        self.deleteProject = deleteProject
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(deletion: Deletion = .idle) {
            self.deletion = deletion
        }

        // MARK: Public

        public enum Deletion: Equatable, Sendable {
            case idle
            case confirming(projectID: ProjectID)
            case committing(projectID: ProjectID)
            case failed(projectID: ProjectID, error: ProjectError)
        }

        public var deletion: Deletion

        public static func ==(
            lhs: Self,
            rhs: Self,
        ) -> Bool {
            lhs.deletion == rhs.deletion
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
            case request(ProjectID)
            case cancel
            case confirm
        }

        @CasePathable
        public enum EffectEvent: Equatable, Sendable {
            case deletionFinished(projectID: ProjectID, error: ProjectError?)
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case deleted(projectID: ProjectID)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .input(.request(let projectID)):
                switch state.deletion {
                case .idle,
                     .failed:
                    state.deletion = .confirming(projectID: projectID)

                case .confirming,
                     .committing:
                    break
                }
                return .none

            case .input(.cancel):
                switch state.deletion {
                case .confirming,
                     .failed:
                    state.deletion = .idle

                case .idle,
                     .committing:
                    break
                }
                return .none

            case .input(.confirm):
                guard case .confirming(let projectID) = state.deletion else { return .none }
                state.deletion = .committing(projectID: projectID)
                let instanceID = state.instanceID
                return .run { [deleteProject] send in
                    do {
                        try await deleteProject(projectID)
                        await send(.effect(.deletionFinished(
                            projectID: projectID,
                            error: nil,
                        )))
                    } catch {
                        let mapped = error as? ProjectError ?? .unexpected
                        await send(.effect(.deletionFinished(
                            projectID: projectID,
                            error: mapped,
                        )))
                    }
                }
                .cancellable(
                    id: CancelID.deletion(instanceID),
                    cancelInFlight: false,
                )

            case .effect(.deletionFinished(let projectID, nil)),
                 .effect(.deletionFinished(let projectID, .some(.notFound))):
                state.deletion = .idle
                return .send(.delegate(.deleted(projectID: projectID)))

            case .effect(.deletionFinished(let projectID, .some(let error))):
                state.deletion = .failed(
                    projectID: projectID,
                    error: error,
                )
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case deletion(UUID)
    }

    private let deleteProject: @Sendable (ProjectID) async throws -> Void

}
