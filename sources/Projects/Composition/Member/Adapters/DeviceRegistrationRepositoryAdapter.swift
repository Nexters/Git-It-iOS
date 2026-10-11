import DataMember
import DomainUseCaseDependency
import DomainUseCaseInterface

// MARK: - DeviceRegistrationRepositoryAdapter

public struct DeviceRegistrationRepositoryAdapter: DeviceRegistrationRepository {

    // MARK: Lifecycle

    public init(remote: MemberRemote) {
        self.remote = remote
    }

    // MARK: Public

    public func register(_ registration: DeviceRegistration) async throws {
        do {
            try await remote.registerDeviceInfo(DeviceInfoRequestDTO(
                deviceID: registration.deviceID,
                deviceType: deviceType(registration.platform),
                appVersion: registration.appVersion,
                osVersion: registration.osVersion,
                deviceToken: registration.token,
            ))
        } catch let error as MemberServiceError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: MemberRemote

    private func deviceType(_ platform: DevicePlatform) -> String {
        switch platform {
        case .ios: "ios"
        @unknown default: "ios"
        }
    }

    private func domainError(for error: MemberServiceError) -> AppSettingError {
        switch error {
        case .invalidRequest:
            .invalidRequest

        case .unauthorized:
            .unauthorized

        case .memberUnavailable,
             .temporarilyUnavailable,
             .transport,
             .unexpectedStatus:
            .temporarilyUnavailable

        @unknown default:
            .temporarilyUnavailable
        }
    }

}
