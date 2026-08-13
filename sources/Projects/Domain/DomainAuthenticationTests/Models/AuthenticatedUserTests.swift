import Testing

@testable import DomainAuthentication

@Suite("인증 사용자")
struct AuthenticatedUserTests {
    @Test
    func `서버 사용자 ID와 이용 가능 상태 및 선택적 표시 이름만 표현한다`() {
        let availableUser = AuthenticatedUser(
            id: "user-1",
            availability: .available,
            displayName: "Git It 사용자",
        )
        let unavailableUser = AuthenticatedUser(
            id: "user-2",
            availability: .unavailable,
            displayName: nil,
        )

        #expect(availableUser.id == "user-1")
        #expect(availableUser.availability == .available)
        #expect(availableUser.displayName == "Git It 사용자")
        #expect(unavailableUser.availability == .unavailable)
        #expect(unavailableUser.displayName == nil)

        let fieldNames = Set(Mirror(reflecting: availableUser).children.compactMap(\.label))
        #expect(fieldNames == ["id", "availability", "displayName"])
    }
}
