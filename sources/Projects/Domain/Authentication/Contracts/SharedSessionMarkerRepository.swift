// MARK: - SharedSessionMarkerRepository

public protocol SharedSessionMarkerRepository: Sendable {
    func signedInState() async -> Bool?
}
