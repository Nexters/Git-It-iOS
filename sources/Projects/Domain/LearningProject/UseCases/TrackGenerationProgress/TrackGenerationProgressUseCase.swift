import Foundation

public protocol TrackGenerationProgressUseCase: Sendable {

    func begin(
        projectID: String,
        requestedAt: Date,
    ) async

    func current() async -> GenerationProgress?

    func end() async

}
