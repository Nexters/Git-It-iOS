import DomainMember

actor UpdateMemberPositionUseCaseMock {

    // MARK: Lifecycle

    init(errors: [MemberError?] = [nil]) {
        self.errors = errors
    }

    // MARK: Internal

    nonisolated var updatePosition: @Sendable (MemberPosition) async throws -> Void {
        { try await self($0) }
    }

    func callAsFunction(_ position: MemberPosition) async throws {
        requestedPositions.append(position)
        if let error = nextError() {
            throw error
        }
    }

    func snapshot() -> [MemberPosition] {
        requestedPositions
    }

    // MARK: Private

    private var errors: [MemberError?]
    private var requestedPositions = [MemberPosition]()

    private func nextError() -> MemberError? {
        guard !errors.isEmpty else { return nil }
        return errors.count > 1 ? errors.removeFirst() : errors[0]
    }

}
