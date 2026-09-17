import Foundation

public enum ProjectGenerationPhase: Equatable, Sendable {
    case inProgress(readyAt: Date)
    case preparing(readyAt: Date)
    case ready
    case failed
}
