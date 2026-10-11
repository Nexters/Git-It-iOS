import Foundation
import Security

public enum SecureRandomGeneratorError: Error, Equatable, Sendable {
    case invalidLength
    case unavailable
}
