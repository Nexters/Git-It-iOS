import DataAuthentication
import DataShared
import DomainAccount
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
        let requestCredentialProvider = RequestCredentialProvider(secureStorage: sessionStorage)
        self.requestCredentialProvider = requestCredentialProvider

        let markerCoding = sharedStorage.map(SharedSessionStateMarkerCoding.init(storage:))
        signInAvailability = {
            guard let isSignedIn = await markerCoding?.loadSignedInState() else { return .appLaunchRequired }
            guard isSignedIn, await requestCredentialProvider.credential() != .signedOut else { return .signInRequired }
            return .signedIn
        }
    }

    // MARK: Public

    public let requestCredentialProvider: RequestCredentialProvider
    public let signInAvailability: @Sendable () async -> SignInAvailability

}
