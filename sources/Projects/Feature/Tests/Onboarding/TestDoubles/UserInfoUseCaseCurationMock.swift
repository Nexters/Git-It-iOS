import DomainUserInfo
import Foundation

actor UserInfoUseCaseCurationMock {

    // MARK: Lifecycle

    init(
        results: [Result<Void, UserInfoError>] = [.success(())],
        suspendsRequests: Bool = false,
    ) {
        self.results = results
        self.suspendsRequests = suspendsRequests
    }

    // MARK: Internal

    nonisolated var updateCuration: @Sendable (Curation) async throws -> Void {
        { try await self($0) }
    }

    func callAsFunction(_ curation: Curation) async throws {
        calls.append(curation)
        let result = nextResult()
        guard suspendsRequests else { return try result.get() }

        return try await withCheckedThrowingContinuation { continuation in
            continuations.append((continuation, result))
        }
    }

    func snapshot() -> [Curation] {
        calls
    }

    func resumeOldest() {
        guard !continuations.isEmpty else { return }
        let (continuation, result) = continuations.removeFirst()
        continuation.resume(with: result)
    }

    // MARK: Private

    private var results: [Result<Void, UserInfoError>]
    private let suspendsRequests: Bool
    private var calls = [Curation]()
    private var continuations = [(CheckedContinuation<Void, any Error>, Result<Void, UserInfoError>)]()

    private func nextResult() -> Result<Void, UserInfoError> {
        guard !results.isEmpty else { return .success(()) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
