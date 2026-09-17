import CompositionShared
import DataMember
import DataShared
import DomainAuthentication
import DomainMember
import Foundation
import InfrastructureNetworkClient

// MARK: - MemberAssembly

public struct MemberAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        loginSessionRepository: any LoginSessionRepository,
        accessTokenProvider: @escaping @Sendable () async -> String?,
        clearLocalStateAfterAccountDeletion: @escaping @Sendable () async -> Void = { },
        transport: (any HTTPTransport)? = nil,
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
    ) {
        let client = makeHTTPClient(baseURL: baseURL, responseTimeout: responseTimeout, transport: transport)
        let baseRepository = MemberRepositoryAdapter(
            remote: MemberRemote(client: client, accessTokenProvider: accessTokenProvider)
        )
        let repository = CurationRepositoryAdapter(
            remote: baseRepository,
            loginSessionRepository: loginSessionRepository,
        )

        memberAccount = MemberAccount(repository: repository)
        self.repository = repository
        deleteMemberAccount = DeleteMemberAccount(
            repository: repository,
            clearLocalState: clearLocalStateAfterAccountDeletion,
        )
    }

    // MARK: Public

    public let memberAccount: any MemberAccountUseCase
    public let deleteMemberAccount: any DeleteMemberAccountUseCase

    public func makeRegisterCurrentDevice(
        secureStorage: (any SecureValueStorage)?,
        appVersion: String,
        osVersion: String,
        deviceTokenProvider: @escaping @Sendable () async throws -> String,
    ) -> @Sendable () async throws -> Void {
        let registerCurrentDevice = RegisterCurrentDevice(
            repository: repository,
            deviceIdentifierRepository: DeviceIdentifierRepositoryAdapter(
                secureStorage: secureStorage ?? StorageFactory.secureValueStorage(
                    namespace: LocalDeviceIdentifierStore.namespace,
                    location: .appGroup,
                )
            ),
            appVersion: appVersion,
            osVersion: osVersion,
            deviceTokenProvider: deviceTokenProvider,
        )
        return { try await registerCurrentDevice() }
    }

    // MARK: Private

    private let repository: any MemberRepository

}
