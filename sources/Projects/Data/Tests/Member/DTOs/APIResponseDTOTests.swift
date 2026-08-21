import Foundation
import Testing

@testable import DataMember

// MARK: - APIResponseDTOTests

@Suite("공통 응답 Envelope 디코딩")
struct APIResponseDTOTests {

    @Test
    func `data 키가 있으면 payload를 디코딩한다`() throws {
        let json = Data(#"{"success":true,"data":{"value":"ok"},"code":null,"message":null,"errors":null}"#.utf8)

        let response = try JSONDecoder().decode(APIResponseDTO<Payload>.self, from: json)

        #expect(response.success)
        #expect(response.data == Payload(value: "ok"))
    }

    @Test
    func `data 키가 없어도 Unit 응답을 정상 디코딩한다`() throws {
        let json = Data(#"{"success":true}"#.utf8)

        let response = try JSONDecoder().decode(APIResponseDTO<Payload>.self, from: json)

        #expect(response.success)
        #expect(response.data == nil)
    }

    @Test
    func `data 값이 null이어도 정상 디코딩한다`() throws {
        let json = Data(#"{"success":true,"data":null}"#.utf8)

        let response = try JSONDecoder().decode(APIResponseDTO<Payload>.self, from: json)

        #expect(response.success)
        #expect(response.data == nil)
    }

    @Test
    func `FieldErrorDTO는 field와 message를 디코딩한다`() throws {
        let json = Data(#"{"field":"deviceId","message":"invalid"}"#.utf8)

        let error = try JSONDecoder().decode(FieldErrorDTO.self, from: json)

        #expect(error.field == "deviceId")
        #expect(error.message == "invalid")
    }

}

// MARK: - Payload

private struct Payload: Decodable, Equatable, Sendable {
    let value: String
}
