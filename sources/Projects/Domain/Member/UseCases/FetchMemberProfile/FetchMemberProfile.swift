public struct FetchMemberProfile: FetchMemberProfileUseCase {

    // MARK: Lifecycle

    public init(repository: MemberRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction() async throws -> MemberProfile {
        try await repository.fetchProfile()
    }

    // MARK: Private

    private let repository: MemberRepository

}
