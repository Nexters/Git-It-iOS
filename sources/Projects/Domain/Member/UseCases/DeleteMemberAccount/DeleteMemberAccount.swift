public struct DeleteMemberAccount: DeleteMemberAccountUseCase {

    // MARK: Lifecycle

    public init(repository: MemberRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction() async throws {
        try await repository.deleteAccount()
    }

    // MARK: Private

    private let repository: MemberRepository

}
