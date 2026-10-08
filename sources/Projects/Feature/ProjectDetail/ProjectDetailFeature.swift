import ComposableArchitecture
import DomainIdentifier
import DomainProject
import Foundation

// MARK: - ProjectDetailFeature

@Reducer
public struct ProjectDetailFeature: Sendable {

    // MARK: Lifecycle

    public init(
        projectDetail: @escaping @Sendable (ProjectID) async throws -> ProjectDetail,
        deleteProject: @escaping @Sendable (ProjectID) async throws -> Void,
    ) {
        self.projectDetail = projectDetail
        self.deleteProject = deleteProject
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(projectID: ProjectID) {
            detailLoad = ProjectDetailLoadFeature.State(projectID: projectID)
        }

        // MARK: Public

        public var detailLoad: ProjectDetailLoadFeature.State
        public var isMenuPresented = false
        public var deletion = ProjectDeletionFeature.State()

        public var projectID: ProjectID {
            detailLoad.projectID
        }

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case input(Input)
        case delegate(Delegate)
        case detailLoad(ProjectDetailLoadFeature.Action)
        case deletion(ProjectDeletionFeature.Action)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case retryTapped
            case setStartTapped(setID: QuizSetID)
            case resumeTapped
            case menuTapped
            case menuDismissed
            case savedQuestionsTapped
            case repositoryLinkTapped
            case deleteTapped
            case deletionCancelled
            case deletionConfirmed
            case backTapped
        }

        @CasePathable
        public enum Input: Sendable, Equatable {
            case refreshRequested
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case setStartRequested(projectID: ProjectID, setID: QuizSetID, label: String)
            case savedQuestionsRequested(projectID: ProjectID)
            case externalURLRequested(URL)
            case projectDeleted(projectID: ProjectID)
            case dismissRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(
            state: \.detailLoad,
            action: \.detailLoad,
        ) {
            ProjectDetailLoadFeature(projectDetail: projectDetail)
        }
        Scope(
            state: \.deletion,
            action: \.deletion,
        ) {
            ProjectDeletionFeature(deleteProject: deleteProject)
        }
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

            case .delegate,
                 .detailLoad:
                .none

            case .deletion(let action):
                reduce(
                    into: &state,
                    deletion: action,
                )
            }
        }
    }

    // MARK: Private

    private let projectDetail: @Sendable (ProjectID) async throws -> ProjectDetail
    private let deleteProject: @Sendable (ProjectID) async throws -> Void

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .task,
             .retryTapped:
            return .send(.detailLoad(.input(.load)))

        case .setStartTapped(let setID):
            guard let progress = state.detailLoad.detail?.sets.first(where: { $0.setID == setID }) else { return .none }
            return .send(.delegate(.setStartRequested(
                projectID: state.projectID,
                setID: progress.setID,
                label: progress.label,
            )))

        case .resumeTapped:
            guard let progress = state.detailLoad.firstIncompleteSet else { return .none }
            return .send(.delegate(.setStartRequested(
                projectID: state.projectID,
                setID: progress.setID,
                label: progress.label,
            )))

        case .menuTapped:
            state.isMenuPresented = true
            return .none

        case .menuDismissed:
            state.isMenuPresented = false
            return .none

        case .savedQuestionsTapped:
            state.isMenuPresented = false
            return .send(.delegate(.savedQuestionsRequested(projectID: state.projectID)))

        case .repositoryLinkTapped:
            guard
                let repositoryURL = state.detailLoad.detail?.repository.url,
                let url = URL(string: repositoryURL)
            else { return .none }
            state.isMenuPresented = false
            return .send(.delegate(.externalURLRequested(url)))

        case .deleteTapped:
            state.isMenuPresented = false
            return .send(.deletion(.input(.request(state.projectID))))

        case .deletionCancelled:
            return .send(.deletion(.input(.cancel)))

        case .deletionConfirmed:
            return .send(.deletion(.input(.confirm)))

        case .backTapped:
            return .send(.delegate(.dismissRequested))
        }
    }

    private func reduce(
        into _: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .refreshRequested:
            .send(.detailLoad(.input(.load)))
        }
    }

    private func reduce(
        into _: inout State,
        deletion action: ProjectDeletionFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .deleted(let projectID):
            return .send(.delegate(.projectDeleted(projectID: projectID)))
        }
    }

}
