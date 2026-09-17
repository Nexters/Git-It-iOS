public protocol UserInfoRepository: Sendable {
    func profile() async throws -> UserProfile
    func updateCuration(_ curation: Curation) async throws
    func updatePosition(_ position: MemberPosition) async throws
    func updateCareerLevel(_ careerLevel: CareerLevel) async throws
}
