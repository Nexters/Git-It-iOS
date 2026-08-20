import Testing

@testable import DomainLearningProject

// MARK: - ExternalRepositoryLookupContractTests

@Suite("ExternalRepositoryLookup 계약")
struct ExternalRepositoryLookupContractTests {
    @Test
    func `소유자와 저장소 이름으로 조회만 제공한다`() async throws {
        let expected = ExternalRepository(
            canonicalURL: "https://github.com/owner/repo",
            ownerName: "owner",
            repositoryName: "repo",
            imageURL: nil,
            starCount: 10,
            techStack: ["Swift"],
        )
        let lookup = ExternalRepositoryLookupContractProbe(repository: expected)

        let result = try await lookup.repository(owner: "owner", name: "repo")

        #expect(result == expected)
        #expect(await lookup.recordedCalls() == [.repository(owner: "owner", name: "repo")])
    }
}

// MARK: - ExternalRepositoryLookupContractProbe

private actor ExternalRepositoryLookupContractProbe: ExternalRepositoryLookup {

    // MARK: Lifecycle

    init(repository: ExternalRepository) {
        self.repository = repository
    }

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case repository(owner: String, name: String)
    }

    func repository(
        owner: String,
        name: String,
    ) async throws -> ExternalRepository {
        calls.append(.repository(owner: owner, name: name))
        return repository
    }

    func recordedCalls() -> [Call] {
        calls
    }

    // MARK: Private

    private let repository: ExternalRepository
    private var calls = [Call]()

}
