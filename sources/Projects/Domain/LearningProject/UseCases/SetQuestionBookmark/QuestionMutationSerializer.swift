import Foundation

public actor QuestionMutationSerializer {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func run<Value: Sendable>(
        key: String,
        _ operation: @escaping @Sendable () async throws -> Value,
    ) async throws -> Value {
        let token = UUID()
        let previous = inFlight[key]

        let task = Task<Value, Error> {
            _ = await previous?.awaitCompletion()
            return try await operation()
        }
        inFlight[key] = PendingMutation(token: token, awaitCompletion: { _ = try? await task.value })

        defer {
            if inFlight[key]?.token == token {
                inFlight[key] = nil
            }
        }

        return try await task.value
    }

    // MARK: Private

    private struct PendingMutation {
        let token: UUID
        let awaitCompletion: @Sendable () async -> Void
    }

    private var inFlight = [String: PendingMutation]()

}
