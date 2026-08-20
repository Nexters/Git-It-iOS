public enum QuizGenerationStatus: CaseIterable, Equatable, Sendable {
    case ready
    case analyzed
    case anchored
    case rejected
    case failed
    case completed
}
