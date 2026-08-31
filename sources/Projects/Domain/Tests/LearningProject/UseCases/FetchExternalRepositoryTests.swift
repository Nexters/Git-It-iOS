import Testing

@testable import DomainLearningProject

// MARK: - FetchExternalRepositoryTests

@Suite("FetchExternalRepository")
struct FetchExternalRepositoryTests {
    @Test
    func `파싱 가능한 URL은 조회 결과를 그대로 반환한다`() async throws {
        let expected = ExternalRepository(
            canonicalURL: "https://github.com/owner/repo",
            ownerName: "owner",
            repositoryName: "repo",
            imageURL: nil,
            starCount: 3,
            techStack: ["Swift"],
        )
        let lookup = FetchExternalRepositoryLookup(behavior: .succeed(expected))
        let fetchExternalRepository = FetchExternalRepository(lookup: lookup)

        let result = try await fetchExternalRepository(url: "https://github.com/owner/repo")

        #expect(result == expected)
        #expect(await lookup.recordedOwnerAndName() == ["owner/repo"])
    }

    @Test(arguments: [
        "github.com/owner/repo",
        "www.github.com/owner/repo",
        "http://github.com/owner/repo",
        "http://www.github.com/owner/repo",
        "https://www.github.com/owner/repo",
        "HTTPS://GitHub.com/owner/repo",
    ])
    func `scheme·www 조합이 달라도 같은 owner-repo로 조회한다`(_ url: String) async throws {
        let expected = ExternalRepository(
            canonicalURL: "https://github.com/owner/repo",
            ownerName: "owner",
            repositoryName: "repo",
            imageURL: nil,
            starCount: 3,
            techStack: ["Swift"],
        )
        let lookup = FetchExternalRepositoryLookup(behavior: .succeed(expected))
        let fetchExternalRepository = FetchExternalRepository(lookup: lookup)

        let result = try await fetchExternalRepository(url: url)

        #expect(result == expected)
        #expect(await lookup.recordedOwnerAndName() == ["owner/repo"])
    }

    @Test
    func `파싱할 수 없는 URL은 조회 없이 URL 형식 오류를 던진다`() async throws {
        let lookup = FetchExternalRepositoryLookup(behavior: .succeed(
            ExternalRepository(
                canonicalURL: "unused",
                ownerName: "unused",
                repositoryName: "unused",
                imageURL: nil,
                starCount: 0,
                techStack: [],
            )
        ))
        let fetchExternalRepository = FetchExternalRepository(lookup: lookup)

        await #expect(throws: ExternalRepositoryError.invalidURLFormat) {
            try await fetchExternalRepository(url: "")
        }
        #expect(await lookup.recordedOwnerAndName().isEmpty)
    }

    @Test
    func `오프라인 오류를 그대로 전파한다`() async throws {
        let lookup = FetchExternalRepositoryLookup(behavior: .fail(.offline))
        let fetchExternalRepository = FetchExternalRepository(lookup: lookup)

        await #expect(throws: ExternalRepositoryError.offline) {
            try await fetchExternalRepository(url: "https://github.com/owner/repo")
        }
    }

    @Test
    func `그 밖의 오류를 그대로 전파한다`() async throws {
        let lookup = FetchExternalRepositoryLookup(behavior: .fail(.other))
        let fetchExternalRepository = FetchExternalRepository(lookup: lookup)

        await #expect(throws: ExternalRepositoryError.other) {
            try await fetchExternalRepository(url: "https://github.com/owner/repo")
        }
    }
}

// MARK: - FetchExternalRepositoryLookup

private actor FetchExternalRepositoryLookup: ExternalRepositoryLookup {

    // MARK: Lifecycle

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed(ExternalRepository)
        case fail(ExternalRepositoryError)
    }

    func repository(
        owner: String,
        name: String,
    ) async throws -> ExternalRepository {
        calls.append("\(owner)/\(name)")

        switch behavior {
        case .succeed(let repository):
            return repository

        case .fail(let error):
            throw error
        }
    }

    func recordedOwnerAndName() -> [String] {
        calls
    }

    // MARK: Private

    private let behavior: Behavior
    private var calls = [String]()

}
