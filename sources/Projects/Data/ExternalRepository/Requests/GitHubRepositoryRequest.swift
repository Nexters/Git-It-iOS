public struct GitHubRepositoryRequest: Equatable, Sendable {
    public init(
        owner: String,
        repository: String,
    ) {
        scheme = "https"
        host = "api.github.com"
        method = "GET"
        path = "/repos/\(owner)/\(repository)"
        headers = ["Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"]
    }

    public let scheme: String
    public let host: String
    public let method: String
    public let path: String
    public let headers: [String: String]
}
