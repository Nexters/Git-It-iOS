import DomainUseCaseInterface

actor AppSettingUseCaseStub: AppSettingUseCase {

    // MARK: Lifecycle

    init(
        statuses: [NotificationAuthorizationStatus] = [.authorized],
        requestedStatuses: [NotificationAuthorizationStatus] = [.authorized],
    ) {
        self.statuses = statuses
        self.requestedStatuses = requestedStatuses
    }

    // MARK: Internal

    func notificationAuthorization() async -> NotificationAuthorizationStatus {
        statusCallCount += 1
        guard !statuses.isEmpty else { return .denied }
        return statuses.count > 1 ? statuses.removeFirst() : statuses[0]
    }

    func requestNotificationAuthorization() async -> NotificationAuthorizationStatus {
        authorizationRequestCount += 1
        guard !requestedStatuses.isEmpty else { return .denied }
        return requestedStatuses.count > 1 ? requestedStatuses.removeFirst() : requestedStatuses[0]
    }

    func registerDevice() async throws {
        registerDeviceCallCount += 1
    }

    func updateDeviceToken(_ token: DeviceToken) async throws {
        updatedDeviceTokens.append(token)
    }

    func snapshot() -> (statusCallCount: Int, authorizationRequestCount: Int) {
        (statusCallCount, authorizationRequestCount)
    }

    // MARK: Private

    private var statuses: [NotificationAuthorizationStatus]
    private var requestedStatuses: [NotificationAuthorizationStatus]
    private var statusCallCount = 0
    private var authorizationRequestCount = 0
    private var registerDeviceCallCount = 0
    private var updatedDeviceTokens = [DeviceToken]()

}
