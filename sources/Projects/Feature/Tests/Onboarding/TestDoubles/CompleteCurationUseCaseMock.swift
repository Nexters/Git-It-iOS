import DomainUserInfo
import Foundation

actor CompleteCurationUseCaseMock {

    // MARK: Lifecycle

    init(results: [Result<Void, UserInfoError>] = [.success(())]) {
        self.results = results
    }

    // MARK: Internal

    nonisolated var updateCuration: @Sendable (Curation) async throws -> Void {
        { try await self($0) }
    }

    func callAsFunction(_ curation: Curation) async throws {
        calls.append(curation)
        try nextResult().get()
    }

    func snapshot() -> [Curation] {
        calls
    }

    // MARK: Private

    private var results: [Result<Void, UserInfoError>]
    private var calls = [Curation]()

    private func nextResult() -> Result<Void, UserInfoError> {
        guard !results.isEmpty else { return .success(()) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
