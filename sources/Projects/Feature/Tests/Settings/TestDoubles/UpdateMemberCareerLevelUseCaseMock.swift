import DomainMember

actor UpdateMemberCareerLevelUseCaseMock {

    // MARK: Lifecycle

    init(errors: [MemberError?] = [nil]) {
        self.errors = errors
    }

    // MARK: Internal

    nonisolated var updateCareerLevel: @Sendable (CareerLevel) async throws -> Void {
        { try await self($0) }
    }

    func callAsFunction(_ careerLevel: CareerLevel) async throws {
        requestedCareerLevels.append(careerLevel)
        if let error = nextError() {
            throw error
        }
    }

    func snapshot() -> [CareerLevel] {
        requestedCareerLevels
    }

    // MARK: Private

    private var errors: [MemberError?]
    private var requestedCareerLevels = [CareerLevel]()

    private func nextError() -> MemberError? {
        guard !errors.isEmpty else { return nil }
        return errors.count > 1 ? errors.removeFirst() : errors[0]
    }

}
