// MARK: - RefreshSession

public struct RefreshSession: RefreshSessionUseCase {

    // MARK: Lifecycle

    public init(
        loginSessionRepository: any LoginSessionRepository,
        coordinator: SingleFlightCoordinator = SingleFlightCoordinator(),
    ) {
        self.loginSessionRepository = loginSessionRepository
        self.coordinator = coordinator
    }

    // MARK: Public

    public func callAsFunction() async -> SessionRefreshOutcome {
        await coordinator.run {
            do {
                let tokens = try await loginSessionRepository.refresh()
                try await loginSessionRepository.replaceTokens(tokens)
                return .refreshed(tokens)
            } catch let error as LoginSessionError {
                switch error {
                case .temporarilyUnavailable:
                    return .temporarilyUnavailable

                case .refreshRejectedOrExpired,
                     .accountUnavailable,
                     .unauthorized:
                    return .rejected
                }
            } catch {
                return .temporarilyUnavailable
            }
        }
    }

    // MARK: Private

    private let loginSessionRepository: any LoginSessionRepository
    private let coordinator: SingleFlightCoordinator

}
