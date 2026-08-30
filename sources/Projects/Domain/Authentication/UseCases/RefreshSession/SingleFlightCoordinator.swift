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

        let task = Task { await operation() }
        inFlight = task
        defer { inFlight = nil }
        return await task.value
    }

    // MARK: Private

    private var inFlight: Task<SessionRefreshOutcome, Never>?

}
