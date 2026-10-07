public struct DeleteMemberAccount: DeleteMemberAccountUseCase {

    // MARK: Lifecycle

    public init(
        repository: MemberRepository,
        clearLocalState: @escaping @Sendable () async -> Void = { },
    ) {
        self.repository = repository
        self.clearLocalState = clearLocalState
    }

    // MARK: Public

    public func callAsFunction() async throws {
        try await repository.deleteAccount()
        await clearLocalState()
    }

    // MARK: Private

    private let repository: MemberRepository
    private let clearLocalState: @Sendable () async -> Void

}
