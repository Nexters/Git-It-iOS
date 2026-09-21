#if DEBUG
import ComposableArchitecture
import DomainExternalRepository
import DomainIdentifier
import DomainProjectGeneration
import Foundation

// MARK: - ShareRegistrationPreviewSupport

enum ShareRegistrationPreviewSupport {

    // MARK: Internal

    static func store(
        phase: SharedRepositoryRegistrationFeature.State.Phase? = nil,
        step: ShareRegistrationFeature.Step = .repositoryConfirmation,
    ) -> StoreOf<ShareRegistrationFeature> {
        var state = ShareRegistrationFeature.State(sharedURL: "https://github.com/apple/swift")
        state.registration.phase = phase ?? .ready(sampleRepository)
        state.step = step
        state.repositoryConfirmation.repository = sampleRepository
        return Store(initialState: state) {
            ShareRegistrationFeature(
                parseRepositoryLink: PreviewRepositoryLocator(),
                externalRepository: PreviewExternalRepository(),
                projectGeneration: PreviewProjectGeneration(),
                signInAvailability: { .signedIn },
            )
        }
    }

    // MARK: Private

    private struct PreviewRepositoryLocator: ExternalRepositoryLocator {
        func location(from _: ExternalRepositoryURL) -> ExternalRepositoryLocation? {
            ExternalRepositoryLocation(owner: "apple", name: "swift")
        }
    }

    private struct PreviewExternalRepository: ExternalRepositoryUseCase {
        func repository(at _: ExternalRepositoryURL) async throws -> ExternalRepository {
            ShareRegistrationPreviewSupport.sampleRepository
        }
    }

    private struct PreviewProjectGeneration: ProjectGenerationUseCase {
        func request(_ request: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt {
            ProjectGenerationReceipt(projectID: "preview-project", quizLevel: request.quizLevel)
        }

        func states() async -> AsyncStream<ProjectGenerationState> {
            AsyncStream { $0.finish() }
        }
    }

    private static let sampleRepository = ExternalRepository(
        canonicalURL: "https://github.com/apple/swift",
        ownerName: "apple",
        repositoryName: "swift",
        imageURL: nil,
        starCount: 1000,
        techStack: ["Swift"],
    )

}
#endif
