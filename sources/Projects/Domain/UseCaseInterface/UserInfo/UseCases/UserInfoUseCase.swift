public protocol UserInfoUseCase: Sendable {
    func detail() async throws -> UserDetail
    func curation() async throws -> Curation?
    func updateCuration(_ curation: Curation) async throws
    func updatePosition(_ position: MemberPosition) async throws
    func updateCareerLevel(_ careerLevel: CareerLevel) async throws
}
