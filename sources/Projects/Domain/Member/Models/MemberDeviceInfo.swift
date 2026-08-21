public struct MemberDeviceInfo: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        deviceID: String,
        deviceType: DeviceType,
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

    public enum DeviceType: CaseIterable, Equatable, Sendable {
        case ios
    }

    public let deviceID: String
    public let deviceType: DeviceType
    public let appVersion: String
    public let osVersion: String
    /// 알림 권한이 없으면 nil을 허용한다.
    public let deviceToken: String?

}
