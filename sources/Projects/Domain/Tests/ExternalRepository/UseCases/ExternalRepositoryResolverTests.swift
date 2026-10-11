import Foundation
import Testing

@testable import DomainUseCaseImplementation
@testable import DomainUseCaseInterface

@Suite("ExternalRepositoryResolver")
struct ExternalRepositoryResolverTests {

    // MARK: Internal

    @Test
    func `저장소 위치를 해석하지 못하면 조회 없이 invalidURLFormat을 던진다`() async {
        let lookup = StubExternalRepositoryLookup(repository: Self.repository)
        let resolver = ExternalRepositoryResolver(
            lookup: lookup,
            locator: StubExternalRepositoryLocator(location: nil),
        )

        await #expect(throws: ExternalRepositoryError.invalidURLFormat) {
            try await resolver.repository(at: "not-a-repository")
        }
        #expect(await lookup.requestedLocations.isEmpty)
    }

    @Test
    func `해석한 소유자와 이름으로 저장소를 조회한다`() async throws {
        let location = ExternalRepositoryLocation(
            owner: "owner",
            name: "repo",
        )
        let lookup = StubExternalRepositoryLookup(repository: Self.repository)
        let resolver = ExternalRepositoryResolver(
            lookup: lookup,
            locator: StubExternalRepositoryLocator(location: location),
        )

        let repository = try await resolver.repository(at: "https://github.com/owner/repo")

        #expect(repository == Self.repository)
        #expect(await lookup.requestedLocations == [location])
    }

    // MARK: Private

    private static let repository = ExternalRepository(
        canonicalURL: "https://github.com/owner/repo",
        ownerName: "owner",
        repositoryName: "repo",
        imageURL: nil,
        starCount: 10,
        techStack: ["Swift"],
    )

}
