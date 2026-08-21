import Foundation

/// UC17/UC18처럼 서로 다른 필드를 독립적으로 변경하는 mutation을 key별로 직렬화하는 actor.
/// 같은 key의 중복 제출은 순차 실행되고, 서로 다른 key는 서로 영향을 주지 않는다.
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
