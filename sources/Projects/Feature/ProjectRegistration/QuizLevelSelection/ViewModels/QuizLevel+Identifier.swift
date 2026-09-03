import DomainLearningProject

extension QuizLevel {
    var identifier: String {
        switch self {
        case .l1: "l1"
        case .l2: "l2"
        case .l3: "l3"
        @unknown default: "unknown"
        }
    }
}
