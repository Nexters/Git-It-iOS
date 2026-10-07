public enum QuizContent: Equatable, Sendable {
    case choice(options: [String], submitted: ChoiceSubmission?)
    case essay(submitted: EssaySubmission?)
}
