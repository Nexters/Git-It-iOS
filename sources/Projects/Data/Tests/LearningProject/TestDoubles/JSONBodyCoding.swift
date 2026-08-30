import Foundation
import InfrastructureNetworkClient

struct JSONBodyCoding: HTTPBodyCoding {
    func encode(_ body: some Encodable) throws -> Data {
        try JSONEncoder().encode(body)
    }

    func decode<Body: Decodable>(
        _: Body.Type,
        from data: Data,
    ) throws -> Body {
        try JSONDecoder().decode(Body.self, from: data)
    }
}
