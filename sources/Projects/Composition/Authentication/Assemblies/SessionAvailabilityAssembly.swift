import DataAuthentication
import DomainAuthentication
import Foundation
import InfrastructureAuthentication

// MARK: - SessionAvailabilityAssembly

public struct SessionAvailabilityAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        keychainStore: KeychainStore,
        sharedDefaults: UserDefaults?,
    ) {
        let markerCoding = sharedDefaults.map(SharedSessionStateMarkerCoding.init(userDefaults:))
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
