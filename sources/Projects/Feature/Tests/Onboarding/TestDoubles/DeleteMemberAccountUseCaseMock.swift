import DomainAccount
import Foundation

actor DeleteMemberAccountUseCaseMock {

    // MARK: Lifecycle

    init(shouldThrow: Bool = false) {
        self.shouldThrow = shouldThrow
    }

    // MARK: Internal

    nonisolated var withdraw: @Sendable () async throws -> Void {
        { try await self() }
    }

    func callAsFunction() async throws {
        callCount += 1
        if shouldThrow {
            throw AccountError.withdrawalUnavailable
        }
    }

    func snapshot() -> Int {
        callCount
    }

    // MARK: Private

    private let shouldThrow: Bool
    private var callCount = 0

}
