public protocol CompleteCurationUseCase: Sendable {
    func callAsFunction(
        position: MemberPosition,
        careerLevel: CareerLevel,
    ) async throws
}
