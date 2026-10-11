public protocol WithdrawalRepository: Sendable {
    func withdraw() async throws
}
