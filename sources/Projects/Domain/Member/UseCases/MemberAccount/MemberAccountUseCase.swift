public protocol MemberAccountUseCase: Sendable {
    func profile() async throws -> MemberProfile
    func updatePosition(_ position: MemberPosition) async throws
    func updateCareerLevel(_ careerLevel: CareerLevel) async throws
    func completeCuration(
        position: MemberPosition,
        careerLevel: CareerLevel,
    ) async throws
}
