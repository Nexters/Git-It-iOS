import DomainIdentifier
import Foundation

public protocol PendingGenerationRepository: Sendable {
    func pendingState() async -> GenerationState
    func pendingStateChanges() async -> AsyncStream<GenerationState>
    func beginGeneration(
        repositoryURL: ExternalRepositoryURL,
        requestedAt: Date,
    ) async -> Bool
    func attachProjectID(
        _ projectID: ProjectID,
        toRepositoryURL repositoryURL: ExternalRepositoryURL,
    ) async
    func finishGeneration(
        projectID: ProjectID,
        status: GenerationRecord.Status,
        finishedAt: Date,
    ) async -> Bool
    func releaseGeneration(repositoryURL: ExternalRepositoryURL) async
    func releaseGeneration(projectID: ProjectID) async
    func releaseAll() async
    func enqueueReminder(projectID: ProjectID) async
    func drainReminderProjectIDs() async -> [ProjectID]
}
