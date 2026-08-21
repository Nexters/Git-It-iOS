import Foundation
import InfrastructureNetworkClient

// MARK: - StandardJSONBodyCoding

/// `InfrastructureNetworkClient`가 본문 형식을 소유하지 않는 계약(HTTPBodyCoding)을
/// 충족하는 Composition 소유 JSON 구현입니다.
struct StandardJSONBodyCoding: HTTPBodyCoding {
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
