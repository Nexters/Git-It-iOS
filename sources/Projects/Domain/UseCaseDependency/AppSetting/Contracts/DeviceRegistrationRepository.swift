import DomainUseCaseInterface

public protocol DeviceRegistrationRepository: Sendable {
    func register(_ registration: DeviceRegistration) async throws
}
