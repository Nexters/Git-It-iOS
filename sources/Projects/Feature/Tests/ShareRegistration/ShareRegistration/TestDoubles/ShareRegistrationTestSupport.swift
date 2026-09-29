import DomainExternalRepository

enum ShareRegistrationTestSupport {

    static let sharedURL = "https://github.com/apple/swift"

    static let location = ExternalRepositoryLocation(
        owner: "apple",
        name: "swift",
    )

    static let repository = ExternalRepository(
        canonicalURL: "https://github.com/apple/swift",
        ownerName: "apple",
        repositoryName: "swift",
        imageURL: nil,
        starCount: 1000,
        techStack: ["Swift"],
    )

}
