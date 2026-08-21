// MARK: - RefreshSession

/// UC12 — Session refresh 구조 구현. 서버 refresh endpoint는 미확보(`INT-API-001`)이므로
/// `loginSessionRepository.refresh()`가 capability 부재를 던지는 경로까지만 다루며 임의
/// request/response 계약을 만들지 않는다. 동시 401은 `SingleFlightCoordinator`가 하나의
/// 실행에 합류시킨다.
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

// MARK: - SingleFlightCoordinator

/// 동시 호출을 하나의 in-flight 작업에 합류시키는 single-flight 실행기.
/// `RefreshSession`과 같은 무인자 async 재실행을 안전하게 공유한다.
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
