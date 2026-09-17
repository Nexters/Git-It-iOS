import DomainUserInfo

actor UpdateMemberPositionUseCaseMock {

    // MARK: Lifecycle

    init(errors: [UserInfoError?] = [nil]) {
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

    private var errors: [UserInfoError?]
    private var requestedPositions = [MemberPosition]()

    private func nextError() -> UserInfoError? {
        guard !errors.isEmpty else { return nil }
        return errors.count > 1 ? errors.removeFirst() : errors[0]
    }

}
