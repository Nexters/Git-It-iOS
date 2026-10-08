import ComposableArchitecture
import Foundation

// MARK: - LearningCompletionFeature

@Reducer
public struct LearningCompletionFeature: Sendable {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            projectID: String,
            correctChoiceCount: Int = 0,
            choiceQuestionCount: Int = 0,
        ) {
            self.projectID = projectID
            self.correctChoiceCount = correctChoiceCount
            self.choiceQuestionCount = choiceQuestionCount
        }

        // MARK: Public

        public let projectID: String
        public var correctChoiceCount = 0
        public var choiceQuestionCount = 0

        public var isScorePresented: Bool {
            choiceQuestionCount > 0
        }

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case closeTapped
            case primaryActionTapped
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case dismissRequested
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

            case .delegate:
                .none
            }
        }
    }

    // MARK: Private

    private func reduce(
        into _: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .closeTapped,
             .primaryActionTapped:
            .send(.delegate(.dismissRequested))
        }
    }

}
