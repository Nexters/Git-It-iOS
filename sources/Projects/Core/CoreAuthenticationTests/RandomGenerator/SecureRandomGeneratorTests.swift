import Testing

@testable import CoreAuthentication

@Suite("SecureRandomGenerator")
struct SecureRandomGeneratorTests {
    @Test
    func `nonce state attemptID grantID용 CSPRNG 값을 생성한다`() throws {
        let generator = SecureRandomGenerator()
        let values = try [generator.value(length: 24), generator.value(length: 24)]
        #expect(values.allSatisfy { $0.count == 24 })
        #expect(values[0] != values[1])
    }

    @Test
    func `난수 생성 실패를 기술 오류로 전달한다`() {
        let generator = SecureRandomGenerator(bytes: { _ in throw SecureRandomGeneratorError.unavailable })
        #expect(throws: SecureRandomGeneratorError.unavailable) { try generator.value(length: 24) }
    }
}
