public struct DeviceInfoRequestDTO: Encodable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        deviceID: String,
        deviceType: String,
        appVersion: String,
        osVersion: String,
        deviceToken: String?,
    ) {
        self.deviceID = deviceID
        self.deviceType = deviceType
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.deviceToken = deviceToken
    }

    // MARK: Public

    public let deviceID: String
    public let deviceType: String
    public let appVersion: String
    public let osVersion: String
    public let deviceToken: String?

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case deviceID = "deviceId"
        case deviceType
        case appVersion
        case osVersion
        case deviceToken
    }

}
