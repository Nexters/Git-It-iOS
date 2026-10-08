public struct DeviceRegistration: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        deviceID: DeviceID,
        platform: DevicePlatform,
        appVersion: String,
        osVersion: String,
        token: DeviceToken?,
    ) {
        self.deviceID = deviceID
        self.platform = platform
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.token = token
    }

    // MARK: Public

    public let deviceID: DeviceID
    public let platform: DevicePlatform
    public let appVersion: String
    public let osVersion: String
    public let token: DeviceToken?

}
