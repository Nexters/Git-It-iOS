// MARK: - RegisterCurrentDevice

public struct RegisterCurrentDevice: RegisterCurrentDeviceUseCase {

    // MARK: Lifecycle

    public init(
        repository: any MemberRepository,
        deviceIdentifierRepository: any DeviceIdentifierRepository,
        appVersion: String,
        osVersion: String,
        deviceTokenProvider: @escaping @Sendable () async throws -> String,
    ) {
        self.repository = repository
        self.deviceIdentifierRepository = deviceIdentifierRepository
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.deviceTokenProvider = deviceTokenProvider
    }

    // MARK: Public

    public func callAsFunction() async throws {
        let deviceToken = try await deviceTokenProvider()
        let deviceID = await deviceIdentifierRepository.currentDeviceID()
        try await repository.registerDevice(MemberDeviceInfo(
            deviceID: deviceID,
            deviceType: .ios,
            appVersion: appVersion,
            osVersion: osVersion,
            deviceToken: deviceToken,
        ))
    }

    // MARK: Private

    private let repository: any MemberRepository
    private let deviceIdentifierRepository: any DeviceIdentifierRepository
    private let appVersion: String
    private let osVersion: String
    private let deviceTokenProvider: @Sendable () async throws -> String

}
