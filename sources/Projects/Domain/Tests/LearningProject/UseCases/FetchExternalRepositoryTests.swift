import Synchronization
import Testing

@testable import DomainLearningProject

// MARK: - FetchExternalRepositoryTests

@Suite("FetchExternalRepository")
struct FetchExternalRepositoryTests {

    // MARK: Internal

    @Test
    func `해석된 위치로 조회하고 결과를 그대로 반환한다`() async throws {
        let expected = ExternalRepository(
            canonicalURL: "https://github.com/owner/repo",
            ownerName: "owner",
            repositoryName: "repo",
            imageURL: nil,
            starCount: 3,
            techStack: ["Swift"],
        )
        let lookup = FetchExternalRepositoryLookup(behavior: .succeed(expected))
        let parser = StubExternalRepositoryURLParser(
            location: ExternalRepositoryLocation(owner: "owner", name: "repo")
        )
        let fetchExternalRepository = FetchExternalRepository(lookup: lookup, urlParser: parser)

        let result = try await fetchExternalRepository(url: "https://github.com/owner/repo")

        #expect(result == expected)
        #expect(await lookup.recordedOwnerAndName() == ["owner/repo"])
        #expect(parser.receivedURLs() == ["https://github.com/owner/repo"])
    }

    @Test
    func `해석하지 못한 URL은 조회 없이 URL 형식 오류를 던진다`() async throws {
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
        let fetchExternalRepository = FetchExternalRepository(
            lookup: lookup,
            urlParser: StubExternalRepositoryURLParser(location: nil),
        )

        await #expect(throws: ExternalRepositoryError.invalidURLFormat) {
            try await fetchExternalRepository(url: "")
        }
        #expect(await lookup.recordedOwnerAndName().isEmpty)
    }

    @Test
    func `오프라인 오류를 그대로 전파한다`() async throws {
        let fetchExternalRepository = FetchExternalRepository(
            lookup: FetchExternalRepositoryLookup(behavior: .fail(.offline)),
            urlParser: Self.matchingParser,
        )

        await #expect(throws: ExternalRepositoryError.offline) {
            try await fetchExternalRepository(url: "https://github.com/owner/repo")
        }
    }

    @Test
    func `그 밖의 오류를 그대로 전파한다`() async throws {
        let fetchExternalRepository = FetchExternalRepository(
            lookup: FetchExternalRepositoryLookup(behavior: .fail(.other)),
            urlParser: Self.matchingParser,
        )

        await #expect(throws: ExternalRepositoryError.other) {
            try await fetchExternalRepository(url: "https://github.com/owner/repo")
        }
    }

    // MARK: Private

    private static var matchingParser: StubExternalRepositoryURLParser {
        StubExternalRepositoryURLParser(location: ExternalRepositoryLocation(owner: "owner", name: "repo"))
    }

}

// MARK: - StubExternalRepositoryURLParser

private final class StubExternalRepositoryURLParser: ExternalRepositoryURLParser {

    // MARK: Lifecycle

    init(location: ExternalRepositoryLocation?) {
        self.location = location
    }

    // MARK: Internal

    func location(from url: String) -> ExternalRepositoryLocation? {
        received.withLock { $0.append(url) }
        return location
    }

    func receivedURLs() -> [String] {
        received.withLock(\.self)
    }

    // MARK: Private

    private let location: ExternalRepositoryLocation?
    private let received = Mutex([String]())

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
