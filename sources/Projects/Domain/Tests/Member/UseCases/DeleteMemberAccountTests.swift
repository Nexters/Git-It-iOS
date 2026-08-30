import Testing

@testable import DomainMember

// MARK: - DeleteMemberAccountTests

@Suite("DeleteMemberAccount")
struct DeleteMemberAccountTests {
    @Test
    func `성공하면 정확히 한 번 요청한다`() async throws {
        let repository = DeleteMemberAccountRepository()
        let deleteMemberAccount = DeleteMemberAccount(repository: repository)

        try await deleteMemberAccount()

        #expect(await repository.callCount == 1)
    }

    @Test
    func `실패하면 오류를 그대로 전파한다`() async throws {
        let repository = DeleteMemberAccountRepository(behavior: .fail)
        let deleteMemberAccount = DeleteMemberAccount(repository: repository)

        await #expect(throws: MemberError.temporarilyUnavailable) {
            try await deleteMemberAccount()
        }
    }
}

// MARK: - DeleteMemberAccountRepository

private actor DeleteMemberAccountRepository: MemberRepository {

    // MARK: Lifecycle

    init(behavior: Behavior = .succeed) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed
        case fail
    }

    private(set) var callCount = 0

    func completeCuration(
        position _: MemberPosition,
        careerLevel _: CareerLevel,
    ) async throws { }
    func fetchProfile() async throws -> MemberProfile {
        throw MemberError.memberUnavailable
    }

    func updatePosition(_: MemberPosition) async throws { }
    func updateCareerLevel(_: CareerLevel) async throws { }
    func registerDevice(_: MemberDeviceInfo) async throws { }

    func deleteAccount() async throws {
        callCount += 1
        if case .fail = behavior {
            throw MemberError.temporarilyUnavailable
        }
    }

    // MARK: Private

    private let behavior: Behavior

}
