import Foundation

// MARK: - MemberAccount

public actor MemberAccount: MemberAccountUseCase {

    // MARK: Lifecycle

    public init(repository: any MemberRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func profile() async throws -> MemberProfile {
        try await repository.fetchProfile()
    }

    public func updatePosition(_ position: MemberPosition) async throws {
        let repository = repository
        try await serialize(key: "position") {
            try await repository.updatePosition(position)
        }
    }

    public func updateCareerLevel(_ careerLevel: CareerLevel) async throws {
        let repository = repository
        try await serialize(key: "careerLevel") {
            try await repository.updateCareerLevel(careerLevel)
        }
    }

    public func completeCuration(
        position: MemberPosition,
        careerLevel: CareerLevel,
    ) async throws {
        let repository = repository
        try await serialize(key: "curation") {
            try await repository.completeCuration(position: position, careerLevel: careerLevel)
        }
    }

    // MARK: Internal

    var pendingKeyCount: Int { inFlight.count }

    // MARK: Private

    private struct PendingMutation {
        let token: UUID
        let awaitCompletion: @Sendable () async -> Void
    }

    private let repository: any MemberRepository

    private var inFlight = [String: PendingMutation]()

    private func serialize(
        key: String,
        _ operation: @escaping @Sendable () async throws -> Void,
    ) async throws {
        let token = UUID()
        let previous = inFlight[key]

        let task = Task<Void, Error> {
            await previous?.awaitCompletion()
            try await operation()
        }
        inFlight[key] = PendingMutation(token: token, awaitCompletion: { _ = try? await task.value })

        defer {
            if inFlight[key]?.token == token {
                inFlight[key] = nil
            }
        }

        try await task.value
    }

}
