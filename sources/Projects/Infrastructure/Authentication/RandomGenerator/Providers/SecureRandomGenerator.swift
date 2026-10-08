import Foundation
import Security

public struct SecureRandomGenerator: Sendable {

    // MARK: Lifecycle

    public init() {
        bytes = { count in
            var values = [UInt8](
                repeating: 0,
                count: count,
            )
            guard
                SecRandomCopyBytes(
                    kSecRandomDefault,
                    count,
                    &values,
                ) == errSecSuccess
            else {
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
        let encoded = String(
            Data(try bytes(requiredBytes)).base64EncodedString().compactMap { character in
                switch character {
                case "+": "-"
                case "/": "_"
                case "=": nil
                default: character
                }
            }
        )
        return String(encoded.prefix(length))
    }

    // MARK: Private

    private let bytes: @Sendable (Int) throws -> [UInt8]

}
