import DomainUserInfo

actor UserInfoUseCaseCareerLevelMock {

    // MARK: Lifecycle

    init(errors: [UserInfoError?] = [nil]) {
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

    private var errors: [UserInfoError?]
    private var requestedCareerLevels = [CareerLevel]()

    private func nextError() -> UserInfoError? {
        guard !errors.isEmpty else { return nil }
        return errors.count > 1 ? errors.removeFirst() : errors[0]
    }

}
