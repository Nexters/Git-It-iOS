public actor UserInfo: UserInfoUseCase {

    // MARK: Lifecycle

    public init(repository: any UserInfoRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func detail() async throws -> UserDetail {
        try await sharedProfile().detail
    }

    public func curation() async throws -> Curation? {
        try await sharedProfile().curation
    }

    public func updateCuration(_ curation: Curation) async throws {
        let repository = repository
        try await serialize {
            try await repository.updateCuration(curation)
        }
    }

    public func updatePosition(_ position: MemberPosition) async throws {
        let repository = repository
        try await serialize {
            try await repository.updatePosition(position)
        }
    }

    public func updateCareerLevel(_ careerLevel: CareerLevel) async throws {
        let repository = repository
        try await serialize {
            try await repository.updateCareerLevel(careerLevel)
        }
    }

    // MARK: Private

    private let repository: any UserInfoRepository

    private var profileTask: Task<UserProfile, Error>?
    private var lastMutation: Task<Void, Never>?

    private func sharedProfile() async throws -> UserProfile {
        if let profileTask {
            return try await profileTask.value
        }
        let repository = repository
        let task = Task<UserProfile, Error> {
            try await repository.profile()
        }
        profileTask = task
        defer { profileTask = nil }
        return try await task.value
    }

    private func serialize(_ operation: @escaping @Sendable () async throws -> Void) async throws {
        let previous = lastMutation
        let task = Task<Void, Error> {
            await previous?.value
            try await operation()
        }
        lastMutation = Task { _ = try? await task.value }
        try await task.value
    }

}
