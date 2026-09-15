import Foundation

public protocol TrackGenerationUseCase: Sendable {
    func begin(
        githubRepoURL: String,
        requestedAt: Date,
    ) async -> Bool

    func attachProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) async

    func end(githubRepoURL: String) async

    func end(projectID: String) async

    func current() async -> GenerationState

    func states() async -> AsyncStream<GenerationState>
}
