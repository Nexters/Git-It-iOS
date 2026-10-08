import DataAuthentication
import DataMember
import DataShared
import DomainUseCaseImplementation
import DomainUseCaseInterface
import Foundation

// MARK: - MemberAssembly

public struct MemberAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        credential: @escaping @Sendable () async -> RequestCredential,
        credentialRejected: @escaping @Sendable () async -> Void,
        secureStorage: (any SecureValueStorage)? = nil,
        transport: (any RequestTransport)? = nil,
        responseTimeout: Duration = RequestClientFactory.defaultResponseTimeout,
    ) {
        let sessionStorage = secureStorage ?? StorageFactory.secureValueStorage(
            namespace: SessionStorageLayout.namespace,
            location: .appGroup,
        )
        userInfo = UserInfo(
            repository: UserInfoRepositoryAdapter(
                remote: MemberRemote(
                    baseURL: baseURL,
                    transport: transport,
                    responseTimeout: responseTimeout,
                    credential: credential,
                    credentialRejected: credentialRejected,
                ),
                sessionStorage: sessionStorage,
            )
        )
    }

    // MARK: Public

    public let userInfo: any UserInfoUseCase

}
