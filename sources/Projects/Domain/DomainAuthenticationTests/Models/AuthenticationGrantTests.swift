import Testing

@testable import DomainAuthentication

@Suite("인증 grant")
struct AuthenticationGrantTests {
    @Test
    func `불투명 ID와 인증 방식만 보유한다`() {
        let id = AuthenticationGrant.ID(rawValue: "opaque-grant-id")
        let grant = AuthenticationGrant(id: id, method: .apple)

        #expect(grant.id == id)
        #expect(grant.method == .apple)

        let fieldNames = Set(Mirror(reflecting: grant).children.compactMap(\.label))
        #expect(fieldNames == ["id", "method"])
        #expect(!fieldNames.contains("credential"))
        #expect(!fieldNames.contains("token"))
    }
}
