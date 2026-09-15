// MARK: - RegisterCurrentDevice

public struct RegisterCurrentDevice: RegisterCurrentDeviceUseCase {

    // MARK: Lifecycle

    public init(
        registerMemberDevice: any RegisterMemberDeviceUseCase,
        deviceIdentifierRepository: any DeviceIdentifierRepository,
        appVersion: String,
        osVersion: String,
        deviceTokenProvider: @escaping @Sendable () async throws -> String,
    ) {
        self.registerMemberDevice = registerMemberDevice
        self.deviceIdentifierRepository = deviceIdentifierRepository
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.deviceTokenProvider = deviceTokenProvider
    }

    // MARK: Public

    public func callAsFunction() async throws {
        let deviceToken = try await deviceTokenProvider()
        let deviceID = await deviceIdentifierRepository.currentDeviceID()
        try await registerMemberDevice(MemberDeviceInfo(
            deviceID: deviceID,
            deviceType: .ios,
            appVersion: appVersion,
            osVersion: osVersion,
            deviceToken: deviceToken,
        ))
    }

    // MARK: Private

    private let registerMemberDevice: any RegisterMemberDeviceUseCase
    private let deviceIdentifierRepository: any DeviceIdentifierRepository
    private let appVersion: String
    private let osVersion: String
    private let deviceTokenProvider: @Sendable () async throws -> String

}
