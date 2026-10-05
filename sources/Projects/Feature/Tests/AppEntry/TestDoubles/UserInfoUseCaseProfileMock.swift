import DomainUseCaseInterface
import Foundation

actor UserInfoUseCaseProfileMock {

    // MARK: Lifecycle

    init(results: [Result<UserProfile, UserInfoError>] = [.failure(.temporarilyUnavailable)]) {
        self.results = results
    }

    // MARK: Internal

    nonisolated var profile: @Sendable () async throws -> UserProfile {
        { try await self() }
    }

    nonisolated var curation: @Sendable () async throws -> Curation? {
        { try await self().curation }
    }

    func callAsFunction() async throws -> UserProfile {
        callCount += 1
        return try nextResult().get()
    }

    func snapshot() -> Int {
        callCount
    }

    // MARK: Private

    private var results: [Result<UserProfile, UserInfoError>]
    private var callCount = 0

    private func nextResult() -> Result<UserProfile, UserInfoError> {
        guard !results.isEmpty else { return .failure(.temporarilyUnavailable) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
