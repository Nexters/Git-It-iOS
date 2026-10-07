// MARK: - DeviceIdentifierRepository

public protocol DeviceIdentifierRepository: Sendable {
    func currentDeviceID() async -> String
}
