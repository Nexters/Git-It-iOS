import InfrastructureNetworkClient

struct AuthorizedRequestHeaders: Equatable, Sendable {
    init(accessToken: String) {
        headers = [
            "Authorization": "Bearer \(accessToken)",
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
    }

    let headers: HTTPHeaders
}
