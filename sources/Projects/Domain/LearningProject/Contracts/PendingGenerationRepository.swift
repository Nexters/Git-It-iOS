import Foundation

// MARK: - PendingGenerationRepository

public protocol PendingGenerationRepository: Sendable {
    func pendingState() async -> GenerationState

    func pendingStateChanges() async -> AsyncStream<GenerationState>

    func beginGeneration(
        githubRepoURL: String,
        requestedAt: Date,
    ) async -> Bool

    func attachProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) async

    func finishGeneration(
        projectID: String,
        status: GenerationRecord.Status,
        finishedAt: Date,
    ) async

    func releaseGeneration(githubRepoURL: String) async

    func releaseGeneration(projectID: String) async

    func enqueueReminder(projectID: String) async

    func drainReminderProjectIDs() async -> [String]
}
