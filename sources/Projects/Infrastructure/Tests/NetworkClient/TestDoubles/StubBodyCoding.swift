import Foundation
@testable import InfrastructureNetworkClient

struct StubBodyCoding: HTTPBodyCoding {

    // MARK: Lifecycle

    init(
        failsEncoding: Bool = false,
        failsDecoding: Bool = false,
        allowsEmptyBody: Bool = false,
        encodedBody: Data? = nil,
    ) {
        self.failsEncoding = failsEncoding
        self.failsDecoding = failsDecoding
        self.allowsEmptyBody = allowsEmptyBody
        self.encodedBody = encodedBody
    }

    // MARK: Internal

    let failsEncoding: Bool
    let failsDecoding: Bool
    let allowsEmptyBody: Bool
    let encodedBody: Data?

    func encode(_ body: some Encodable) throws -> Data {
        guard !failsEncoding else { throw StubBodyCodingError.expected }
        if let encodedBody {
            return encodedBody
        }
        return try JSONEncoder().encode(body)
    }

    func decode<Body: Decodable>(
        _: Body.Type,
        from data: Data,
    ) throws -> Body {
        guard !failsDecoding else { throw StubBodyCodingError.expected }

        let payload =
            if data.isEmpty, allowsEmptyBody {
                Data("{}".utf8)
            } else {
                data
            }
        return try JSONDecoder().decode(Body.self, from: payload)
    }

}
