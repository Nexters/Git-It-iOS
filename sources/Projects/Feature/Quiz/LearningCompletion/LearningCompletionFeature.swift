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

        public var scoreAccessibilityLabel: String? {
            guard isScorePresented else { return nil }
            return "객관식 \(choiceQuestionCount)문제 중 \(correctChoiceCount)문제 정답"
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
        Reduce { _, action in
            switch action {
            case .view(.closeTapped),
                 .view(.primaryActionTapped):
                .send(.delegate(.dismissRequested))

            case .delegate:
                .none
            }
        }
    }

}
