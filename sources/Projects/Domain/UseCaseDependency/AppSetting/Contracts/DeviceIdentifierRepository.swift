import DomainUseCaseInterface

public protocol DeviceIdentifierRepository: Sendable {
    func currentDeviceID() async -> DeviceID
}
