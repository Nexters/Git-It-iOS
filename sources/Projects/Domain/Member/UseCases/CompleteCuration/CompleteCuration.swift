public struct CompleteCuration: CompleteCurationUseCase {

    // MARK: Lifecycle

    public init(repository: MemberRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(
        position: MemberPosition,
        careerLevel: CareerLevel,
    ) async throws {
        try await repository.completeCuration(position: position, careerLevel: careerLevel)
    }

    // MARK: Private

    private let repository: MemberRepository

}
