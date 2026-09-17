import DataAuthentication
import DataShared
import DomainAuthentication
import Foundation
import InfrastructureAuthentication

// MARK: - SessionAvailabilityAssembly

public struct SessionAvailabilityAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        keychainStore: KeychainStore,
        sharedStorage: (any KeyValueStorage)?,
    ) {
        let markerCoding = sharedStorage.map(SharedSessionStateMarkerCoding.init(storage:))
        let resolveSessionAvailability: @Sendable () async -> SessionAvailability = {
            guard let markerCoding else { return .appLaunchRequired }
            return await ResolveSessionAvailability(
                signInStateRepository: SharedSignInStateRepositoryAdapter(markerCoding: markerCoding),
                sessionRepository: CurrentSessionRepositoryAdapter(keychainStore: keychainStore),
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
