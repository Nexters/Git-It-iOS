public enum QuizDetailError: CaseIterable, Equatable, Error, Sendable {
    case invalidAnswer
    case quizSetUnavailable
    case quizUnavailable
    case notFound
    case unauthorized
    case temporarilyUnavailable
    case unexpected
}
