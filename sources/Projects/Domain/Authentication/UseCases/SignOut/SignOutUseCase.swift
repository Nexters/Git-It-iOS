public protocol SignOutUseCase: Sendable {
    func callAsFunction() async -> SignOutResult
}
