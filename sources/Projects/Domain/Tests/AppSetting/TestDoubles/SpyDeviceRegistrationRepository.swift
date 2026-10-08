import DomainUseCaseDependency
@testable import DomainUseCaseInterface

actor SpyDeviceRegistrationRepository: DeviceRegistrationRepository, DeviceIdentifierRepository {

    // MARK: Lifecycle

    init(deviceID: DeviceID = "device-1") {
        self.deviceID = deviceID
    }

    // MARK: Internal

    private(set) var registrations = [DeviceRegistration]()

    func register(_ registration: DeviceRegistration) async throws {
        registrations.append(registration)
    }

    func currentDeviceID() async -> DeviceID {
        deviceID
    }

    // MARK: Private

    private let deviceID: DeviceID

}
