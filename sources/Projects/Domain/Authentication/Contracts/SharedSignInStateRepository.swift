// MARK: - SharedSignInStateRepository

public protocol SharedSignInStateRepository: Sendable {
    func signedInState() async -> Bool?
}
