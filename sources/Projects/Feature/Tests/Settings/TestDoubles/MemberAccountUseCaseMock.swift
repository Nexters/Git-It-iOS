import DomainUserInfo

actor MemberAccountUseCaseMock: UserInfoUseCase {

    // MARK: Lifecycle

    init(
        profileResults: [Result<UserProfile, UserInfoError>] = [.failure(.temporarilyUnavailable)],
        positionErrors: [UserInfoError?] = [nil],
        careerLevelErrors: [UserInfoError?] = [nil],
        curationResults: [Result<Void, UserInfoError>] = [.success(())],
    ) {
        self.profileResults = profileResults
        self.positionErrors = positionErrors
        self.careerLevelErrors = careerLevelErrors
        self.curationResults = curationResults
    }

    // MARK: Internal

    func detail() async throws -> UserDetail {
        try nextProfile().detail
    }

    func curation() async throws -> Curation? {
        try nextProfile().curation
    }

    func updateCuration(_ curation: Curation) async throws {
        curations.append(curation)
        guard !curationResults.isEmpty else { return }
        let result = curationResults.count > 1 ? curationResults.removeFirst() : curationResults[0]
        try result.get()
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

    func snapshot() -> (
        profileCallCount: Int,
        positions: [MemberPosition],
        careerLevels: [CareerLevel],
        curations: [Curation],
    ) {
        (profileCallCount, requestedPositions, requestedCareerLevels, curations)
    }

    // MARK: Private

    private var profileResults: [Result<UserProfile, UserInfoError>]
    private var positionErrors: [UserInfoError?]
    private var careerLevelErrors: [UserInfoError?]
    private var curationResults: [Result<Void, UserInfoError>]

    private var profileCallCount = 0
    private var requestedPositions = [MemberPosition]()
    private var requestedCareerLevels = [CareerLevel]()
    private var curations = [Curation]()

    private func nextProfile() throws -> UserProfile {
        profileCallCount += 1
        guard !profileResults.isEmpty else { throw UserInfoError.temporarilyUnavailable }
        let result = profileResults.count > 1 ? profileResults.removeFirst() : profileResults[0]
        return try result.get()
    }

    private func next(_ errors: inout [UserInfoError?]) -> UserInfoError? {
        guard !errors.isEmpty else { return nil }
        return errors.count > 1 ? errors.removeFirst() : errors[0]
    }

}
