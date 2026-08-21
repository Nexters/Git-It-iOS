public protocol UpdateMemberPositionUseCase: Sendable {
    func callAsFunction(_ position: MemberPosition) async throws
}
