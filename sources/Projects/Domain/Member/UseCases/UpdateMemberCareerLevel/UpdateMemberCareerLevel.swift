public struct UpdateMemberCareerLevel: UpdateMemberCareerLevelUseCase {

    // MARK: Lifecycle

    public init(
        repository: MemberRepository,
        serializer: MemberMutationSerializer = MemberMutationSerializer(),
    ) {
        self.repository = repository
        self.serializer = serializer
    }

    // MARK: Public

    public func callAsFunction(_ careerLevel: CareerLevel) async throws {
        try await serializer.run(key: "careerLevel") {
            try await repository.updateCareerLevel(careerLevel)
        }
    }

    // MARK: Private

    private let repository: MemberRepository
    private let serializer: MemberMutationSerializer

}
