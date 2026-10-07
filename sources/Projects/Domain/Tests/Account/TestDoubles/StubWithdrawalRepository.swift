@testable import DomainAccount

actor StubWithdrawalRepository: WithdrawalRepository {

    // MARK: Lifecycle

    init(error: AccountError? = nil) {
        self.error = error
    }

    // MARK: Internal

    private(set) var withdrawCount = 0

    func withdraw() async throws {
        withdrawCount += 1
        if let error {
            throw error
        }
    }

    // MARK: Private

    private let error: AccountError?

}
