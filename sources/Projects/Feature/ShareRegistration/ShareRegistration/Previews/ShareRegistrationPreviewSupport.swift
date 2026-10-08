#if DEBUG
import ComposableArchitecture
import DomainUseCaseInterface

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
            EmptyReducer()
        }
    }

    // MARK: Private

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
