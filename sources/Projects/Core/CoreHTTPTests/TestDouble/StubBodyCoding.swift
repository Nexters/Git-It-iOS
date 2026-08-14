import Foundation

@testable import CoreHTTP

// MARK: - TestPayload

/// 요청·응답 JSON 변환의 성공 경로에 쓰는 최소 테스트 본문입니다.
struct TestPayload: Codable, Equatable, Sendable {
    let id: Int
    let name: String
}

// MARK: - EmptyPayload

/// 빈 성공 본문을 허용하는 변환 규칙이 정상 값을 만들 수 있음을 보이는 전용 타입입니다.
struct EmptyPayload: Codable, Equatable, Sendable { }

// MARK: - StubBodyCodingError

enum StubBodyCodingError: Error {
    case expected
}

// MARK: - StubBodyCoding

/// CoreHTTP가 특정 본문 형식을 소유하지 않는다는 계약을 검증하기 위한 호출자 측 JSON 구현입니다.
/// 세 플래그로 인코딩 실패, 디코딩 실패, 빈 본문 허용을 독립적으로 구성합니다.
struct StubBodyCoding: HTTPBodyCoding {

    // MARK: Lifecycle

    init(
        failsEncoding: Bool = false,
        failsDecoding: Bool = false,
        allowsEmptyBody: Bool = false,
    ) {
        self.failsEncoding = failsEncoding
        self.failsDecoding = failsDecoding
        self.allowsEmptyBody = allowsEmptyBody
    }

    // MARK: Internal

    let failsEncoding: Bool
    let failsDecoding: Bool
    let allowsEmptyBody: Bool

    func encode(_ body: some Encodable) throws -> Data {
        // 실패를 먼저 내보내면 HTTPClient가 전송 전에 requestEncodingFailed로 매핑하는지 확인할 수 있습니다.
        guard !failsEncoding else { throw StubBodyCodingError.expected }
        return try JSONEncoder().encode(body)
    }

    func decode<Body: Decodable>(
        _: Body.Type,
        from data: Data,
    ) throws -> Body {
        // 성공 상태 코드의 본문 변환 실패는 responseDecodingFailed로 분류돼야 합니다.
        guard !failsDecoding else { throw StubBodyCodingError.expected }

        // 클라이언트는 빈 본문을 자체 해석하지 않고 그대로 전달해야 합니다.
        // 이 대역만 빈 바이트를 빈 JSON 객체로 바꿔 EmptyPayload의 성공 규칙을 표현합니다.
        let payload =
            if data.isEmpty, allowsEmptyBody {
                Data("{}".utf8)
            } else {
                data
            }
        return try JSONDecoder().decode(Body.self, from: payload)
    }

}
