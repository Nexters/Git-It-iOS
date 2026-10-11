// MARK: - RequestCredential

public enum RequestCredential: Equatable, Sendable {
    case available(String)
    case signedOut
}
