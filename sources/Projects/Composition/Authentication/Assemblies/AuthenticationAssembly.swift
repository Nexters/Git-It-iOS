import DataAuthentication
import DataShared
import Foundation

// MARK: - AuthenticationAssembly

public struct AuthenticationAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        secureStorage: (any SecureValueStorage)? = nil,
        sharedStorage: (any KeyValueStorage)? = StorageFactory.keyValueStorage(
            namespace: SessionStorageLayout.sharedSessionNamespace,
            location: .appGroup,
        ),
    ) {
        let sessionStorage = secureStorage ?? StorageFactory.secureValueStorage(
            namespace: SessionStorageLayout.namespace,
            location: .appGroup,
        )
        let requestCredentialProvider = RequestCredentialProvider(secureStorage: sessionStorage)
        self.requestCredentialProvider = requestCredentialProvider

        let markerCoding = sharedStorage.map(SharedSessionStateMarkerCoding.init(storage:))
        recordSharedSessionState = {
            await markerCoding?.save(isSignedIn: requestCredentialProvider.credential() != .signedOut)
        }
    }

    // MARK: Public

    public let requestCredentialProvider: RequestCredentialProvider

    public let recordSharedSessionState: @Sendable () async -> Void

}
