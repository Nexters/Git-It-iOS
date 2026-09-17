import DataAuthentication
import DataShared
import DomainAuthentication
import Foundation

// MARK: - SessionAvailabilityAssembly

public struct SessionAvailabilityAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        secureStorage: (any SecureValueStorage)?,
        sharedStorage: (any KeyValueStorage)?,
    ) {
        let sessionStorage = secureStorage ?? StorageFactory.secureValueStorage(
            namespace: SessionStorageLayout.namespace,
            location: .appGroup,
        )
        let markerCoding = sharedStorage.map(SharedSessionStateMarkerCoding.init(storage:))
        let resolveSessionAvailability: @Sendable () async -> SessionAvailability = {
            guard let markerCoding else { return .appLaunchRequired }
            return await ResolveSessionAvailability(
                signInStateRepository: SharedSignInStateRepositoryAdapter(markerCoding: markerCoding),
                sessionRepository: CurrentSessionRepositoryAdapter(secureStorage: sessionStorage),
            )()
        }
        self.resolveSessionAvailability = resolveSessionAvailability
        accessTokenProvider = {
            guard case .available(let accessToken) = await resolveSessionAvailability() else { return nil }
            return accessToken
        }
    }

    // MARK: Public

    public let resolveSessionAvailability: @Sendable () async -> SessionAvailability
    public let accessTokenProvider: @Sendable () async -> String?

}
