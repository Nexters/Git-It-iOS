public protocol MemberRepository: Sendable {
    func completeCuration(
        position: MemberPosition,
        careerLevel: CareerLevel,
    ) async throws
    func fetchProfile() async throws -> MemberProfile
    func updatePosition(_ position: MemberPosition) async throws
    func updateCareerLevel(_ careerLevel: CareerLevel) async throws
    func registerDevice(_ device: MemberDeviceInfo) async throws
    func deleteAccount() async throws
}
