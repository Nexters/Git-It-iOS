public struct AppSetting: AppSettingUseCase {

    // MARK: Lifecycle

    public init(
        notificationAuthorization: any NotificationAuthorization,
        deviceRegistrationRepository: any DeviceRegistrationRepository,
        deviceIdentifierRepository: any DeviceIdentifierRepository,
        appVersion: String,
        osVersion: String,
        deviceToken: @escaping @Sendable () async throws -> DeviceToken,
    ) {
        authorization = notificationAuthorization
        self.deviceRegistrationRepository = deviceRegistrationRepository
        self.deviceIdentifierRepository = deviceIdentifierRepository
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.deviceToken = deviceToken
    }

    // MARK: Public

    public func notificationAuthorization() async -> NotificationAuthorizationStatus {
        await authorization.status()
    }

    public func requestNotificationAuthorization() async -> NotificationAuthorizationStatus {
        await authorization.requestAuthorization()
    }

    public func registerDevice() async throws {
        let token = try await deviceToken()
        try await register(token: token)
    }

    public func updateDeviceToken(_ token: DeviceToken) async throws {
        try await register(token: token)
    }

    // MARK: Private

    private let authorization: any NotificationAuthorization
    private let deviceRegistrationRepository: any DeviceRegistrationRepository
    private let deviceIdentifierRepository: any DeviceIdentifierRepository
    private let appVersion: String
    private let osVersion: String
    private let deviceToken: @Sendable () async throws -> DeviceToken

    private func register(token: DeviceToken) async throws {
        let registration = await DeviceRegistration(
            deviceID: deviceIdentifierRepository.currentDeviceID(),
            platform: .ios,
            appVersion: appVersion,
            osVersion: osVersion,
            token: token,
        )
        try await deviceRegistrationRepository.register(registration)
    }

}
