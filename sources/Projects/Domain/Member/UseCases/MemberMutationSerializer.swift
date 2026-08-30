import Foundation

public actor MemberMutationSerializer {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func run(
        key: String,
        _ operation: @escaping @Sendable () async throws -> Void,
    ) async throws {
        let token = UUID()
        let previous = inFlight[key]

        let task = Task<Void, Error> {
            _ = await previous?.awaitCompletion()
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

    // MARK: Private

    private struct PendingMutation {
        let token: UUID
        let awaitCompletion: @Sendable () async -> Void
    }

    private var inFlight = [String: PendingMutation]()

}
