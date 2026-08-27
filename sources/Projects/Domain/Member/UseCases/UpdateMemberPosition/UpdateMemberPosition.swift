public struct UpdateMemberPosition: UpdateMemberPositionUseCase {

    // MARK: Lifecycle

    public init(
        repository: MemberRepository,
        serializer: MemberMutationSerializer = MemberMutationSerializer(),
    ) {
        self.repository = repository
        self.serializer = serializer
    }

    // MARK: Public

    public func callAsFunction(_ position: MemberPosition) async throws {
        try await serializer.run(key: "position") {
            try await repository.updatePosition(position)
        }
    }

    // MARK: Private

    private let repository: MemberRepository
    private let serializer: MemberMutationSerializer

}
