public actor SingleFlightCoordinator {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func run(
        _ operation: @escaping @Sendable () async -> SessionRefreshOutcome
    ) async -> SessionRefreshOutcome {
        if let inFlight {
            return await inFlight.value
        }

        let task = Task { [weak self] () -> SessionRefreshOutcome in
            let outcome = await operation()
            await self?.clearInFlight()
            return outcome
        }
        inFlight = task
        return await task.value
    }

    // MARK: Private

    private var inFlight: Task<SessionRefreshOutcome, Never>?

    private func clearInFlight() {
        inFlight = nil
    }

}
