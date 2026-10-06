import Foundation

public struct TrackGenerationProgress: TrackGenerationProgressUseCase, Sendable {

    // MARK: Lifecycle

    public init(progressRepository: any GenerationProgressRepository) {
        self.progressRepository = progressRepository
    }

    // MARK: Public

    public func begin(
        projectID: String,
        requestedAt: Date,
    ) async {
        await progressRepository.save(
            GenerationProgress(projectID: projectID, requestedAt: requestedAt)
        )
    }

    public func current() async -> GenerationProgress? {
        await progressRepository.load()
    }

    public func end() async {
        await progressRepository.clear()
    }

    // MARK: Private

    private let progressRepository: any GenerationProgressRepository

}
