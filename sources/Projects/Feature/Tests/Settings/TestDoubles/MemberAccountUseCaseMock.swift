import DomainMember

actor MemberAccountUseCaseMock: MemberAccountUseCase {

    // MARK: Lifecycle

    init(
        profileResults: [Result<MemberProfile, MemberError>] = [.failure(.temporarilyUnavailable)],
        positionErrors: [MemberError?] = [nil],
        careerLevelErrors: [MemberError?] = [nil],
        curationResults: [Result<Void, MemberError>] = [.success(())],
    ) {
        self.profileResults = profileResults
        self.positionErrors = positionErrors
        self.careerLevelErrors = careerLevelErrors
        self.curationResults = curationResults
    }

    // MARK: Internal

    struct CurationCall: Equatable {
        let position: MemberPosition
        let careerLevel: CareerLevel
    }

    func profile() async throws -> MemberProfile {
        profileCallCount += 1
        guard !profileResults.isEmpty else { throw MemberError.temporarilyUnavailable }
        let result = profileResults.count > 1 ? profileResults.removeFirst() : profileResults[0]
        return try result.get()
    }

    func updatePosition(_ position: MemberPosition) async throws {
        requestedPositions.append(position)
        if let error = next(&positionErrors) {
            throw error
        }
    }

    func updateCareerLevel(_ careerLevel: CareerLevel) async throws {
        requestedCareerLevels.append(careerLevel)
        if let error = next(&careerLevelErrors) {
            throw error
        }
    }

    func completeCuration(
        position: MemberPosition,
        careerLevel: CareerLevel,
    ) async throws {
        curationCalls.append(CurationCall(position: position, careerLevel: careerLevel))
        guard !curationResults.isEmpty else { return }
        let result = curationResults.count > 1 ? curationResults.removeFirst() : curationResults[0]
        try result.get()
    }

    func snapshot() -> (
        profileCallCount: Int,
        positions: [MemberPosition],
        careerLevels: [CareerLevel],
        curationCalls: [CurationCall]
    ) {
        (profileCallCount, requestedPositions, requestedCareerLevels, curationCalls)
    }

    // MARK: Private

    private var profileResults: [Result<MemberProfile, MemberError>]
    private var positionErrors: [MemberError?]
    private var careerLevelErrors: [MemberError?]
    private var curationResults: [Result<Void, MemberError>]

    private var profileCallCount = 0
    private var requestedPositions = [MemberPosition]()
    private var requestedCareerLevels = [CareerLevel]()
    private var curationCalls = [CurationCall]()

    private func next(_ errors: inout [MemberError?]) -> MemberError? {
        guard !errors.isEmpty else { return nil }
        return errors.count > 1 ? errors.removeFirst() : errors[0]
    }

}
