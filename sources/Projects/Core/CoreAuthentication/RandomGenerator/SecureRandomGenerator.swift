import Foundation
import Security

// MARK: - SecureRandomGeneratorError

public enum SecureRandomGeneratorError: Error, Equatable, Sendable {
    case invalidLength
    case unavailable
}

// MARK: - SecureRandomGenerator

public struct SecureRandomGenerator: Sendable {

    // MARK: Lifecycle

    public init() {
        bytes = { count in
            var values = [UInt8](repeating: 0, count: count)
            guard SecRandomCopyBytes(kSecRandomDefault, count, &values) == errSecSuccess else {
                throw SecureRandomGeneratorError.unavailable
            }
            return values
        }
    }

    init(bytes: @escaping @Sendable (Int) throws -> [UInt8]) {
        self.bytes = bytes
    }

    // MARK: Public

    public func value(length: Int) throws -> String {
        guard length > 0 else { throw SecureRandomGeneratorError.invalidLength }
        let requiredBytes = ((length + 3) / 4) * 3
        let encoded = Data(try bytes(requiredBytes))
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return String(encoded.prefix(length))
    }

    // MARK: Private

    private let bytes: @Sendable (Int) throws -> [UInt8]

}
