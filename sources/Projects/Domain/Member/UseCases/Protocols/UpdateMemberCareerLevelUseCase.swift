public protocol UpdateMemberCareerLevelUseCase: Sendable {
    func callAsFunction(_ careerLevel: CareerLevel) async throws
}
