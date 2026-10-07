#if DEBUG
import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - ShareRegistrationPreviewSupport

enum ShareRegistrationPreviewSupport {

    // MARK: Internal

    static func store(status: ShareRegistrationFeature.Status) -> StoreOf<ShareRegistrationFeature> {
        var state = ShareRegistrationFeature.State(sharedURL: "https://github.com/apple/swift")
        state.status = status
        state.repositoryConfirmation.repository = sampleRepository
        return Store(initialState: state) {
            ShareRegistrationFeature(
                parseRepositoryLink: PreviewURLParser(),
                fetchExternalRepository: PreviewFetchExternalRepository(),
                createLearningProject: PreviewCreateLearningProject(),
                resolveSession: { .available },
            )
        }
    }

    // MARK: Private

    private struct PreviewURLParser: ExternalRepositoryURLParser {
        func location(from _: String) -> ExternalRepositoryLocation? {
            ExternalRepositoryLocation(owner: "apple", name: "swift")
        }
    }

    private struct PreviewFetchExternalRepository: FetchExternalRepositoryUseCase {
        func callAsFunction(url _: String) async throws -> ExternalRepository {
            ShareRegistrationPreviewSupport.sampleRepository
        }
    }

    private struct PreviewCreateLearningProject: CreateLearningProjectUseCase {
        func callAsFunction(
            githubRepoURL _: String,
            quizLevel: QuizLevel,
        ) async throws -> ProjectRegistrationReceipt {
            ProjectRegistrationReceipt(
                projectID: "preview-project",
                requestStatus: "accepted",
                quizLevel: quizLevel,
            )
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
