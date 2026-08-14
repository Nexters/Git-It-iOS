import Foundation

// MARK: - HTTPBodyCoding

public protocol HTTPBodyCoding: Sendable {
    func encode(_ body: some Encodable) throws -> Data
    func decode<Body: Decodable>(_ type: Body.Type, from data: Data) throws -> Body
}
