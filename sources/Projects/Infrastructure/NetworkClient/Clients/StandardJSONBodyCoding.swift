import Foundation

// MARK: - StandardJSONBodyCoding

public struct StandardJSONBodyCoding: HTTPBodyCoding {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func encode(_ body: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(body)
    }

    public func decode<Body: Decodable>(
        _: Body.Type,
        from data: Data,
    ) throws -> Body {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Body.self, from: data)
    }

}
