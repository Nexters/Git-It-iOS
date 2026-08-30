import Testing

@testable import DataAuthentication

@Suite("Data 민감 값 비노출")
struct SensitiveValueExposureTests {

    @Test
    func `idToken과 accessToken, refreshToken을 설명 및 디버그 문자열에 노출하지 않는다`() {
        let idTokenMarker = "id-token-marker-9384"
        let accessMarker = "access-marker-5821"
        let refreshMarker = "refresh-marker-7492"

        let values: [Any] = [
            AppleLoginRequestDTO(idToken: idTokenMarker),
            LoginResponseDTO(accessToken: accessMarker, refreshToken: refreshMarker, needsCuration: false),
        ]

        for value in values {
            let descriptions = [String(describing: value), String(reflecting: value)]
            for description in descriptions {
                #expect(!description.contains(idTokenMarker))
                #expect(!description.contains(accessMarker))
                #expect(!description.contains(refreshMarker))
            }
        }
    }

}
