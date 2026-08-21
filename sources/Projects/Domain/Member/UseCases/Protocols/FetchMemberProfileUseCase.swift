public protocol FetchMemberProfileUseCase: Sendable {
    func callAsFunction() async throws -> MemberProfile
}
