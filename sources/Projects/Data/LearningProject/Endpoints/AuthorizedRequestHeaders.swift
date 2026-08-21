public struct AuthorizedRequestHeaders: Equatable, Sendable {
    public init(accessToken: String) {
        fieldValues = [
            "Authorization": "Bearer \(accessToken)",
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
    }

    public let fieldValues: [String: String]
}
