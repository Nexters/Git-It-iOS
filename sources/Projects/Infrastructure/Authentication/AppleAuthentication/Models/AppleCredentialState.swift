import AuthenticationServices
import Foundation

public enum AppleCredentialState: Equatable, Sendable {
    case authorized
    case revoked
    case notFound
    case transferred
    case temporarilyUnavailable
}
